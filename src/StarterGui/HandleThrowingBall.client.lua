--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

--// MODULES & OBJECTS
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local ClientFunctions = require(SharedModules:WaitForChild("ClientFunctions"))
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local PlayerScripts = player:WaitForChild("PlayerScripts")
local PlayerModuleEvents = PlayerScripts:WaitForChild("PlayerModuleEvents")
local GameValues = ReplicatedStorage:WaitForChild("GameValues")

--// UI Elements
local throwGui = player:WaitForChild("PlayerGui"):WaitForChild("AbilityPower"):WaitForChild("AbilityButtons")
local throwButton = throwGui:WaitForChild("Throw")

local throwingScreen = player:WaitForChild("PlayerGui"):WaitForChild("ThrowingScreen")
local basesFrame = throwingScreen:WaitForChild("BasesFrame")
local platesFolder = workspace:WaitForChild("Plates")

--// Base Buttons Mapping
local baseButtons = {
	["First"] = platesFolder:WaitForChild("First Base"),
	["Second"] = platesFolder:WaitForChild("Second Base"),
	["Third"] = platesFolder:WaitForChild("Third Base"),
	["Home"] = platesFolder:WaitForChild("Home Base"),
}

local gamepadBaseKeybinds = {
	[Enum.KeyCode.DPadRight] = baseButtons["First"], -- DPad Right = 1st
	[Enum.KeyCode.DPadUp]    = baseButtons["Second"], -- DPad Up = 2nd
	[Enum.KeyCode.DPadLeft]  = baseButtons["Third"], -- DPad Left = 3rd
	[Enum.KeyCode.DPadDown]  = baseButtons["Home"],  -- DPad Down = Home
}

local baseKeybinds = {
	[Enum.KeyCode.One] = baseButtons["First"],
	[Enum.KeyCode.Two] = baseButtons["Second"],
	[Enum.KeyCode.Three] = baseButtons["Third"],
	[Enum.KeyCode.Four] = baseButtons["Home"],
}

--// Throw Target UI
local ThrowTargetUI = ReplicatedStorage.SharedGUIs:WaitForChild("ThrowTargetAttachment")
local defenderUIs = {}

--// Visual Targeting
local circle = ReplicatedStorage.SharedObjects:WaitForChild("Target"):Clone()
circle.CanQuery = false
circle.Parent = nil


--// THROW STATE
local throwEnabled = false
local baseball = nil
local thrown = false
local lastStableTarget = nil
local lastMobileTapPosition = nil
local gloveConnection = nil
local arcParts = {}

--// UTIL FUNCTIONS
local function clearArc()
	for _, part in pairs(arcParts) do
		part:Destroy()
	end
	arcParts = {}
end

local function applyConsoleKeybindIcons()
	local show = GuiService:IsTenFootInterface() -- console-only
	for _, name in ipairs({"First","Second","Third","Home"}) do
		local frame = basesFrame:FindFirstChild(name)
		if frame then
			local xb = frame:FindFirstChild("XboxKeybind")
			if xb then xb.Visible = show end
		end
	end
end

local function computeVelocity(startPos, endPos, duration)
	local gravity = workspace.Gravity
	local displacement = endPos - startPos
	local vxz = Vector3.new(displacement.X, 0, displacement.Z) / duration
	local vy = (displacement.Y + 0.5 * gravity * duration * duration) / duration
	return Vector3.new(vxz.X, vy, vxz.Z)
end

local function drawArcFromTo(startPos, endPos, duration)
	clearArc()
	local velocity = computeVelocity(startPos, endPos, duration)
	local steps = 50
	local gravity = workspace.Gravity

	for i = 0, steps do
		local t = (i / steps) * duration
		local displacement = velocity * t + Vector3.new(0, -0.5 * gravity * t * t, 0)
		local pos = startPos + displacement

		local arcPart = Instance.new("Part")
		arcPart.Size = Vector3.new(0.3, 0.3, 0.3)
		arcPart.Shape = Enum.PartType.Ball
		arcPart.Anchored = true
		arcPart.CanCollide = false
		arcPart.CanQuery = false
		arcPart.Material = Enum.Material.Neon
		arcPart.Color = Color3.fromRGB(0, 255, 0)
		arcPart.Transparency = 0.25
		arcPart.Position = pos
		arcPart.Parent = workspace

		table.insert(arcParts, arcPart)
	end
end

local function getEquippedGlove()
	if player.Character then
		for _, obj in pairs(player.Character:GetChildren()) do
			if obj:IsA("Model") and obj:FindFirstChild("Baseball") then
				return obj
			end
		end
	end
	return nil
end

local function playerHasBall()
	return throwEnabled and baseball ~= nil
end


local function cancelThrow()
	throwEnabled = false
	baseball = nil
	thrown = false
	lastStableTarget = nil
	lastMobileTapPosition = nil
	clearArc()

	if circle.Parent then circle.Parent = nil end
	ContextActionService:UnbindAction("ThrowBall")

	for keyCode, _ in pairs(baseKeybinds) do
		ContextActionService:UnbindAction("ThrowToBase_" .. tostring(keyCode))
	end
	for keyCode, _ in pairs(gamepadBaseKeybinds) do
		ContextActionService:UnbindAction("ThrowToBase_" .. tostring(keyCode))
	end

	if gloveConnection then
		gloveConnection:Disconnect()
		gloveConnection = nil
	end

	throwButton.Visible = false
	basesFrame.Visible = false
end

local function buildThrowRaycastExclude()
	local list = {}

	if player.Character then
		table.insert(list, player.Character)
	end

	local loaded = workspace:FindFirstChild("LoadedBallpark")
	if loaded then
		local iw = loaded:FindFirstChild("InvisibleWalls")
		if iw then table.insert(list, iw) end

		local fw = loaded:FindFirstChild("FoulWalls")
		if fw then table.insert(list, fw) end

		local fieldw = loaded:FindFirstChild("FieldWalls")
		if fieldw then table.insert(list, fieldw) end
		
		mouse.TargetFilter = iw
	end

	return list
end

local function updateCirclePosition()
	if playerHasBall() and not thrown then
		if not circle.Parent then
			circle.Parent = workspace.GreenThrowCircle
		end

		local camera = workspace.CurrentCamera
		local targetPosition

		if UserInputService.TouchEnabled and lastMobileTapPosition then
			targetPosition = lastMobileTapPosition
		else
			local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = buildThrowRaycastExclude()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, rayParams)
			targetPosition = result and result.Position or nil
		end

		if targetPosition then
			lastStableTarget = targetPosition
		elseif not lastStableTarget then
			local forwardPoint = camera.CFrame.Position + camera.CFrame.LookVector * 200
			local groundParams = RaycastParams.new()
			groundParams.FilterType = Enum.RaycastFilterType.Exclude
			groundParams.FilterDescendantsInstances = {player.Character}
			local groundHit = workspace:Raycast(forwardPoint, Vector3.new(0, -1000, 0), groundParams)
			lastStableTarget = groundHit and groundHit.Position or forwardPoint
		end

		if lastStableTarget then
			local glove = getEquippedGlove()
			local origin = (glove and glove:FindFirstChild("MeshPart")) and glove.MeshPart.Position or camera.CFrame.Position
			local direction = lastStableTarget - origin
			local minDistance, maxDistance = 2, 200
			local clampedDistance = math.clamp(direction.Magnitude, minDistance, maxDistance)
			local clampedTarget = origin + direction.Unit * clampedDistance

			circle.Position = Vector3.new(clampedTarget.X, 2, clampedTarget.Z)

			if glove and glove:FindFirstChild("MeshPart") then
				drawArcFromTo(origin, circle.Position, 1.0)
			end
		end
	else
		lastStableTarget = nil
		if circle.Parent then
			circle.Parent = nil
		end
		clearArc()
	end
end

--// THROW TO A POINT
local function throwToTarget(targetPos)
	local glove = getEquippedGlove()
	local throwOrigin = glove and glove:FindFirstChild("MeshPart") and glove.MeshPart.Position or workspace.CurrentCamera.CFrame.Position

	local direction = targetPos - throwOrigin
	local clampedDistance = math.clamp(direction.Magnitude, 2, 200)
	local clampedTarget = throwOrigin + direction.Unit * clampedDistance

	-- Play throw animation
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local throwAnimation = Instance.new("Animation")
			throwAnimation.AnimationId = "rbxassetid://121275694106607"
			local animTrack = humanoid:LoadAnimation(throwAnimation)
			animTrack:Play()
			animTrack:AdjustSpeed(2)
		end
	end

	thrown = true
	PlayerModuleEvents.DisableMovement:Fire(true)
	task.wait(0.3)
	Remotes.AttachBallToHand:FireServer()
	task.wait(0.35)
	Remotes.ThrowBall:FireServer(clampedTarget)
	cancelThrow()

	task.wait(0.5)
	if GameValues.BallHit.Value or (GameValues.CurrentBatter.Value ~= player and GameValues.CurrentPitcher.Value ~= player) then
		PlayerModuleEvents.DisableMovement:Fire(false)
	end
end

local function baseKeyHandler(actionName, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then return end
	local key = inputObject.KeyCode
	local basePart = baseKeybinds[key] or gamepadBaseKeybinds[key]
	if basePart and playerHasBall() then
		throwToTarget(basePart.Position + Vector3.new(0, 3, 0))
	end
end

--// NORMAL THROW HANDLER
function unifiedThrowHandler(actionName, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then return end
	if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then return end

	if lastStableTarget then
		throwToTarget(lastStableTarget)
	end
end

--// BASE BUTTONS
for baseName, basePart in pairs(baseButtons) do
	local button = basesFrame:FindFirstChild(baseName)
	if button then
		button.MouseButton1Click:Connect(function()
			if playerHasBall() then
				throwToTarget(basePart.Position + Vector3.new(0, 3, 0))
			end
		end)
	end
end

--// TOUCH TAP POSITION HANDLER
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if UserInputService.TouchEnabled and input.UserInputType == Enum.UserInputType.Touch then
		if gameProcessed then return end
		local screenPos = input.Position
		local camera = workspace.CurrentCamera
		local unitRay = camera:ScreenPointToRay(screenPos.X, screenPos.Y)
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {
			player.Character,
			workspace.LoadedBallpark.InvisibleWalls,
			workspace.LoadedBallpark.FoulWalls,
			workspace.FieldWalls
		}
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, rayParams)
		if result then
			lastMobileTapPosition = result.Position
		end
	end
end)

--// BALL GRAB EVENT
-- BALL GRAB EVENT
Remotes.GrabBall.OnClientEvent:Connect(function(ball)
	cancelThrow()
	throwEnabled = true
	baseball = ball
	applyConsoleKeybindIcons()

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		throwButton.Visible = true
	end

	basesFrame.Visible = true

	local glove = getEquippedGlove()
	if glove then
		if gloveConnection then
			gloveConnection:Disconnect()
		end
		gloveConnection = glove.ChildRemoved:Connect(function(child)
			if child.Name == "Baseball" then
				cancelThrow()
			end
		end)
	end

	local inputs = {
		Enum.UserInputType.MouseButton1,
		Enum.KeyCode.ButtonR2,
	}

	if not (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) then
		table.insert(inputs, Enum.UserInputType.Touch)
	end

	for keyCode, _ in pairs(baseKeybinds) do
		ContextActionService:BindAction("ThrowToBase_" .. tostring(keyCode), baseKeyHandler, false, keyCode)
	end

	for keyCode, _ in pairs(gamepadBaseKeybinds) do
		ContextActionService:BindAction("ThrowToBase_" .. tostring(keyCode), baseKeyHandler, false, keyCode)
	end

	ContextActionService:BindAction("ThrowBall", unifiedThrowHandler, false, unpack(inputs))
end)


-- TOUCH THROW BUTTON
throwButton.MouseButton1Click:Connect(function()
	if throwEnabled and not thrown then
		unifiedThrowHandler("ThrowBall", Enum.UserInputState.Begin, {UserInputType = Enum.UserInputType.Touch})
	end
end)

-- REMOVE GREEN CIRCLE
Remotes.RemoveGreenThrowCircle.OnClientEvent:Connect(function()
	if circle.Parent then circle.Parent = nil end
end)

-- UPDATE ARC EACH FRAME
RunService.RenderStepped:Connect(updateCirclePosition)
