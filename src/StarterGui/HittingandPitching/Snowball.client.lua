local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local SnowfaceEffectRE = Remotes:WaitForChild("SnowballEffect")

local flakes = {"19003948", "19003957", "19003971", "19003978", "19003982", "19003990", "19003998"}
local globs  = {"19323823", "19323854"}

-- =========================
-- Center-biased spawn helpers
-- =========================
local function rand01()
	return math.random()
end

-- Returns a value in [min, max], biased toward the midpoint by averaging samples
local function randCenter(min: number, max: number, samples: number?)
	samples = samples or 2
	local s = 0
	for _ = 1, samples do
		s += rand01()
	end
	local t = s / samples -- 0..1, biased toward 0.5
	return min + (max - min) * t
end

-- Safer boundaries so splats aren't near the edges
local SAFE_MIN = 0.18
local SAFE_MAX = 0.82

local function makeImage(parent: Instance, assetId: string, pos: UDim2, size: UDim2)
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.BorderSizePixel = 0
	img.Image = "rbxassetid://" .. assetId
	img.Position = pos
	img.Size = size
	img.SizeConstraint = Enum.SizeConstraint.RelativeXX
	img.ImageTransparency = 1
	img.Parent = parent
	return img
end

local function playSnowface(duration: number)
	duration = tonumber(duration) or 5
	duration = math.clamp(duration, 1, 15)

	-- Clean any old one (prevents stacking)
	local pg = player:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("SnowfaceEffectGui")
	if old then old:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "SnowfaceEffectGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 999999
	gui.Parent = pg

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "SnowfaceEffect"
	mainFrame.BackgroundTransparency = 1
	mainFrame.BorderSizePixel = 0
	mainFrame.Position = UDim2.fromScale(0, 0)
	mainFrame.Size = UDim2.fromScale(1, 1)
	mainFrame.Parent = gui

	-- Big glob (more centered bias)
	do
		local size = (math.random() * 0.2) + 0.5

		local x = randCenter(SAFE_MIN, SAFE_MAX, 3)
		local y = randCenter(SAFE_MIN, SAFE_MAX, 3)
		local pos = UDim2.fromScale(x - (size / 2), y - (size / 2))

		local s = makeImage(
			mainFrame,
			globs[math.random(1, #globs)],
			pos,
			UDim2.fromScale(size, size)
		)

		-- Fade in
		TweenService:Create(s, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 0.05
		}):Play()

		-- Slight drift (tiny motion feels more “splat”)
		local drift = UDim2.new(
			pos.X.Scale + (math.random(-10, 10) / 1000),
			0,
			pos.Y.Scale + (math.random(-10, 10) / 1000),
			0
		)
		TweenService:Create(s, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = drift
		}):Play()
	end

	-- Flakes (still somewhat centered, but less strict)
	for i = 1, 20 do
		local size = (math.random() * 0.05) + 0.05

		local x = randCenter(SAFE_MIN, SAFE_MAX, 2)
		local y = randCenter(SAFE_MIN, SAFE_MAX, 2)
		local pos = UDim2.fromScale(x - (size / 2), y - (size / 2))

		local s = makeImage(
			mainFrame,
			flakes[math.random(1, #flakes)],
			pos,
			UDim2.fromScale(size, size)
		)

		-- Staggered fade-in
		task.delay(math.random() * 0.15, function()
			if s and s.Parent then
				TweenService:Create(s, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					ImageTransparency = 0.15
				}):Play()
			end
		end)

		-- Auto-remove like the old gear
		Debris:AddItem(s, 3 + (math.random() * 6))
	end

	-- Hard cleanup timer for the whole gui
	task.delay(duration, function()
		if not gui or not gui.Parent then return end

		-- Fade out everything still alive
		for _, d in ipairs(mainFrame:GetChildren()) do
			if d:IsA("ImageLabel") then
				TweenService:Create(d, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					ImageTransparency = 1
				}):Play()
			end
		end

		task.delay(0.28, function()
			if gui and gui.Parent then
				gui:Destroy()
			end
		end)
	end)
end

SnowfaceEffectRE.OnClientEvent:Connect(function(duration)
	wait(10)
	playSnowface(duration)
end)
