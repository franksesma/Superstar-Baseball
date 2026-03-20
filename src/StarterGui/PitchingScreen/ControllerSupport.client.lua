local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")

local mouse = player:GetMouse()
local Cursor = script.Parent.Cursor

local cursorPosition = Vector2.new(game.Workspace.CurrentCamera.ViewportSize.X / 2,
	game.Workspace.CurrentCamera.ViewportSize.Y / 2)

local isController = false

local function updateCursor()
	Cursor.Position = UDim2.new(0, cursorPosition.X - 25, 0, cursorPosition.Y - 25)
end

local function onInputChanged(input)
	if input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.Thumbstick1 then
		isController = true
		local move = input.Position
		local speed = 10

		cursorPosition = cursorPosition + Vector2.new(move.X * speed, -move.Y * speed)

		local viewportSize = game.Workspace.CurrentCamera.ViewportSize
		cursorPosition = Vector2.new(
			math.clamp(cursorPosition.X, 0, viewportSize.X),
			math.clamp(cursorPosition.Y, 0, viewportSize.Y)
		)

		updateCursor()
	end
end

mouse.Move:Connect(function()
	if not isController then
	    local MouseLocation = userInputService:GetMouseLocation()
	    Cursor.Position = UDim2.fromOffset(MouseLocation.X - (Cursor.AbsoluteSize.X / 2), MouseLocation.Y - (Cursor.AbsoluteSize.Y / 2))
	end
end)

userInputService.InputChanged:Connect(onInputChanged)

