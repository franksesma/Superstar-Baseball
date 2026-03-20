local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage.RemoteEvents
local SharedModules = ReplicatedStorage.SharedModules
local GameValues = ReplicatedStorage.GameValues

local GuiAnimationModule = require(SharedModules.GuiAnimation)

local Frame = script.Parent.Background
local Countdown = Frame.Countdown
local Buttons = Frame.ButtonsFrame

local AmericaContainer = Frame.AmericaContainer
local JapanContainer = Frame.JapanContainer
local KoreaContainer = Frame.KoreaContainer

local player = Players.LocalPlayer

local frames = {
	[Buttons.America] = AmericaContainer;
	[Buttons.Japan] = JapanContainer;
	[Buttons.Korea] = KoreaContainer;
}

local buttonClicked = false

local function frameButtonClicked(frame, button)
	if not buttonClicked then
		buttonClicked = true
		GuiAnimationModule.ButtonPress(player, "PositiveClick")

		frame.Visible = true
		button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		button.UIStroke.Color = Color3.fromRGB(0, 255, 255)

		for k,v in pairs(frames) do
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

local function isPlayerCaptain()
	local homeCaptain = GameValues.HomeCaptain.Value
	local awayCaptain = GameValues.AwayCaptain.Value

	if player == homeCaptain or player == awayCaptain then
		return true
	else
		return false
	end
end

for button, frame in pairs(frames) do
	GuiAnimationModule.SetupGrowButton(button)

	button.MouseButton1Click:connect(function()
		frameButtonClicked(frame, button)
	end)
	
	for _, button in pairs(frame:GetChildren()) do
		if button:IsA("TextButton") then
			if isPlayerCaptain() then
				GuiAnimationModule.SetupShrinkButton(button)

				button.MouseButton1Click:Connect(function()
					Remotes.TeamSelect:FireServer(button.Name)
					GuiAnimationModule.ButtonPress(player, "PositiveClick")
				end)
			else
				button.AutoButtonColor = false
				button.Active = false
				button.Selectable = false
				Frame.WaitLabel.Visible = true
			end
		end
	end
end

local function showPlayerProfilePic(button, captainPlayer, designation)
	if captainPlayer ~= nil then
		local success, img = pcall(function()
			return Players:GetUserThumbnailAsync(captainPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)
		
		if success and img and captainPlayer.UserId > 0 then
			button.CaptainPicked.Image = img
		else
			button.CaptainPicked.Image = "rbxassetid://135927875061357"
		end
		button.Designation.Visible = true
		button.Designation.Text = "("..designation..")"
	end
end

local function updateCaptainSelects()	
	for _, frame in pairs(frames) do
		for _, button in pairs(frame:GetChildren()) do
			if button:IsA("TextButton") then
				if button.Name == GameValues.AwayTeamPicked.Value then
					showPlayerProfilePic(button, GameValues.AwayCaptain.Value, "Away")
				elseif button.Name == GameValues.HomeTeamPicked.Value then
					showPlayerProfilePic(button, GameValues.HomeCaptain.Value, "Home")
				else
					button.CaptainPicked.Image = ""
					button.Designation.Visible = false
				end
			end
		end 
	end
end

updateCaptainSelects()

GameValues.AwayTeamPicked.Changed:Connect(function()
	updateCaptainSelects()
end)

GameValues.HomeTeamPicked.Changed:Connect(function()
	updateCaptainSelects()
end)

Remotes.UICountdown.OnClientEvent:Connect(function(value)
	Countdown.Text = value
end)