local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AFK_TIME = 60*5

local Remotes = ReplicatedStorage.RemoteEvents
local SharedModules = ReplicatedStorage.SharedModules
local GameValues = ReplicatedStorage.GameValues

local ClientFunctions = require(SharedModules.ClientFunctions)

AFKTimer = 0

UIS.InputBegan:Connect(function()
	AFKTimer = 0
end)

if GameValues.ServerType.Value ~= "ReservedServer" then
	while true do
		wait(5)
		
		if Players.LocalPlayer.TeamColor == Teams.Lobby.TeamColor or not GameValues.GameActive.Value or RunService:IsStudio() then AFKTimer = 0 end
		
		AFKTimer += 5
		
		--print(AFKTimer)

		if AFKTimer >= AFK_TIME then
			Remotes.ReturnToLobby:FireServer()
			ClientFunctions.Notification(Players.LocalPlayer, "You were returned to the lobby for inactivity", "Alert")
		end
	end
end