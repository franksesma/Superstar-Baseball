-- ReplicatedStorage/SharedModules/PitchTrajectory.lua
-- Shared deterministic pitch trajectory for both server + client.

local PitchTrajectory = {}
PitchTrajectory.__index = PitchTrajectory

-- === basic helpers ===

local function lerp(a: Vector3, b: Vector3, t: number): Vector3
	return a + (b - a) * t
end

local function quadraticBezier(t: number, p0: Vector3, p1: Vector3, p2: Vector3): Vector3
	local l1 = lerp(p0, p1, t)
	local l2 = lerp(p1, p2, t)
	return lerp(l1, l2, t)
end

local function tornadoMotion(t: number, startPos: Vector3, midPos: Vector3, endPos: Vector3, amplitude: number, frequency: number): Vector3
	local bezierPos = quadraticBezier(t, startPos, midPos, endPos)
	local sideMovement = math.sin(t * frequency * math.pi * 2) * amplitude
	return bezierPos + Vector3.new(sideMovement, 0, 0)
end

-- === ctor ===
-- params:
--  From, Middle, Target: Vector3
--  Power: number
--  AbilityName: string? ("Whirlwind", "Meditation", etc.)
--  Direct: boolean? (force straight line)
--  Speed: number? (for direct)
--  PitchType: string? ("Slowball", "Knuckleball", etc.)
--  StartTime: number (workspace:GetServerTimeNow() at release)
--  ExtensionDistance: number? (studs beyond Target; defaults to 10)
function PitchTrajectory.new(params)
	local self = setmetatable({}, PitchTrajectory)

	self.From        = params.From
	self.Middle      = params.Middle
	self.Target      = params.Target
	self.Power       = params.Power
	self.AbilityName = params.AbilityName
	self.Direct      = params.Direct
	self.Speed       = params.Speed or 1
	self.PitchType   = params.PitchType
	self.StartTime   = params.StartTime or 0

	self.ExtensionDistance = params.ExtensionDistance or 10

	-- Flags (match your old HandlePitching.lua)
	self.isMeditation  = (self.AbilityName == "Meditation")
	self.isWhirlwind   = (self.AbilityName == "Whirlwind")
	self.isKnuckleball = (self.PitchType == "Knuckleball")
	self.isSlowball    = (self.PitchType == "Slowball")

	-- Old logic: Meditation + Slowball forces straight path
	self.useDirect = (self.isMeditation or self.isSlowball) and true or self.Direct

	-- Base speed: direct uses Speed, otherwise Bezier uses 1/Power
	self.baseSpeed = self.useDirect and self.Speed or (1 / self.Power)

	-- Tunables from your old script
	self.accelThreshold = 0.70 -- Meditation
	self.accelMult      = 2.0

	self.slowStart      = 0.80 -- Slowball
	self.slowMult       = 0.5

	-- Precompute timing for alpha(t) and extension.
	self:_precomputeTimings()

	return self
end

-- Figure out how long each phase takes (pre-extend vs extend) and
-- what alpha looks like as a function of time.
function PitchTrajectory:_precomputeTimings()
	local base = self.baseSpeed
	local mode

	-- default: no Meditation/Slowball
	if self.isMeditation and not self.isSlowball then
		mode = "accel"

		-- until alpha=accelThreshold, alpha(t) = base * t
		local t0 = self.accelThreshold / base

		-- after that, alpha(t) = accelThreshold + base*accelMult*(t - t0)
		local t1 = t0 + (1 - self.accelThreshold) / (base * self.accelMult)

		self.mode      = mode
		self.tSwitch   = t0      -- when we flip to fast mode
		self.tAlphaOne = t1      -- time when alpha reaches 1
	elseif self.isSlowball and not self.isMeditation then
		mode = "slow"

		-- until alpha=slowStart, alpha(t) = base * t
		local t0 = self.slowStart / base

		-- after that, alpha(t) = slowStart + base*slowMult*(t - t0)
		local t1 = t0 + (1 - self.slowStart) / (base * self.slowMult)

		self.mode      = mode
		self.tSwitch   = t0
		self.tAlphaOne = t1
	else
		-- either both or none => treat as simple constant speed
		mode = "simple"
		self.mode      = mode
		self.tSwitch   = nil
		self.tAlphaOne = 1 / base
	end

	-- Extension phase parameters (same formula as in HandlePitching)
	local from     = self.From
	local middle   = self.Middle
	local target   = self.Target
	local useDirect = self.useDirect

	local tangentMag = useDirect and (target - from).Magnitude or (2 * (target - middle)).Magnitude
	local currentBase = self.useDirect and self.Speed or (1 / self.Power)

	local extMult = 1
	if self.isMeditation then
		extMult *= self.accelMult
	end
	if self.isSlowball then
		extMult *= self.slowMult
	end

	self.finalDir = (target - (useDirect and from or middle)).Unit
	self.extSpeed = tangentMag * currentBase * extMult

	if self.extSpeed <= 0 then
		self.extSpeed = 1e-6
	end

	local tExt = self.ExtensionDistance / self.extSpeed

	self.tLand = self.tAlphaOne + tExt
end

-- alpha(t) on [0,1] for pre-extension phase only
function PitchTrajectory:getAlphaAtTime(tRel: number): number
	if tRel <= 0 then
		return 0
	end

	if self.mode == "simple" then
		local alpha = self.baseSpeed * tRel
		if alpha >= 1 then
			return 1
		end
		return alpha
	elseif self.mode == "accel" then
		local t0 = self.tSwitch
		if tRel <= t0 then
			return math.min(1, self.baseSpeed * tRel)
		end
		local alpha = self.accelThreshold + self.baseSpeed * self.accelMult * (tRel - t0)
		if alpha >= 1 then
			return 1
		end
		return alpha
	elseif self.mode == "slow" then
		local t0 = self.tSwitch
		if tRel <= t0 then
			return math.min(1, self.baseSpeed * tRel)
		end
		local alpha = self.slowStart + self.baseSpeed * self.slowMult * (tRel - t0)
		if alpha >= 1 then
			return 1
		end
		return alpha
	end

	-- fallback
	return math.min(1, self.baseSpeed * tRel)
end

-- Main function:
--  tNow = workspace:GetServerTimeNow()
-- returns: position: Vector3, landed: boolean
function PitchTrajectory:GetPosition(tNow: number): (Vector3, boolean)
	local tRel = tNow - self.StartTime
	if tRel < 0 then
		tRel = 0
	end

	-- clamp after full land time
	if tRel >= self.tLand then
		tRel = self.tLand
	end

	-- pre-extension phase (alpha 0→1)
	if tRel < self.tAlphaOne then
		local alpha = self:getAlphaAtTime(tRel)

		local pos: Vector3
		if self.useDirect then
			pos = self.From:Lerp(self.Target, alpha)
		else
			if self.isWhirlwind then
				pos = tornadoMotion(alpha, self.From, self.Middle, self.Target, 2, 4)
			else
				pos = quadraticBezier(alpha, self.From, self.Middle, self.Target)

				-- Knuckle wobble (deterministic; based on time)
				if self.isKnuckleball then
					local wobbleTimer   = tRel
					local wobbleStrength = 0.25
					local wobble = Vector3.new(
						math.sin(wobbleTimer * 12) * wobbleStrength,
						math.sin(wobbleTimer * 9)  * wobbleStrength * 0.8,
						math.sin(wobbleTimer * 7)  * wobbleStrength * 0.5
					)
					pos += wobble
				end
			end
		end

		return pos, false
	end

	-- extension phase
	local tExt = tRel - self.tAlphaOne
	local extProg = math.min(self.ExtensionDistance, self.extSpeed * tExt)
	local pos = self.Target + self.finalDir * extProg
	local landed = (extProg >= self.ExtensionDistance)

	return pos, landed
end

return PitchTrajectory
