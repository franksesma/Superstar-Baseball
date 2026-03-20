local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local AbilityCinematics = SharedModules:WaitForChild("AbilityCinematics")

local animationsToPreload = {}

for _, descendant in ipairs(AbilityCinematics:GetDescendants()) do
	if descendant:IsA("Animation") then
		table.insert(animationsToPreload, descendant)
	end
end

local success, err = pcall(function()
	ContentProvider:PreloadAsync(animationsToPreload)
end)
