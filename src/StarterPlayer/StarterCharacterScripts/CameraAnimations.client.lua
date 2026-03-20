local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local GameValues = ReplicatedStorage.GameValues
local CameraValues = GameValues.CameraValues
local Remotes = ReplicatedStorage.RemoteEvents
local SharedModules = ReplicatedStorage.SharedModules
local Shared = ReplicatedStorage.Shared
local SharedServices = Shared.Services

local activeRenderStepped = nil
local ondeckRenderStepped = nil

local PlayerIntroSpots = workspace.PlayerIntroSpots
local fieldCameras = workspace.FieldCameras
local player = Players.LocalPlayer
local PlayerScripts = player:WaitForChild("PlayerScripts")
local PlayerModuleEvents = PlayerScripts:WaitForChild("PlayerModuleEvents")

local ClientFunctions = require(SharedModules.ClientFunctions)
local PlayerUtilsClient = require(SharedServices.Utilities.PlayerUtilsClient)

local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Custom
camera.FieldOfView = 70

local character = player.Character

character:WaitForChild("States")

local function startFieldPan()
	local goal = {}
	local tweenInfo
	local tween

	local rotationAngle = Instance.new("NumberValue")
	local tweenComplete = false

	local cameraOffset = Vector3.new(0, 50, 100)
	local rotationTime = 30  -- Time in seconds
	local rotationDegrees = 360
	local rotationRepeatCount = -1  -- Use -1 for infinite repeats
	local lookAtTarget = true  -- Whether the camera tilts to point directly at the target
	
	camera.CameraType = Enum.CameraType.Scriptable
	
	local function updateCamera()
		camera.Focus = fieldCameras.CamFocal.CFrame
		
		local rotatedCFrame = CFrame.Angles(0, math.rad(rotationAngle.Value), 0)
		rotatedCFrame = CFrame.new(fieldCameras.CamFocal.Position) * rotatedCFrame
		camera.CFrame = rotatedCFrame:ToWorldSpace(CFrame.new(cameraOffset))
		
		if lookAtTarget then
			camera.CFrame = CFrame.new(camera.CFrame.Position, fieldCameras.CamFocal.Position)
		end
	end

	tweenInfo = TweenInfo.new(rotationTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, rotationRepeatCount)
	tween = TweenService:Create(rotationAngle, tweenInfo, {Value = rotationDegrees})
	tween:Play()
	
	activeRenderStepped = RunService.RenderStepped:Connect(function()
		if character == nil then
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			activeRenderStepped:Disconnect()
		end
		
		if player.Team and player.Team.Name == "Lobby" and not character.States.InStylesLocker.Value then
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		elseif character and character:FindFirstChild("States") and not character.States.InStylesLocker.Value then
			updateCamera()
		end
	end)
end

local function stopFieldPan()
	if activeRenderStepped then
		activeRenderStepped:Disconnect()
	end
end

if CameraValues.FieldPan.Value then
	startFieldPan()
end

CameraValues.FieldPan.Changed:Connect(function()
	if CameraValues.FieldPan.Value then
		startFieldPan()
	else
		stopFieldPan()
	end
end)

local function startPlayerSelectCam(startTween)
	if player.Character and player.Character:FindFirstChild("States") and player.Character.States:FindFirstChild("InStylesLocker") then
		if player.Character.States.InStylesLocker.Value or player.Team.Name == "Lobby" then
			return
		end
		
		camera.CameraType = Enum.CameraType.Custom

		PlayerUtilsClient.enableMouselock(false)
		
		if player.PlayerGui:FindFirstChild("MobileShiftlock") and player.PlayerGui.MobileShiftlock:FindFirstChild("DisableShiftLock") then
			player.PlayerGui.MobileShiftlock.DisableShiftLock:Fire()
		end
		
		RunService.RenderStepped:Wait()

		camera.CameraType = Enum.CameraType.Scriptable

		local goal = {}
		local tweenInfo = TweenInfo.new(2)
		
		if not startTween then
			camera.CFrame = CFrame.new(fieldCameras.CamPlayerSelectOrigin.Position, fieldCameras.CamPlayerSelectFocal.Position)
		else
			goal.CFrame = CFrame.new(fieldCameras.CamPlayerSelectOrigin.Position, fieldCameras.CamPlayerSelectFocal.Position)
			local tween = TweenService:Create(camera, tweenInfo, goal)
			tween:Play()
		end
	end
end

if CameraValues.PlayerSelectCam.Value then
	startPlayerSelectCam(false)
end

CameraValues.PlayerSelectCam.Changed:Connect(function()
	if CameraValues.PlayerSelectCam.Value then
		startPlayerSelectCam(true)
	end
end)

local function startMVPAwardPan(startTween)
	if (player.Character:FindFirstChild("States") and player.Character.States.InStylesLocker.Value) or (player.Team and player.Team.Name == "Lobby") then
		return
	end
	
	camera.CameraType = Enum.CameraType.Scriptable

	local goal = {}
	local tweenInfo = TweenInfo.new(2)
	
	if not startTween then
		camera.CFrame = CFrame.new(fieldCameras.CamMVPSceneOrigin.Position, fieldCameras.CamPlayerSelectFocal.Position)
	else
		goal.CFrame = CFrame.new(fieldCameras.CamMVPSceneOrigin.Position, fieldCameras.CamPlayerSelectFocal.Position)
		local tween = TweenService:Create(camera, tweenInfo, goal)
		tween:Play()
	end
end

if CameraValues.MVPAwardCam.Value then
	startMVPAwardPan(false)
end

CameraValues.MVPAwardCam.Changed:Connect(function()
	if CameraValues.MVPAwardCam.Value then
		startMVPAwardPan(true)
	end
end)

script.ExitedStylesMenu.Event:Connect(function()
	if CameraValues.PlayerSelectCam.Value then
		startPlayerSelectCam(false)
	elseif CameraValues.MVPAwardCam.Value then
		startMVPAwardPan(false)
	end
end)

local function startPlayerIntro()
	if player.Team and player.Team.Name == "Lobby" then
		return
	end
	
	if player.PlayerGui.StylesGui.StylesFrame.Visible then
		player.PlayerGui.StylesGui.StylesFrame.Visible = false
		player.Character.States.InStylesLocker.Value = false
	end
	
	ClientFunctions.ToggleStylesGuiView(true)

	player.Character.States.StylesLockerDisabled.Value = true
	
	local waitTime = 4
	
	camera.CameraType = Enum.CameraType.Scriptable
	
	camera.CFrame = CFrame.new(PlayerIntroSpots.Home.Cams.CamStart.Position, PlayerIntroSpots.Home.Cams.CamStartFocal.Position)

	local goal = {}
	local tweenInfo = TweenInfo.new(waitTime, Enum.EasingStyle.Linear)

	goal.CFrame = CFrame.new(PlayerIntroSpots.Home.Cams.CamEnd.Position, PlayerIntroSpots.Home.Cams.CamEndFocal.Position)
	local tween = TweenService:Create(camera, tweenInfo, goal)
	tween:Play()
	
	wait(waitTime)

	camera.CFrame = CFrame.new(PlayerIntroSpots.Away.Cams.CamStart.Position, PlayerIntroSpots.Away.Cams.CamStartFocal.Position)

	goal.CFrame = CFrame.new(PlayerIntroSpots.Away.Cams.CamEnd.Position, PlayerIntroSpots.Away.Cams.CamEndFocal.Position)
	local tween = TweenService:Create(camera, tweenInfo, goal)
	tween:Play()
	
	wait(waitTime)
	
	player.Character.States.StylesLockerDisabled.Value = false
end

if CameraValues.PlayerIntro.Value then
	startPlayerIntro()
end

CameraValues.PlayerIntro.Changed:Connect(function()
	if CameraValues.PlayerIntro.Value then
		startPlayerIntro()
	end
end)

Remotes.ResetFOV.OnClientEvent:Connect(function()
	camera.FieldOfView = 70
	local player = game.Players.LocalPlayer
	local mouse = player:GetMouse()
	UserInputService.MouseIconEnabled = true
end)

Remotes.OnDeckCamera.OnClientEvent:Connect(function(active, batter)
	if ondeckRenderStepped then
		ondeckRenderStepped:Disconnect()
		ondeckRenderStepped = nil
	end
	
	if not active or (player.Team and player.Team.Name == "Lobby") then
		return
	end
	
	if not CameraValues.OnDeckCam.Value then
		return
	end

	if GameValues.CurrentBatter.Value == player or player == GameValues.CurrentPitcher.Value then
		PlayerUtilsClient.enableMouselock(false)
		if player.PlayerGui:FindFirstChild("MobileShiftlock") and player.PlayerGui.MobileShiftlock:FindFirstChild("DisableShiftLock") then
			player.PlayerGui.MobileShiftlock.DisableShiftLock:Fire()
		end
		
		camera.CameraType = Enum.CameraType.Custom
		
		if player.Character 
			and player.Character:FindFirstChild("States") 
			and player.Character.States:FindFirstChild("InStylesLocker")  
			and player.Character.States.InStylesLocker.Value
		then
			player.Character.States.InStylesLocker.Value = false
		end
		
		if player:FindFirstChild("PlayerGui") 
			and player.PlayerGui:FindFirstChild("StylesGui") 
			and player.PlayerGui.StylesGui:FindFirstChild("StylesFrame") 
		then
			player.PlayerGui.StylesGui.StylesFrame.Visible = false
		end
		
		RunService.RenderStepped:Wait()
		
		if not CameraValues.OnDeckCam.Value then
			return
		end
	end
	
	camera.CameraType = Enum.CameraType.Scriptable
	
	local function updateCamera()
		if batter and batter:FindFirstChild("HumanoidRootPart") then
			local targetPosition = batter.HumanoidRootPart.Position
			local startCFrame = camera.CFrame
			local targetCFrame = CFrame.new(fieldCameras.CamOnDeck.CFrame.Position, targetPosition)

			camera.CFrame = startCFrame:Lerp(targetCFrame, 0.2) 
		end
	end
	
	ondeckRenderStepped = RunService.RenderStepped:Connect(function()
		if not CameraValues.OnDeckCam.Value then
			ondeckRenderStepped:Disconnect()
			ondeckRenderStepped = nil

			if ClientFunctions.NoOtherCameraActive(player) and GameValues.CurrentBatter.Value ~= player then
				workspace.Camera.CameraType = Enum.CameraType.Custom
			end
		end
		
		if not player.Character.States.InStylesLocker.Value and player.Team and player.Team.Name ~= "Lobby" then
			updateCamera()
		end
	end)
end)

Remotes.WalkBatterCamera.OnClientEvent:Connect(function()
	if player.Character.States.InStylesLocker.Value or (player.Team and player.Team.Name == "Lobby") then
		return
	end
	
	camera.CameraType = Enum.CameraType.Scriptable
	
	camera.CFrame = CFrame.new(fieldCameras.CamBallWalkFocal.CFrame.Position, fieldCameras.CamPlayerSelectOrigin.CFrame.Position)
	
	task.delay(8, function()
		if ondeckRenderStepped == nil 
			and ClientFunctions.NoOtherCameraActive(player) 
		then
			workspace.Camera.CameraType = Enum.CameraType.Custom
		end
	end)
end)