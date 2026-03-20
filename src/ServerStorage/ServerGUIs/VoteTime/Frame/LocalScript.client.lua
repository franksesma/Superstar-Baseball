local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage.RemoteEvents
local SharedModules = ReplicatedStorage.SharedModules
local GameValues = ReplicatedStorage.GameValues

local GuiAnimationModule = require(SharedModules.GuiAnimation)

local Frame = script.Parent.Background
local Countdown = Frame.Countdown
local Container = Frame.Container

local player = Players.LocalPlayer

for _, button in pairs(Container:GetChildren()) do
	if button:IsA("TextButton") then
		GuiAnimationModule.SetupShrinkButton(button)

		button.MouseButton1Click:Connect(function()
			Remotes.VoteGameTime:FireServer(button.Name)
			GuiAnimationModule.ButtonPress(player, "PositiveClick")
			script.Parent.Parent:Destroy()
		end)
	end
end

Remotes.UICountdown.OnClientEvent:Connect(function(value)
	Countdown.Text = value
end)