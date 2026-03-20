local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.RemoteEvents
local Settings = UserSettings()
local GameSettings = Settings.GameSettings

local ShiftLockController = {}
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui, InputCn = nil, nil
local IsShiftLockMode = true
local IsShiftLocked = true
local IsActionBound = false
local IsInFirstPerson = false
ShiftLockController.OnShiftLockToggled = Instance.new("BindableEvent")

local function isShiftLockMode()
	local currentCamera = workspace.CurrentCamera
	return LocalPlayer.DevEnableMouseLock
		and GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch
		and LocalPlayer.DevComputerMovementMode ~= Enum.DevComputerMovementMode.ClickToMove
		and GameSettings.ComputerMovementMode ~= Enum.ComputerMovementMode.ClickToMove
		and LocalPlayer.DevComputerMovementMode ~= Enum.DevComputerMovementMode.Scriptable
		and currentCamera and currentCamera.CameraType ~= Enum.CameraType.Scriptable -- Prevent Shift Lock in Scriptable mode
end

if not UserInputService.TouchEnabled then
	IsShiftLockMode = isShiftLockMode()
end

local function onShiftLockToggled()
	IsShiftLocked = not IsShiftLocked
	ShiftLockController.OnShiftLockToggled:Fire()
end

local function disableShiftLock()
	if ScreenGui then
		ScreenGui.Parent = nil
	end
	IsShiftLockMode = false
	Mouse.Icon = ""
	if InputCn then
		InputCn:Disconnect()
		InputCn = nil
	end
	IsActionBound = false
	ShiftLockController.OnShiftLockToggled:Fire()
end

local function enableShiftLock()
	local currentCamera = workspace.CurrentCamera
	if currentCamera and currentCamera.CameraType == Enum.CameraType.Scriptable then
		disableShiftLock() -- Ensure Shift Lock is disabled if the camera is scriptable
		return
	end

	IsShiftLockMode = isShiftLockMode()
	if IsShiftLockMode then
		if ScreenGui then
			ScreenGui.Parent = PlayerGui
		end
		if IsShiftLocked then
			ShiftLockController.OnShiftLockToggled:Fire()
		end
		if not IsActionBound then
			InputCn = UserInputService.InputBegan:Connect(function(inputObject, isProcessed)
				if isProcessed then return end
				if inputObject.UserInputType == Enum.UserInputType.Keyboard and 
					(inputObject.KeyCode == Enum.KeyCode.LeftShift or inputObject.KeyCode == Enum.KeyCode.RightShift) then
					onShiftLockToggled()
				end
			end)
			IsActionBound = true
		end
	end
end

GameSettings.Changed:Connect(function(property)
	if property == "ControlMode" then
		if GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch then
			enableShiftLock()
		else
			disableShiftLock()
		end
	elseif property == "ComputerMovementMode" then
		if GameSettings.ComputerMovementMode == Enum.ComputerMovementMode.ClickToMove then
			disableShiftLock()
		else
			enableShiftLock()
		end
	end
end)

LocalPlayer.Changed:Connect(function(property)
	if property == "DevEnableMouseLock" then
		if LocalPlayer.DevEnableMouseLock then
			enableShiftLock()
		else
			disableShiftLock()
		end
	elseif property == "DevComputerMovementMode" then
		if LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.ClickToMove 
			or LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.Scriptable then
			disableShiftLock()
		else
			enableShiftLock()
		end
	end
end)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local currentCamera = workspace.CurrentCamera
	if currentCamera then
		currentCamera:GetPropertyChangedSignal("CameraType"):Connect(function()
			if currentCamera.CameraType == Enum.CameraType.Scriptable then
				disableShiftLock()
			else
				enableShiftLock()
			end
		end)
	end
end)

if UserInputService.TouchEnabled then
	script.Parent.Enabled = true
end

enableShiftLock()

return ShiftLockController
