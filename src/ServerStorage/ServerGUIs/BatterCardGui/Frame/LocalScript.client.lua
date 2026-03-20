local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage.RemoteEvents
local SharedModules = ReplicatedStorage.SharedModules
local GameValues = ReplicatedStorage.GameValues

local Frame = script.Parent

local player = Players.LocalPlayer

if player.Character 
	and player.Character:FindFirstChild("States") 
	and player.Character.States:FindFirstChild("InStylesLocker") 
	and player.Character.States.InStylesLocker.Value 
	and GameValues.CurrentBatter.Value ~= player
then
	task.wait()
	Frame.Parent:Destroy()
else
	Frame:TweenPosition(UDim2.new(0.25, 0, 0.8, 0), 'Out', 'Quint', 1)

	wait(4)

	Frame:TweenPosition(UDim2.new(0.25, 0, 1.05, 0), 'In', 'Quint', 1)

	wait(1.5)

	Frame.Parent:Destroy()
end

