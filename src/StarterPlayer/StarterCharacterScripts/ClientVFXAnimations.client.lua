local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animations = script:WaitForChild("Animations")
local Remotes = ReplicatedStorage.RemoteEvents

local player = Players.LocalPlayer
local character = player.Character
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

local loadedAnimations = {}

for _, animation in pairs(Animations:GetChildren()) do
	local loadedAnimTrack = animator:LoadAnimation(animation)
	loadedAnimations[animation.Name] = loadedAnimTrack
end

Remotes.PlayClientVFXAnimation.OnClientEvent:Connect(function(animName, play)
	if play then
		loadedAnimations[animName]:Play()
	else
		loadedAnimations[animName]:Stop()
	end
end)
