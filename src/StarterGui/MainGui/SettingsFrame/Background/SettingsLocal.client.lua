local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local SharedDataFolder = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local Remotes = ReplicatedStorage.RemoteEvents
local GameValues = ReplicatedStorage.GameValues
local SharedGUIs = ReplicatedStorage.SharedGUIs

local GuiAnimationModule = require(SharedModules.GuiAnimation)
local ClientFunctions = require(SharedModules.ClientFunctions)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local ExitButton = script.Parent.ExitButton
local Container = script.Parent.Container.ContainerFrame

local JerseyName = Container.JerseyName
local JerseyNumber = Container.JerseyNumber
local GameMusic = Container.GameMusic
local WalkUpSongs = Container.WalkUpSongs
local WalkUpSongID = Container.WalkUpSongID
local Narration = Container.Narration
local RewardCode = Container.Code
local MobileCursor = Container.MobileCursor
local LegacyHitting = Container.LegacyHitting
local LeagueServer = Container.LeagueServer
local ConsolePCI = Container.ConsolePCI
local CrowdMotion = Container.CrowdMotion

local CONSOLE_PCI_MIN = 0.5
local CONSOLE_PCI_MAX = 5

GuiAnimationModule.SetupShrinkButton(JerseyName.ChangeButton)
JerseyName.ChangeButton.MouseButton1Click:Connect(function()
	if JerseyName.TextBox.Text ~= "" then
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		Remotes.ChangeJerseyInfo:FireServer("Name", JerseyName.TextBox.Text)
	end
end)

GuiAnimationModule.SetupShrinkButton(JerseyNumber.ChangeButton)
JerseyNumber.ChangeButton.MouseButton1Click:Connect(function()
	if JerseyNumber.TextBox.Text ~= "" then
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		Remotes.ChangeJerseyInfo:FireServer("Number", JerseyNumber.TextBox.Text)
	end
end)

GuiAnimationModule.SetupShrinkButton(WalkUpSongID.ChangeButton)
WalkUpSongID.ChangeButton.MouseButton1Click:Connect(function()
	if WalkUpSongID.TextBox.Text ~= "" then
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		Remotes.ChangeWalkUpSong:FireServer(WalkUpSongID.TextBox.Text)
	end
end)

GuiAnimationModule.SetupShrinkButton(RewardCode.RedeemButton)
RewardCode.RedeemButton.MouseButton1Click:Connect(function()
	if RewardCode.TextBox.Text ~= "" then
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		Remotes.RewardCode:FireServer(RewardCode.TextBox.Text)
	end
end)

Remotes.ChangeWalkUpSong.OnClientEvent:Connect(function(action)
	if action == "Reset" then
		WalkUpSongID.TextBox.Text = ""
	end
end)

Remotes.ChangeJerseyInfo.OnClientEvent:connect(function(jerseyName, jerseyNumber)
	if jerseyNumber == "" then
		JerseyNumber.TextBox.Text = "0"
	else
		JerseyNumber.TextBox.Text = jerseyNumber
	end

	if jerseyName == "" then
		JerseyName.TextBox.Text = player.Name
	else
		JerseyName.TextBox.Text = jerseyName
	end
end)

GuiAnimationModule.ExitButtonPressed(player, script.Parent.Parent, ExitButton)

local playerDataFolder = SharedDataFolder:WaitForChild(player.Name)

local function updateSettingButton(settingName)
	local settingVal = playerDataFolder.Settings:FindFirstChild(settingName)
	local frame = Container:FindFirstChild(settingName)
	if not settingVal or not frame or not frame:FindFirstChild("EnableButton") or not frame.EnableButton:FindFirstChild("Label") then
		return
	end
	if settingVal.Value then
		frame.EnableButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		frame.EnableButton.Label.Text = "ON"

		if settingName == "GameMusic" then
			SoundService.Music.GameTheme.Volume = 0.1
			SoundService.Music.VictoryTheme.Volume = 0.1
		elseif settingName == "Narration" then
			for _, sound in pairs(SoundService.Narration:GetChildren()) do
				sound.Volume = 0.75
			end
		elseif settingName == "MobileCursor" then
		elseif settingName == "LegacyHitting" then
		end
	else
		frame.EnableButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		frame.EnableButton.Label.Text = "OFF"

		if settingName == "GameMusic" then
			SoundService.Music.GameTheme.Volume = 0
			SoundService.Music.VictoryTheme.Volume = 0
		elseif settingName == "WalkUpSongs" then
			SoundService.WalkUpMusic:ClearAllChildren()
		elseif settingName == "Narration" then
			for _, sound in pairs(SoundService.Narration:GetChildren()) do
				sound.Volume = 0
			end
		elseif settingName == "MobileCursor" then
		elseif settingName == "LegacyHitting" then
		end
	end
end

SoundService.WalkUpMusic.ChildAdded:Connect(function(soundObj)
	if not playerDataFolder.Settings["WalkUpSongs"].Value then
		wait()
		soundObj:Destroy()
	end
end)

updateSettingButton(GameMusic.Name)
GuiAnimationModule.SetupShrinkButton(GameMusic.EnableButton)
GameMusic.EnableButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	Remotes.UpdatePlayerSetting:FireServer(GameMusic.Name)
end)

updateSettingButton(CrowdMotion.Name)
GuiAnimationModule.SetupShrinkButton(CrowdMotion.EnableButton)
CrowdMotion.EnableButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	Remotes.UpdatePlayerSetting:FireServer(CrowdMotion.Name)
end)

updateSettingButton(Narration.Name)
GuiAnimationModule.SetupShrinkButton(Narration.EnableButton)
Narration.EnableButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	Remotes.UpdatePlayerSetting:FireServer(Narration.Name)
end)

updateSettingButton(WalkUpSongs.Name)
GuiAnimationModule.SetupShrinkButton(WalkUpSongs.EnableButton)
WalkUpSongs.EnableButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	Remotes.UpdatePlayerSetting:FireServer(WalkUpSongs.Name)
end)

updateSettingButton(MobileCursor.Name)
GuiAnimationModule.SetupShrinkButton(MobileCursor.EnableButton)
MobileCursor.EnableButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	Remotes.UpdatePlayerSetting:FireServer(MobileCursor.Name)
end)

if LegacyHitting and LegacyHitting:FindFirstChild("EnableButton") and LegacyHitting.EnableButton:FindFirstChild("Label") then
	updateSettingButton(LegacyHitting.Name)
	GuiAnimationModule.SetupShrinkButton(LegacyHitting.EnableButton)
	LegacyHitting.EnableButton.MouseButton1Click:Connect(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		Remotes.UpdatePlayerSetting:FireServer(LegacyHitting.Name)
	end)
end

Remotes.UpdatePlayerSetting.OnClientEvent:Connect(function(settingName)
	updateSettingButton(settingName)
end)

if playerDataFolder:FindFirstChild("WalkUpSongID") then
	WalkUpSongID.TextBox.Text = playerDataFolder.WalkUpSongID.Value
end

do
	local settingValObj = playerDataFolder.Settings:FindFirstChild("ConsolePCI")
	local initialValue = 1

	if settingValObj then
		initialValue = settingValObj.Value
	end

	ConsolePCI.TextBox.Text = tostring(initialValue)

	ConsolePCI.TextBox.FocusLost:Connect(function(enterPressed)
		local raw = ConsolePCI.TextBox.Text
		local num = tonumber(raw)
		if not num then
			ConsolePCI.TextBox.Text = tostring(initialValue)
			return
		end

		num = math.clamp(num, CONSOLE_PCI_MIN, CONSOLE_PCI_MAX)
		num = math.floor(num * 10 + 0.5) / 10

		ConsolePCI.TextBox.Text = tostring(num)
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		Remotes.UpdateConsolePCI:FireServer(num)
	end)
end

Remotes.UpdateConsolePCI.OnClientEvent:Connect(function(newValue)
	ConsolePCI.TextBox.Text = tostring(newValue)
end)

if game.PlaceId == 101432174163538 then
	LeagueServer.Visible = true

	GuiAnimationModule.SetupShrinkButton(LeagueServer.EnableButton)
	LeagueServer.EnableButton.Activated:Connect(function()
		if playerGui:FindFirstChild("LeagueServerUI") then return end

		GuiAnimationModule.ButtonPress(player, "PositiveClick")

		local leagueServerUI = SharedGUIs.LeagueServerUI:Clone()
		leagueServerUI.Parent = playerGui
	end)
end

local AdminEvents = ReplicatedStorage.AdminEvents
local isPrivateServerOwner = AdminEvents.IsPrivateServerOwner:InvokeServer()

if isPrivateServerOwner then
	local ButtonsFrame = script.Parent.ButtonsFrame
	local ContainerFrame = script.Parent.ServerContainer.ContainerFrame
	local ChangeBalls = ContainerFrame.ChangeBalls
	local ChangeOuts = ContainerFrame.ChangeOuts
	local ChangeStrikes = ContainerFrame.ChangeStrikes
	local ChangeInning = ContainerFrame.ChangeInning
	local AwayScore = ContainerFrame.AwayScore
	local HomeScore = ContainerFrame.HomeScore
	local SetAway = ContainerFrame.SetAway
	local SetHome = ContainerFrame.SetHome
	local KickPlayer = ContainerFrame.KickPlayer
	local PowerUps = ContainerFrame.PowerUps

	local frames = {
		[ButtonsFrame.PlayerSettings] = script.Parent.Container;
		[ButtonsFrame.ServerSettings] = script.Parent.ServerContainer;
	}

	local buttonClicked = false

	local function frameButtonClicked(frame, button)
		if not buttonClicked then
			buttonClicked = true
			GuiAnimationModule.ButtonPress(player, "PositiveClick")

			frame.Visible = true
			button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			button.UIStroke.Color = Color3.fromRGB(0, 255, 255)

			for k, v in pairs(frames) do
				if v ~= frame then
					k.BackgroundColor3 = Color3.fromRGB(170, 255, 255)
					k.UIStroke.Color = Color3.fromRGB(255, 255, 255)
					v.Visible = false
				end
			end

			if frame then
				buttonClicked = false
			end
		end
	end

	for button, frame in pairs(frames) do
		GuiAnimationModule.SetupShrinkButton(button)

		button.MouseButton1Click:connect(function()
			frameButtonClicked(frame, button)
		end)
	end

	script.Parent.LabelFrame.Visible = false
	ButtonsFrame.Visible = true

	GuiAnimationModule.SetupShrinkButton(ChangeOuts.AddButton)
	ChangeOuts.AddButton.MouseButton1Click:Connect(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		AdminEvents.ChangeOuts:FireServer("Add")
	end)

	GuiAnimationModule.SetupShrinkButton(ChangeOuts.SubtractButton)
	ChangeOuts.SubtractButton.MouseButton1Click:Connect(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		AdminEvents.ChangeOuts:FireServer("Subtract")
	end)

	GuiAnimationModule.SetupShrinkButton(ChangeBalls.AddButton)
	ChangeBalls.AddButton.MouseButton1Click:Connect(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		AdminEvents.ChangeBalls:FireServer("Add")
	end)

	GuiAnimationModule.SetupShrinkButton(ChangeBalls.SubtractButton)
	ChangeBalls.SubtractButton.MouseButton1Click:Connect(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		AdminEvents.ChangeBalls:FireServer("Subtract")
	end)

	GuiAnimationModule.SetupShrinkButton(ChangeStrikes.AddButton)
	ChangeStrikes.AddButton.MouseButton1Click:Connect(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		AdminEvents.ChangeStrikes:FireServer("Add")
	end)

	GuiAnimationModule.SetupShrinkButton(ChangeStrikes.SubtractButton)
	ChangeStrikes.SubtractButton.MouseButton1Click:Connect(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		AdminEvents.ChangeStrikes:FireServer("Subtract")
	end)

	GuiAnimationModule.SetupShrinkButton(ChangeInning.AddButton)
	ChangeInning.AddButton.MouseButton1Click:Connect(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		AdminEvents.ChangeInning:FireServer("Add")
	end)

	GuiAnimationModule.SetupShrinkButton(ChangeInning.SubtractButton)
	ChangeInning.SubtractButton.MouseButton1Click:Connect(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		AdminEvents.ChangeInning:FireServer("Subtract")
	end)

	GuiAnimationModule.SetupShrinkButton(HomeScore.AddButton)
	HomeScore.AddButton.MouseButton1Click:Connect(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		AdminEvents.HomeScore:FireServer("Add")
	end)

	GuiAnimationModule.SetupShrinkButton(HomeScore.SubtractButton)
	HomeScore.SubtractButton.MouseButton1Click:Connect(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		AdminEvents.HomeScore:FireServer("Subtract")
	end)

	GuiAnimationModule.SetupShrinkButton(AwayScore.AddButton)
	AwayScore.AddButton.MouseButton1Click:Connect(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		AdminEvents.AwayScore:FireServer("Add")
	end)

	GuiAnimationModule.SetupShrinkButton(AwayScore.SubtractButton)
	AwayScore.SubtractButton.MouseButton1Click:Connect(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		AdminEvents.AwayScore:FireServer("Subtract")
	end)

	GuiAnimationModule.SetupShrinkButton(PowerUps.EnableButton)
	PowerUps.EnableButton.MouseButton1Click:Connect(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		AdminEvents.PowerUps:FireServer()
	end)

	GameValues.PowerUpsEnabled.Changed:Connect(function()
		if GameValues.PowerUpsEnabled.Value then
			PowerUps.EnableButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		else
			PowerUps.EnableButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		end
	end)

	SetAway.TextBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			AdminEvents.SetPlayerTeam:FireServer(SetAway.TextBox.Text, "Away")
		end
	end)

	SetHome.TextBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			AdminEvents.SetPlayerTeam:FireServer(SetHome.TextBox.Text, "Home")
		end
	end)

	KickPlayer.TextBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			AdminEvents.KickPlayer:FireServer(KickPlayer.TextBox.Text)
		end
	end)
end
