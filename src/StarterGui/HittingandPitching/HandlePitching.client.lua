local RunService = game:GetService("RunService")
local Remotes = game.ReplicatedStorage.RemoteEvents
local StrikeZone = workspace:WaitForChild("Pitching"):WaitForChild("StrikeZone")
local PlateDistance = require(game.ReplicatedStorage.SharedModules:WaitForChild("PlateDistance"))
local GameValues = game.ReplicatedStorage.GameValues

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = {StrikeZone}

function lerp(a, b, t)
	return a + (b - a) * t
end

function quadraticBezier(t, p0, p1, p2)
	local l1 = lerp(p0, p1, t)
	local l2 = lerp(p1, p2, t)
	local quad = lerp(l1, l2, t)
	return quad
end

function tornadoMotion(t, startPos, midPos, endPos, amplitude, frequency)
	local bezierPos = quadraticBezier(t, startPos, midPos, endPos)
	local sideMovement = math.sin(t * frequency * math.pi * 2) * amplitude
	return bezierPos + Vector3.new(sideMovement, 0, 0)
end

Remotes.PitchBall.OnClientEvent:Connect(function(Ball, From, Middle, Target, Power, AbilityName, Direct, Speed, PitchType)
	Ball.CFrame = CFrame.new(From)

	local alpha = 0
	local baseBezierSpeed = 1 / Power
	local connection
	local hitStrikeZone = false
	local firedBallLanded = false
	local Tornado
	local Boomerang
	local AI_SwingFired = false

	-- Follow-through config
	local extend = false
	local extensionDistance = 10
	local extensionProgress = 0
	local extensionSpeed = 0
	local finalDirection = nil

	-- VFX (keep as-is)
	if AbilityName == "Whirlwind" then
		Tornado = game.ReplicatedStorage.VFX.Tornado:Clone()
		Tornado.Parent = Ball
		Tornado:SetPrimaryPartCFrame(Ball.CFrame)
		local weld = Instance.new("WeldConstraint"); weld.Part0 = Ball; weld.Part1 = Tornado.PrimaryPart; weld.Parent = Ball
		task.delay(2, function() if Tornado and Tornado.Parent then Tornado:Destroy() end end)
	end
	if AbilityName == "Growth" then
		local Baseball = game.ReplicatedStorage.VFX.GiantBaseball:Clone()
		Baseball.Name = "BigBaseballVFX"; Baseball.Parent = workspace.VFXFolder
		Baseball:SetPrimaryPartCFrame(Ball.CFrame)
		local weld = Instance.new("WeldConstraint"); weld.Part0 = Ball; weld.Part1 = Baseball.PrimaryPart; weld.Parent = Ball
		task.delay(3, function() if Baseball and Baseball.Parent then Baseball:Destroy() end end)
	end
	if AbilityName == "Boomerang" then
		Boomerang = game.ReplicatedStorage.VFX.Boomerang:Clone()
		Boomerang.Parent = Ball
		Boomerang:SetPrimaryPartCFrame(Ball.CFrame * CFrame.Angles(math.rad(90), 0, 0))
		local weld = Instance.new("WeldConstraint"); weld.Part0 = Ball; weld.Part1 = Boomerang.PrimaryPart; weld.Parent = Ball
		task.delay(2, function() if Boomerang and Boomerang.Parent then Boomerang:Destroy() end end)
	end

	-- Ghost/Knuckle
	local shouldBlink = (AbilityName == "Ghost")
	local isKnuckleball = (PitchType == "Knuckleball")
	local blinkCounter, blinkInterval, isBallVisible = 0, 0.2, true
	local wobbleTimer, boomerangAngle = 0, 0

	-- Rolling spin
	local ballRotation = CFrame.identity
	local rotationSpeed = math.rad(360)

	-- === Pitch behavior flags ===
	local isMeditation = (AbilityName == "Meditation")
	local isSlowball   = (PitchType == "Slowball")

	-- Force straight path for Meditation and Slowball
	local useDirect = (isMeditation or isSlowball) and true or Direct

	-- Meditation: late boost
	local accelThreshold, accelMult, accelerated = 0.70, 2.0, false

	-- Slowball: hard slowdown at exactly 60%
	local slowStart, slowMult, decelerated = 0.80, 0.5, false  -- 30% slower after 0.60

	connection = RunService.RenderStepped:Connect(function(deltaTime)
		local prevPos = Ball.CFrame.Position
		local newPos

		if GameValues.BallHit.Value then
			connection:Disconnect()
			return
		end

		-- Ghost blink
		if shouldBlink then
			blinkCounter += deltaTime
			if blinkCounter >= blinkInterval then
				blinkCounter = 0
				isBallVisible = not isBallVisible
				Ball.Transparency = isBallVisible and 0 or 1
			end
		end

		-- === Compute alpha step with abrupt 60% slow for Slowball ===
		local stepBase = (useDirect and Speed or baseBezierSpeed)
		local step = 0

		if isSlowball then
			-- Split the frame at the threshold so slowdown happens exactly at 0.60
			local preSpeed  = stepBase
			local postSpeed = stepBase * slowMult

			if not decelerated then
				local remainingTo60 = slowStart - alpha
				if remainingTo60 <= 0 then
					-- already past threshold: fully slowed this frame
					decelerated = true
					step = postSpeed * deltaTime
				else
					-- time needed at full speed to reach 0.60
					local t_pre_needed = remainingTo60 / math.max(preSpeed, 1e-6)
					if t_pre_needed >= deltaTime then
						-- won't reach 0.60 this frame: all full speed
						step = preSpeed * deltaTime
					else
						-- reach 0.60, then immediately apply slowdown for the leftover time
						local dt_post = deltaTime - t_pre_needed
						local part1 = preSpeed  * t_pre_needed
						local part2 = postSpeed * dt_post
						step = part1 + part2
						decelerated = true
					end
				end
			else
				-- already slowed in earlier frame
				step = postSpeed * deltaTime
			end
		else
			-- non-slowball behavior (incl. Meditation boost)
			local stepSpeed = stepBase
			if isMeditation and alpha >= accelThreshold then
				stepSpeed = stepSpeed * accelMult
				accelerated = true
			end
			step = stepSpeed * deltaTime
		end

		-- === MAIN FLIGHT ===
		if not extend then
			alpha = math.min(1, alpha + step)

			if useDirect then
				newPos = From:Lerp(Target, alpha)
			else
				if AbilityName == "Whirlwind" then
					newPos = tornadoMotion(alpha, From, Middle, Target, 2, 4)
				else
					newPos = quadraticBezier(alpha, From, Middle, Target)
					if isKnuckleball then
						wobbleTimer += deltaTime
						local wobbleStrength = 0.25
						local wobble = Vector3.new(
							math.sin(wobbleTimer * 12) * wobbleStrength,
							math.sin(wobbleTimer * 9)  * wobbleStrength * 0.8,
							math.sin(wobbleTimer * 7)  * wobbleStrength * 0.5
						)
						newPos += wobble
					end
				end
			end
		else
			-- === EXTENSION: inherit slowdown/boost if already active at switch time ===
			local extMult = 1
			if isMeditation and accelerated then extMult *= accelMult end
			if isSlowball and decelerated then extMult *= slowMult end

			local extStep = deltaTime * extensionSpeed * extMult
			extensionProgress += extStep
			newPos = Target + finalDirection * extensionProgress
		end

		-- Rolling spin
		local direction = (newPos - prevPos)
		if direction.Magnitude > 0.001 then
			local dirUnit = direction.Unit
			local up = Vector3.new(0, 1, 0)
			local axis = dirUnit:Cross(up)
			if axis.Magnitude < 0.01 then axis = dirUnit:Cross(Vector3.new(1,0,0)) end
			axis = axis.Unit
			local angle = rotationSpeed * deltaTime
			ballRotation = CFrame.fromAxisAngle(axis, -angle) * ballRotation
		end

		-- Apply final CFrame with spin
		if Boomerang then
			boomerangAngle += math.rad(10)
			Ball.CFrame = CFrame.new(newPos) * CFrame.Angles(0, boomerangAngle, 0)
		elseif isKnuckleball then
			local spin = CFrame.Angles(
				math.rad(math.random(-0.3, 0.3)),
				math.rad(math.random(-0.3, 0.3)),
				math.rad(math.random(-0.3, 0.3))
			)
			Ball.CFrame = CFrame.new(newPos) * spin
		else
			Ball.CFrame = CFrame.new(newPos) * ballRotation
		end

		-- Direction attribute
		Ball:SetAttribute("Direction", CFrame.lookAt(prevPos, newPos).LookVector * (prevPos - newPos).Magnitude)

		-- Plate ray
		if not hitStrikeZone then
			local dir = newPos - prevPos
			local rayResult = workspace:Raycast(prevPos, dir, rayParams)
			if rayResult and rayResult.Instance == StrikeZone then
				local hitPoint = rayResult.Position
				hitStrikeZone = true
			end
		end

		-- AI swing (unchanged)
		-- AI swing (BUFFED: 100/20 swing, 90/50 hit)
		if not AI_SwingFired then
			local dist, margin = PlateDistance:getRelativeDistToPlate(newPos)

			-- React slightly early so we don't miss the exact frame window
			local effectiveMargin = margin * 1.20

			if math.abs(dist) <= effectiveMargin then
				local currentBatter = GameValues.CurrentBatter.Value
				if currentBatter and currentBatter:IsA("Model") and currentBatter:GetAttribute("IsAI") then
					AI_SwingFired = true

					-- Use your raycast tag result from earlier in this script
					local inZone = hitStrikeZone

					-- Your requested probabilities
					local swingChance = inZone and 1.00 or 0.20
					local hitChance   = inZone and 0.90 or 0.50

					if math.random() < swingChance then
						local willHit = (math.random() < hitChance)

						-- Tighter aim when we intend to hit (nearly perfect click)
						local HIT_OFFSET_MAX  = 0.35  -- studs (was ~1)
						local MISS_OFFSET_MAX = 5.00  -- studs

						-- small gaussian-ish jitter
						local function jitter(maxMag)
							local r = (math.random() + math.random()) * 0.5 -- 0..1 peaked near 0.5
							return (r * 2 - 1) * maxMag
						end

						local offsetMax = willHit and HIT_OFFSET_MAX or MISS_OFFSET_MAX

						-- forward nudge in flight direction helps server timing mapping
						local dir = newPos - prevPos
						local fwd = (dir.Magnitude > 1e-3) and dir.Unit or Vector3.new(0,0,1)
						local forwardNudge = willHit and 0.35 or 0.10

						local clickPos = newPos
							+ Vector3.new(jitter(offsetMax), jitter(offsetMax), jitter(offsetMax))
							+ fwd * forwardNudge

						local ballDir = CFrame.lookAt(prevPos, newPos).LookVector * (prevPos - newPos).Magnitude
						local hitType = "Contact"

						Remotes.HitBallAI:FireServer(clickPos, newPos, ballDir, hitType)

						-- swing anim (unchanged)
						local hum = currentBatter:FindFirstChildWhichIsA("Humanoid")
						local animator = hum and hum:FindFirstChildOfClass("Animator")
						if animator then
							local swingAnim = Instance.new("Animation")
							swingAnim.AnimationId = "rbxassetid://103117459835657"
							local swingTrack = animator:LoadAnimation(swingAnim)
							swingTrack:Play()
						end
					end
				end
			end
		end


		-- Fake ball pop (unchanged)
		if alpha >= 0.7 and Ball:GetAttribute("Fake") then
			local effectBall = Ball:Clone()
			effectBall.Transparency = 1; effectBall.Anchored = true; effectBall.Parent = workspace.CurrentCamera
			local vfx = game.ReplicatedStorage.VFXParticlesFB.FakeBallPop:Clone()
			vfx.Parent = effectBall; vfx:Emit(15)
			task.delay(2, function() effectBall:Destroy() end)
			Ball.Parent = nil
			connection:Disconnect()
			return
		end

		-- Switch to extension (inherit state at switch)
		if alpha >= 1 and not extend then
			finalDirection = (Target - (useDirect and From or Middle)).Unit
			local tangentMag = useDirect and (Target - From).Magnitude or (2 * (Target - Middle)).Magnitude
			local currentBase = (useDirect and Speed or baseBezierSpeed)

			local extMult = 1
			if isMeditation and accelerated then extMult *= accelMult end
			if isSlowball and decelerated then extMult *= slowMult end

			extensionSpeed = tangentMag * currentBase * extMult
			extend = true
		elseif extend and extensionProgress >= extensionDistance and not firedBallLanded then
			firedBallLanded = true
			if Tornado then Tornado:Destroy() end
			if Boomerang then Boomerang:Destroy() end
			Remotes.BallLanded:FireServer(Ball, Target, hitStrikeZone)
			connection:Disconnect()
		end
	end)
end)

