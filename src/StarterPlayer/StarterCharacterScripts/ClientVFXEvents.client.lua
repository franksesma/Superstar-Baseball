local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedModules = ReplicatedStorage.SharedModules
local ClientVFXHandler = require(SharedModules.ClientVFXHandler)
local Remotes = ReplicatedStorage.RemoteEvents

Remotes.EnableSpeedlinesVFX.OnClientEvent:Connect(function(enabled)
	if enabled then
		ClientVFXHandler.StartSpeedlines()
	else
		ClientVFXHandler.StopSpeedlines()
	end
end)