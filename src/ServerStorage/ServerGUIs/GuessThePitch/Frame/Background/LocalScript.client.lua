local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local SharedDataFolder = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local Remotes = ReplicatedStorage.RemoteEvents

local GuiAnimationModule = require(SharedModules.GuiAnimation)
local ClientFunctions = require(SharedModules.ClientFunctions)

local GuessFrame = script.Parent.GuessFrame

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

if player.Character 
	and player.Character:FindFirstChild("States") 
	and player.Character.States:FindFirstChild("InStylesLocker")
	and player.Character.States.InStylesLocker.Value 
then
	script.Parent.Parent.Visible = false
end

for _, button in pairs(GuessFrame:GetChildren()) do
	if button:IsA("TextButton") then
		GuiAnimationModule.SetupShrinkButton(button)
		
		button.MouseButton1Click:Connect(function()
			GuiAnimationModule.ButtonPress(player, "PositiveClick")
			
			Remotes.GuessThePitch:FireServer(button.Name)
			
			for _, button in pairs(GuessFrame:GetChildren()) do
				if button:IsA("TextButton") then
					button.Visible = false
					button.Selectable = false
					button.Interactable = false
				end
			end
			GuessFrame.Label.Visible = true
			GuessFrame.Label.Text = "Your guess: "..button.Name..". Awaiting the pitch..."
		end)
	end
end
