local TweenService = game:GetService("TweenService")
local Player = game.Players.LocalPlayer
local Frame = script.Parent

local inner = Frame:WaitForChild("InnerCircle")
local rays = Frame:WaitForChild("Rays")
local outer = Frame:WaitForChild("OuterCircle")

-- Tween Info for pulsing
local tweenInfo = TweenInfo.new(
	0.5, -- duration
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.InOut,
	-1, -- repeat forever
	true -- reverse (ping-pong)
)

-- Rays: expand/contract
TweenService:Create(rays, tweenInfo, {
	Size = UDim2.new(1.3, 0, 1.3, 0)
}):Play()

-- InnerCircle: pulse size + faint flicker
TweenService:Create(inner, tweenInfo, {
	Size = UDim2.new(0.6, 0, 0.6, 0),
	ImageTransparency = 0.1
}):Play()

-- OuterCircle: transparency breathing
TweenService:Create(outer, tweenInfo, {
	ImageTransparency = 0.3 -- will tween between original (assumed 0) and 0.3
}):Play()