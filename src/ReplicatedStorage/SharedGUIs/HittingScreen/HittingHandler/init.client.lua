-- HittingClient.lua  (NO Batting Practice section)
-- Mobile Hitting:
--   LegacyHitting = true  -> tap-to-swing (uses LastTapPosition)
--   LegacyHitting = false -> AimGrid aiming + Roblox CAS touch button to swing
--
-- NOTE:
-- - This script assumes you have a ModuleScript child named "AimGrid"
--   and that AimGrid clones a ScreenGui named "MobileScreen" internally.
-- - This script prevents spawning multiple AimGrids by guarding setAimGridEnabled().
-- - Swing button: custom GUI button at jump position; default jump hidden while hitting.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Debris = game:GetService("Debris")

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local Remotes = ReplicatedStorage.RemoteEvents
local camera = workspace.CurrentCamera
local CameraFolder = workspace.Cameras
local HittingScreen = player.PlayerGui:WaitForChild("HittingScreen")

local SharedModules = ReplicatedStorage.SharedModules
local SharedData = ReplicatedStorage.SharedData
local PlayerData = SharedData:WaitForChild(player.Name)
local PlayerScripts = player:WaitForChild("PlayerScripts")
local PlayerModuleEvents = PlayerScripts:WaitForChild("PlayerModuleEvents")
local GameValues = ReplicatedStorage.GameValues

local Shared = ReplicatedStorage.Shared
local SharedServices = Shared.Services
local SharedObjects = ReplicatedStorage:WaitForChild("SharedObjects")

local PlateDistance = require(SharedModules.PlateDistance)
local GuiAnimationModule = require(SharedModules.GuiAnimation)
local StylesModule = require(SharedModules.Styles)
local ClientFunctions = require(SharedModules.ClientFunctions)
local PlayerUtilsClient = require(SharedServices.Utilities.PlayerUtilsClient)

-- AimGrid module (ModuleScript child of this LocalScript)
local AimGridModule = require(script:WaitForChild("AimGrid"))

local LastTapPosition: Vector2? = nil
local BALL_RADIUS = 0.35

local SwingDataGUI = player.PlayerGui:WaitForChild("SwingData")
local SwingData = SwingDataGUI.SwingData

local missParams = RaycastParams.new()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- SETTINGS: LegacyHitting toggle (tap vs aimgrid)
--------------------------------------------------------------------------------
local function getLegacyHitting()
	local settings = PlayerData:FindFirstChild("Settings")
	if settings then
		local v = settings:FindFirstChild("LegacyHitting")
		if v and v:IsA("BoolValue") then
			return v.Value
		end
	end
	-- default = AimGrid ON
	return false
end

local LegacyHitting = getLegacyHitting()

--------------------------------------------------------------------------------
-- 1) HITTING ANIMATIONS
--------------------------------------------------------------------------------
local Animator: Animator? = nil
local BattingStanceTrack: AnimationTrack? = nil
local LiftLegTrack: AnimationTrack? = nil
local SwingTrack: AnimationTrack? = nil

local function loadAnimationsForStyle(styleName: string, character: Model)
	local AnimationsModule = require(ReplicatedStorage.SharedModules.HittingAnimations)
	local chosenAnimations = AnimationsModule[styleName] or AnimationsModule["Combustion"]

	Animator = character:WaitForChild("Humanoid"):WaitForChild("Animator")

	if BattingStanceTrack then BattingStanceTrack:Stop() end
	if LiftLegTrack then LiftLegTrack:Stop() end
	if SwingTrack then SwingTrack:Stop() end

	local BattingStanceAnim = Instance.new("Animation")
	BattingStanceAnim.Name = "Batting Stance"
	BattingStanceAnim.AnimationId = chosenAnimations.Idle
	BattingStanceTrack = Animator:LoadAnimation(BattingStanceAnim)

	local LiftLegAnim = Instance.new("Animation")
	LiftLegAnim.Name = "Leg Lift"
	LiftLegAnim.AnimationId = chosenAnimations.LegLift
	LiftLegTrack = Animator:LoadAnimation(LiftLegAnim)

	local SwingAnim = Instance.new("Animation")
	SwingAnim.Name = "Swing"
	SwingAnim.AnimationId = chosenAnimations.Swing
	SwingTrack = Animator:LoadAnimation(SwingAnim)
end

--------------------------------------------------------------------------------
-- HIT TYPE UI (HitTypes on PC; MobileHitTypes on mobile ? same structure)
--------------------------------------------------------------------------------
local hitType: string? = nil
local currentHitButton: Instance? = nil
local activeHitTypesFrame: GuiObject? = nil  -- HitTypes or MobileHitTypes, set when entering batter

local function handleHitButtonClick(button: ImageButton)
	button.UIStroke.Color = Color3.fromRGB(255, 255, 0)
	if currentHitButton and currentHitButton ~= button then
		currentHitButton.UIStroke.Color = Color3.fromRGB(0, 0, 0)
	end
	currentHitButton = button
	hitType = button.Name
end

local function setupHitTypeButtons(container: GuiObject)
	for _, button in container:GetChildren() do
		if button:IsA("ImageButton") then
			if button.Name == "Contact" then
				if currentHitButton == nil then
					handleHitButtonClick(button)
				end
			end

			GuiAnimationModule.SetupGrowButton(button)
			button.MouseButton1Click:Connect(function()
				GuiAnimationModule.ButtonPress(player, "PositiveClick")

				if button.Name == "Star Swing" then
					if PlayerData.HittingPower.Value >= 100 then
						if not GameValues.PowerUpsEnabled.Value then
							ClientFunctions.Notification(player, "Power Ups are currently disabled by the private server owner", "Alert")
							return
						end

						if activeHitTypesFrame then
							activeHitTypesFrame.Visible = false
						end
						handleHitButtonClick(button)
					end
				else
					handleHitButtonClick(button)
				end
			end)
		end
	end
end

setupHitTypeButtons(HittingScreen.HitTypes)
local mobileHitTypes = HittingScreen:FindFirstChild("MobileHitTypes")
if mobileHitTypes and mobileHitTypes:IsA("Frame") then
	setupHitTypeButtons(mobileHitTypes)
end

local StarPowerMax = 100
for _, container in ipairs({ HittingScreen.HitTypes, mobileHitTypes }) do
	if container and container:FindFirstChild("Star Swing") and container["Star Swing"]:FindFirstChild("Meter") then
		container["Star Swing"].Meter:TweenSizeAndPosition(
			UDim2.new(1, 0, PlayerData:WaitForChild("HittingPower").Value / StarPowerMax, 0),
			UDim2.new(0, 0, 1 - (PlayerData:WaitForChild("HittingPower").Value / StarPowerMax), 0),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Linear,
			0.1,
			true
		)
	end
end

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------
local State = "idle"
local swingTimeout: thread? = nil
local canSwing = true

local function resetLegLift()
	if not Animator then return end
	for _, track in pairs(Animator:GetPlayingAnimationTracks()) do
		if track.Name == "Leg Lift" then
			track:AdjustSpeed(-1)
			task.wait(0.35)
			track:Stop()
			break
		end
	end
	State = "idle"
end

--------------------------------------------------------------------------------
-- CURSOR HELPERS (AimGrid drives Cursor)
--------------------------------------------------------------------------------
local function setCursorToViewportPoint(px: number, py: number)
	local cursor = script.Parent:FindFirstChild("Cursor")
	if not cursor then return end
	cursor.Position = UDim2.new(0, px, 0, py)
end

local function setCursorFromAimGridUV(uv: Vector2)
	-- Map UV (0..1) to cursor inside MouseFrame (includes balls/strikes)
	local mouseFrame = HittingScreen:FindFirstChild("MouseFrame")
	if not mouseFrame then return end

	local absPos = mouseFrame.AbsolutePosition
	local absSize = mouseFrame.AbsoluteSize

	local px = absPos.X + (uv.X * absSize.X)
	local py = absPos.Y + (uv.Y * absSize.Y)

	setCursorToViewportPoint(px, py)
end

--------------------------------------------------------------------------------
-- AIMGRID MODE + ROBLOX TOUCH SWING BUTTON (CAS)
--------------------------------------------------------------------------------
local aimGrid = nil
local aimGridConn: RBXScriptConnection? = nil

-- Mobile swing button lives in HittingScreen.SwingButton; hide default jump while hitting
local swingButtonConn: RBXScriptConnection? = nil
local hiddenJumpButtons: { GuiObject } = {}

local function findDefaultJumpButtons(): { GuiObject }
	local out = {}
	for _, gui in ipairs(player.PlayerGui:GetDescendants()) do
		if gui:IsA("GuiObject") and (gui.Name == "Jump" or gui.Name == "JumpButton") then
			table.insert(out, gui)
		end
	end
	return out
end

local function hideJumpButton()
	hiddenJumpButtons = findDefaultJumpButtons()
	for _, btn in ipairs(hiddenJumpButtons) do
		btn.Visible = false
	end
end

local function showJumpButton()
	for _, btn in ipairs(hiddenJumpButtons) do
		btn.Visible = true
	end
	hiddenJumpButtons = {}
end

local function unbindTouchSwingButton()
	if swingButtonConn then
		swingButtonConn:Disconnect()
		swingButtonConn = nil
	end
	local swingBtn = HittingScreen:FindFirstChild("SwingButton")
	if swingBtn and swingBtn:IsA("GuiObject") then
		swingBtn.Visible = false
	end
	showJumpButton()
end

local function bindTouchSwingButton()
	if not UserInputService.TouchEnabled then return end
	local swingBtn = HittingScreen:FindFirstChild("SwingButton")
	if not swingBtn or not (swingBtn:IsA("ImageButton") or swingBtn:IsA("TextButton")) then return end

	unbindTouchSwingButton()

	swingButtonConn = swingBtn.MouseButton1Click:Connect(function()
		if _G.__HITTING_EXEC_SWING then
			_G.__HITTING_EXEC_SWING()
		end
	end)
	swingBtn.Visible = true
	hideJumpButton()
end
local function destroyAimGrid()
	if aimGridConn then
		aimGridConn:Disconnect()
		aimGridConn = nil
	end
	if aimGrid then
		aimGrid:Destroy()
		aimGrid = nil
	end
end

local function setAimGridEnabled(enabled: boolean)
	-- GUARD: prevents spawning a bunch of MobileScreens
	if enabled and aimGrid then
		return
	end
	if (not enabled) and (not aimGrid) then
		unbindTouchSwingButton()
		return
	end

	unbindTouchSwingButton()

	if enabled then
		local mouseFrame = HittingScreen:WaitForChild("MouseFrame")

		aimGrid = AimGridModule.New(mouseFrame, {
			DisplayOrder = 9999,
		})

		aimGridConn = aimGrid.Changed.Event:Connect(function(uv)
			if typeof(uv) == "Vector2" then
				setCursorFromAimGridUV(uv)
			end
		end)

		-- Swing button (HittingScreen.SwingButton) only in AimGrid mode on touch
		if UserInputService.TouchEnabled then
			bindTouchSwingButton()
		end
	else
		destroyAimGrid()
	end
end

--------------------------------------------------------------------------------
-- SWING LOGIC (supports legacy tap OR aimgrid cursor)
--------------------------------------------------------------------------------
local function executeSwing()
	if not canSwing then return end
	canSwing = false

	local ball = workspace.BallHolder:FindFirstChild("Baseball")
	if not ball or GameValues.BallHit.Value then
		canSwing = true
		return
	end

	if swingTimeout then
		task.cancel(swingTimeout)
		swingTimeout = nil
	end

	if Animator then
		for _, track in pairs(Animator:GetPlayingAnimationTracks()) do
			if track.Name == "Leg Lift" then
				track:Stop()
			end
		end
	end

	if hitType ~= "Star Swing" then
		if SwingTrack then
			SwingTrack:AdjustSpeed(1)
			SwingTrack:Play()
		end

		local swingSound = Instance.new("Sound")
		swingSound.SoundId = "rbxassetid://9113305619"
		swingSound.Volume = 1
		swingSound.Parent = player.Character and (player.Character:FindFirstChild("HumanoidRootPart") or workspace) or workspace
		swingSound:Play()
		Debris:AddItem(swingSound, 2)
	end

	State = "idle"

	local ray
	if UserInputService.TouchEnabled and LegacyHitting and LastTapPosition then
		-- Legacy tap: swing from tap position (cursor was already moved there)
		ray = camera:ViewportPointToRay(LastTapPosition.X, LastTapPosition.Y)
	else
		local cursor = script.Parent:FindFirstChild("Cursor")
		local cursorPosition = cursor and cursor.Position or UDim2.new(0.5, 0, 0.5, 0)
		ray = camera:ViewportPointToRay(cursorPosition.X.Offset, cursorPosition.Y.Offset, 1)
	end

	local rayResult = workspace:Raycast(ray.Origin, ray.Direction * 500, missParams)
	LastTapPosition = nil

	local ballPosition = ball.Position
	local hitPos = rayResult and rayResult.Position or (ray.Origin + ray.Direction * 50)

	Remotes.SwingBat:FireServer(hitPos, ballPosition, ball:GetAttribute("Direction"), hitType)

	-- Timing UI
	local TimingLabel = SwingDataGUI.TimingLabel
	TimingLabel.Visible = true

	local earlyCushion = 2
	local lateCushion = 0.5

	local dist, margin = PlateDistance:getRelativeDistToPlate(ball.Position)

	if dist >= -margin - earlyCushion and dist <= margin + lateCushion then
		TimingLabel.Text = "ON TIME"
	elseif dist < -margin - earlyCushion then
		TimingLabel.Text = "EARLY"
	else
		TimingLabel.Text = "LATE"
	end

	LastTapPosition = nil
end

-- allow AimGrid touch button closure to call this without ordering problems
_G.__HITTING_EXEC_SWING = executeSwing

--------------------------------------------------------------------------------
-- INPUT BINDING (mouse / gamepad + legacy touch tap)
--------------------------------------------------------------------------------
local function isPositionInMouseFrame(viewportPos: Vector2): boolean
	local mouseFrame = HittingScreen:FindFirstChild("MouseFrame")
	if not mouseFrame then return false end
	local ap = mouseFrame.AbsolutePosition
	local as_ = mouseFrame.AbsoluteSize
	return viewportPos.X >= ap.X and viewportPos.X <= ap.X + as_.X
		and viewportPos.Y >= ap.Y and viewportPos.Y <= ap.Y + as_.Y
end

local function onSwing(actionName, inputState, inputObject)
	if GameValues.CurrentBatter.Value ~= player then return end
	if inputState ~= Enum.UserInputState.Begin then return end

	local PitchWindup = GameValues:WaitForChild("PitchWindup")
	local BallPitched = GameValues:WaitForChild("BallPitched")
	if not canSwing or (not PitchWindup.Value and not BallPitched.Value) then
		return
	end

	-- Legacy: tap-to-swing; move hitting cursor to tap position so swing uses that aim
	if UserInputService.TouchEnabled and LegacyHitting and inputObject.UserInputType == Enum.UserInputType.Touch then
		setCursorToViewportPoint(inputObject.Position.X, inputObject.Position.Y)
		LastTapPosition = inputObject.Position
	end

	-- Non-legacy mobile touch: touch is for aiming only; swing uses CAS button.
	if inputObject.UserInputType == Enum.UserInputType.Touch then
		if not LegacyHitting then
			return
		end
	end

	-- AimGrid mode on mobile only: don't swing on tap in hitting zone (use swing button). PC mouse click still swings.
	if not LegacyHitting and UserInputService.TouchEnabled and isPositionInMouseFrame(inputObject.Position) then
		return
	end

	if hitType == "Contact" or hitType == "Power" then
		executeSwing()
	elseif hitType == "Star Swing" then
		if PlayerData.HittingPower.Value >= 100 then
			executeSwing()
		end
	end
end

--------------------------------------------------------------------------------
-- STRIKEZONE ALIGN
--------------------------------------------------------------------------------
local function alignSwingFrameToStrikeZone(strikeZonePart: BasePart)
	local strikeZone = strikeZonePart
	local swingFrame = HittingScreen.HitFrame
	local viewportSize = camera.ViewportSize

	local topLeftInset = Vector2.zero
	local safeWidth = viewportSize.X
	local safeHeight = viewportSize.Y

	if not HittingScreen.IgnoreGuiInset then
		local tl, br = GuiService:GetGuiInset()
		topLeftInset = tl
		safeWidth = viewportSize.X - tl.X - br.X
		safeHeight = viewportSize.Y - tl.Y - br.Y
	end
	if safeWidth <= 0 or safeHeight <= 0 then return end

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
	local any = false

	for _, worldPoint in ipairs(corners) do
		local sp, onScreen = camera:WorldToViewportPoint(worldPoint)
		if onScreen then
			local gx = sp.X - topLeftInset.X
			local gy = sp.Y - topLeftInset.Y
			minX = math.min(minX, gx)
			minY = math.min(minY, gy)
			maxX = math.max(maxX, gx)
			maxY = math.max(maxY, gy)
			any = true
		end
	end
	if not any then return end

	local frameX = minX / safeWidth
	local frameY = minY / safeHeight
	local frameW = (maxX - minX) / safeWidth
	local frameH = (maxY - minY) / safeHeight

	swingFrame.AnchorPoint = Vector2.new(0, 0)
	swingFrame.Position = UDim2.new(frameX, 0, frameY, 0)
	swingFrame.Size = UDim2.new(frameW, 0, frameH, 0)
end

--------------------------------------------------------------------------------
-- SETUP BATTER EVENT
--------------------------------------------------------------------------------
Remotes.SetupBatter.OnClientEvent:Connect(function(equippedOffensiveStyle)
	inBattingCage = false
	CAS:UnbindAction("PracticeSwing")
	CAS:UnbindAction("PracticeThrowPitch")

	-- Bind Swing: legacy touch handled by InputBegan (GUI blocks CAS touch); mouse + gamepad always via CAS
	CAS:UnbindAction("Swing")
	LegacyHitting = getLegacyHitting()
	if LegacyHitting then
		CAS:BindAction("Swing", onSwing, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonA)
	else
		CAS:BindAction("Swing", onSwing, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.KeyCode.ButtonA)
	end

	local NPCs = workspace:FindFirstChild("NPCs")
	if NPCs then
		NPCs.Parent = ReplicatedStorage
	end

	PlayerUtilsClient.enableMouselock(false)
	if player.PlayerGui:FindFirstChild("MobileShiftlock") and player.PlayerGui.MobileShiftlock:FindFirstChild("DisableShiftLock") then
		player.PlayerGui.MobileShiftlock.DisableShiftLock:Fire()
	end

	RunService.RenderStepped:Wait()

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(CameraFolder.HittingCam.Position, CameraFolder.HittingCamFocal.Position)

	SwingData.Visible = false
	SwingData.StrikeZone.Hit.Visible = false
	SwingData.StrikeZone.Ball.Visible = false
	SwingData.BallZone.Hit.Visible = false
	SwingData.BallZone.Ball.Visible = false

	-- LegacyHitting true: always HitTypes visible, MobileHitTypes hidden. Else: mobile uses MobileHitTypes, PC uses HitTypes.
	local mobileHitTypesFrame = HittingScreen:FindFirstChild("MobileHitTypes")
	if getLegacyHitting() then
		activeHitTypesFrame = HittingScreen.HitTypes
		HittingScreen.HitTypes.Visible = true
		if mobileHitTypesFrame and mobileHitTypesFrame:IsA("GuiObject") then
			mobileHitTypesFrame.Visible = false
		end
	elseif UserInputService.TouchEnabled and mobileHitTypesFrame and mobileHitTypesFrame:IsA("GuiObject") then
		activeHitTypesFrame = mobileHitTypesFrame
		HittingScreen.HitTypes.Visible = false
		mobileHitTypesFrame.Visible = true
	else
		activeHitTypesFrame = HittingScreen.HitTypes
		HittingScreen.HitTypes.Visible = true
		if mobileHitTypesFrame and mobileHitTypesFrame:IsA("GuiObject") then
			mobileHitTypesFrame.Visible = false
		end
	end

	handleHitButtonClick(activeHitTypesFrame.Contact)

	local equippedStyle = Remotes.GetStyleData:InvokeServer("Offensive")
	local styleName = equippedStyle or "Heat"
	loadAnimationsForStyle(styleName, player.Character)

	if equippedOffensiveStyle ~= nil
		and StylesModule.OffensiveStyles[equippedOffensiveStyle]
		and StylesModule.OffensiveStyles[equippedOffensiveStyle].SubType == "Hitting"
	then
		activeHitTypesFrame["Star Swing"].Visible = true
		activeHitTypesFrame["Star Swing"].UltimateName.Text = StylesModule.OffensiveStyles[equippedOffensiveStyle].Ultimate
		activeHitTypesFrame["Star Swing"].PercentLabel.Text = tostring(PlayerData.HittingPower.Value) .. "%"

		if PlayerData.HittingPower.Value == 100 then
			activeHitTypesFrame["Star Swing"].Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
			activeHitTypesFrame["Star Swing"].UltAvailable.Visible = true
			activeHitTypesFrame["Star Swing"].Active = true
			activeHitTypesFrame["Star Swing"].Interactable = true
			activeHitTypesFrame["Star Swing"].AutoButtonColor = true
			activeHitTypesFrame["Star Swing"].BackgroundColor3 = Color3.fromRGB(255, 85, 0)
		else
			activeHitTypesFrame["Star Swing"].Icon.ImageColor3 = Color3.fromRGB(99, 99, 99)
			activeHitTypesFrame["Star Swing"].UltAvailable.Visible = false
			activeHitTypesFrame["Star Swing"].Active = false
			activeHitTypesFrame["Star Swing"].Interactable = false
			activeHitTypesFrame["Star Swing"].AutoButtonColor = false
			activeHitTypesFrame["Star Swing"].BackgroundColor3 = Color3.fromRGB(156, 156, 156)
		end
	else
		activeHitTypesFrame["Star Swing"].Visible = false
	end

	camera.FieldOfView = 40
	alignSwingFrameToStrikeZone(workspace.Pitching.StrikeZone)

	if BattingStanceTrack then
		BattingStanceTrack:Play()
	end

	UserInputService.MouseIconEnabled = false

	-- Hide coins display while hitting
	local coinsDisplay = player.PlayerGui:FindFirstChild("CoinsDisplay")
	if coinsDisplay then
		local frame = coinsDisplay:FindFirstChild("CoinsDisplayFrame")
		if frame and frame:IsA("GuiObject") then
			frame.Visible = false
		end
	end

	-- Enable AimGrid if touch + not legacy
	setAimGridEnabled(UserInputService.TouchEnabled and (not LegacyHitting))
end)

Remotes.BatResults.OnClientEvent:Connect(function()
	local currentHitter = GameValues:FindFirstChild("CurrentBatter")
	if currentHitter and currentHitter.Value == player and activeHitTypesFrame then
		activeHitTypesFrame.Visible = true
	end
end)

Remotes.UnbindHitting.OnClientEvent:Connect(function()
	inBattingCage = false
	CAS:UnbindAction("Swing")
	CAS:UnbindAction("PracticeSwing")
	CAS:UnbindAction("PracticeThrowPitch")

	UserInputService.MouseIconEnabled = true
	setAimGridEnabled(false)
	unbindTouchSwingButton()

	-- Restore HitTypes visible and hide MobileHitTypes when done hitting
	HittingScreen.HitTypes.Visible = true
	local mobileHitTypesFrame = HittingScreen:FindFirstChild("MobileHitTypes")
	if mobileHitTypesFrame and mobileHitTypesFrame:IsA("GuiObject") then
		mobileHitTypesFrame.Visible = false
	end
	activeHitTypesFrame = nil

	-- Bring back coins display after hitting
	local coinsDisplay = player.PlayerGui:FindFirstChild("CoinsDisplay")
	if coinsDisplay then
		local frame = coinsDisplay:FindFirstChild("CoinsDisplayFrame")
		if frame and frame:IsA("GuiObject") then
			frame.Visible = true
		end
	end
end)

--------------------------------------------------------------------------------
-- BallPitched visibility behavior
--------------------------------------------------------------------------------
GameValues.BallPitched.Changed:Connect(function()
	local currentHitter = GameValues:FindFirstChild("CurrentBatter")
	if not currentHitter or currentHitter.Value ~= player then return end

	canSwing = true
	if activeHitTypesFrame then
		if GameValues.BallPitched.Value then
			activeHitTypesFrame.Visible = false
		else
			activeHitTypesFrame.Visible = true
		end
	end
end)

--------------------------------------------------------------------------------
-- Keybind visibility + AimGrid toggle (IMPORTANT: don't spam-create AimGrid)
--------------------------------------------------------------------------------
local function updateKeybindsVisibility()
	if UserInputService.GamepadEnabled then
		HittingScreen.Keybinds.Visible = true
	else
		HittingScreen.Keybinds.Visible = false
	end

	if UserInputService.TouchEnabled then
		HittingScreen.MobileKeybinds.Visible = true

		-- Show mobile cursor when: Mobile Cursor setting ON, OR Legacy Hitting OFF (AimGrid needs cursor for aim)
		-- Hide only when Legacy Hitting ON and Mobile Cursor setting OFF
		local mobileCursorOn = PlayerData.Settings:FindFirstChild("MobileCursor") and PlayerData.Settings.MobileCursor.Value
		local legacyOn = getLegacyHitting()
		script.Parent.Cursor.Visible = mobileCursorOn or (not legacyOn)
	else
		HittingScreen.MobileKeybinds.Visible = false
		script.Parent.Cursor.Visible = true
	end

	LegacyHitting = getLegacyHitting()
	setAimGridEnabled(UserInputService.TouchEnabled and (not LegacyHitting))
end

updateKeybindsVisibility()

UserInputService.LastInputTypeChanged:Connect(updateKeybindsVisibility)

if PlayerData.Settings:FindFirstChild("MobileCursor") then
	PlayerData.Settings.MobileCursor.Changed:Connect(function()
		if UserInputService.TouchEnabled then
			updateKeybindsVisibility()
		end
	end)
end

if PlayerData.Settings:FindFirstChild("LegacyHitting") then
	PlayerData.Settings.LegacyHitting.Changed:Connect(function()
		LegacyHitting = getLegacyHitting()
		if UserInputService.TouchEnabled then
			updateKeybindsVisibility()
		end
	end)
end

-- Legacy touch: handle tap via InputBegan so GUI doesn't block (CAS often doesn't get touch when tapping on frames)
-- Supports both in-game (CurrentBatter) and batting cage (inBattingCage)
local DEBUG_LEGACY_CAGE = false
local function debugLegacyCage(...)
	if DEBUG_LEGACY_CAGE then
		print("[LegacyCage]", ...)
	end
end

local inBattingCage = false
UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
	if inputObject.UserInputType ~= Enum.UserInputType.Touch then return end
	if not getLegacyHitting() then
		debugLegacyCage("fail: legacy off")
		return
	end
	if not isPositionInMouseFrame(inputObject.Position) then
		debugLegacyCage("fail: not in MouseFrame", inputObject.Position.X, inputObject.Position.Y)
		return
	end

	debugLegacyCage("touch ok, inBattingCage=", inBattingCage)
	setCursorToViewportPoint(inputObject.Position.X, inputObject.Position.Y)
	LastTapPosition = inputObject.Position

	if inBattingCage then
		debugLegacyCage("in cage hitType=", hitType)
		if hitType == "Contact" or hitType == "Power" then
			debugLegacyCage("calling executePracticeSwing")
			_G.__LEGACY_CAGE_SWING = true
			if _G.__HITTING_EXEC_SWING then
				_G.__HITTING_EXEC_SWING()
			end
		else
			debugLegacyCage("fail: hitType not Contact/Power", hitType)
		end
		return
	end

	if GameValues.CurrentBatter.Value ~= player then return end
	local PitchWindup = GameValues:FindFirstChild("PitchWindup")
	local BallPitched = GameValues:FindFirstChild("BallPitched")
	if not PitchWindup or not BallPitched then return end
	if not canSwing or (not PitchWindup.Value and not BallPitched.Value) then return end

	if hitType == "Contact" or hitType == "Power" then
		executeSwing()
	elseif hitType == "Star Swing" and PlayerData.HittingPower.Value >= 100 then
		executeSwing()
	end
end)
--------------------------------------------------------------------------------
-- Everything below is your BattingCage / Practice code (UNCHANGED)
-- I did not rewrite it; your request was mobile hitting + aimgrid switching.
--------------------------------------------------------------------------------

local TweenService2 = game:GetService("TweenService")
local FakeBaseball = SharedObjects:WaitForChild("Baseball")

Remotes.BallLanded.OnClientEvent:Connect(function(position: Vector3, wasHit)
	if GameValues.CurrentBatter.Value ~= player then
		return
	end

	if not wasHit then
		spawn(function()
			local marker = FakeBaseball:Clone()
			marker.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(90), 0, 0)
			marker.Parent = workspace

			task.wait(0.5)

			local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local goal = {Size = Vector3.new(0, 0.1, 0), Transparency = 1}
			local tween = TweenService2:Create(marker, tweenInfo, goal)
			tween:Play()

			game:GetService("Debris"):AddItem(marker, 2)
		end)
	end
end)

-- (rest of your batting cage code remains exactly as you pasted it)
-- ...

--============================================================================================== 
-------------------- BATTING CAGE / PRACTICE CODE
--==============================================================================================
local battingCage = workspace:WaitForChild("BattingCage", 3)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
if battingCage then
	rayParams.FilterDescendantsInstances = {battingCage.Pitching.StrikeZone}
else
	return
end

local AnimationsModule = require(SharedModules.PitchingAnimations)
local PitchTypes = require(SharedModules.PitchTypes)

local canThrow = true
local canPracticeSwing = false
local practicePitchWindup = true
local practiceBallPitched = true
local practiceBallHit = false
local practiceSwingTimeout

function lerp(a, b, t)
	return a + (b - a) * t
end

function quadraticBezier(t, p0, p1, p2)
	local l1 = lerp(p0, p1, t)
	local l2 = lerp(p1, p2, t)
	local quad = lerp(l1, l2, t)
	return quad
end

local function BattingCagePitchBall(Ball, From, Middle, Target, Power, AbilityName, Direct, Speed, PitchType)
	Ball.CFrame = CFrame.new(From)

	local alpha = 0
	local baseBezierSpeed = 1 / Power
	local connection
	local hitStrikeZone = false
	local firedBallLanded = false

	-- Follow-through config
	local extend = false
	local extensionDistance = 10
	local extensionProgress = 0
	local extensionSpeed = 0
	local finalDirection = nil

	-- Ghost/Knuckle
	local isKnuckleball = (PitchType == "Knuckleball")
	local wobbleTimer, boomerangAngle = 0, 0

	-- Rolling spin
	local ballRotation = CFrame.identity
	local rotationSpeed = math.rad(360)

	-- === Pitch behavior flags ===
	local isMeditation = (AbilityName == "Meditation")
	local isSlowball   = (PitchType == "Slowball")

	-- Force straight path for Meditation and Slowball
	local useDirect = (isMeditation or isSlowball) and true or Direct

	-- Meditation: late boost
	local accelThreshold, accelMult, accelerated = 0.70, 2.0, false

	-- Slowball: hard slowdown at exactly 60%
	local slowStart, slowMult, decelerated = 0.80, 0.5, false  -- 30% slower after 0.60

	connection = RunService.RenderStepped:Connect(function(deltaTime)
		if not Ball or not Ball.Parent then
			connection:Disconnect()
			return
		end

		local prevPos = Ball.CFrame.Position
		local newPos

		if practiceBallHit then
			connection:Disconnect()
			return
		end

		-- === Compute alpha step with abrupt 60% slow for Slowball ===
		local stepBase = (useDirect and Speed or baseBezierSpeed)
		local step = 0

		if isSlowball then
			-- Split the frame at the threshold so slowdown happens exactly at 0.60
			local preSpeed  = stepBase
			local postSpeed = stepBase * slowMult

			if not decelerated then
				local remainingTo60 = slowStart - alpha
				if remainingTo60 <= 0 then
					-- already past threshold: fully slowed this frame
					decelerated = true
					step = postSpeed * deltaTime
				else
					-- time needed at full speed to reach 0.60
					local t_pre_needed = remainingTo60 / math.max(preSpeed, 1e-6)
					if t_pre_needed >= deltaTime then
						-- won't reach 0.60 this frame: all full speed
						step = preSpeed * deltaTime
					else
						-- reach 0.60, then immediately apply slowdown for the leftover time
						local dt_post = deltaTime - t_pre_needed
						local part1 = preSpeed  * t_pre_needed
						local part2 = postSpeed * dt_post
						step = part1 + part2
						decelerated = true
					end
				end
			else
				-- already slowed in earlier frame
				step = postSpeed * deltaTime
			end
		else
			-- non-slowball behavior (incl. Meditation boost)
			local stepSpeed = stepBase
			if isMeditation and alpha >= accelThreshold then
				stepSpeed = stepSpeed * accelMult
				accelerated = true
			end
			step = stepSpeed * deltaTime
		end

		-- === MAIN FLIGHT ===
		if not extend then
			alpha = math.min(1, alpha + step)

			if useDirect then
				newPos = From:Lerp(Target, alpha)
			else
				newPos = quadraticBezier(alpha, From, Middle, Target)
				if isKnuckleball then
					wobbleTimer += deltaTime
					local wobbleStrength = 0.25
					local wobble = Vector3.new(
						math.sin(wobbleTimer * 12) * wobbleStrength,
						math.sin(wobbleTimer * 9)  * wobbleStrength * 0.8,
						math.sin(wobbleTimer * 7)  * wobbleStrength * 0.5
					)
					newPos += wobble
				end
			end
		else
			-- === EXTENSION: inherit slowdown/boost if already active at switch time ===
			local extMult = 1
			if isMeditation and accelerated then extMult *= accelMult end
			if isSlowball and decelerated then extMult *= slowMult end

			local extStep = deltaTime * extensionSpeed * extMult
			extensionProgress += extStep
			newPos = Target + finalDirection * extensionProgress
		end

		-- Rolling spin
		local direction = (newPos - prevPos)
		if direction.Magnitude > 0.001 then
			local dirUnit = direction.Unit
			local up = Vector3.new(0, 1, 0)
			local axis = dirUnit:Cross(up)
			if axis.Magnitude < 0.01 then axis = dirUnit:Cross(Vector3.new(1,0,0)) end
			axis = axis.Unit
			local angle = rotationSpeed * deltaTime
			ballRotation = CFrame.fromAxisAngle(axis, -angle) * ballRotation
		end

		-- Apply final CFrame with spin
		if isKnuckleball then
			local spin = CFrame.Angles(
				math.rad(math.random(-0.3, 0.3)),
				math.rad(math.random(-0.3, 0.3)),
				math.rad(math.random(-0.3, 0.3))
			)
			Ball.CFrame = CFrame.new(newPos) * spin
		else
			Ball.CFrame = CFrame.new(newPos) * ballRotation
		end

		-- Direction attribute
		Ball:SetAttribute("Direction", CFrame.lookAt(prevPos, newPos).LookVector * (prevPos - newPos).Magnitude)

		-- Plate ray
		if not hitStrikeZone then
			local dir = newPos - prevPos
			local rayResult = workspace:Raycast(prevPos, dir, rayParams)
			if rayResult and rayResult.Instance == battingCage.Pitching.StrikeZone then
				local hitPoint = rayResult.Position
				hitStrikeZone = true
			end
		end

		-- Fake ball pop (unchanged)
		if alpha >= 0.7 and Ball:GetAttribute("Fake") then
			local effectBall = Ball:Clone()
			effectBall.Transparency = 1; effectBall.Anchored = true; effectBall.Parent = workspace.CurrentCamera
			local vfx = game.ReplicatedStorage.VFXParticlesFB.FakeBallPop:Clone()
			vfx.Parent = effectBall; vfx:Emit(15)
			task.delay(2, function() effectBall:Destroy() end)
			Ball.Parent = nil
			connection:Disconnect()
			return
		end

		-- Switch to extension (inherit state at switch)
		if alpha >= 1 and not extend then
			finalDirection = (Target - (useDirect and From or Middle)).Unit
			local tangentMag = useDirect and (Target - From).Magnitude or (2 * (Target - Middle)).Magnitude
			local currentBase = (useDirect and Speed or baseBezierSpeed)

			local extMult = 1
			if isMeditation and accelerated then extMult *= accelMult end
			if isSlowball and decelerated then extMult *= slowMult end

			extensionSpeed = tangentMag * currentBase * extMult
			extend = true
		elseif extend and extensionProgress >= extensionDistance and not firedBallLanded then
			firedBallLanded = true
			--Remotes.BallLanded:FireServer(Ball, Target, hitStrikeZone)
			canPracticeSwing = false
			local TimingLabel = SwingDataGUI.TimingLabel
			TimingLabel.Visible = true
			TimingLabel.Text = "STRIKE"
			connection:Disconnect()

			if Ball and Ball.Parent then
				Ball:Destroy()
			end
		end
	end)
end

local function BattingCageAutoPitchAI()
	local aiPitcher = battingCage.AIPitcher
	if not aiPitcher then return end

	battingCage.CageBallHolder:ClearAllChildren()

	-- RESET STATE for a fresh pitch
	--GameValues.BallHit.Value = false
	practiceBallHit = false
	--GameValues.BallPitched.Value = true
	--GameValues.PitchWindup.Value = true

	local BallHolder = battingCage.CageBallHolder

	local styleName = aiPitcher:GetAttribute("EquippedDefensiveStyle") or "Default"
	local styleData = AnimationsModule[styleName] or AnimationsModule["Default"]

	--local possiblePitches = styleData.Pitches or {"Fastball"}
	local possiblePitches = {"Fastball"}
	local chosenPitch = possiblePitches[math.random(1, #possiblePitches)]

	-- Random target in strike zone
	local strikeZone = battingCage:WaitForChild("Pitching"):WaitForChild("StrikeZone")
	local center = strikeZone.Position
	local size = strikeZone.Size
	local offset = Vector3.new(
		math.random(-size.X * 50, size.X * 50) / 100,
		math.random(-size.Y * 50, size.Y * 50) / 100,
		math.random(-size.Z * 50, size.Z * 50) / 100
	)
	local target = center + offset

	-- Throw animation
	local humanoid = aiPitcher:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator")
		local pitchAnim = Instance.new("Animation")
		pitchAnim.AnimationId = styleData.Pitch
		local pitchTrack = animator:LoadAnimation(pitchAnim)
		pitchTrack:Play()
		task.wait(styleData.ReleaseTime)
	end

	-- Ball
	local From = aiPitcher.LeftHand.Position
	local ball = SharedObjects.Baseball:Clone()
	ball.Name = "PracticeBall"
	ball.Parent = BallHolder
	ball:AddTag("InStrikeZone")

	-- Freeze physics; client animates CFrame
	ball.CanCollide = false
	ball.CollisionGroup = "BaseballGroup"

	local Middle = PitchTypes.CalculateMiddle(chosenPitch, From, target)
	local Power = 1 - PitchTypes.Data[chosenPitch].Power

	--task.wait(.1)

	task.spawn(function()
		--Remotes.PitchBall:FireAllClients(ball, From, Middle, target, Power, nil, nil, nil, chosenPitch)
		BattingCagePitchBall(ball, From, Middle, target, Power, nil, nil, nil, chosenPitch)
	end)

	if ball then
		local s = Instance.new("Sound")
		s.SoundId = "rbxassetid://75754607063587"
		s.Volume  = 1
		s.TimePosition = 0.15
		s.Parent  = ball
		s:Play()
		game.Debris:AddItem(s, 2)
	end

	--GameValues.BallPitched.Value = false
end

local function practiceThrowPitch(actionName, inputState, inputObject, isMobileClick)
	if inputState ~= Enum.UserInputState.Begin and not isMobileClick then return end
	if not canThrow then return end

	canThrow = false
	practicePitchWindup = true
	practiceBallPitched = true
	canPracticeSwing = true
	_G.__CAGE_PITCH_THROWN = true

	BattingCageAutoPitchAI()

	task.delay(3, function()
		canThrow = true
	end)
end

local CONTACT_DEBUG = true
local TIMING_RELAX  = CONTACT_DEBUG and 1.15 or 1.0   -- widen plate timing margin
local CLICK_RELAX   = CONTACT_DEBUG and 1.35 or 1.0   -- widen click margin
local FIELD_Y_PLANE               = 2
local MAX_Y_ANGLE                 = 30
local MIN_X_ANGLE, MAX_X_ANGLE    = 5, 90
local X_CLICK_OFFSET_RANGE        = 1
local Y_CLICK_OFFSET_RANGE        = 1
local GRAVITY_SCALE = 0.10
local g             = workspace.Gravity * GRAVITY_SCALE
local MIN_BALL_DIST                         = 175
local MAX_BALL_DIST                         = 550
local OUTSIDE_STRIKE_ZONE_DIST_MULTIPLIER   = 0.5
local OUTSIDE_STRIKE_ZONE_MARGIN_MULTIPLIER = 0.5

local function practiceSwingBat(clickPos, ballPos: Vector3, ballDir: Vector3?, hitType: string)
	-- real baseball (not Fake)
	local holder = battingCage:FindFirstChild("CageBallHolder")

	local ball
	for _, v in ipairs(holder:GetChildren()) do
		if v.Name == "PracticeBall" and not v:GetAttribute("Fake") then
			ball = v; break
		end
	end

	--[[
	if not ball then 
		GameValues.LastSwingWasMiss.Value = true 
		return 
	end
	--]]

	-- if ball is below strikezone, then swing is a miss
	local strikeZone = battingCage.Batting.StrikeZone
	local bottomY = strikeZone.Position.Y - (strikeZone.Size.Y / 2)

	local batterStyle, styleInventory = Remotes.GetStyleData:InvokeServer("Offensive")

	----------------------------------------------------------------
	--  Hit / Miss (Contact-First Hotfix)
	----------------------------------------------------------------
	local hitMargins   = {Power = 2, Contact = 5.5, ["Star Swing"] = 5}
	local clickMargins = {Power = .4, Contact = .75, ["Star Swing"] = 2}

	local ballHitMargin  = hitMargins[hitType] or 5
	local clickHitMargin = clickMargins[hitType] or .75

	-- Plate timing
	local dist, margin = PlateDistance:getRelativeDistToPlate(ballPos, true)
	margin = (margin or 0) + (ballHitMargin or 0)

	-- Click distances: PlateDistance-based and raw 3D, take safer
	local okPD, clickDistPD = pcall(function()
		return PlateDistance:getBallRelativeDist(ballPos, clickPos)
	end)
	if not okPD then clickDistPD = math.huge end
	local clickDist3D = (clickPos - ballPos).Magnitude
	local clickDist   = math.min(clickDistPD, clickDist3D)

	-- Zone (TEMP: gentle buff only)
	local inZone = false
	local okTag, hasTag = pcall(function() return ball:HasTag("InStrikeZone") end)
	if okTag then inZone = hasTag end
	if inZone then
		clickHitMargin = clickHitMargin + 0.05
	end

	-- Apply relaxers (debug)
	local margin_used        = margin * TIMING_RELAX
	local clickHitMargin_used= clickHitMargin * CLICK_RELAX

	local didHit = (math.abs(dist) <= margin_used) and (clickDist <= clickHitMargin_used)
	--GameValues.LastSwingWasMiss.Value = true

	-- Debug line for contact gate

	if not didHit then
		----------------------------------------------------------------
		-- MISS REPORT (deep-dive)
		----------------------------------------------------------------
		local reasonPieces = {}
		local timingMissed = (math.abs(dist) > margin_used)
		local aimMissed    = (clickDist > clickHitMargin_used)

		if timingMissed then table.insert(reasonPieces, "Timing") end
		if aimMissed    then table.insert(reasonPieces, "Aim") end
		if #reasonPieces == 0 then table.insert(reasonPieces, "Other") end
		local reasonStr = table.concat(reasonPieces, " + ")

		-- Signed timing miss (how far outside timing margin)
		local timingOverBy = math.abs(dist) - margin_used

		-- Aim miss by (PlateDistance and raw 3D)
		local aimOverByPD  = (clickDistPD or math.huge) - clickHitMargin_used
		local aimOverBy3D  = clickDist3D - clickHitMargin_used

		-- Compute click offsets & ?intended? angles, even on miss
		local toPos = workspace.Batting.To.Position

		-- re-use same targeting fallback you use for hits
		local ballTarget = nil

		if not ballTarget then
			if ballDir and ballDir.Magnitude > 0.1 then
				ballTarget = ballPos + ballDir.Unit * 15
			else
				local fwd = CFrame.lookAt(Vector3.new(ballPos.X, FIELD_Y_PLANE, ballPos.Z), toPos).LookVector
				ballTarget = ballPos + fwd * 15
			end
		end

		local ballOffsetCF  = CFrame.lookAt(ballTarget, toPos)
		local clickOffsetCF = CFrame.lookAt(clickPos,   toPos)
		local offsetLocal   = ballOffsetCF:ToObjectSpace(clickOffsetCF).Position

		-- normalized scalars (same mapping math you use below)
		local xClickScalar = (math.clamp(offsetLocal.X / X_CLICK_OFFSET_RANGE, -1, 1) + 1) * 0.5
		local yClickScalar = (math.clamp(offsetLocal.Y / Y_CLICK_OFFSET_RANGE, -1, 1) + 1) * 0.5

		-- predict the ?intended? yaw/pitch from the click (inverted mapping)
		local yawMax             = MAX_Y_ANGLE
		local pitchMin, pitchMax = MIN_X_ANGLE, MAX_X_ANGLE
		local intendedYawDeg     = lerp(-yawMax,  yawMax, xClickScalar)     -- left click -> right field (+yaw)
		local intendedPitchDeg   = lerp( pitchMax, pitchMin, yClickScalar)  -- above -> lower launch

		-- extra grounder bias if clicked ABOVE the ball (mirrors live code)
		if (clickPos.Y - ballPos.Y) > 0 then
			intendedPitchDeg = math.max(1, intendedPitchDeg - 8)
		end

		-- raw vectors for extra clarity
		local clickDeltaWorld = clickPos - ballPos
		local inZone = false
		local okTag, hasTag = pcall(function() return ball:HasTag("InStrikeZone") end)
		if okTag then inZone = hasTag end

		-- ability bits we sometimes care about when debugging misses
		local abilityTag     = tostring(ball:GetAttribute("Ability") or "None")
		local timeScaleTag   = tonumber(ball:GetAttribute("TimeScale") or 1)

		-- Compact booleans
		local INZONE_Y       = inZone

		-- Keep your existing MISS knock-away feedback
		if ballDir and ballDir.Magnitude > 1e-3 then
			local dur = math.log(1.001 + ballDir.Magnitude * 0.02)
			if dur < 1e-3 then dur = 0.05 end
			local imp = ballDir / dur + Vector3.new(0, workspace.Gravity * dur * 0.5, 0)
			ball.Position = ballPos
			ball:ApplyImpulse(imp * ball.AssemblyMass)
		end
		return
	end


	----------------------------------------------------------------
	--  HIT setup
	--------------------------------------------------------------------
	practiceBallHit = true

	local oldCF = ball.CFrame
	ball:Destroy()
	ball = SharedObjects.Baseball:Clone()
	ball.Name = "PracticeBall"
	ball.Parent = holder
	ball.CFrame = oldCF
	ball:SetAttribute("Hit", true)


	----------------------------------------------------------------
	--  Offsets ? angles (INVERTED mapping as requested)
	----------------------------------------------------------------
	local toPos = battingCage.Batting.To.Position

	-- fallback if shared target missing
	local ballTarget = nil
	if not ballTarget then
		if ballDir and ballDir.Magnitude > 0.1 then
			ballTarget = ballPos + ballDir.Unit * 15
		else
			local fwd = CFrame.lookAt(Vector3.new(ballPos.X, FIELD_Y_PLANE, ballPos.Z), toPos).LookVector
			ballTarget = ballPos + fwd * 15
		end
	end

	local ballOffsetCF  = CFrame.lookAt(ballTarget, toPos)
	local clickOffsetCF = CFrame.lookAt(clickPos,   toPos)

	-- measure click in ball?s local frame
	local offset = ballOffsetCF:ToObjectSpace(clickOffsetCF).Position

	-- normalized 0..1 scalars
	local xClickScalar = (math.clamp(offset.X / X_CLICK_OFFSET_RANGE, -1, 1) + 1) * 0.5
	local yClickScalar = (math.clamp(offset.Y / Y_CLICK_OFFSET_RANGE, -1, 1) + 1) * 0.5

	-- INVERTED mappings:
	--  Left of ball -> RIGHT field (flip yaw sign)
	--  Above ball    -> LOWER launch angle (liner/grounder)
	local yawMax             = MAX_Y_ANGLE
	local pitchMin, pitchMax = MIN_X_ANGLE, MAX_X_ANGLE

	local yAngle = lerp(-yawMax,  yawMax, xClickScalar)   -- left click ? +yaw (right field)
	local xAngle = lerp( pitchMax, pitchMin, yClickScalar) -- above ? lower launch

	-- extra grounder bias if clicked ABOVE the ball
	if (clickPos.Y - ballPos.Y) > 0 then
		xAngle = math.max(1, xAngle - 8) -- up to 8? lower, never < 1?
	end

	----------------------------------------------------------------
	--  Distance window by type + modifiers
	----------------------------------------------------------------
	local minDist, maxDist = MIN_BALL_DIST, MAX_BALL_DIST
	if hitType == "Power"   then minDist += 25; maxDist += 50 end
	if hitType == "Contact" then minDist -= 10; maxDist -= 35 end

	-- timing scalar (no forced override)
	local rawTiming = math.clamp(math.abs(dist) / math.max((margin or 0), 1e-3), 0, 1)

	-- harsher curve, tune exponent
	local p = 0.6  -- try 2.0?3.0 for harsher
	local timingCurve = math.pow(rawTiming, p)

	local distance = lerp(maxDist, minDist, timingCurve)
	--print (distance, "HERES THE DISTANCE")

	----------------------------------------------------------------
	--  Direction & speed (ballistics)
	----------------------------------------------------------------
	local targetDir = (CFrame.lookAt(ballTarget, toPos) * CFrame.Angles(math.rad(xAngle), math.rad(yAngle), 0)).LookVector
	if targetDir.Magnitude < 1e-6 then
		targetDir = CFrame.lookAt(Vector3.new(ballPos.X, FIELD_Y_PLANE, ballPos.Z), toPos).LookVector
	end
	targetDir = targetDir.Unit

	local forwardDir   = CFrame.lookAt(Vector3.new(ballPos.X, FIELD_Y_PLANE, ballPos.Z), toPos).LookVector
	local dot          = math.clamp(targetDir:Dot(forwardDir), -1, 1)
	local launchAngle  = math.acos(dot)

	-- allow true lasers/grounders
	local minLaunchAngle = math.rad(1)   -- lowered from 3?
	local maxLaunchAngle = math.rad(45)
	launchAngle = math.clamp(launchAngle, minLaunchAngle, maxLaunchAngle)

	local sinDouble = math.sin(launchAngle * 2)
	if math.abs(sinDouble) < 1e-6 then sinDouble = math.sin(minLaunchAngle * 2) end
	local speed    = math.sqrt(math.max(distance, 0) * g / sinDouble)
	local velocity = targetDir * speed

	-- Debug line for timing/ballistics

	----------------------------------------------------------------
	--  Predict landing (time-of-flight)
	----------------------------------------------------------------
	local vy     = velocity.Y
	local deltaY = ballPos.Y - FIELD_Y_PLANE
	local disc   = vy*vy + 2 * g * deltaY
	if disc < 0 then disc = 0 end
	local t = (vy + math.sqrt(disc)) / g
	if t < 0.05 then t = 0.05 end

	local finalPos = Vector3.new(
		ballPos.X + velocity.X * t,
		FIELD_Y_PLANE,
		ballPos.Z + velocity.Z * t
	)

	local predictedLanding = finalPos
	local desiredFinal     = finalPos

	-- Star Swing: force fair landing (keep same T, re-aim)

	ball:SetAttribute("PredictedLanding", desiredFinal)

	----------------------------------------------------------------
	--  Sounds & ability hooks
	----------------------------------------------------------------
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://9113303129"
	s.Volume  = 0.75
	s.Parent  = battingCage["Home Base"]
	s:Play()
	game:GetService("Debris"):AddItem(s, 2)

	----------------------------------------------------------------
	--  Launch the ball (unless overridden)
	----------------------------------------------------------------
	ball.CanCollide     = true
	ball.Anchored = false
	ball.CollisionGroup = "BaseballGroup"

	task.wait() -- allow owner update

	local ts = ball:GetAttribute("TimeScale")
	if ts and ts > 0 and ts < 1 then
		local Tnew = math.max(0.15, t * ts)
		local gvec = Vector3.new(0, -g, 0)
		velocity = (finalPos - ballPos - 0.5 * gvec * Tnew * Tnew) / Tnew
	end

	ball.CFrame = CFrame.new(ballPos)
	ball.AssemblyLinearVelocity = velocity

	task.spawn(function()
		local rolling = false

		local rollingDampFactor = 0.92
		local dampInterval = 0.05
		local minSpeedToStop = 0.1

		ball.Touched:Connect(function(hit)
			if hit:IsDescendantOf(ball) then return end
			if rolling then return end

			-- Only apply anti-roll if the material is Grass
			if hit.Material ~= Enum.Material.Grass then
				return
			end

			rolling = true

			task.spawn(function()
				while rolling and ball.AssemblyLinearVelocity.Magnitude > minSpeedToStop do
					local currentVel = ball.AssemblyLinearVelocity

					local horizontalVel = Vector3.new(currentVel.X, 0, currentVel.Z) * rollingDampFactor
					local newVel = Vector3.new(horizontalVel.X, currentVel.Y, horizontalVel.Z)

					ball.AssemblyLinearVelocity = newVel
					task.wait(dampInterval)
				end

				rolling = false
			end)
		end)

		local force = Instance.new("BodyForce")
		force.Parent = ball

		while ball and ball.Parent and ball:FindFirstChild("GravityOn") and ball.GravityOn.Value do
			force.Force = Vector3.new(
				0,
				workspace.Gravity * ball.AssemblyMass * (1 - GRAVITY_SCALE),
				0
			)
			task.wait(0.1)
		end
	end)

	----------------------------------------------------------------
	--  Trail / client indicator
	----------------------------------------------------------------
	ball.Trail.Enabled = true

	game:GetService("Debris"):AddItem(ball, 5)
end

local function executePracticeSwing()
	local fromLegacyCageTap = (_G.__LEGACY_CAGE_SWING == true)
	if fromLegacyCageTap then
		_G.__LEGACY_CAGE_SWING = nil
		if not _G.__CAGE_PITCH_THROWN then return end
		_G.__CAGE_PITCH_THROWN = nil
	end
	if not fromLegacyCageTap and not canPracticeSwing then return end
	canPracticeSwing = false

	local ball = battingCage.CageBallHolder:FindFirstChild("PracticeBall")

	--[[
	if practiceSwingTimeout then
		task.cancel(swingTimeout)
		swingTimeout = nil
	end
	--]]

	local battingCageCharacter = battingCage.BattingCageCharacter

	-- Stop Leg Lift if needed
	for _, track in pairs(battingCageCharacter.Humanoid.Animator:GetPlayingAnimationTracks()) do
		if track.Name == "Leg Lift" then
			track:Stop()
		end
	end

	if hitType ~= "Star Swing" then
		SwingTrack:AdjustSpeed(1)
		SwingTrack:Play()
		local swingSound = Instance.new("Sound")
		swingSound.SoundId = "rbxassetid://9113305619"
		swingSound.Volume = 1
		swingSound.PlayOnRemove = false
		swingSound.Parent = battingCageCharacter:FindFirstChild("HumanoidRootPart") or workspace
		swingSound:Play()
		game:GetService("Debris"):AddItem(swingSound, 2)
	end
	State = "idle"

	if not ball then
		LastTapPosition = nil
		return
	end

	local ray
	if UserInputService.TouchEnabled and LastTapPosition then
		ray = workspace.CurrentCamera:ViewportPointToRay(LastTapPosition.X, LastTapPosition.Y)
	else
		local cursorPosition = script.Parent.Cursor.Position
		ray = workspace.CurrentCamera:ViewportPointToRay(cursorPosition.X.Offset, cursorPosition.Y.Offset, 1)
	end

	local rayResult = workspace:Raycast(ray.Origin, ray.Direction * 500, missParams)
	LastTapPosition = nil
	local ballPosition = ball.Position

	-- Fire server for actual swing logic
	--Remotes.SwingBat:FireServer(rayResult.Position, ballPosition, ball:GetAttribute("Direction"), hitType)
	practiceSwingBat(rayResult.Position, ballPosition, ball:GetAttribute("Direction"), hitType)
	-- ------- existing timing label UI (unchanged) -------
	local TimingLabel = SwingDataGUI.TimingLabel
	TimingLabel.Visible = true

	local earlyCushion = 2      -- keep generous buffer for "EARLY"
	local lateCushion  = 0.5    -- much tighter buffer for "LATE"

	local dist, margin = PlateDistance:getRelativeDistToPlate(ball.Position, true)

	-- On-time window is asymmetric now: [-margin - earlyCushion,  margin + lateCushion]
	if dist >= -margin - earlyCushion and dist <= margin + lateCushion then
		TimingLabel.Text = "ON TIME"
	elseif dist < -margin - earlyCushion then
		TimingLabel.Text = "EARLY"
	else
		TimingLabel.Text = "LATE"
	end

	-- Reset touch position
	LastTapPosition = nil
end

local function setPracticeAimGridEnabled(enabled: boolean)
	-- We reuse the SAME AimGrid + CAS button system
	if enabled then
		-- Route CAS swing to practice swing
		_G.__HITTING_EXEC_SWING = executePracticeSwing
		setAimGridEnabled(true)
	else
		-- Route back to normal swing
		_G.__HITTING_EXEC_SWING = executeSwing
		setAimGridEnabled(false)
	end
end

local function onPracticeSwing(actionName, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then return end

	if not canPracticeSwing or (not practicePitchWindup and not practiceBallPitched) then
		return
	end

	-- AimGrid mode in practice: tap/click in hitting zone is for aiming only
	if UserInputService.TouchEnabled and (not LegacyHitting) and isPositionInMouseFrame(inputObject.Position) then
		return
	end

	if inputObject.UserInputType == Enum.UserInputType.Touch then
		LastTapPosition = inputObject.Position
	end

	if hitType == "Contact" or hitType == "Power" then
		executePracticeSwing()
	end		
end

Remotes.BattingCage.SetupBattingPractice.OnClientEvent:Connect(function()
	if not battingCage then
		return
	end

	inBattingCage = true
	canPracticeSwing = true
	practicePitchWindup = true
	practiceBallPitched = true
	_G.__CAGE_PITCH_THROWN = nil
	battingCage.CageBallHolder:ClearAllChildren()

	CAS:UnbindAction("PracticeSwing")
	CAS:UnbindAction("PracticeThrowPitch")

	-- Legacy touch uses InputBegan (same as in-game); mouse + gamepad via CAS
	CAS:BindAction("PracticeSwing", onPracticeSwing, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonA)
	CAS:BindAction("PracticeThrowPitch", practiceThrowPitch, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonR2)

	PlayerUtilsClient.enableMouselock(false)
	if player.PlayerGui:FindFirstChild("MobileShiftlock") and player.PlayerGui.MobileShiftlock:FindFirstChild("DisableShiftLock") then
		player.PlayerGui.MobileShiftlock.DisableShiftLock:Fire()
	end

	local cameraFolder = battingCage.Cameras

	player.Character.States.InStylesLocker.Value = true

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(cameraFolder.HittingCam.Position, cameraFolder.HittingCamFocal.Position)

	SwingData.Visible = false
	SwingData.StrikeZone.Hit.Visible = false
	SwingData.StrikeZone.Ball.Visible = false
	SwingData.BallZone.Hit.Visible = false
	SwingData.BallZone.Ball.Visible = false

	-- LegacyHitting true: always HitTypes visible, MobileHitTypes hidden. Else: mobile uses MobileHitTypes, PC uses HitTypes.
	local practiceMobileHitTypes = HittingScreen:FindFirstChild("MobileHitTypes")
	if getLegacyHitting() then
		activeHitTypesFrame = HittingScreen.HitTypes
		HittingScreen.HitTypes.Visible = true
		if practiceMobileHitTypes and practiceMobileHitTypes:IsA("GuiObject") then
			practiceMobileHitTypes.Visible = false
		end
	elseif UserInputService.TouchEnabled and practiceMobileHitTypes and practiceMobileHitTypes:IsA("GuiObject") then
		activeHitTypesFrame = practiceMobileHitTypes
		HittingScreen.HitTypes.Visible = false
		practiceMobileHitTypes.Visible = true
	else
		activeHitTypesFrame = HittingScreen.HitTypes
		HittingScreen.HitTypes.Visible = true
		if practiceMobileHitTypes and practiceMobileHitTypes:IsA("GuiObject") then
			practiceMobileHitTypes.Visible = false
		end
	end

	handleHitButtonClick(activeHitTypesFrame.Contact)

	local equippedStyle, styleInventory = Remotes.GetStyleData:InvokeServer("Offensive")
	local styleName = equippedStyle or "Heat"
	loadAnimationsForStyle(equippedStyle, battingCage.BattingCageCharacter)

	activeHitTypesFrame["Star Swing"].Visible = false

	camera.FieldOfView = 40

	alignSwingFrameToStrikeZone(battingCage.Pitching.StrikeZone)

	BattingStanceTrack:Play()

	UserInputService.MouseIconEnabled = false

	LegacyHitting = getLegacyHitting()
	if UserInputService.TouchEnabled and (not LegacyHitting) then
		setPracticeAimGridEnabled(true)
	else
		setPracticeAimGridEnabled(false)
	end
	-- Always use practice swing while in cage (so legacy tap can call _G.__HITTING_EXEC_SWING())
	_G.__HITTING_EXEC_SWING = executePracticeSwing
end)

do
	local playerGui = player.PlayerGui
	if playerGui:FindFirstChild("BattingPracticeGui") then
		local battingPracticeFrame = playerGui.BattingPracticeGui.BattingPracticeFrame

		local mobileOptions = battingPracticeFrame.MobileOptions

		mobileOptions.Pitch.Activated:Connect(function()
			practiceThrowPitch(nil, nil, nil, true)
		end)
	end
end