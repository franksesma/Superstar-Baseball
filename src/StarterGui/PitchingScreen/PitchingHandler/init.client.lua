local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local Remotes = ReplicatedStorage.RemoteEvents
local camera = workspace.CurrentCamera
local CameraFolder = workspace.Cameras
local PitchingScreen = player.PlayerGui:WaitForChild("PitchingScreen")
local PitchBar = PitchingScreen.PitchForce.Bar
local SharedModules = ReplicatedStorage.SharedModules
local GameValues = ReplicatedStorage.GameValues
local ScoreboardValues = GameValues.ScoreboardValues
local SharedData = ReplicatedStorage.SharedData
local PlayerData = SharedData:WaitForChild(player.Name)
local PlayerScripts = player:WaitForChild("PlayerScripts")
local PlayerModuleEvents = PlayerScripts:WaitForChild("PlayerModuleEvents")
local Shared = ReplicatedStorage.Shared
local SharedServices = Shared.Services

local aimGrid = nil

local GuiAnimationModule = require(SharedModules.GuiAnimation)
local StylesModule = require(SharedModules.Styles)
local AnimationsModule = require(SharedModules.PitchingAnimations)
local ClientFunctions = require(SharedModules.ClientFunctions)
local PlayerUtilsClient = require(SharedServices.Utilities.PlayerUtilsClient)

local isCircleShrinking = false
local firstClick = true
local pitchPower = 0
local cursor = script.Parent.Cursor



--------------------------------------------------------------------------------
-- 1) REQUIRE YOUR PITCHING ANIMATIONS & GET PLAYER'S EQUIPPED STYLE:
--------------------------------------------------------------------------------
local Animator = nil
local PitchingStanceTrack, PitchThrowTrack = nil, nil
local chosenAnimations = nil

local function updatePitchButtons(pitchNames)
	local pitchFrames = {
		PitchingScreen.PitchTypes:FindFirstChild("Pitch1"),
		PitchingScreen.PitchTypes:FindFirstChild("Pitch2"),
		PitchingScreen.PitchTypes:FindFirstChild("Pitch3"),
		PitchingScreen.PitchTypes:FindFirstChild("Pitch4"),
	}

	local pitchSpeeds = AnimationsModule.PitchSpeeds 

	for i, frame in ipairs(pitchFrames) do
		if frame and pitchNames[i] then
			local nameLabel = frame:FindFirstChild("Name")
			local speedLabel = frame:FindFirstChild("Speed")

			if nameLabel then
				nameLabel.Text = pitchNames[i]
			end

			if speedLabel and pitchSpeeds[pitchNames[i]] then
				speedLabel.Text = pitchSpeeds[pitchNames[i]]
			end
		end
	end
end

local function loadPitchingAnimations(styleName)
	chosenAnimations = AnimationsModule[styleName] or AnimationsModule["Default"]

	Animator = player.Character:WaitForChild("Humanoid"):WaitForChild("Animator")

	if PitchingStanceTrack then PitchingStanceTrack:Stop() end
	if PitchThrowTrack then PitchThrowTrack:Stop() end

	local HoldingAnimation = Instance.new("Animation")
	HoldingAnimation.Name = "Style Holding Animation"
	HoldingAnimation.AnimationId = chosenAnimations.Idle
	PitchingStanceTrack = Animator:LoadAnimation(HoldingAnimation)

	local PitchingAnimation = Instance.new("Animation")
	PitchingAnimation.Name = "Style Pitch Animation"
	PitchingAnimation.AnimationId = chosenAnimations.Pitch
	PitchThrowTrack = Animator:LoadAnimation(PitchingAnimation)

	-- ?? Add this here
	if chosenAnimations.Pitches then
		updatePitchButtons(chosenAnimations.Pitches)
	end

	player.Character:PivotTo(workspace.Pitching.Mound.CFrame)

	if chosenAnimations.FaceBatter and player.Character:FindFirstChild("HumanoidRootPart") then
		player.Character.HumanoidRootPart.CFrame = CFrame.new(player.Character.HumanoidRootPart.Position, workspace.Plates["Home Base"].Position)
	end
end
--------------------------------------------------------------------------------

local function startPitchCircle()
	isCircleShrinking = true
	pitchPower = 0
	local shrinking = true

	spawn(function()
		while isCircleShrinking do
			if shrinking then
				pitchPower = pitchPower + 0.02
			else
				pitchPower = pitchPower - 0.02
			end

			local sizeScale = 0.4 + (1 - 0.4) * (1 - pitchPower)
			PitchBar.Size = UDim2.fromScale(sizeScale, sizeScale)

			PitchBar.BackgroundColor3 = Color3.fromRGB(255, 33, 33):Lerp(Color3.fromRGB(92, 255, 56), pitchPower)

			if pitchPower >= 1 then
				shrinking = false
			elseif pitchPower <= 0 then
				shrinking = true
			end

			wait()
		end
	end)
end

local function stopPitchBar()
	cursor.Visible = true
	PitchingScreen.PitchForce.Visible = false
	isCircleShrinking = false
	return 1.5 - pitchPower
end

local pitchType = nil
local currentButton = nil

local function handleButtonHover(frame, isHover)
	local strokeColor = isHover and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
	frame.Button.UIStroke.Color = strokeColor
end

local function handleButtonClick(frame)
	if PitchingScreen.PitchTypes.Visible == false then return end
	frame.Button.UIStroke.Color = Color3.fromRGB(255, 255, 255)
	PitchingScreen.PitchTypes.Visible = false

	if frame:FindFirstChild("UltimateName") then
		pitchType = "Ultimate"
	else
		local pitchNameLabel = frame:FindFirstChild("Name")
		if pitchNameLabel then
			pitchType = pitchNameLabel.Text
		end
	end
end

local function getInputType()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.GamepadEnabled then
		return "Mobile"
	elseif UserInputService.GamepadEnabled then
		return "Controller"
	else
		return "PC"
	end
end

local inputType = getInputType()

for i, frame in pairs(PitchingScreen.PitchTypes:GetChildren()) do
	if frame:IsA("Frame") and frame:FindFirstChild("Button") then
		frame.MouseEnter:Connect(function()
			handleButtonHover(frame, true)
		end)
		frame.MouseLeave:Connect(function()
			handleButtonHover(frame, false)
		end)

		GuiAnimationModule.SetupGrowButton(frame.Button)
		frame.Button.MouseButton1Click:Connect(function()
			GuiAnimationModule.ButtonPress(player, "PositiveClick")

			if frame.Name ~= "Ultimate" then
				handleButtonClick(frame)
			else
				local PlayerData = SharedData:WaitForChild(player.Name)
				if PlayerData.PitchingPower.Value >= 100 then
					if not GameValues.PowerUpsEnabled.Value then
						ClientFunctions.Notification(player, "Power Ups are currently disabled by the private server owner", "Alert")
						return
					end

					handleButtonClick(frame)
					-- Remotes.StarSwing:FireServer(player)
				end
			end
		end)
	end
end

local function updatePitchTypeUI()
	local inputType = getInputType()

	for i, frame in pairs(PitchingScreen.PitchTypes:GetChildren()) do
		if frame:IsA("Frame") and frame:FindFirstChild("Button") then
			local button = frame.Button
			local buttonFrame = button:FindFirstChild("Frame")

			if buttonFrame then
				local icon = buttonFrame:FindFirstChild("Icon")
				local buttonText = buttonFrame:FindFirstChild("Button")

				if icon then
					icon.Visible = (inputType == "Controller")
				end

				if buttonText then
					buttonText.Visible = (inputType == "PC" or inputType == "Mobile")
				end
			end
		end
	end

	if inputType == "Controller" then
		PitchingScreen.Keybinds.Visible = true
	else
		PitchingScreen.Keybinds.Visible = false
	end
end

updatePitchTypeUI()

UserInputService.LastInputTypeChanged:Connect(function()
	updatePitchTypeUI()
end)


local PlayerData = SharedData:WaitForChild(player.Name)
local StarPowerMax = 100
-- Example star bar usage commented out
-- PitchingScreen.PitchTypes.Star.Bar:TweenSize(
-- 	UDim2.new(PlayerData.StarPower.Value/StarPowerMax, 0, 1, 0),
-- 	Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.1, true
-- )

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.ButtonA then
		local pitch1Button = PitchingScreen.PitchTypes:FindFirstChild("Pitch1")
		if pitch1Button then
			handleButtonClick(pitch1Button)
		end
	elseif input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.ButtonX then
		local pitch2Button = PitchingScreen.PitchTypes:FindFirstChild("Pitch2")
		if pitch2Button then
			handleButtonClick(pitch2Button)
		end
	elseif input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.ButtonY then
		local pitch3Button = PitchingScreen.PitchTypes:FindFirstChild("Pitch3")
		if pitch3Button then
			handleButtonClick(pitch3Button)
		end
	elseif input.KeyCode == Enum.KeyCode.Four or input.KeyCode == Enum.KeyCode.ButtonB then
		local pitch4Button = PitchingScreen.PitchTypes:FindFirstChild("Pitch4")
		if pitch4Button then
			handleButtonClick(pitch4Button)
		end
	elseif input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonR1 then		
		local ultimateButton = PitchingScreen.PitchTypes:FindFirstChild("Ultimate")
		if ultimateButton then
			if PlayerData.PitchingPower.Value >= 100 then
				if not GameValues.PowerUpsEnabled.Value then
					ClientFunctions.Notification(player, "Power Ups are currently disabled by the private server owner", "Alert")
					return
				end

				handleButtonClick(ultimateButton)
			end
		end
	end
end)

local canPitch = true

--[[ Example cursor follow
mouse.Move:Connect(function()
	local MouseLocation = UserInputService:GetMouseLocation()
	cursor.Position = UDim2.fromOffset(
		MouseLocation.X - (cursor.AbsoluteSize.X / 2),
		MouseLocation.Y - (cursor.AbsoluteSize.Y / 2)
	)
end)
]]

local function alignPitchFrameToStrikeZone()
	local strikeZone = workspace:WaitForChild("Pitching"):WaitForChild("StrikeZone")
	local camera = workspace.CurrentCamera
	local pitchFrame = PitchingScreen.PitchFrame
	local viewportSize = camera.ViewportSize

	local cf = strikeZone.CFrame
	local size = strikeZone.Size
	local half = size / 2

	local corners = {
		cf * Vector3.new(-half.X,  half.Y, -half.Z),
		cf * Vector3.new( half.X,  half.Y, -half.Z),
		cf * Vector3.new(-half.X, -half.Y, -half.Z),
		cf * Vector3.new( half.X, -half.Y, -half.Z),
		cf * Vector3.new(-half.X,  half.Y,  half.Z),
		cf * Vector3.new( half.X,  half.Y,  half.Z),
		cf * Vector3.new(-half.X, -half.Y,  half.Z),
		cf * Vector3.new( half.X, -half.Y,  half.Z),
	}

	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge

	for _, worldPoint in ipairs(corners) do
		local screenPoint, onScreen = camera:WorldToViewportPoint(worldPoint)
		if onScreen then
			minX = math.min(minX, screenPoint.X)
			minY = math.min(minY, screenPoint.Y)
			maxX = math.max(maxX, screenPoint.X)
			maxY = math.max(maxY, screenPoint.Y)
		end
	end

	local frameX = minX / viewportSize.X
	local frameY = minY / viewportSize.Y
	local frameWidth = (maxX - minX) / viewportSize.X
	local frameHeight = (maxY - minY) / viewportSize.Y

	pitchFrame.Position = UDim2.new(frameX, 0, frameY, 0)
	pitchFrame.Size = UDim2.new(frameWidth, 0, frameHeight, 0)
	pitchFrame.AnchorPoint = Vector2.new(0, 0)
end


local catcherAnimations = {
	BottomRight = "rbxassetid://87950577592801",
	BottomLeft  = "rbxassetid://113045870528618",
	TopLeft     = "rbxassetid://105376900863478",
	Middle      = "rbxassetid://84950575685466",
	TopRight    = "rbxassetid://138567775434221"
}

local function getPitchLocation(target)
	local strikeZone = workspace.Pitching:WaitForChild("StrikeZone")
	local zoneSize = strikeZone.Size
	local zonePosition = strikeZone.Position

	local relativeX = (target.X - zonePosition.X) / zoneSize.X
	local relativeY = (target.Y - zonePosition.Y) / zoneSize.Y

	if relativeX > 0.8 then
		if relativeY > 0.4 then
			return "TopRight"
		elseif relativeY < -0.2 then
			return "BottomRight"
		else
			return "Middle"
		end
	elseif relativeX < 0.5 then
		if relativeY > 0.4 then
			return "TopLeft"
		elseif relativeY < -0.2 then
			return "BottomLeft"
		else
			return "Middle"
		end
	else
		return "Middle"
	end
end

local function playCatcherAnimation(location)
	local catcher = workspace.NPCs:FindFirstChild("Catcher")
	if not catcher then return end

	local humanoid = catcher:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local Animator = humanoid:WaitForChild("Animator")

	local animationId = catcherAnimations[location]
	if animationId then
		local animation = Instance.new("Animation")
		animation.AnimationId = animationId
		local animationTrack = Animator:LoadAnimation(animation)
		animationTrack:Play()

		spawn(function()
			task.wait(animationTrack.Length * 0.8)
			animationTrack:AdjustSpeed(0)
			wait(1)
			animationTrack:AdjustSpeed(1)
		end)
	end
end

--------------------------------------------------------------------------------
-- REMOVE the old default "Holding Stance" creation lines here. We already have
-- "PitchingStanceTrack" loaded from chosenAnimations above.
--------------------------------------------------------------------------------
-- local Animator = player.Character.Humanoid:WaitForChild("Animator")
-- local HoldingAnimation = Instance.new("Animation")
-- HoldingAnimation.Name = "Holding Stance"
-- HoldingAnimation.AnimationId = "rbxassetid://18512502047"
-- local PitchingStanceTrack = Animator:LoadAnimation(HoldingAnimation)
--------------------------------------------------------------------------------

local Target = nil
local firstClick = true

local Target = nil
local inStrikeZone = false

local clickCount = 0

local function onPitch(actionName, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then return end
	if not pitchType then
		print("[onPitch] ? No pitchType selected")
		return
	end
	if not canPitch then
		print("[onPitch] ? Can�t pitch right now")
		return
	end
	if not ScoreboardValues.PitchClockEnabled.Value then
		print("[onPitch] ? Pitch clock not enabled")
		return
	end

	clickCount += 1
	print("[onPitch] CLICKED", clickCount, " | firstClick =", firstClick, "| canPitch =", canPitch)

	if aimGrid == nil then
		return
	end

	local partsToIgnore = {
		workspace:WaitForChild("Pitching"):WaitForChild("StrikeZone"),
		workspace:WaitForChild("PitcherWalls"),
		workspace:WaitForChild("Batting"):WaitForChild("StrikeZone"),
		--workspace:WaitForChild("Field"):WaitForChild("Dirt")
	}

	local cursorPos = cursor.Position
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = partsToIgnore
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist

	if inputType == "Mobile" then
		if firstClick then
			Target, inStrikeZone = aimGrid:GetTarget()

			print("[onPitch] ?? Mobile First Click | Target =", Target, "| InStrikeZone =", inStrikeZone)

			if not Target then
				warn("[onPitch] ? No target from aimGrid (uv is nil)")
				return
			end

			cursor.Visible = false
			PitchingScreen.PitchForce.Visible = true
			PitchingScreen.PitchForce.Position = UDim2.fromOffset(cursorPos.X.Offset + 20, cursorPos.Y.Offset + 20)

			-- Fire PitchStarted to update the visual circle position with the correct calculated target
			--Remotes.PitchStarted:FireServer(Target, pitchType, inStrikeZone)

			aimGrid:Freeze()
			startPitchCircle()
			firstClick = false

		else
			local finalPower = stopPitchBar()
			canPitch = false

			print("[onPitch] ?? Mobile Second Click | FinalPower =", finalPower)

			aimGrid:Reset()
			if aimGrid.gui then aimGrid.gui.Enabled = false end

			Remotes.StopPitchClock:FireServer()
			Remotes.AlertPitch:FireServer()

			if pitchType ~= "Ultimate" then
				print("[onPitch] ?? Playing PitchThrowTrack")
				PitchThrowTrack:Play()
				wait(chosenAnimations.ReleaseTime)
			end

			local pitchLocation = getPitchLocation(Target)
			playCatcherAnimation(pitchLocation)
			CAS:UnbindAction("Pitch")

			Remotes.PitchBall:FireServer(Target, finalPower, pitchType, inStrikeZone)

			firstClick = true
			canPitch = true
			pitchType = nil
		end

	else
		if firstClick then
			local unitRay = camera:ViewportPointToRay(cursorPos.X.Offset + 20, cursorPos.Y.Offset + 20)
			local rayResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, rayParams)

			if rayResult and rayResult.Instance and rayResult.Instance.Name == "ThrowSpot" then
				Target = rayResult.Position
				print("[onPitch] ??? PC First Click | Target =", Target)

				local strikeZone = workspace:WaitForChild("Pitching"):WaitForChild("StrikeZone")
				local zoneCFrame = strikeZone.CFrame
				local zoneSize = strikeZone.Size
				local tolerance = 0.01
				local ballRadius = 0.35

				local planeZ = strikeZone.Position.Z
				local t = (planeZ - unitRay.Origin.Z) / unitRay.Direction.Z
				local intersection = unitRay.Origin + unitRay.Direction * t
				local relative = zoneCFrame:PointToObjectSpace(intersection)

				inStrikeZone =
					math.abs(relative.X) <= (zoneSize.X / 2 + ballRadius + tolerance) and
					math.abs(relative.Y) <= (zoneSize.Y / 2 + ballRadius + tolerance)

				print("[onPitch] ??? InStrikeZone =", inStrikeZone)

				cursor.Visible = false
				PitchingScreen.PitchForce.Visible = true
				PitchingScreen.PitchForce.Position = UDim2.fromOffset(cursorPos.X.Offset + 20, cursorPos.Y.Offset + 20)
				--Remotes.PitchStarted:FireServer(Target, pitchType, inStrikeZone)
				startPitchCircle()
				firstClick = false
			else
				warn("[onPitch] ? Raycast didn�t hit ThrowSpot")
			end

		else
			local finalPower = stopPitchBar()
			canPitch = false

			print("[onPitch] ??? PC Second Click | FinalPower =", finalPower)

			Remotes.StopPitchClock:FireServer()
			Remotes.AlertPitch:FireServer()

			if pitchType ~= "Ultimate" then
				print("[onPitch] ??? Playing PitchThrowTrack")
				PitchThrowTrack:Play()
				wait(chosenAnimations.ReleaseTime)
			end

			if aimGrid and aimGrid.gui then
				aimGrid.gui.Enabled = false
			end

			local pitchLocation = getPitchLocation(Target)
			playCatcherAnimation(pitchLocation)
			CAS:UnbindAction("Pitch")

			Remotes.PitchBall:FireServer(Target, finalPower, pitchType, inStrikeZone)

			firstClick = true
			canPitch = true
			pitchType = nil
		end
	end
end





Remotes.BatResults.OnClientEvent:Connect(function(message)
	if message == "Ball" or message == "Strike" or message == "Pitch Clock Violation" then
		local currentPitcher = GameValues:FindFirstChild("CurrentPitcher")
		if currentPitcher and currentPitcher.Value == player then
			if inputType == "Mobile" and aimGrid and aimGrid.gui then				
				aimGrid.gui.Enabled = true
			end
			PitchingScreen.PitchTypes.Visible = true
			CAS:BindAction("Pitch", onPitch, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.KeyCode.ButtonR2)
		end
	end
end)

Remotes.AutoPitchPlayer.OnClientEvent:Connect(function()
	if not canPitch then return end
	canPitch = false

	isCircleShrinking = false
	firstClick = true
	pitchPower = 0
	cursor.Visible = true
	PitchingScreen.PitchForce.Visible = false
	PitchBar.Size = UDim2.fromScale(1, 1)
	PitchBar.BackgroundColor3 = Color3.fromRGB(255, 33, 33)
	if aimGrid then
		aimGrid:Reset()
		if aimGrid.gui then
			aimGrid.gui.Enabled = false
		end
	end
	CAS:UnbindAction("Pitch")


	-- Choose a random pitch (excluding Ultimate)
	local pitchFrames = {}
	for _, frame in pairs(PitchingScreen.PitchTypes:GetChildren()) do
		if frame:IsA("Frame") and frame.Name ~= "Ultimate" and frame:FindFirstChild("Name") then
			table.insert(pitchFrames, frame)
		end
	end

	if #pitchFrames == 0 then
		warn("[AutoPitch] ? No valid pitches found.")
		canPitch = true
		return
	end

	local randomFrame = pitchFrames[math.random(1, #pitchFrames)]
	local pitchNameLabel = randomFrame:FindFirstChild("Name")
	if not pitchNameLabel then
		warn("[AutoPitch] ? Selected pitch has no label.")
		canPitch = true
		return
	end

	pitchType = pitchNameLabel.Text

	-- Generate random target inside strike zone
	local strikeZone = workspace:WaitForChild("Pitching"):WaitForChild("StrikeZone")
	local center = strikeZone.Position
	local size = strikeZone.Size

	local offset = Vector3.new(
		math.random(-size.X * 50, size.X * 50) / 100,
		math.random(-size.Y * 50, size.Y * 50) / 100,
		math.random(-size.Z * 50, size.Z * 50) / 100
	)

	Target = center + offset
	inStrikeZone = true

	-- Play animation
	if PitchThrowTrack then
		PitchThrowTrack:Play()
	else
		warn("[PitchingHandler] ? PitchThrowTrack is nil")
	end

	wait(chosenAnimations.ReleaseTime)

	local pitchLocation = getPitchLocation(Target)
	playCatcherAnimation(pitchLocation)

	-- Send to server
	Remotes.StopPitchClock:FireServer()
	Remotes.AlertPitch:FireServer()
	Remotes.PitchBall:FireServer(Target, 1, pitchType, inStrikeZone)

	firstClick = true
	canPitch = true
	pitchType = nil
end)


Remotes.AutoPitchAI.OnClientEvent:Connect(function(styleName)
	local styleData = AnimationsModule[styleName] or AnimationsModule["Default"]
	local possiblePitches = styleData.Pitches or {"Fastball"}

	local chosenPitch = possiblePitches[math.random(1, #possiblePitches)]

	-- Pick random target
	local strikeZone = workspace:WaitForChild("Pitching"):WaitForChild("StrikeZone")
	local center = strikeZone.Position
	local size = strikeZone.Size

	local offset = Vector3.new(
		math.random(-size.X * 50, size.X * 50) / 100,
		math.random(-size.Y * 50, size.Y * 50) / 100,
		math.random(-size.Z * 50, size.Z * 50) / 100
	)

	local target = center + offset

	local aiPitcher = workspace:FindFirstChild("AIPitcher")
	if not aiPitcher then warn("[AutoPitchAI] No AI pitcher found.") return end

	local humanoid = aiPitcher:FindFirstChildOfClass("Humanoid")
	if not humanoid then warn("[AutoPitchAI] No Humanoid in AI pitcher.") return end

	local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator")

	local pitchAnim = Instance.new("Animation")
	pitchAnim.AnimationId = styleData.Pitch
	local pitchTrack = animator:LoadAnimation(pitchAnim)
	pitchTrack:Play()

	task.wait(styleData.ReleaseTime)

	Remotes.PitchBall:FireServer(target, 1, chosenPitch, true)

	--print("? AutoPitchAI thrown:", chosenPitch, "Target:", target)
end)

local RunService = game:GetService("RunService")

Remotes.SetupPitcher.OnClientEvent:Connect(function(equippedDefensiveStyle)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
	local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator")

	CAS:UnbindAction("Pitch")
	CAS:BindAction("Pitch", onPitch, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.KeyCode.ButtonR2)

	PlayerUtilsClient.enableMouselock(false)

	if player.PlayerGui:FindFirstChild("MobileShiftlock") and player.PlayerGui.MobileShiftlock:FindFirstChild("DisableShiftLock") then
		player.PlayerGui.MobileShiftlock.DisableShiftLock:Fire()
	end

	RunService.RenderStepped:Wait()

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(CameraFolder.PitchingCam.Position, CameraFolder.PitchingCamFocal.Position)
	camera.FieldOfView = 10

	isCircleShrinking = false
	pitchPower = 0
	PitchingScreen.PitchForce.Visible = false
	PitchBar.Size = UDim2.fromScale(1, 1)
	PitchBar.BackgroundColor3 = Color3.fromRGB(255, 33, 33)

	if aimGrid then
		aimGrid:Destroy()
		aimGrid = nil
	end

	UserInputService.MouseIconEnabled = false
	PitchingScreen.PitchTypes.Visible = true
	PitchingScreen.PitchFrame.Visible = true

	local equippedStyle, styleInventory = Remotes.GetStyleData:InvokeServer("Defensive")
	local styleName = equippedStyle or "Default"
	loadPitchingAnimations(styleName)

	if PitchingStanceTrack then
		PitchingStanceTrack:Play()
	else
		warn("[SetupPitcher] PitchingStanceTrack is nil!")
	end

	alignPitchFrameToStrikeZone()

	local strikeZone = workspace:WaitForChild("Pitching"):WaitForChild("StrikeZone")
	local throwSpot = workspace:WaitForChild("Pitching"):WaitForChild("ThrowSpot")

	-- Use normal ThrowSpot instead of MobileThrowSpot so mobile matches PC
	aimGrid = require(script:WaitForChild("AimGrid")).New(strikeZone, throwSpot, Vector2.new(-1, -1))

	if UserInputService.TouchEnabled and aimGrid and aimGrid.gui then
		aimGrid.gui.Enabled = true
	else
		warn("[SetupPitcher] AimGrid GUI not ready")
	end

	-- Star Power
	if equippedDefensiveStyle and StylesModule.DefensiveStyles[equippedDefensiveStyle] and StylesModule.DefensiveStyles[equippedDefensiveStyle].SubType == "Pitching" then
		PitchingScreen.PitchTypes.StarPower.Visible = true
		PitchingScreen.PitchTypes.Ultimate.UltimateName.Text = StylesModule.DefensiveStyles[equippedDefensiveStyle].Ultimate
		PitchingScreen.PitchTypes.StarPower.PercentLabel.Text = tostring(PlayerData.PitchingPower.Value) .. "%"

		if PlayerData.PitchingPower.Value == 100 then
			PitchingScreen.PitchTypes.StarPower.Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
			PitchingScreen.PitchTypes.Ultimate.Visible = true
		else
			PitchingScreen.PitchTypes.StarPower.Icon.ImageColor3 = Color3.fromRGB(99, 99, 99)
			PitchingScreen.PitchTypes.Ultimate.Visible = false
		end
	else
		PitchingScreen.PitchTypes.StarPower.Visible = false
		PitchingScreen.PitchTypes.Ultimate.Visible = false
	end
end)

Remotes.StopPitching.OnClientEvent:Connect(function()
	canPitch = false	
end)

Remotes.CancelClientPitching.OnClientEvent:Connect(function()
	-- Reset all pitching state
	firstClick = true
	canPitch = true
	pitchType = nil
	isCircleShrinking = false
	print (canPitch, "HERE")
	if aimGrid then
		aimGrid:Reset()
		if aimGrid.gui then
			aimGrid.gui.Enabled = false
		end
	end

	cursor.Visible = true
	PitchingScreen.PitchForce.Visible = false
	PitchingScreen.PitchTypes.Visible = true
	PitchBar.Size = UDim2.fromScale(1, 1)
	PitchBar.BackgroundColor3 = Color3.fromRGB(255, 33, 33)

	CAS:UnbindAction("Pitch")
end)


if UserInputService.GamepadEnabled then
	PitchingScreen.Keybinds.Visible = true
else
	PitchingScreen.Keybinds.Visible = false
end

if UserInputService.TouchEnabled then
	PitchingScreen.MobileKeybinds.Visible = true
else
	PitchingScreen.MobileKeybinds.Visible = false
end


local FakeBaseball = ReplicatedStorage:WaitForChild("SharedObjects"):WaitForChild("Baseball")

Remotes.BallLanded.OnClientEvent:Connect(function(position: Vector3, wasHit)
	local currentPitcher = GameValues.CurrentPitcher.Value
	if currentPitcher ~= player then return end

	-- Spawn a temporary FakeBaseball at the landing position
	if not wasHit then
		task.spawn(function()
			local marker = FakeBaseball:Clone()
			marker.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(90), 0, 0)
			marker.Parent = workspace

			task.wait(0.5)

			local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local goal = {Size = Vector3.new(0, 0.1, 0), Transparency = 1}
			local tween = TweenService:Create(marker, tweenInfo, goal)
			tween:Play()

			game:GetService("Debris"):AddItem(marker, 2)
		end)
	end
end)