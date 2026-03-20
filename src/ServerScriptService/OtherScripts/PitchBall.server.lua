local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local Remotes = ReplicatedStorage.RemoteEvents
local PitchingFolder = workspace.Pitching
local StrikeZone = PitchingFolder:WaitForChild("StrikeZone")
local BallHolder = workspace.BallHolder
local ServerScriptService = game:GetService("ServerScriptService")
local Modules = ServerScriptService.Modules
local SharedModules = ReplicatedStorage.SharedModules

local ServerFunctions = require(Modules.ServerFunctions)
local BaseballFunctions = require(Modules.BaseballFunctions)
local PitchTypes = require(SharedModules.PitchTypes)

local GameValues = ReplicatedStorage.GameValues
local ScoreboardValues = GameValues.ScoreboardValues
local Strikes = ScoreboardValues.Strikes
local Balls = ScoreboardValues.Balls
local SharedData = ReplicatedStorage.SharedData

local SharedModules = ReplicatedStorage.SharedModules
local PitchingAbilities = require(Modules.DefensiveAbilities)
local ClientFunctions = require(SharedModules.ClientFunctions)

local Styles 			 = require(SharedModules:WaitForChild("Styles"))


local LastBallTarget
function shared.GetLastBallTarget()
	return LastBallTarget
end

Remotes.PitchBall.OnServerEvent:Connect(function(player, Target, Power, PitchType, InStrikeZone)
	if GameValues.CurrentPitcher.Value == player and not GameValues.BallPitched.Value then
		GameValues.BallPitched.Value = true
		ServerFunctions.AddStat(player, "Pitching", "Pitches", 1)
		local EquippedPitchingAbility  = Styles.GetEquippedStyleName(player, "Defensive")
		EquippedPitchingAbility        = EquippedPitchingAbility:sub(1, 1):upper() .. EquippedPitchingAbility:sub(2):lower()

		local From = player.Character.LeftHand.Position
		local ball = game.ServerStorage.ServerObjects.Baseball:Clone()

		ball.Parent = BallHolder
		ball:SetNetworkOwner(nil)
		--ball.Anchored = true
		GameValues.CountedStrike.Value = false
		GameValues.LastSwingWasMiss.Value = false
		GameValues.BallHit.Value = false 

		LastBallTarget = Target
		PitchType = string.lower(PitchType)
		PitchType = PitchType:gsub("^%l", string.upper)

		local Middle

		GameValues.PitchGuessActive.PitchSelected.Value = PitchType

		if PitchType == "Ultimate" then
			if SharedData:FindFirstChild(player.Name) and SharedData[player.Name].PitchingPower.Value == 100 then
				local finished = false
				local conn

				conn = Remotes.CinematicFinished.OnServerEvent:Connect(function(p)
					if p == player and not finished then
						finished = true
						if conn then
							conn:Disconnect()
						end
					end
				end)


				local Hitter = GameValues.CurrentBatter.Value
				-- 2. Trigger the cinematic (VFX, ball setup, call to PitchingAbilities etc.)
				GameValues.PendingStarPitch.Value = true
				SharedData[player.Name].PitchingPower.Value = 0
				ball:SetAttribute("Ability", EquippedPitchingAbility)
				BaseballFunctions.RemoveGUIs(GameValues.CurrentPitcher.Value)

				local Curve = PitchingAbilities[EquippedPitchingAbility].Curve
				local Arc = PitchingAbilities[EquippedPitchingAbility].Arc
				Power = Power - PitchingAbilities[EquippedPitchingAbility].Power
				PitchingAbilities[EquippedPitchingAbility].EffectOnBall(player, ball, From, Target, Curve, Arc, Power)
				Middle = ((Target + From) / Curve) + Vector3.new(0, Arc, 0)


				local timeout = 15
				local start = tick()
				repeat task.wait() print(tick() - start) until finished or tick() - start > timeout

				if not finished then
					warn("Cinematic timed out for player:", player.Name)
					conn:Disconnect()
				end

				local Pitcher = GameValues.CurrentPitcher.Value
				wait (.05)
				--ball.Anchored = false
				Remotes.PitchBall:FireAllClients(ball, From, Middle, Target, Power, EquippedPitchingAbility, PitchingAbilities[EquippedPitchingAbility].Direct, PitchingAbilities[EquippedPitchingAbility].Speed)
				spawn(function()
					wait(.1)
					BaseballFunctions.SetUpPitcher(GameValues.CurrentPitcher.Value)
				end)	
			end
		else
			Power = Power - PitchTypes.Data[PitchType].Power
			-- Softball style: fastball uses -5 arc instead of 5
			local pitchData = PitchTypes.Data[PitchType]
			if EquippedPitchingAbility == "Softball" and PitchType == "Fastball" and pitchData then
				Middle = ((Target + From) / pitchData.Curve) + Vector3.new(0, -5, 0)
			else
				Middle = PitchTypes.CalculateMiddle(PitchType, From, Target)
			end
			wait(.05)
			--ball.Anchored = false
			ball:SetAttribute("PitchType", PitchType)
			Remotes.PitchBall:FireAllClients(ball, From, Middle, Target, Power, nil, nil, nil, PitchType)
			BaseballFunctions.SetUpTrail(player, ball)
		end

		BaseballFunctions.PlayPitchWooshSound(ball)
		--first part == curve / 2
		--second == arc of ball (0,5,0)
		if InStrikeZone then
			print ("IN STRIKEZONE ADDING TAG")
			ball:AddTag("InStrikeZone")
		end
	end
end)

local debounce = false

local activeBalls = {} 

local activeBalls = activeBalls or {} -- keep your existing table

Remotes.BallLanded.OnServerEvent:Connect(function(Player, Ball, Position)
	-- Ignore fake/old balls
	if Ball then
		if Ball:GetAttribute("Fake") or not Ball:IsDescendantOf(workspace.BallHolder) then
			return
		end
	end

	-- De-dupe per physical ball (or Position if Ball is nil)
	local dedupeKey = Ball or Position
	if activeBalls[dedupeKey] then return end
	activeBalls[dedupeKey] = true

	-- Snapshot outcome IMMEDIATELY (avoid race with next pitch)
	local pitchedBall = Ball
	if not pitchedBall or not pitchedBall:IsDescendantOf(workspace.BallHolder) then
		pitchedBall = workspace.BallHolder:FindFirstChild("Baseball")
	end

	-- Also snapshot strike-zone tag (it can change if you ClearAllChildren)
	local inStrikeZone = false
	if pitchedBall then
		local ok, hasTag = pcall(function() return pitchedBall:HasTag("InStrikeZone") end)
		inStrikeZone = ok and hasTag or false
	end

	-- Clear visuals now (keeps your look) but AFTER we captured state
	BallHolder:ClearAllChildren()
	Remotes.BallLanded:FireAllClients(Position)

	task.wait(1.1)

	----------------------------------------------------------------
	-- SCORE the pitch NOW (no waiting; avoids race with next pitch)
	----------------------------------------------------------------
	if not GameValues.BallHit.Value then
		if GameValues.LastSwingWasMiss.Value and not GameValues.CountedStrike.Value then
			GameValues.CountedStrike.Value = true
			ScoreboardValues.Strikes.Value += 1

			if ScoreboardValues.Strikes.Value < 3 then
				Remotes.BatResults:FireAllClients("Strike")
				SoundService.Narration.StrikeNarration:Play()
				if workspace:FindFirstChild("NPCs") then
					workspace.NPCs.Umpire.Events.PlayStrikeAnim:Fire()
				end
			else
				if workspace:FindFirstChild("NPCs") then
					workspace.NPCs.Umpire.Events.PlayStrikeoutAnim:Fire()
				end
			end

			local p = GameValues.CurrentPitcher.Value
			if p then ServerFunctions.AddStat(p, "Pitching", "Strikes", 1) end

		elseif inStrikeZone and not GameValues.CountedStrike.Value then
			-- Looking strike
			GameValues.CountedStrike.Value = true
			ScoreboardValues.Strikes.Value += 1

			if ScoreboardValues.Strikes.Value < 3 then
				Remotes.BatResults:FireAllClients("Strike")
				SoundService.Narration.StrikeNarration:Play()
				if workspace:FindFirstChild("NPCs") then
					workspace.NPCs.Umpire.Events.PlayStrikeAnim:Fire()
				end
			else
				if workspace:FindFirstChild("NPCs") then
					workspace.NPCs.Umpire.Events.PlayStrikeoutAnim:Fire()
				end
			end

			local p = GameValues.CurrentPitcher.Value
			if p then ServerFunctions.AddStat(p, "Pitching", "Strikes", 1) end

		else
			-- Ball
			ScoreboardValues.Balls.Value += 1
			Remotes.BatResults:FireAllClients("Ball")
			SoundService.Narration.BallNarration:Play()
		end
	end

	-- (Optional) tiny visual delay after scoring to keep timing feel
	GameValues.PendingStarPitch.Value = false

	for _, defender in pairs(ClientFunctions.GetPlayersInGame()) do
		if defender and ClientFunctions.PlayerIsDefender(defender) then
			ServerFunctions.ResetArms(defender)
		end
	end

	task.delay(5, function()
		activeBalls[dedupeKey] = nil
	end)
end)


local function AutoPitchAI(aiPitcher)
	GameValues.BallPitched.Value = true
	local AnimationsModule = require(game.ReplicatedStorage.SharedModules.PitchingAnimations)
	local BallHolder = workspace.BallHolder

	if not aiPitcher then warn("[AutoPitchAI] No AI pitcher given") return end

	local styleName = aiPitcher:GetAttribute("EquippedDefensiveStyle") or "Default"
	local styleData = AnimationsModule[styleName] or AnimationsModule["Default"]

	local possiblePitches = styleData.Pitches or {"Fastball"}
	local chosenPitch = possiblePitches[math.random(1, #possiblePitches)]

	-- Random target in strike zone
	local strikeZone = workspace:WaitForChild("Pitching"):WaitForChild("StrikeZone")
	local center = strikeZone.Position
	local size = strikeZone.Size

	local offset = Vector3.new(
		math.random(-size.X * 50, size.X * 50) / 100,
		math.random(-size.Y * 50, size.Y * 50) / 100,
		math.random(-size.Z * 50, size.Z * 50) / 100
	)
	local target = center + offset

	-- Play AI pitcher’s throw animation
	local humanoid = aiPitcher:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator")
		local pitchAnim = Instance.new("Animation")
		pitchAnim.AnimationId = styleData.Pitch
		local pitchTrack = animator:LoadAnimation(pitchAnim)
		pitchTrack:Play()

		task.wait(styleData.ReleaseTime)
	end

	-- Actually pitch the ball
	local From = aiPitcher.LeftHand.Position
	local ball = game.ServerStorage.ServerObjects.Baseball:Clone()
	ball.Parent = BallHolder
	ball:SetNetworkOwner(nil)
	ball:AddTag("InStrikeZone")

	GameValues.CountedStrike.Value = false
	GameValues.LastSwingWasMiss.Value = false
	GameValues.BallHit.Value = false 

	LastBallTarget = target

	local Middle = PitchTypes.CalculateMiddle(chosenPitch, From, target)
	local Power = 1 - PitchTypes.Data[chosenPitch].Power


	Remotes.PitchBall:FireAllClients(ball, From, Middle, target, Power, nil, nil, nil, chosenPitch)
	BaseballFunctions.PlayPitchWooshSound(ball)
	print("✅ AI Pitcher threw:", chosenPitch, "Target:", target)
end

local PitchingAnimations = require(ReplicatedStorage.SharedModules.PitchingAnimations)

local pendingPitchTimers = {}

Remotes.PitchStarted.OnServerEvent:Connect(function(player, target, pitchType, inStrikeZone)
	-- Avoid multiple timers
	if pendingPitchTimers[player] then
		task.cancel(pendingPitchTimers[player])
		pendingPitchTimers[player] = nil
	end

	-- Start a 3.5s timer to force pitch
	local function forcePitchIfStuck()
		task.wait(3.3)

		if GameValues.BallPitched.Value or GameValues.CurrentPitcher.Value ~= player then
			return
		end

		if not GameValues.BallPitched.Value and GameValues.CurrentPitcher.Value == player then
			Remotes.CancelClientPitching:FireClient(player)

			local character = player.Character
			if not character then return end

			local leftHand = character:FindFirstChild("LeftHand")
			if not leftHand then return end

			local From = leftHand.Position
			local pitchTypeFormatted = pitchType:gsub("^%l", string.upper)
			local middle = PitchTypes.CalculateMiddle(pitchTypeFormatted, From, target)
			local power = 1 - (PitchTypes.Data[pitchTypeFormatted] and PitchTypes.Data[pitchTypeFormatted].Power or 0)

			local ball = game.ServerStorage.ServerObjects.Baseball:Clone()
			ball.Parent = BallHolder
			ball:SetNetworkOwner(nil)

			GameValues.CountedStrike.Value = false
			GameValues.LastSwingWasMiss.Value = false
			GameValues.BallHit.Value = false 

			GameValues.BallPitched.Value = true
			LastBallTarget = target

			if inStrikeZone then
				ball:AddTag("InStrikeZone")
			end

			local styleName = Styles.GetEquippedStyleName(player, "Defensive") or "Default"
			styleName = styleName:sub(1,1):upper() .. styleName:sub(2):lower()

			local animations = PitchingAnimations[styleName] or PitchingAnimations.Default
			local animId = animations.Pitch
			local releaseTime = animations.ReleaseTime

			-- Play pitcher animation
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator")
				local anim = Instance.new("Animation")
				anim.AnimationId = animId

				local track = animator:LoadAnimation(anim)
				track:Play()
				task.wait(releaseTime)
			end

			-- Play catcher animation
			local catcher = workspace:FindFirstChild("NPCs") and workspace.NPCs:FindFirstChild("Catcher")
			if catcher then
				local catcherHum = catcher:FindFirstChildOfClass("Humanoid")
				if catcherHum then
					local animator = catcherHum:FindFirstChildOfClass("Animator") or catcherHum:WaitForChild("Animator")
					local catcherAnimations = {
						BottomRight = "rbxassetid://87950577592801",
						BottomLeft  = "rbxassetid://113045870528618",
						TopLeft     = "rbxassetid://105376900863478",
						Middle      = "rbxassetid://84950575685466",
						TopRight    = "rbxassetid://138567775434221"
					}
					local anim = Instance.new("Animation")
					anim.AnimationId = catcherAnimations.Middle
					local track = animator:LoadAnimation(anim)
					track:Play()
				end
			end

			if player == GameValues.CurrentPitcher.Value then
				GameValues.ScoreboardValues.PitchClockEnabled.Value = false
			end

			if player == GameValues.CurrentPitcher.Value then
				spawn(function()
					GameValues.PitchWindup.Value = true
					task.wait(4)
					GameValues.PitchWindup.Value = false
				end)
			end

			Remotes.PitchBall:FireAllClients(ball, From, middle, target, power, nil, nil, nil, pitchTypeFormatted)

			BaseballFunctions.SetUpTrail(player, ball)
			BaseballFunctions.PlayPitchWooshSound(ball)
		end

		pendingPitchTimers[player] = nil
	end


	pendingPitchTimers[player] = task.spawn(forcePitchIfStuck)
end)

Remotes.ForceServerPitch.Event:Connect(function(player)
	if not player or not player:IsDescendantOf(game.Players) then return end
	if GameValues.CurrentPitcher.Value ~= player or GameValues.BallPitched.Value then return end
	Remotes.StopPitching:FireClient(GameValues.CurrentPitcher.Value)

	local pitchType = "Fastball"
	local strikeZone = workspace:WaitForChild("Pitching"):WaitForChild("StrikeZone")
	local center = strikeZone.Position
	local size = strikeZone.Size

	local target = center + Vector3.new(
		math.random(-size.X * 50, size.X * 50) / 100,
		math.random(-size.Y * 50, size.Y * 50) / 100,
		0
	)

	local character = player.Character
	if not character then return end

	local leftHand = character:FindFirstChild("LeftHand")
	if not leftHand then return end

	local From = leftHand.Position

	local styleName = Styles.GetEquippedStyleName(player, "Defensive") or "Default"
	styleName = styleName:sub(1,1):upper() .. styleName:sub(2):lower()

	local animations = PitchingAnimations[styleName] or PitchingAnimations.Default
	local animId = animations.Pitch
	local releaseTime = animations.ReleaseTime


	-- Load and play pitch animation on server
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator")
		local anim = Instance.new("Animation")
		anim.AnimationId = animId

		local track = animator:LoadAnimation(anim)
		track:Play()
		task.wait(releaseTime)
	end

	task.wait(require(ReplicatedStorage.SharedModules.PitchingAnimations)["Default"].ReleaseTime)

	-- Spawn and throw ball
	local ball = game.ServerStorage.ServerObjects.Baseball:Clone()
	ball.Parent = BallHolder
	ball:SetNetworkOwner(nil)

	local power = 1 - (PitchTypes.Data[pitchType] and PitchTypes.Data[pitchType].Power or 0)
	local middle = PitchTypes.CalculateMiddle(pitchType, From, target)

	GameValues.BallPitched.Value = true
	LastBallTarget = target
	ball:AddTag("InStrikeZone")

	GameValues.CountedStrike.Value = false
	GameValues.LastSwingWasMiss.Value = false
	GameValues.BallHit.Value = false 

	-- Play catcher animation
	local catcher = workspace:FindFirstChild("NPCs") and workspace.NPCs:FindFirstChild("Catcher")
	if catcher then
		local catcherHum = catcher:FindFirstChildOfClass("Humanoid")
		if catcherHum then
			local animator = catcherHum:FindFirstChildOfClass("Animator") or catcherHum:WaitForChild("Animator")
			local catcherAnimations = {
				BottomRight = "rbxassetid://87950577592801",
				BottomLeft  = "rbxassetid://113045870528618",
				TopLeft     = "rbxassetid://105376900863478",
				Middle      = "rbxassetid://84950575685466",
				TopRight    = "rbxassetid://138567775434221"
			}
			local animId = catcherAnimations.Middle
			local anim = Instance.new("Animation")
			anim.AnimationId = animId
			local track = animator:LoadAnimation(anim)
			track:Play()
		end
	end

	-- Send pitch to clients
	if player == GameValues.CurrentPitcher.Value then
		GameValues.ScoreboardValues.PitchClockEnabled.Value = false
	end

	if player == GameValues.CurrentPitcher.Value then
		spawn(function()
			GameValues.PitchWindup.Value = true
			task.wait(4)
			GameValues.PitchWindup.Value = false
		end)
	end

	Remotes.PitchBall:FireAllClients(ball, From, middle, target, power, nil, nil, nil, pitchType)

	-- Cancel any pending UI on client
	Remotes.CancelClientPitching:FireClient(GameValues.CurrentPitcher.Value)

	-- Setup trail
	BaseballFunctions.SetUpTrail(player, ball)
	BaseballFunctions.PlayPitchWooshSound(ball)
end)


-- Optional cleanup on player leave
Players.PlayerRemoving:Connect(function(player)
	if pendingPitchTimers[player] then
		task.cancel(pendingPitchTimers[player])
		pendingPitchTimers[player] = nil
	end
end)



Remotes.PitchAIBall.Event:Connect(function(AiModel)
	AutoPitchAI(AiModel)
end)