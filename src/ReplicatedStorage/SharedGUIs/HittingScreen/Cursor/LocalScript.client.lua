-- LocalScript inside HittingScreen.Cursor
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

print("✅ Cursor script is running")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local imageLabel = script.Parent
local hittingScreen = player:WaitForChild("PlayerGui"):WaitForChild("HittingScreen")
local hitFrame = hittingScreen:WaitForChild("HitFrame")

imageLabel.Visible = false
mouse.Icon = ""
print("✅ Got references to HitFrame and Cursor ImageLabel")

-- Begin render loop
RunService.RenderStepped:Connect(function()
	print("🔄 RenderStepped tick")

	local mousePos = UserInputService:GetMouseLocation()
	mousePos = Vector2.new(mousePos.X, mousePos.Y - 36) -- Remove topbar offset

	local framePos = hitFrame.AbsolutePosition
	local frameSize = hitFrame.AbsoluteSize

	local withinX = mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X
	local withinY = mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y
	local insideFrame = withinX and withinY

	print("🖱️ Mouse:", mousePos, "| HitFrame:", framePos, frameSize, "| Inside:", insideFrame)

	if insideFrame then
		if not imageLabel.Visible then
			print("🎯 Entered HitFrame — showing custom cursor")
		end
		imageLabel.Visible = true
		mouse.Icon = ""
	else
		if imageLabel.Visible then
			print("🚪 Left HitFrame — reverting to default mouse")
		end
		imageLabel.Visible = false
		mouse.Icon = Enum.MouseIcon.Default
	end

	-- Update position of the imageLabel to match cursor
	imageLabel.Position = UDim2.new(0, mousePos.X - 25, 0, mousePos.Y - 25)
end)
