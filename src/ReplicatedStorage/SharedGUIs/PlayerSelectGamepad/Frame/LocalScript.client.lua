local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage.RemoteEvents
local SharedModules = ReplicatedStorage.SharedModules
local GameValues = ReplicatedStorage.GameValues

local GuiAnimationModule = require(SharedModules.GuiAnimation)

local Frame = script.Parent.Background
local Container = Frame.Container

local player = Players.LocalPlayer

for _, button in pairs(Container:GetChildren()) do
	if button:IsA("TextButton") then
		button.MouseButton1Click:Connect(function()
			GuiAnimationModule.ButtonPress(player, "PositiveClick")
			local selectedPlayer = Players:FindFirstChild(button.Name)
			if selectedPlayer then
				Remotes.PlayerSelect:FireServer(selectedPlayer)
			end
		end)
	end
end