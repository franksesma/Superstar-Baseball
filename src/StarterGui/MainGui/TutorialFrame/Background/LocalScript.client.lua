local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local SharedDataFolder = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local Remotes = ReplicatedStorage.RemoteEvents

local GuiAnimationModule = require(SharedModules.GuiAnimation)
local ClientFunctions = require(SharedModules.ClientFunctions)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local ExitButton = script.Parent.ExitButton
local Buttons = script.Parent.Buttons
local ContentFrame = script.Parent.ContentFrame


GuiAnimationModule.ExitButtonPressed(player, script.Parent.Parent, ExitButton)

local frames = {
	[Buttons.Game] = ContentFrame.GameFrame;
	[Buttons.Abilities] = ContentFrame.AbilitiesFrame;
	[Buttons.Fielding] = ContentFrame.FieldingFrame;
	[Buttons.Hitting] = ContentFrame.HittingFrame;
	[Buttons.Pitching] = ContentFrame.PitchingFrame;
	[Buttons.Styles] = ContentFrame.StylesFrame;
	[Buttons.Update] = ContentFrame.UpdateLogs;
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

for button, frame in pairs(frames) do
	GuiAnimationModule.SetupShrinkButton(button)

	button.MouseButton1Click:connect(function()
		frameButtonClicked(frame, button)
	end)
end

ContentFrame.UpdateLogs.Container.Version.Text = ReplicatedFirst.Version.Value.." Update!"
ContentFrame.UpdateLogs.Container.Description.Text = ReplicatedFirst.VersionDescription.Value
