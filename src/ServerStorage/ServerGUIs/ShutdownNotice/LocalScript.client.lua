local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

for _, gui in pairs(playerGui:GetChildren()) do
	if gui:IsA("ScreenGui") and gui.Name ~= script.Parent.Name then
		gui.Enabled = false
	end
end

script.Blur.Parent = Lighting