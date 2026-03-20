local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ServerScriptService.Modules
local SharedModules = ReplicatedStorage.SharedModules

local ServerFunctions = require(Modules.ServerFunctions)
local BaseballFunctions = require(Modules.BaseballFunctions)
local ClientFunctions = require(SharedModules.ClientFunctions)

local GameValues = ReplicatedStorage.GameValues
local Remotes = ReplicatedStorage.RemoteEvents
local OnBase = GameValues.OnBase

local TOUCH_TAG_DISTANCE = 10

local taggedPlayers = {}

local function hasBallInGlove(player)
	if player and _G.sessionData[player] then
		local equippedGloveName = "PlayerGlove"
		local equippedGlove = player.Character and player.Character:FindFirstChild(equippedGloveName)

		if equippedGlove then
			return equippedGlove:FindFirstChild("Baseball") ~= nil
		end
	end
	return false
end

local function handleTouch(character, otherCharacter)
	local player = game.Players:GetPlayerFromCharacter(character)
	local otherPlayer = game.Players:GetPlayerFromCharacter(otherCharacter)

	if not player or not otherPlayer then
		return
	end

	if taggedPlayers[otherPlayer] or taggedPlayers[player] then
		return
	end
	
	if character:GetAttribute("Untaggable") or otherCharacter:GetAttribute("Untaggable") then
		return
	end
	
	if GameValues.Homerun.Value then
		return
	end

	local playerHasBall = hasBallInGlove(player)
	local otherPlayerHasBall = hasBallInGlove(otherPlayer)
	
	if playerHasBall and not otherPlayerHasBall then
		if OnBase:FindFirstChild(otherPlayer.Name) and not OnBase[otherPlayer.Name].IsSafe.Value then
			taggedPlayers[otherPlayer] = true
			BaseballFunctions.PlayerOut(otherPlayer)
			Remotes.BatResults:FireAllClients(otherPlayer.Name.." is tagged out!")
			ServerFunctions.AddStat(player, "Outfield", "Putouts", 1)
			ServerFunctions.AddFieldingAssistStats(player)
			task.delay(1, function()
				taggedPlayers[otherPlayer] = nil
			end)
		end
	elseif otherPlayerHasBall and not playerHasBall then
		if OnBase:FindFirstChild(player.Name) and not OnBase[player.Name].IsSafe.Value then
			taggedPlayers[player] = true
			BaseballFunctions.PlayerOut(player)
			Remotes.BatResults:FireAllClients(player.Name.." is tagged out!")
			ServerFunctions.AddStat(otherPlayer, "Outfield", "Putouts", 1)
			ServerFunctions.AddFieldingAssistStats(player)
			task.delay(1, function()
				taggedPlayers[player] = nil
			end)
		end
	end
end

local function setupCharacterTouchDetection(character)
	
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				local otherCharacter = hit.Parent
				if otherCharacter and otherCharacter:FindFirstChild("Humanoid") and otherCharacter ~= character then
					local rootPart = character:FindFirstChild("HumanoidRootPart")
					local otherRoot = otherCharacter:FindFirstChild("HumanoidRootPart")

					if rootPart and otherRoot then
						local distance = (rootPart.Position - otherRoot.Position).Magnitude
						
						if distance <= TOUCH_TAG_DISTANCE then
							handleTouch(character, otherCharacter)
						end
					end
				end
			end)
		end
	end
end

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		setupCharacterTouchDetection(character)
	end)

	player.AncestryChanged:Connect(function()
		if not player:IsDescendantOf(game) then
			taggedPlayers[player] = nil
		end
	end)
end)
