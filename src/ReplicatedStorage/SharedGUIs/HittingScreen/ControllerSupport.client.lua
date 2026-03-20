local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedDataFolder = ReplicatedStorage:WaitForChild("SharedData")
local GameValues = ReplicatedStorage:WaitForChild("GameValues")
local mouse = player:GetMouse()
local gui = script.Parent

local Cursor = gui:WaitForChild("Cursor")
local InnerCircle = Cursor:WaitForChild("InnerCircle")
local OuterCircle = Cursor:WaitForChild("OuterCircle")
local Rays = Cursor:WaitForChild("Rays")
local MouseFrame = gui:WaitForChild("MouseFrame")

local UIS = userInputService
local camera = workspace.CurrentCamera

-- Set anchor point
Cursor.AnchorPoint = Vector2.new(0.5, 0.5)

-- Console PCI (speed setting)
local playerData = SharedDataFolder:WaitForChild(player.Name)
local consolePCIValue = playerData.Settings:WaitForChild("ConsolePCI")

local cursorPosition = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
local isController = false

local function isViewportPosInFrame(frame, viewportPos)
	local tl = frame.AbsolutePosition
	local br = tl + frame.AbsoluteSize
	return viewportPos.X >= tl.X and viewportPos.X <= br.X
		and viewportPos.Y >= tl.Y and viewportPos.Y <= br.Y
end

----------------------------------------------------------
-- ?? PCI SPEED MULTIPLIER
----------------------------------------------------------
local function getPCISpeed()
	-- consolePCIValue is 0.5 ? 5
	local pci = tonumber(consolePCIValue.Value) or 1
	return pci   -- directly used as controller cursor speed multiplier
end

----------------------------------------------------------
-- CURSOR UPDATE
----------------------------------------------------------
local function updateCursor()
	Cursor.Position = UDim2.new(0, cursorPosition.X, 0, cursorPosition.Y)
end

local function onInputChanged(input)
	if input.UserInputType == Enum.UserInputType.Gamepad1 
		and input.KeyCode == Enum.KeyCode.Thumbstick1 
	then
		isController = true
		local move = input.Position

		-- base speed
		local baseSpeed = 10

		-- apply PCI multiplier
		local speed = baseSpeed * getPCISpeed()

		cursorPosition = cursorPosition + Vector2.new(move.X * speed, -move.Y * speed)

		-- clamp
		local viewport = camera.ViewportSize
		cursorPosition = Vector2.new(
			math.clamp(cursorPosition.X, 0, viewport.X),
			math.clamp(cursorPosition.Y, 0, viewport.Y)
		)

		updateCursor()
	end
end

mouse.Move:Connect(function()
	-- On touch devices: AimGrid mode uses drag-to-aim only; legacy mode lets mouse move the cursor
	if UIS.TouchEnabled then
		local legacyVal = playerData.Settings:FindFirstChild("LegacyHitting")
		if not legacyVal or not legacyVal.Value then
			return
		end
	end
	if not isController then
		cursorPosition = Vector2.new(mouse.X, mouse.Y)
		updateCursor()
	end
end)

userInputService.InputChanged:Connect(onInputChanged)

----------------------------------------------------------
-- Legacy hitting: on touch, move cursor to tap position (so cursor can move when tapping)
----------------------------------------------------------
UIS.InputBegan:Connect(function(inputObject)
	if inputObject.UserInputType ~= Enum.UserInputType.Touch then return end
	if not UIS.TouchEnabled then return end
	local legacyVal = playerData.Settings:FindFirstChild("LegacyHitting")
	if not legacyVal or not legacyVal.Value then return end
	local currentBatter = GameValues:FindFirstChild("CurrentBatter")
	if not currentBatter or currentBatter.Value ~= player then return end
	if not isViewportPosInFrame(MouseFrame, inputObject.Position) then return end

	cursorPosition = Vector2.new(inputObject.Position.X, inputObject.Position.Y)
	updateCursor()
end)

----------------------------------------------------------
-- VISIBILITY LOGIC
----------------------------------------------------------
local function CursorInFrame(frame)
	local topLeft = frame.AbsolutePosition
	local bottomRight = frame.AbsolutePosition + frame.AbsoluteSize

	return cursorPosition.X >= topLeft.X and cursorPosition.X <= bottomRight.X
		and cursorPosition.Y >= topLeft.Y and cursorPosition.Y <= bottomRight.Y
end

if not UIS.TouchEnabled then
	runService.RenderStepped:Connect(function()
		if CursorInFrame(MouseFrame) then
			Cursor.Visible = true
			InnerCircle.Visible = true
			OuterCircle.Visible = true
			Rays.Visible = true
			UIS.MouseIconEnabled = false
		else
			if isController then
				Cursor.Visible = true
				InnerCircle.Visible = false
				OuterCircle.Visible = true
				Rays.Visible = false
				UIS.MouseIconEnabled = false
			else
				Cursor.Visible = false
				UIS.MouseIconEnabled = true
			end
		end
	end)
end
