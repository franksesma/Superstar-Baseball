local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local model = script.Parent
local player = Players.LocalPlayer

local SharedData = ReplicatedStorage.SharedData:WaitForChild(player.Name)

-- Gather all MeshParts in the model
local meshParts = {}
local originalCFrames = {}
local randomOffsets = {}

local function added(part)
	if part:IsA("BasePart") then
		table.insert(meshParts, part)
		originalCFrames[part] = part.CFrame
		-- Give each part a random phase offset for more natural movement
		randomOffsets[part] = math.random() * math.pi * 2
	end
end

for _, part in model:GetDescendants() do
	added(part)
end


-- Animation parameters
local jumpHeight = 1.5      -- studs
local swayAmount = 0.4      -- studs
local jumpSpeed = 4         -- cycles per second (increased for faster jumping)
local swaySpeed = 2.5       -- cycles per second (increased for faster swaying)

while script:FindFirstAncestorWhichIsA("Workspace") do
	if SharedData 
		and SharedData:FindFirstChild("Settings") 
		and SharedData.Settings:FindFirstChild("CrowdMotion") 
		and SharedData.Settings.CrowdMotion.Value 
	then
		local t = tick()
		for _, part in meshParts do
			local baseCFrame = originalCFrames[part]
			local offset = randomOffsets[part]
			-- Calculate vertical (jump) and horizontal (sway) offsets
			local jump = math.abs(math.sin((t * jumpSpeed) + offset)) * jumpHeight
			local sway = math.sin((t * swaySpeed) + offset) * swayAmount
			-- Apply the offsets to the original CFrame
			local newCFrame = baseCFrame * CFrame.new(sway, 0, jump)
			part.CFrame = newCFrame
		end
	end
	task.wait(0.03)
	--task.wait(1/60)
end