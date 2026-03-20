local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerService = game:GetService("Players")
local RunService = game:GetService("RunService")

local GameValues = ReplicatedStorage.GameValues
local SharedObjects = ReplicatedStorage.SharedObjects
local OnBaseFolder = GameValues.OnBase
local Remotes = ReplicatedStorage.RemoteEvents
local SharedModules = ReplicatedStorage.SharedModules
local ScoreboardValues = GameValues.ScoreboardValues
local Modules = ServerScriptService.Modules
local SharedData = ReplicatedStorage.SharedData

local ServerFunctions = require(Modules.ServerFunctions)
local ClientFunctions = require(SharedModules.ClientFunctions)
local BaseSequence = require(SharedModules.BaseSequence)
local BaseballFunctions = require(Modules.BaseballFunctions)

local BASE_RADIUS = 3.5

local basePlates = workspace.Plates
local BallHolderFolder = workspace.BallHolder

local standingOnBaseRunning = {}
local standingOnBasePitching = {}

local notificationsDisplayed = {}

local function isStandingOnSquare(characterPosition, boxPlatform)
	if characterPosition.X < (boxPlatform.Position.X + (boxPlatform.Size.X / 2)) and characterPosition.X > (boxPlatform.Position.X - (boxPlatform.Size.X / 2)) and characterPosition.Z < (boxPlatform.Position.Z + (boxPlatform.Size.Z / 2)) and characterPosition.Z > (boxPlatform.Position.Z - (boxPlatform.Size.Z / 2)) then
		return true
	else
		return false
	end 
end

local function isNearBase(character, basePart, radius)
	if not (character and basePart and character:FindFirstChild("HumanoidRootPart")) then
		return false
	end
	local distance = (character.HumanoidRootPart.Position - basePart.Position).Magnitude
	return distance <= radius
end


local function isTouchingPlate(character, basePart)
	local partsInBase = workspace:GetPartsInPart(basePart)

	for _, part in ipairs(partsInBase) do
		if part and part.Parent == character then
			return true
		end
	end

	return false
end


local function isHomerun()
	if GameValues.Homerun.Value then
		return true
	else
		return false
	end
end

local function baseOccupied(thisPlayer, baseDict, thisBasePart)
	if isHomerun() then
		return false
	end

	for player, basePart in pairs(baseDict) do
		if basePart == thisBasePart and thisPlayer ~= player then
			return true
		end
	end

	return false
end

local function displayNotification(player, notificationMessage, notificationType)
	if notificationsDisplayed[player] == nil then
		notificationsDisplayed[player] = {}		
	end 

	if table.find(notificationsDisplayed[player], notificationMessage) == nil then
		table.insert(notificationsDisplayed[player], notificationMessage)
		Remotes.Notification:FireClient(player, notificationMessage, notificationType)

		spawn(function()
			for i = 3, 0, -1 do
				wait(1)
			end

			if notificationsDisplayed[player] ~= nil then
				for i, notification in pairs(notificationsDisplayed[player]) do
					if notification == notificationMessage then
						table.remove(notificationsDisplayed[player], i)
						break
					end
				end
			end
		end)
	end
end

local function setUpHomeBaseDetection(basePart)
	basePart.Touched:connect(function(hit)
		local character = hit.Parent
		local player = game.Players:GetPlayerFromCharacter(character)

		if player then
			local currentBaseTracker = OnBaseFolder:FindFirstChild(player.Name)

			if currentBaseTracker and GameValues.BallHit.Value and (not GameValues.FlyBall.Value or isHomerun()) and (not GameValues.Putout.Value or currentBaseTracker.TaggedUp.Value) then
				if basePart.Name == "Home Base" then
					local nextBase = BaseSequence[currentBaseTracker.Value]

					if nextBase == "Home Base" then
						BaseballFunctions.PlayerScored(player)
					end
				end
			end
		end
	end)
end

local function noForcePlayRequired(currentBaseTracker)
	if GameValues.Putout.Value then return true end

	for _, baseTracker in pairs(OnBaseFolder:GetChildren()) do
		if BaseSequence[baseTracker.StartingBase.Value] == currentBaseTracker.Value then 
			return false
		end
	end

	return true
end

local function playerAdvancingLegally(player, currentBaseTracker, basePartName)
	if currentBaseTracker.LockedInBase.Value then
		if currentBaseTracker.Value == basePartName then
			return true
		else
			return false
		end
	else
		return true
	end
end

local function noRunnerLockedInBase(player, baseName)
	for _, baseTracker in pairs(OnBaseFolder:GetChildren()) do
		if baseTracker.Value == baseName and baseTracker.LockedInBase.Value and baseTracker.Name ~= player.Name then
			local notificationMessage = baseTracker.Name.." is already locked in this base. You must advance to "..BaseSequence[baseName].." to be safe!"
			local notificationType = "Alert"
			displayNotification(player, notificationMessage, notificationType)

			return false
		end
	end

	return true
end

local function handleBaseTagging(player, basePart)
	if player and player.Character then
		local character = player.Character
		local currentBaseTracker = OnBaseFolder:FindFirstChild(player.Name)

		if GameValues.BallHit.Value and not GameValues.BallFouled.Value then
			if currentBaseTracker 
				and standingOnBaseRunning[player] == nil 
			then
				local nextBase = BaseSequence[currentBaseTracker.Value]
				local startingBase = currentBaseTracker.StartingBase.Value

				if basePart.Name == nextBase and not currentBaseTracker.LockedInBase.Value and (not GameValues.Putout.Value or currentBaseTracker.TaggedUp.Value) then
					currentBaseTracker.Value = nextBase
					Remotes.ShowBaseMarker:FireClient(player, true, BaseSequence[currentBaseTracker.Value])

					if currentBaseTracker.Value == "First Base" and not GameValues.Homerun.Value then
						ServerFunctions.AddStat(player, "Hitting", "Hits", 1)
						ServerFunctions.AddStat(GameValues.CurrentPitcher.Value, "Pitching", "HitsAllowed", 1)
					end

					spawn(function()
						local baseTapFlare = SharedObjects.BaseTapFlare:Clone()
						local baseTapWave = SharedObjects.BaseTapWave:Clone()

						baseTapFlare.Parent = basePart
						baseTapWave.Parent = basePart

						baseTapFlare:Emit(1)
						baseTapWave:Emit(1)
						basePart.BaseStomp:Play()

						wait(1)

						baseTapFlare:Destroy()
						baseTapWave:Destroy()
					end)
				end

				if (GameValues.Putout.Value and not currentBaseTracker.TaggedUp.Value) then -- flyout
					if startingBase ~= "Home Base" and startingBase == basePart.Name then
						standingOnBaseRunning[player] = basePart

						Remotes.SafeStatusNotification:FireClient(player, true, "Safe")
						currentBaseTracker.IsSafe.Value = true
						currentBaseTracker.TaggedUp.Value = true
						Remotes.CancelSlideDive:FireClient(player)

						local timeIncrement = 0.1

						while character 
							and character:FindFirstChild("HumanoidRootPart") 
							and character:FindFirstChild("LeftFoot")
							and character:FindFirstChild("RightFoot")
							and (isTouchingPlate(character, basePart)
								or isTouchingPlate(character, basePart.TouchPart)
								or isStandingOnSquare(character.HumanoidRootPart.Position, basePart)
								or isStandingOnSquare(character.LeftFoot.Position, basePart)
								or isStandingOnSquare(character.RightFoot.Position, basePart)
								or isNearBase(character, basePart, BASE_RADIUS))
							and GameValues.BallHit.Value 
						do
							wait(timeIncrement)

							if currentBaseTracker and currentBaseTracker:FindFirstChild("LockedInBase") and not currentBaseTracker.LockedInBase.Value and not isHomerun() then
								currentBaseTracker.LockedInBase.BaseElapseTime.Value = currentBaseTracker.LockedInBase.BaseElapseTime.Value + timeIncrement

								if currentBaseTracker.LockedInBase.BaseElapseTime.Value >= 3 then
									currentBaseTracker.LockedInBase.Value = true

									Remotes.LockedInBaseNotification:FireClient(player, true, BaseSequence[currentBaseTracker.Value])
								end
							end
						end

						standingOnBaseRunning[player] = nil

						if (GameValues.BallHit.Value or not isStandingOnSquare(character.HumanoidRootPart.Position, basePart)) and OnBaseFolder:FindFirstChild(player.Name) then
							Remotes.SafeStatusNotification:FireClient(player, true, "Not Safe")
							currentBaseTracker.IsSafe.Value = false
						end
					end
				elseif ((currentBaseTracker.Value == basePart.Name and currentBaseTracker.Value ~= startingBase)  
					or (startingBase ~= "Home Base" and startingBase == currentBaseTracker.Value and noForcePlayRequired(currentBaseTracker)))
					and not baseOccupied(player, standingOnBaseRunning, basePart) 
					and playerAdvancingLegally(player, currentBaseTracker, basePart.Name)
					and noRunnerLockedInBase(player, basePart.Name)
				then
					standingOnBaseRunning[player] = basePart

					Remotes.SafeStatusNotification:FireClient(player, true, "Safe")
					currentBaseTracker.IsSafe.Value = true
					Remotes.CancelSlideDive:FireClient(player)

					local timeIncrement = 0.1

					while character 
						and character:FindFirstChild("HumanoidRootPart") 
						and character:FindFirstChild("LeftFoot")
						and character:FindFirstChild("RightFoot")
						and (isTouchingPlate(character, basePart)
							or isTouchingPlate(character, basePart.TouchPart)
							or isStandingOnSquare(character.HumanoidRootPart.Position, basePart)
							or isStandingOnSquare(character.LeftFoot.Position, basePart)
							or isStandingOnSquare(character.RightFoot.Position, basePart)
							or isNearBase(character, basePart, BASE_RADIUS))
						and GameValues.BallHit.Value 
						and (not GameValues.Putout.Value or currentBaseTracker.TaggedUp.Value)
					do
						wait(timeIncrement)

						if currentBaseTracker and currentBaseTracker:FindFirstChild("LockedInBase") and not currentBaseTracker.LockedInBase.Value and not isHomerun() then
							currentBaseTracker.LockedInBase.BaseElapseTime.Value = currentBaseTracker.LockedInBase.BaseElapseTime.Value + timeIncrement

							if currentBaseTracker.LockedInBase.BaseElapseTime.Value >= 3 then
								currentBaseTracker.LockedInBase.Value = true

								Remotes.LockedInBaseNotification:FireClient(player, true, BaseSequence[currentBaseTracker.Value])
							end
						end
					end

					standingOnBaseRunning[player] = nil

					if (GameValues.BallHit.Value or not isStandingOnSquare(character.HumanoidRootPart.Position, basePart)) and OnBaseFolder:FindFirstChild(player.Name) then
						Remotes.SafeStatusNotification:FireClient(player, true, "Not Safe")
						currentBaseTracker.IsSafe.Value = false
					end
				end
			elseif ClientFunctions.PlayerIsDefender(player) and player.Character then -- defender tagging a base
				local glove = player.Character:FindFirstChild("PlayerGlove")

				if glove and glove:FindFirstChild("Baseball") then -- defender is attempting to force out
					for _, baseTracker in pairs(OnBaseFolder:GetChildren()) do
						if (GameValues.Putout.Value and not baseTracker.TaggedUp.Value) then -- flyout was caught, old bases are up for tags
							if basePart.Name == baseTracker.StartingBase.Value and not baseTracker.IsSafe.Value then
								local outPlayer = PlayerService:FindFirstChild(baseTracker.Name)

								if outPlayer then
									BaseballFunctions.PlayerOut(outPlayer)
									Remotes.BatResults:FireAllClients(outPlayer.Name.." is out!")
									ServerFunctions.AddStat(player, "Outfield", "Putouts", 1)
									ServerFunctions.AddFieldingAssistStats(player)
									break
								end
							end
						else
							if basePart.Name == "First Base" and baseTracker.Value == "Home Base" and baseTracker.StartingBase.Value == "Home Base" then
								local outPlayer = PlayerService:FindFirstChild(baseTracker.Name)

								if outPlayer then
									BaseballFunctions.PlayerOut(outPlayer)
									Remotes.BatResults:FireAllClients(outPlayer.Name.." is out!")
									ServerFunctions.AddStat(player, "Outfield", "Putouts", 1)
									ServerFunctions.AddFieldingAssistStats(player)
									break
								end
							elseif basePart.Name == "Second Base" or basePart.Name == "Third Base" then
								for _, baseTracker in pairs(OnBaseFolder:GetChildren()) do
									local runnerName = baseTracker.Name
									local runner = PlayerService:FindFirstChild(runnerName)

									if runner and BaseSequence[baseTracker.Value] == basePart.Name and baseTracker.StartingBase.Value == baseTracker.Value then
										for _, pushingTracker in pairs(OnBaseFolder:GetChildren()) do -- check to see if someone else is pushing this batter to run
											local pushingPlayer = PlayerService:FindFirstChild(pushingTracker.Name)

											if pushingPlayer 
												and pushingTracker ~= baseTracker 
												and BaseSequence[pushingTracker.StartingBase.Value] == baseTracker.StartingBase.Value then

												BaseballFunctions.PlayerOut(runner)
												Remotes.BatResults:FireAllClients(runner.Name.." is out!")
												ServerFunctions.AddStat(player, "Outfield", "Putouts", 1)
												ServerFunctions.AddFieldingAssistStats(player)
												break
											end
										end
									end
								end
							end
						end 
					end
				end
			end
		else -- check for lead offs
			if currentBaseTracker 
				and (isTouchingPlate(character, basePart) 
					or isTouchingPlate(character, basePart.TouchPart)
					or isStandingOnSquare(character.HumanoidRootPart.Position, basePart)
					or isStandingOnSquare(character.LeftFoot.Position, basePart)
					or isStandingOnSquare(character.RightFoot.Position, basePart))
				and standingOnBasePitching[player] == nil 
				and currentBaseTracker.Value == basePart.Name 
				and not baseOccupied(player, standingOnBaseRunning, basePart)
			then
				standingOnBasePitching[player] = basePart
				Remotes.SafeStatusNotification:FireClient(player, true, "Safe")
				currentBaseTracker.IsSafe.Value = true

				while character 
					and character:FindFirstChild("HumanoidRootPart") 
					and character:FindFirstChild("LeftFoot")
					and character:FindFirstChild("RightFoot")
					and (isTouchingPlate(character, basePart) 
						or isTouchingPlate(character, basePart.TouchPart)
						or isStandingOnSquare(character.HumanoidRootPart.Position, basePart)
						or isStandingOnSquare(character.LeftFoot.Position, basePart)
						or isStandingOnSquare(character.RightFoot.Position, basePart))
					and (not GameValues.BallHit.Value or GameValues.BallFouled.Value)
				do
					wait()
				end

				standingOnBasePitching[player] = nil

				if OnBaseFolder:FindFirstChild(player.Name) then
					Remotes.SafeStatusNotification:FireClient(player, true, "Not Safe")
					currentBaseTracker.IsSafe.Value = false
				end
			end
		end
	end
end


local function setUpDetection(basePart)
	basePart.Touched:connect(function(hit)
		local character = hit.Parent
		local player = game.Players:GetPlayerFromCharacter(character)

		handleBaseTagging(player, basePart)
	end)
end

setUpDetection(basePlates["First Base"])
setUpDetection(basePlates["Second Base"])
setUpDetection(basePlates["Third Base"])
setUpHomeBaseDetection(basePlates["Home Base"])

Remotes.CheckBaseTagging.Event:Connect(function(player, basePart)
	handleBaseTagging(player, basePart)
end)

local MAX_SPEED = 18
local MIN_SPEED = 14
local FATIGUE_RATE = 1 -- speed loss per second
local GRACE_PERIOD = 5 -- seconds

OnBaseFolder.ChildAdded:Connect(function(baseTracking)	
	local player = PlayerService:FindFirstChild(baseTracking.Name)

	if player then
		local character = player.Character

		if character and character:FindFirstChild("Humanoid") then
			local humanoid = character.Humanoid
			humanoid.WalkSpeed = MAX_SPEED
			local currentSpeed = MAX_SPEED
			local runnerFatigueConnection
			local graceStartTime = nil

			runnerFatigueConnection = RunService.Heartbeat:Connect(function(dt)
				if player == nil or humanoid.Parent == nil or OnBaseFolder:FindFirstChild(player.Name) == nil then
					runnerFatigueConnection:Disconnect()
					if player and player.Character and player.Character:FindFirstChild("Humanoid") then
						player.Character.Humanoid.WalkSpeed = MAX_SPEED
					end
					return 
				end

				local isSafe = baseTracking.IsSafe.Value

				if SharedData:FindFirstChild(player.Name) and SharedData[player.Name].ActivatedFBAbility.Value then
					return
				end

				if isSafe 
					or not GameValues.BallHit.Value 
					or GameValues.Homerun.Value 
					or BaseSequence[baseTracking.Value] == "First Base"
				then
					currentSpeed = MAX_SPEED
					humanoid.WalkSpeed = MAX_SPEED
					graceStartTime = nil
				else
					if not graceStartTime then
						graceStartTime = tick()
					end

					if tick() - graceStartTime > GRACE_PERIOD then
						currentSpeed = math.max(MIN_SPEED, currentSpeed - FATIGUE_RATE * dt)
						humanoid.WalkSpeed = currentSpeed
					else
						humanoid.WalkSpeed = MAX_SPEED
					end
				end
			end)
		end
	end
end)
