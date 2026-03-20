local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Remotes = ReplicatedStorage.RemoteEvents
local SharedData = ReplicatedStorage.SharedData

local TRAINING_GROUNDS_PLACE_ID = 109493382032395

-- Function to show tutorial for new players
local function checkAndShowTutorial(player)
	-- Wait for data to be loaded
	local attempts = 0
	while (not _G.sessionData or not _G.sessionData[player]) and attempts < 30 do
		task.wait(0.1)
		attempts = attempts + 1
	end

	if not _G.sessionData or not _G.sessionData[player] then
		warn("[TutorialHandler] Could not load player data for " .. player.Name)
		return
	end

	local tutorialSeen = _G.sessionData[player].TutorialSeen

	if not tutorialSeen then
		-- Wait a bit for character to fully load
		task.wait(1)

		-- Show tutorial GUI via remote event
		Remotes.ShowTutorial:FireClient(player)
	end
end

-- Wait for player data to be loaded
Players.PlayerAdded:Connect(function(player)
	-- Check on character spawn
	player.CharacterAdded:Connect(function(character)
		-- Wait a bit for everything to initialize
		task.wait(2)
		checkAndShowTutorial(player)
	end)
end)

-- Create RemoteEvents if they don't exist
local function getOrCreateRemote(name)
	local remote = Remotes:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = Remotes
	end
	return remote
end

-- Create ShowTutorial remote (server -> client)
local showTutorialRemote = getOrCreateRemote("ShowTutorial")

-- Handle tutorial Accept button (Teleport to Training Grounds)
local tutorialAcceptRemote = getOrCreateRemote("TutorialAccept")

tutorialAcceptRemote.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end

	-- DON'T mark tutorial as seen yet - only mark it when they decline or complete it
	-- This way, if they're new and click Teleport, TutorialSeen will still be false
	-- and TrainingGrounds can detect they're new and auto-start tutorial

	-- Set flag via TeleportData so Training Grounds knows to auto-start tutorial
	local teleportOptions = Instance.new("TeleportOptions")
	local teleportData = {
		AutoStartTutorial = true
	}
	teleportOptions:SetTeleportData(teleportData)

	print("[TutorialHandler] Teleporting", player.Name, "to TrainingGrounds")
	print("[TutorialHandler] TeleportData being set:", teleportData)

	-- Teleport to Training Grounds place
	local success, err = pcall(function()
		TeleportService:Teleport(TRAINING_GROUNDS_PLACE_ID, player, teleportOptions)
	end)

	if not success then
		warn("[TutorialHandler] Failed to teleport player to Training Grounds:", err)
	else
		print("[TutorialHandler] Successfully teleported", player.Name, "to TrainingGrounds")
	end
end)

-- Handle tutorial Decline button
local tutorialDeclineRemote = getOrCreateRemote("TutorialDecline")

tutorialDeclineRemote.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end

	-- Mark tutorial as seen (but not completed) so it won't show again
	if _G.sessionData and _G.sessionData[player] then
		_G.sessionData[player].TutorialSeen = true

		-- Update SharedData
		if SharedData:FindFirstChild(player.Name) then
			local playerDataFolder = SharedData[player.Name]
			if not playerDataFolder:FindFirstChild("TutorialSeen") then
				local tutorialSeenValue = Instance.new("BoolValue")
				tutorialSeenValue.Name = "TutorialSeen"
				tutorialSeenValue.Parent = playerDataFolder
			end
			playerDataFolder.TutorialSeen.Value = true
		end
	end
end)
