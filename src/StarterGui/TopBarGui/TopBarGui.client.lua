local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage.RemoteEvents

local SharedModules = ReplicatedStorage.SharedModules
local GameValues = ReplicatedStorage.GameValues
local SharedData = ReplicatedStorage.SharedData
local Emotes = ReplicatedStorage.ShopItems.Emote

local Icon = require(SharedModules.Icon)
local ClientFunctions = require(SharedModules.ClientFunctions)
local GuiAnimationModule = require(SharedModules.GuiAnimation)
local FreecamModule = require(SharedModules.FreecamModule)

local player = Players.LocalPlayer
local playingAnimTrack = nil
local runningConn = nil

local camera = workspace.CurrentCamera

local emoteIcon = Icon.new()
	:setImage("rbxassetid://114515697762488")
	--:setLabel("Emotes")
	:setName("EmoteIcon")
	:bindToggleKey(Enum.KeyCode.Tab)

local function setupEmoteButton(emoteName)
	local dropdownIcon = Icon.new()
		:setLabel(emoteName)
	-- Optional: .setImage() here if you want unique emote icons

	dropdownIcon.selected:Connect(function()
		if workspace.CurrentCamera.CameraType == Enum.CameraType.Scriptable then
			return
		end

		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				local animator = humanoid:FindFirstChild("Animator")

				if animator then
					if playingAnimTrack then
						playingAnimTrack:Stop()
						playingAnimTrack:Destroy()
						playingAnimTrack = nil
					end

					if runningConn then
						runningConn:Disconnect()
						runningConn = nil
					end

					local animation = Instance.new("Animation")
					animation.AnimationId = Emotes[emoteName].AnimationId

					local track = humanoid:LoadAnimation(animation)
					playingAnimTrack = track
					track:Play()

					runningConn = humanoid.Running:Connect(function(speed)
						if speed > 0 then
							if playingAnimTrack then
								playingAnimTrack:Stop()
								playingAnimTrack:Destroy()
								playingAnimTrack = nil
							end
							if runningConn then
								runningConn:Disconnect()
								runningConn = nil
							end
						end
					end)
				end
			end
		end
		-- Optional: collapse menu after play
		emoteIcon:deselect()
	end)

	return dropdownIcon
end


local function populateDropdown()
	--if emoteIcon:getDropdown() then
	--	emoteIcon:clearDropdown()
	--end
	local dropdownIcons = {}
	
	SharedData:WaitForChild(player.Name)
	
	local emotes = Remotes.GetEmoteInventory:InvokeServer()

	for emoteName, owned in pairs(emotes) do
		local dropdownIcon = setupEmoteButton(emoteName)
		
		table.insert(dropdownIcons, dropdownIcon)
	end
	
	emoteIcon:setDropdown(dropdownIcons)
end

populateDropdown()

Remotes.DisableEmotes.OnClientEvent:connect(function()
	if playingAnimTrack then
		playingAnimTrack:Stop()
		playingAnimTrack:Destroy()
		playingAnimTrack = nil
	end
	if runningConn then
		runningConn:Disconnect()
		runningConn = nil
	end
end)

Remotes.UpdateEmoteInventory.OnClientEvent:Connect(function()
	Icon.getIcon("EmoteIcon"):destroy()
	
	emoteIcon = Icon.new()
		:setImage("rbxassetid://114515697762488")
		--:setLabel("Emotes")
		:setName("EmoteIcon")
		:bindToggleKey(Enum.KeyCode.Tab)
	
	populateDropdown()
end)

local function setupSpectate()
	if player.TeamColor == game.Teams.Lobby.TeamColor then
		local function getSpectatePlayers()
			local players = {}

			for _, otherPlayer in pairs(Players:GetPlayers()) do
				if (ClientFunctions.PlayerIsDefender(otherPlayer) 
					or ClientFunctions.PlayerIsOffense(otherPlayer)) and otherPlayer ~= player
				then
					table.insert(players, otherPlayer)
				end
			end

			return players
		end

		if Icon.getIcon("SpectateIcon") then
			Icon.getIcon("SpectateIcon"):Destroy()
		end

		local spectateIcon = Icon.new()
			:setImage("rbxassetid://109132560029203")
			:setName("SpectateIcon")
		
		-- LEAGUE FREECAM: only on this place + keyboard-enabled devices
		if game.PlaceId == 82183144153025 and UserInputService.KeyboardEnabled then
			local freecamEnabled = false

			spectateIcon.selected:Connect(function()
				if freecamEnabled then
					freecamEnabled = false

					FreecamModule:StopFreecam()

					camera.CameraType = Enum.CameraType.Custom
					if player.Character and player.Character:FindFirstChild("Humanoid") then
						camera.CameraSubject = player.Character.Humanoid
					end
					
					player.PlayerGui.LobbyRelatedUI.Enabled = true
					player.PlayerGui.CoinsDisplay.Enabled = true
					player.PlayerGui.AbilityPower.Enabled = true
					SharedData[player.Name].FreecamMode.Value = false
					
					ClientFunctions.Notification(player, "FreeCam disabled!")
				else
					freecamEnabled = true

					FreecamModule:EnableFreecam()
					
					player.PlayerGui.LobbyRelatedUI.Enabled = false
					player.PlayerGui.CoinsDisplay.Enabled = false
					player.PlayerGui.AbilityPower.Enabled = false
					SharedData[player.Name].FreecamMode.Value = true
					
					ClientFunctions.Notification(player, "FreeCam enabled!")
				end
			end)

			return
		end

		local spectateEnabled = false

		local spectateFrame = player:WaitForChild("PlayerGui"):WaitForChild("LobbyRelatedUI"):WaitForChild("SpectateFrame")
		local nextButton = spectateFrame:WaitForChild("Next")
		local prevButton = spectateFrame:WaitForChild("Prev")
		local exitButton = spectateFrame:WaitForChild("Exit")
		local spectateLabel = spectateFrame:WaitForChild("Label")

		local spectatePlayers = getSpectatePlayers()
		local spectateIndex = 1
		local spectateCycleDebounce = false

		spectateIcon.selected:Connect(function()
			if spectateEnabled then
				spectateEnabled = false

				player.PlayerGui.LobbyRelatedUI.SpectateFrame.Visible = false
				camera.CameraSubject = player.Character.Humanoid
			else
				if #spectatePlayers ~= #getSpectatePlayers() then
					spectatePlayers = getSpectatePlayers()
				end

				if #spectatePlayers > 0 then
					player.PlayerGui.LobbyRelatedUI.SpectateFrame.Visible = true

					local spectatedPlayer = spectatePlayers[spectateIndex] 

					if spectatedPlayer and spectatedPlayer.Character and spectatedPlayer.Character:FindFirstChild("Humanoid") then
						camera.CameraSubject = spectatePlayers[spectateIndex].Character.Humanoid
						spectateLabel.Text = "Spectating: "..spectatedPlayer.Name
						spectateEnabled = true
					end
				else
					ClientFunctions.Notification(player, "No players to spectate!")
				end
			end
		end)

		GuiAnimationModule.SetupShrinkButton(nextButton)
		nextButton.MouseButton1Click:Connect(function()
			spectateCycleDebounce = true

			GuiAnimationModule.ButtonPress(player, "PositiveClick")

			if #spectatePlayers ~= #getSpectatePlayers() then
				spectatePlayers = getSpectatePlayers()
			end

			local foundSpectatePlayer = false

			repeat
				if spectateIndex + 1 <= #getSpectatePlayers() then
					spectateIndex += 1
				else
					spectateIndex = 1
				end

				local spectatedPlayer = spectatePlayers[spectateIndex] 

				if spectatedPlayer and spectatedPlayer.Character and spectatedPlayer.Character:FindFirstChild("Humanoid") then
					camera.CameraSubject = spectatePlayers[spectateIndex].Character.Humanoid
					foundSpectatePlayer = true
					spectateLabel.Text = "Spectating: "..spectatedPlayer.Name
				end
			until foundSpectatePlayer

			spectateCycleDebounce = false
		end)

		GuiAnimationModule.SetupShrinkButton(prevButton)
		prevButton.MouseButton1Click:Connect(function()
			spectateCycleDebounce = true

			GuiAnimationModule.ButtonPress(player, "PositiveClick")

			if #spectatePlayers ~= #getSpectatePlayers() then
				spectatePlayers = getSpectatePlayers()
			end

			local foundSpectatePlayer = false

			repeat
				if spectateIndex - 1 > 0 then
					spectateIndex = spectateIndex - 1
				else
					spectateIndex = #spectatePlayers
				end

				local spectatedPlayer = spectatePlayers[spectateIndex] 

				if spectatedPlayer and spectatedPlayer.Character and spectatedPlayer.Character:FindFirstChild("Humanoid") then
					camera.CameraSubject = spectatePlayers[spectateIndex].Character.Humanoid
					foundSpectatePlayer = true
					spectateLabel.Text = "Spectating: "..spectatedPlayer.Name
				end
			until foundSpectatePlayer

			spectateCycleDebounce = false
		end)

		GuiAnimationModule.SetupShrinkButton(exitButton)
		exitButton.MouseButton1Click:Connect(function()
			GuiAnimationModule.ButtonPress(player, "PositiveClick")
			player.PlayerGui.LobbyRelatedUI.SpectateFrame.Visible = false
			camera.CameraSubject = player.Character.Humanoid
		end)
	else
		if Icon.getIcon("SpectateIcon") then
			Icon.getIcon("SpectateIcon"):Destroy()
		end
	end
end

player:GetPropertyChangedSignal("TeamColor"):Connect(function()
	setupSpectate()
end)

setupSpectate()

