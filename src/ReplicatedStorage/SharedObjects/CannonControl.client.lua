-- ReplicatedStorage.CannonControl (LocalScript)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local cannonModelName = script:GetAttribute("CannonModelName")
local cannon = workspace:WaitForChild(cannonModelName)
local frame = cannon:WaitForChild("Frame")
local base = cannon:WaitForChild("Bottom")

local pitch, yaw = 0, 0
local PITCH_LIMIT = math.rad(45)

local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Left then
		yaw -= 5
	elseif input.KeyCode == Enum.KeyCode.Right then
		yaw += 5
	elseif input.KeyCode == Enum.KeyCode.Up then
		pitch = math.clamp(pitch - 5, -45, 45)
	elseif input.KeyCode == Enum.KeyCode.Down then
		pitch = math.clamp(pitch + 5, -45, 45)
	end
end)

RunService.RenderStepped:Connect(function()
	if cannon and frame and base then
		local baseCF = base.CFrame
		local yawCF = CFrame.Angles(0, math.rad(yaw), 0)
		local pitchCF = CFrame.Angles(math.rad(pitch), 0, 0)
		frame.CFrame = baseCF * yawCF * pitchCF * CFrame.new(0, 2, 0)
	end
end)

-- Cleanup after 3 seconds (or any timeout you want)
task.delay(3, function()
	if script then script:Destroy() end
end)
