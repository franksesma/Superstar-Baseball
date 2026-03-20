--------------------------------------------------------------------
--  Services
--------------------------------------------------------------------
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local Players             = game:GetService("Players")
local ServerStorage       = game:GetService("ServerStorage")
local Debris              = game:GetService("Debris")
local SoundService        = game:GetService("SoundService")

--------------------------------------------------------------------
--  Tunables / constants
--------------------------------------------------------------------
local GRAVITY_SCALE = 0.10
local g             = workspace.Gravity * GRAVITY_SCALE

local MIN_BALL_DIST                         = 175
local MAX_BALL_DIST                         = 550
local OUTSIDE_STRIKE_ZONE_DIST_MULTIPLIER   = 0.5
local OUTSIDE_STRIKE_ZONE_MARGIN_MULTIPLIER = 0.5

local MAX_Y_ANGLE                 = 30
local MIN_X_ANGLE, MAX_X_ANGLE    = 5, 90
local X_CLICK_OFFSET_RANGE        = 1
local Y_CLICK_OFFSET_RANGE        = 1
local FIELD_Y_PLANE               = 2

-- foul planes
local FAIR_MARGIN = 2

-- indicator
local MAX_INDICATOR_DIST   = 300
local INDICATOR_TEMPLATE   = ServerStorage.ServerObjects:FindFirstChild("Indicator")
local INDICATOR_MIN_SIZE   = Vector3.new(.107, 5, 5)
local originalIndicatorSize= INDICATOR_TEMPLATE and INDICATOR_TEMPLATE.Size or Vector3.new(1,1,1)

--------------------------------------------------------------------
--  Debug toggles
--------------------------------------------------------------------
-- Master debug (extra prints)
local DEBUG = true
-- Contact-first relaxers (turn off after contact is verified)
local CONTACT_DEBUG = true
local TIMING_RELAX  = CONTACT_DEBUG and 1.15 or 1.0   -- widen plate timing margin
local CLICK_RELAX   = CONTACT_DEBUG and 1.35 or 1.0   -- widen click margin

local function dbg(...) if DEBUG then print("[SWING DBG]", ...) end end

--------------------------------------------------------------------
--  Modules / singletons
--------------------------------------------------------------------
local Modules           = ServerScriptService:WaitForChild("Modules")
local Remotes           = ReplicatedStorage:WaitForChild("RemoteEvents")
local GameValues        = ReplicatedStorage:WaitForChild("GameValues")
local OnBaseTracker     = GameValues:WaitForChild("OnBase")
local SharedModules     = ReplicatedStorage:WaitForChild("SharedModules")
local SharedData        = ReplicatedStorage:WaitForChild("SharedData")
local PlateDistance     = require(SharedModules:WaitForChild("PlateDistance"))
local ServerFunctions   = require(Modules:WaitForChild("ServerFunctions"))
local BaseballFunctions = require(Modules:WaitForChild("BaseballFunctions"))
local HittingAbilities  = require(Modules:WaitForChild("OffensiveAbilities"))
local PitchingAbilities = require(Modules:WaitForChild("DefensiveAbilities"))
local Styles 			= require(SharedModules:WaitForChild("Styles"))
local ClientFunctions 	= require(SharedModules.ClientFunctions)


--------------------------------------------------------------------
--  Helpers
--------------------------------------------------------------------

local function safeGetStyle(who, slot)
	local ok, result = pcall(function()
		return Styles.GetEquippedStyleName(who, slot)
	end)
	if ok and result and result ~= "" then
		return result
	end
	return "Default"
end

local function v3s(v) return string.format("(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z) end
local function lerp(a, b, t) return a + (b - a) * t end

local function clampToFairXZ(p: Vector3): Vector3
	return Vector3.new(
		math.min(p.X, ClientFunctions.GetFoulWallPos("FairX") - FAIR_MARGIN),
		p.Y,
		math.min(p.Z, ClientFunctions.GetFoulWallPos("FairZ") - FAIR_MARGIN)
	)
end

--------------------------------------------------------------------
--  Walls / HR distance broadcast
--------------------------------------------------------------------
local FoulWalls 
local HomerunWalls

workspace.LoadedBallpark.ChildAdded:Connect(function()
	FoulWalls    = workspace.LoadedBallpark:FindFirstChild("FoulWalls")
	HomerunWalls = workspace.LoadedBallpark:FindFirstChild("HomerunWalls")

	if HomerunWalls and not HomerunWalls:GetAttribute("HRHooked") then
		HomerunWalls:SetAttribute("HRHooked", true)

		for _, wall in ipairs(HomerunWalls:GetChildren()) do
			wall.Touched:Connect(function(hit)
				if hit.Name ~= "Baseball" then return end
				if hit.Parent ~= workspace:FindFirstChild("BallHolder") then return end
				if not GameValues.BallHit.Value then return end
				if not GameValues.FlyBall.Value or GameValues.Homerun.Value or GameValues.Putout.Value then return end

				GameValues.Homerun.Value = true
				local currentBatter = GameValues.CurrentBatter.Value
				if currentBatter and OnBaseTracker:FindFirstChild(currentBatter.Name)
					and OnBaseTracker[currentBatter.Name].Value == "Home Base" then
					ServerFunctions.AddStat(currentBatter, "Hitting", "Hits", 1)
					if GameValues.CurrentPitcher.Value then
						ServerFunctions.AddStat(GameValues.CurrentPitcher.Value, "Pitching", "HitsAllowed", 1)
					end
				end

				local homePlatePos   = workspace.Plates["Home Base"].Position
				local predictedFinal = hit:GetAttribute("PredictedLanding")
				local endPos         = typeof(predictedFinal) == "Vector3" and predictedFinal or hit.Position

				-- 3D distance (matches your original style):
				local distance = (endPos - homePlatePos).Magnitude
				-- If you prefer horizontal-only, use this instead:
				-- local distance = (Vector3.new(endPos.X, 0, endPos.Z) - Vector3.new(homePlatePos.X, 0, homePlatePos.Z)).Magnitude

				ReplicatedStorage.RemoteEvents:WaitForChild("DisplayHitDistance")
					:FireAllClients(currentBatter, math.floor(distance + 0.5))
			end)
		end
	end
end)

local function updateIndicatorSize(baseball: BasePart, indicator: BasePart)
	if not baseball or not indicator then return end
	local d = (indicator.Position - baseball.Position).Magnitude
	local scale = math.clamp(d / MAX_INDICATOR_DIST, 0, 1)
	local s0 = originalIndicatorSize
	indicator.Size = s0:Lerp(INDICATOR_MIN_SIZE, 1 - scale)
end

local function playRandomHitSound()
	local ids = {
		"rbxassetid://9125375073",
		"rbxassetid://9113303129",
		"rbxassetid://9113301297"
	}
	local s = Instance.new("Sound")
	s.SoundId = ids[math.random(1, #ids)]
	s.Volume  = 1
	s.Parent  = workspace.Plates["Home Base"]
	s:Play()
	Debris:AddItem(s, 2)
end

local function StarSwing(player, predictedLocation, xClickScalar, yClickScalar)
	if not (player and player.Character) then return end
	local bat  = player.Character:FindFirstChild("PlayerBat")
	local ball = workspace.BallHolder:FindFirstChild("Baseball")

	local style = safeGetStyle(player, "Offensive")
	if not HittingAbilities[style] then return end

	if ball then ball.Transparency = 1 end
	if bat  then HittingAbilities[style].EffectOnBat(player, bat) end
	if ball then
		HittingAbilities[style].EffectOnBall(ball, predictedLocation, xClickScalar, yClickScalar)
		ball.Transparency = 0
	end
end

--------------------------------------------------------------------
--  MAIN SWING HANDLER
--------------------------------------------------------------------
local function HandleSwing(actor, clickPos: Vector3, ballPos: Vector3, ballDir: Vector3?, hitType: string)
	-- enforce batter
	local batter = GameValues.CurrentBatter.Value
	if actor ~= batter then return end
	if not GameValues.PlayActive.Value then return end
	if GameValues.BallHit.Value then return end

	-- real baseball (not Fake)
	local holder = workspace:FindFirstChild("BallHolder")
	if not holder then return end
	local ball
	for _, v in ipairs(holder:GetChildren()) do
		if v.Name == "Baseball" and not v:GetAttribute("Fake") then
			ball = v; break
		end
	end

	if not ball then 
		GameValues.LastSwingWasMiss.Value = true 
		return 
	end

	-- if ball is below strikezone, then swing is a miss
	local strikeZone = workspace.Batting.StrikeZone
	local bottomY = strikeZone.Position.Y - (strikeZone.Size.Y / 2)

	--[[local cushion = 0.5  

	if ballPos.Y < (bottomY - cushion) then
		GameValues.LastSwingWasMiss.Value = true
		return
	end]]--

	GameValues.PendingStarHit.Value = false
	local batterStyle   = safeGetStyle(batter, "Offensive")
	local batterAbility = HittingAbilities[batterStyle]

	----------------------------------------------------------------
	--  Hit / Miss (Contact-First Hotfix)
	----------------------------------------------------------------
	local hitMargins   = {Power = 2, Contact = 5.5, ["Star Swing"] = 5}
	local clickMargins = {Power = .4, Contact = .75, ["Star Swing"] = 2}

	local ballHitMargin  = hitMargins[hitType] or 5
	local clickHitMargin = clickMargins[hitType] or .75

	-- Batter accuracy overrides
	if batterAbility then
		if hitType == "Power" and batterAbility.PowerAccuracy then
			clickHitMargin = batterAbility.PowerAccuracy
		elseif hitType == "Contact" and batterAbility.ContactAccuracy then
			clickHitMargin = batterAbility.ContactAccuracy
		end
	end

	-- Plate timing
	local dist, margin = PlateDistance:getRelativeDistToPlate(ballPos)
	margin = (margin or 0) + (ballHitMargin or 0)

	-- Click distances: PlateDistance-based and raw 3D, take safer
	local okPD, clickDistPD = pcall(function()
		return PlateDistance:getBallRelativeDist(ballPos, clickPos)
	end)
	if not okPD then clickDistPD = math.huge end
	local clickDist3D = (clickPos - ballPos).Magnitude
	local clickDist   = math.min(clickDistPD, clickDist3D)

	-- Zone (TEMP: gentle buff only)
	local inZone = false
	local okTag, hasTag = pcall(function() return ball:HasTag("InStrikeZone") end)
	if okTag then inZone = hasTag end
	if inZone then
		clickHitMargin = clickHitMargin + 0.05
	end

	-- Apply relaxers (debug)
	local margin_used        = margin * TIMING_RELAX
	local clickHitMargin_used= clickHitMargin * CLICK_RELAX

	local didHit = (math.abs(dist) <= margin_used) and (clickDist <= clickHitMargin_used)
	GameValues.LastSwingWasMiss.Value = true

	-- Debug line for contact gate
	print(("[CONTACT DBG] dist=%.3f <= %.3f | click=%.3f <= %.3f | inZone=%s | hitType=%s | didHit=%s")
		:format(dist, margin_used, clickDist, clickHitMargin_used, tostring(inZone), tostring(hitType), tostring(didHit)))

	if not didHit then
		----------------------------------------------------------------
		-- MISS REPORT (deep-dive)
		----------------------------------------------------------------
		local reasonPieces = {}
		local timingMissed = (math.abs(dist) > margin_used)
		local aimMissed    = (clickDist > clickHitMargin_used)

		if timingMissed then table.insert(reasonPieces, "Timing") end
		if aimMissed    then table.insert(reasonPieces, "Aim") end
		if #reasonPieces == 0 then table.insert(reasonPieces, "Other") end
		local reasonStr = table.concat(reasonPieces, " + ")

		-- Signed timing miss (how far outside timing margin)
		local timingOverBy = math.abs(dist) - margin_used

		-- Aim miss by (PlateDistance and raw 3D)
		local aimOverByPD  = (clickDistPD or math.huge) - clickHitMargin_used
		local aimOverBy3D  = clickDist3D - clickHitMargin_used

		-- Compute click offsets & “intended” angles, even on miss
		local toPos = workspace.Batting.To.Position

		-- re-use same targeting fallback you use for hits
		local ballTarget = (shared and typeof(shared.GetLastBallTarget) == "function" and shared.GetLastBallTarget()) or nil
		print (ballTarget, "THIS RIGHT HERE IS THE BALL TARGET")
		if not ballTarget then
			if ballDir and ballDir.Magnitude > 0.1 then
				ballTarget = ballPos + ballDir.Unit * 15
				print (ballTarget, "THIS RIGHT HERE IS THE UPDATED BALL TARGET")
			else
				local fwd = CFrame.lookAt(Vector3.new(ballPos.X, FIELD_Y_PLANE, ballPos.Z), toPos).LookVector
				print (ballTarget, "THIS RIGHT HERE IS THE BALL TARGET2")
				ballTarget = ballPos + fwd * 15
			end
		end

		local ballOffsetCF  = CFrame.lookAt(ballTarget, toPos)
		local clickOffsetCF = CFrame.lookAt(clickPos,   toPos)
		local offsetLocal   = ballOffsetCF:ToObjectSpace(clickOffsetCF).Position

		-- normalized scalars (same mapping math you use below)
		local xClickScalar = (math.clamp(offsetLocal.X / X_CLICK_OFFSET_RANGE, -1, 1) + 1) * 0.5
		local yClickScalar = (math.clamp(offsetLocal.Y / Y_CLICK_OFFSET_RANGE, -1, 1) + 1) * 0.5

		-- predict the “intended” yaw/pitch from the click (inverted mapping)
		local yawMax             = MAX_Y_ANGLE
		local pitchMin, pitchMax = MIN_X_ANGLE, MAX_X_ANGLE
		local intendedYawDeg     = lerp(-yawMax,  yawMax, xClickScalar)     -- left click -> right field (+yaw)
		local intendedPitchDeg   = lerp( pitchMax, pitchMin, yClickScalar)  -- above -> lower launch

		-- extra grounder bias if clicked ABOVE the ball (mirrors live code)
		if (clickPos.Y - ballPos.Y) > 0 then
			intendedPitchDeg = math.max(1, intendedPitchDeg - 8)
		end

		-- raw vectors for extra clarity
		local clickDeltaWorld = clickPos - ballPos
		local inZone = false
		local okTag, hasTag = pcall(function() return ball:HasTag("InStrikeZone") end)
		if okTag then inZone = hasTag end

		-- ability bits we sometimes care about when debugging misses
		local abilityTag     = tostring(ball:GetAttribute("Ability") or "None")
		local timeScaleTag   = tonumber(ball:GetAttribute("TimeScale") or 1)
		local isAI           = (GameValues.CurrentBatter.Value and GameValues.CurrentBatter.Value:GetAttribute("IsAI")) or false

		-- Compact booleans
		local INZONE_Y       = inZone
		local AI_Y           = isAI

		-- Keep your existing MISS knock-away feedback
		if ballDir and ballDir.Magnitude > 1e-3 then
			local dur = math.log(1.001 + ballDir.Magnitude * 0.02)
			if dur < 1e-3 then dur = 0.05 end
			local imp = ballDir / dur + Vector3.new(0, workspace.Gravity * dur * 0.5, 0)
			ball.Position = ballPos
			ball:ApplyImpulse(imp * ball.AssemblyMass)
		end
		return
	end


	----------------------------------------------------------------
	--  HIT setup
	--------------------------------------------------------------------
	GameValues.BallHit.Value = true

	local oldCF = ball.CFrame
	ball:Destroy()
	ball = ServerStorage.ServerObjects.Baseball:Clone()
	ball.CatchBall.Enabled = true
	ball.Catchable.Value = true
	ball.Parent = holder
	ball.CFrame = oldCF
	ball:SetAttribute("Hit", true)

	if GameValues.CurrentPitcher.Value and not GameValues.CurrentPitcher.Value:GetAttribute("IsAI") then
		BaseballFunctions.RemoveGUIs(GameValues.CurrentPitcher.Value)
	end
	if batter and not batter:GetAttribute("IsAI") then
		BaseballFunctions.RemoveGUIs(batter)
	end

	----------------------------------------------------------------
	--  Offsets → angles (INVERTED mapping as requested)
	----------------------------------------------------------------
	local toPos = workspace.Batting.To.Position

	-- fallback if shared target missing
	local ballTarget = (shared and typeof(shared.GetLastBallTarget) == "function" and shared.GetLastBallTarget()) or nil
	if not ballTarget then
		if ballDir and ballDir.Magnitude > 0.1 then
			ballTarget = ballPos + ballDir.Unit * 15
		else
			local fwd = CFrame.lookAt(Vector3.new(ballPos.X, FIELD_Y_PLANE, ballPos.Z), toPos).LookVector
			ballTarget = ballPos + fwd * 15
		end
	end

	local ballOffsetCF  = CFrame.lookAt(ballTarget, toPos)
	local clickOffsetCF = CFrame.lookAt(clickPos,   toPos)

	-- measure click in ball’s local frame
	local offset = ballOffsetCF:ToObjectSpace(clickOffsetCF).Position

	-- normalized 0..1 scalars
	local xClickScalar = (math.clamp(offset.X / X_CLICK_OFFSET_RANGE, -1, 1) + 1) * 0.5
	local yClickScalar = (math.clamp(offset.Y / Y_CLICK_OFFSET_RANGE, -1, 1) + 1) * 0.5

	local isStarSwing = (hitType == "Star Swing")
	if isStarSwing then
		-- small centralization for consistency
		xClickScalar = 0.5 + (xClickScalar - 0.5) * 0.4
		yClickScalar = 0.5 + (yClickScalar - 0.5) * 0.4
	end

	-- INVERTED mappings:
	--  Left of ball -> RIGHT field (flip yaw sign)
	--  Above ball    -> LOWER launch angle (liner/grounder)
	local yawMax             = MAX_Y_ANGLE
	local pitchMin, pitchMax = MIN_X_ANGLE, MAX_X_ANGLE

	local yAngle = lerp(-yawMax,  yawMax, xClickScalar)   -- left click → +yaw (right field)
	local xAngle = lerp( pitchMax, pitchMin, yClickScalar) -- above → lower launch

	-- extra grounder bias if clicked ABOVE the ball
	if (clickPos.Y - ballPos.Y) > 0 then
		xAngle = math.max(1, xAngle - 8) -- up to 8° lower, never < 1°
	end

	-- Debug line for mapping
	print(("[MAP DBG] offX=%.2f offY=%.2f | xS=%.2f yS=%.2f | yaw=%.1f° pitch=%.1f°")
		:format(offset.X, offset.Y, xClickScalar, yClickScalar, yAngle, xAngle))

	----------------------------------------------------------------
	--  Distance window by type + modifiers
	----------------------------------------------------------------
	local minDist, maxDist = MIN_BALL_DIST, MAX_BALL_DIST
	if hitType == "Power"   then minDist += 25; maxDist += 50 end
	if hitType == "Contact" then minDist -= 10; maxDist -= 35 end

	-- pitcher/batter modifiers
	local modifiers = {}
	do
		local pitcher = GameValues.CurrentPitcher.Value
		local ps = pitcher and _G.sessionData[pitcher]
		local equippedDefensiveStyle = safeGetStyle(batter, "Defensive")
		local pAbility = PitchingAbilities[equippedDefensiveStyle]

		if pAbility and pAbility.Modifiers and ps then
			local activeName = Styles.GetEquippedStyleName(pitcher, "Defensive")
			if (hitType ~= "Star Swing" or pAbility.Modifiers.IgnoreUlts)
				and ball:GetAttribute("Ability") == activeName
			then
				for k,v in pairs(pAbility.Modifiers) do modifiers[k] = v end
			end
		end

		if batterAbility and batterAbility.Modifiers then
			if isStarSwing and batterAbility.Modifiers.OverrideHit then
				modifiers.OverrideHit = true
			end
			local pitcherSession = GameValues.CurrentPitcher.Value and _G.sessionData[GameValues.CurrentPitcher.Value]
			local ignoreUlts = batterAbility.IgnoreUlts
			local sameAbility = false
			if pitcherSession then
				local name = Styles.GetEquippedStyleName(pitcher, "Defensive")
				sameAbility = (ball:GetAttribute("Ability") == name)
			end
			if isStarSwing and (ignoreUlts or not sameAbility) then
				for k,v in pairs(batterAbility.Modifiers) do modifiers[k] = v end
			end
		end
	end

	if batterAbility then
		if hitType == "Power" and batterAbility.PowerDistance then
			minDist += batterAbility.PowerDistance; maxDist += batterAbility.PowerDistance
		elseif hitType == "Contact" and batterAbility.ContactDistance then
			minDist += batterAbility.ContactDistance; maxDist += batterAbility.ContactDistance
		end
	end

	if modifiers.MinDist then minDist = modifiers.MinDist end
	if modifiers.MaxDist then maxDist = modifiers.MaxDist end
	if modifiers.XAngleMin and modifiers.XAngleMax then
		xAngle = lerp(modifiers.XAngleMin, modifiers.XAngleMax, yClickScalar)
	end
	if modifiers.YAngleMax then
		yAngle = lerp(modifiers.YAngleMax, -modifiers.YAngleMax, xClickScalar)
	end

	-- timing scalar (no forced override)
	local rawTiming = math.clamp(math.abs(dist) / math.max((margin or 0), 1e-3), 0, 1)

	-- harsher curve, tune exponent
	local p = 0.6  -- try 2.0–3.0 for harsher
	local timingCurve = math.pow(rawTiming, p)

	local distance = lerp(maxDist, minDist, timingCurve)
	print (distance, "HERES THE DISTANCE")

	----------------------------------------------------------------
	--  Direction & speed (ballistics)
	----------------------------------------------------------------
	local targetDir = (CFrame.lookAt(ballTarget, toPos) * CFrame.Angles(math.rad(xAngle), math.rad(yAngle), 0)).LookVector
	if targetDir.Magnitude < 1e-6 then
		targetDir = CFrame.lookAt(Vector3.new(ballPos.X, FIELD_Y_PLANE, ballPos.Z), toPos).LookVector
	end
	targetDir = targetDir.Unit

	local forwardDir   = CFrame.lookAt(Vector3.new(ballPos.X, FIELD_Y_PLANE, ballPos.Z), toPos).LookVector
	local dot          = math.clamp(targetDir:Dot(forwardDir), -1, 1)
	local launchAngle  = math.acos(dot)

	-- allow true lasers/grounders
	local minLaunchAngle = math.rad(1)   -- lowered from 3°
	local maxLaunchAngle = math.rad(45)
	launchAngle = math.clamp(launchAngle, minLaunchAngle, maxLaunchAngle)

	local sinDouble = math.sin(launchAngle * 2)
	if math.abs(sinDouble) < 1e-6 then sinDouble = math.sin(minLaunchAngle * 2) end
	local speed    = math.sqrt(math.max(distance, 0) * g / sinDouble)
	local velocity = targetDir * speed

	-- Debug line for timing/ballistics

	----------------------------------------------------------------
	--  Predict landing (time-of-flight)
	----------------------------------------------------------------
	local vy     = velocity.Y
	local deltaY = ballPos.Y - FIELD_Y_PLANE
	local disc   = vy*vy + 2 * g * deltaY
	if disc < 0 then disc = 0 end
	local t = (vy + math.sqrt(disc)) / g
	if t < 0.05 then t = 0.05 end

	local finalPos = Vector3.new(
		ballPos.X + velocity.X * t,
		FIELD_Y_PLANE,
		ballPos.Z + velocity.Z * t
	)

	local predictedLanding = finalPos
	local desiredFinal     = finalPos

	-- Star Swing: force fair landing (keep same T, re-aim)
	if isStarSwing then
		desiredFinal = clampToFairXZ(finalPos)
		local gvec = Vector3.new(0, -g, 0)
		velocity = (desiredFinal - ballPos - 0.5 * gvec * t * t) / t
		predictedLanding = desiredFinal
	end

	ball:SetAttribute("PredictedLanding", desiredFinal)

	----------------------------------------------------------------
	--  Sounds & ability hooks
	----------------------------------------------------------------
	if isStarSwing then
		local pdata = SharedData:FindFirstChild(batter.Name)
		if pdata and pdata.HittingPower.Value == 100 then
			pdata.HittingPower.Value = 0
			GameValues.PendingStarHit.Value = true
			StarSwing(batter, predictedLanding, xClickScalar, yClickScalar)
			GameValues.PendingStarHit.Value = false
			playRandomHitSound()
		end
	else
		playRandomHitSound()
	end

	ServerFunctions.EnableLeadBlockers(false)
	ServerFunctions.EnablePitcherWalls(false)

	----------------------------------------------------------------
	--  Launch the ball (unless overridden)
	----------------------------------------------------------------
	ball.CanCollide     = true
	ball.CollisionGroup = "BaseballGroup"

	if not modifiers.OverrideHit then
		if ball:IsDescendantOf(workspace) then
			ball:SetNetworkOwner(nil)
		end
		task.wait() -- allow owner update

		local ts = ball:GetAttribute("TimeScale")
		if ts and ts > 0 and ts < 1 then
			local Tnew = math.max(0.15, t * ts)
			local gvec = Vector3.new(0, -g, 0)
			velocity = (finalPos - ballPos - 0.5 * gvec * Tnew * Tnew) / Tnew
		end

		ball.CFrame = CFrame.new(ballPos)
		ball.AssemblyLinearVelocity = velocity
	end

	----------------------------------------------------------------
	--  Trail / client indicator
	----------------------------------------------------------------
	if not isStarSwing then
		BaseballFunctions.SetUpTrail(batter, ball)
	end

	local guiTemplate = ReplicatedStorage:WaitForChild("SharedGUIs"):FindFirstChild("BallIndicator")
	if guiTemplate and not ball:GetAttribute("NoIndicator") then
		local gui = guiTemplate:Clone()
		gui.Adornee = ball
		gui.Parent  = ball
	end

	----------------------------------------------------------------
	--  Server landing marker
	----------------------------------------------------------------
	local marker = INDICATOR_TEMPLATE and INDICATOR_TEMPLATE:Clone()
	if marker then
		marker.Position = desiredFinal
		marker.Parent   = workspace:WaitForChild("LandingIndicators")

		task.spawn(function()
			if batterStyle == "Shadow" or batterStyle == "Overdrive" then
				marker:Destroy()
				return
			end
			while marker.Parent do
				if not ball or not ball.Parent then break end
				updateIndicatorSize(ball, marker)
				task.wait()
			end
			if marker and marker.Parent then marker:Destroy() end
		end)
	end

	----------------------------------------------------------------
	--  Foul check
	----------------------------------------------------------------
	local isFoul = (predictedLanding.Z > ClientFunctions.GetFoulWallPos("FairZ") or predictedLanding.X > -math.abs(ClientFunctions.GetFoulWallPos("FairX")))
	print(("[FOUL DBG] predictedLanding=%s | foul=%s"):format(v3s(predictedLanding), tostring(isFoul)))

	if isFoul then
		GameValues.BallFouled.Value = true
		print("Ball Hit Foul")
	else
		BaseballFunctions.PlayHitWooshSound(ball)
		BaseballFunctions.PlayBallLaunchEffects()
		GameValues.BallHit.Value = true
		Remotes.LockedInBaseNotification:FireAllClients(false)
		SoundService.Effects.CrowdCheerShort:Play()
		-- reset base "safe" flags
		for _, tracker in pairs(OnBaseTracker:GetChildren()) do
			local runner = Players:FindFirstChild(tracker.Name)
			if runner then
				tracker.IsSafe.Value = false
				Remotes.SafeStatusNotification:FireClient(runner, true, "Not Safe")
			end
		end
	end

	dbg("[HIT SUMMARY]",
		"dist=", dist,
		"clickDist=", string.format("%.3f (PD) / %.3f (3D) -> %.3f", clickDistPD or -1, clickDist3D, clickDist),
		"angles(pitch,yaw)=", string.format("(%.1f, %.1f)", xAngle, yAngle),
		"finalPos=", v3s(finalPos),
		"foul=", isFoul
	)

	----------------------------------------------------------------
	--  In-play messaging
	----------------------------------------------------------------
	GameValues.FlyBall.Value = true
	ball.Catchable.Value = true
	Remotes.BallLanded:FireAllClients(ballPos, GameValues.BallHit.Value)

	----------------------------------------------------------------
	--  Marker cleanup on first valid touch
	----------------------------------------------------------------
	local canRemoveMarker = false
	task.delay(0.1, function() canRemoveMarker = true end)

	local touchConn
	touchConn = ball.Touched:Connect(function(part)
		if not canRemoveMarker then return end
		if not marker or not marker.Parent then
			if touchConn then touchConn:Disconnect() end
			return
		end
		if part:IsA("BasePart") and part.Parent.Name ~= "KillBricks"
			and (not FoulWalls or not FoulWalls:IsAncestorOf(part)) then
			marker:Destroy()
			if touchConn then touchConn:Disconnect() end
		end
	end)

	----------------------------------------------------------------
	--  Post-hit cleanup (UI, camera, movement)
	----------------------------------------------------------------
	task.delay(1, function()
		if GameValues.PlayActive.Value then
			GameValues.AbilitiesCanBeUsed.Value = true
		end
	end)

	task.delay(1.5, function()
		BaseballFunctions.UnSetupPlayer(batter, false)
		if GameValues.CurrentPitcher.Value then
			BaseballFunctions.UnSetupPlayer(GameValues.CurrentPitcher.Value, false)
		end

		local pitcher = GameValues.CurrentPitcher.Value
		if pitcher and not pitcher:GetAttribute("IsAI") then
			Remotes.ChangeCameraType:FireClient(pitcher, Enum.CameraType.Custom)
			Remotes.DisableMovement:FireClient(pitcher, false)
			Remotes.EnableMouselock:FireClient(pitcher, true)
		end

		if batter and not batter:GetAttribute("IsAI") then
			Remotes.ChangeCameraType:FireClient(batter, Enum.CameraType.Custom)
			Remotes.EnableFieldWalls:FireClient(batter, true)
			Remotes.ShowBaseMarker:FireClient(batter, true, "First Base")
			Remotes.DisableMovement:FireClient(batter, false)
			Remotes.EnableMouselock:FireClient(batter, true)
			Remotes.UnbindHitting:FireClient(batter)
		end
	end)
end

--------------------------------------------------------------------
--  Remote hooks
--------------------------------------------------------------------
Remotes.SwingBat.OnServerEvent:Connect(function(player, clickPos, ballPos, ballDir, hitType)
	HandleSwing(player, clickPos, ballPos, ballDir, hitType)
end)

Remotes.HitBallAI.OnServerEvent:Connect(function(player, clickPos, ballPos, ballDir, hitType)
	local aiModel = GameValues.CurrentBatter.Value
	HandleSwing(aiModel, clickPos, ballPos, ballDir, hitType)
end)
