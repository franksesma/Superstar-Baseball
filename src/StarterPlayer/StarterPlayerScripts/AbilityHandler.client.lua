local ReplicatedStorage = game.ReplicatedStorage
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local Remotes = ReplicatedStorage.RemoteEvents

local AbilityCinematics = require(ReplicatedStorage.SharedModules:WaitForChild("AbilityCinematics"))

Remotes.AbilityCamera.OnClientEvent:Connect(function(pitcher, hitter, ability, category, bat)
	if Players.LocalPlayer.TeamColor == Teams.Lobby.TeamColor then return end
	
	AbilityCinematics.HandleAbilityCamera(pitcher, hitter, ability, category, bat)
end)
