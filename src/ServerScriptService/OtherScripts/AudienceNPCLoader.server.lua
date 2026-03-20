local ServerStorage = game:GetService("ServerStorage")

local AIs = ServerStorage.AIs
local AccessoryFolder = ServerStorage:WaitForChild("NPCAccessories")
local RigTemplate = AIs:WaitForChild("AudienceNPC")
local AnimationFolder = script:WaitForChild("Animations")

local FACES = AccessoryFolder.Faces
local HAIRS = AccessoryFolder.Hairs
local HATS = AccessoryFolder.Hats

local AudienceFolder = workspace:WaitForChild("AudienceNPCs")
local NPCSpots = AudienceFolder:GetDescendants()

-- random skin tone palette
local SKIN_COLORS = {
	Color3.fromRGB(255, 220, 177),
	Color3.fromRGB(255, 220, 177),
	Color3.fromRGB(226, 188, 151),
	Color3.fromRGB(202, 157, 114),
	Color3.fromRGB(161, 119, 78),
}

-- clothing color palettes
local SHIRT_COLORS = {
	Color3.fromRGB(25, 118, 210),
	Color3.fromRGB(200, 50, 50),
	Color3.fromRGB(50, 200, 90),
	Color3.fromRGB(255, 200, 40),
	Color3.fromRGB(70, 70, 70),
	Color3.fromRGB(140, 90, 200)
}

local PANTS_COLORS = {
	Color3.fromRGB(30, 30, 30),
	Color3.fromRGB(90, 90, 90),
	Color3.fromRGB(40, 70, 130),
	Color3.fromRGB(10, 40, 80),
	Color3.fromRGB(110, 60, 40)
}

local function getRandomChild(folder)
	local children = folder:GetChildren()
	if #children == 0 then return nil end
	return children[math.random(1, #children)]
end

local function randomGender()
	return math.random(1,2) == 1 and "Men" or "Women"
end

local function applyAccessories(rig, gender)
	-- Face (Decal on head)
	local faceFolder = FACES:FindFirstChild(gender)
	if faceFolder then
		local face = getRandomChild(faceFolder)
		if face then
			local newFace = face:Clone()
			local head = rig:FindFirstChild("Head")
			if head then
				local existingFace = head:FindFirstChildOfClass("Decal")
				if existingFace then existingFace:Destroy() end
				newFace.Parent = head
			end
		end
	end

	-- Hair (Accessory)
	local hairFolder = HAIRS:FindFirstChild(gender)
	if hairFolder then
		local hair = getRandomChild(hairFolder)
		if hair then
			hair:Clone().Parent = rig
		end
	end

	-- Hat (Accessory)
	local hat = getRandomChild(HATS)
	if hat then
		hat:Clone().Parent = rig
	end
end

local function applyColors(rig)
	local skinColor = SKIN_COLORS[math.random(1, #SKIN_COLORS)]
	local shirtColor = SHIRT_COLORS[math.random(1, #SHIRT_COLORS)]
	local pantsColor = PANTS_COLORS[math.random(1, #PANTS_COLORS)]

	for _, part in ipairs(rig:GetChildren()) do
		if part:IsA("BasePart") then
			if part.Name == "Head" or part.Name == "Left Arm" or part.Name == "Right Arm" then
				part.Color = skinColor
			elseif part.Name == "Torso" then
				part.Color = shirtColor
			elseif part.Name == "Left Leg" or part.Name == "Right Leg" then
				part.Color = pantsColor
			end
		end
	end
end

local function playIdleAnimation(rig)
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

	local animations = AnimationFolder:GetChildren()
	if #animations == 0 then
		warn("No animations found in Animations folder")
		return
	end

	local randomAnim = animations[math.random(1, #animations)]

	if randomAnim:IsA("Animation") then
		local track = animator:LoadAnimation(randomAnim)
		track.Looped = true
		track.TimePosition = math.random() * (track.Length or 1)
		track:Play()
	else
		warn(("Invalid animation instance: %s"):format(randomAnim.Name))
	end
end

local function spawnNPCAtSpot(spot)
	local rig = RigTemplate:Clone()
	rig.Name = "NPC_" .. tostring(math.random(10000,99999))
	rig.Parent = AudienceFolder

	local gender = randomGender()
	applyAccessories(rig, gender)
	applyColors(rig)

	-- Align NPC to the NPCSpot
	if rig.PrimaryPart then
		rig:SetPrimaryPartCFrame(spot.CFrame)
	else
		warn("R6Template has no PrimaryPart set")
	end

	playIdleAnimation(rig)
end

-- Spawn an NPC for each NPCSpot
for _, spot in ipairs(NPCSpots) do
	if spot:IsA("BasePart") then
		spawnNPCAtSpot(spot)
	end
end
