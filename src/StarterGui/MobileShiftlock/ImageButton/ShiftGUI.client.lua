local MobileCameraFramework = {}
local players = game:GetService("Players")
local runservice = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local player = players.LocalPlayer

repeat wait() until player.Character
local character = player.Character
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera
local button = script.Parent

-- Visibility
local uis = game:GetService("UserInputService")
local ismobile = uis.TouchEnabled
button.Visible = ismobile

local states = {
	OFF = "rbxasset://textures/ui/mouseLock_off@2x.png",
	ON = "rbxasset://textures/ui/mouseLock_on@2x.png"
}

local MAX_LENGTH = 900000
local active = false
local ENABLED_OFFSET = CFrame.new(1.7, 0, 0)
local DISABLED_OFFSET = CFrame.new(-1.7, 0, 0)

local function UpdateImage(STATE)
	button.Image = states[STATE]
end

local function UpdateAutoRotate(BOOL)
	humanoid.AutoRotate = BOOL
end

local function GetUpdatedCameraCFrame(ROOT, CAMERA)
	return CFrame.new(root.Position, Vector3.new(CAMERA.CFrame.LookVector.X * MAX_LENGTH, root.Position.Y, CAMERA.CFrame.LookVector.Z * MAX_LENGTH))
end

local function EnableShiftlock()
	if camera.CameraType == Enum.CameraType.Scriptable then
		-- Prevent enabling Shift Lock when CameraType is Scriptable
		return
	end

	UpdateAutoRotate(false)
	UpdateImage("ON")
	root.CFrame = GetUpdatedCameraCFrame(root, camera)
	camera.CFrame = camera.CFrame * ENABLED_OFFSET
end

local function DisableShiftlock()
	if active then
		UpdateAutoRotate(true)
		UpdateImage("OFF")
		camera.CFrame = camera.CFrame * DISABLED_OFFSET

		pcall(function()
			if active then
				active:Disconnect()
				active = nil
			end
		end)
	end
end

UpdateImage("OFF")
active = false

function ShiftLock()
	if camera.CameraType == Enum.CameraType.Scriptable then
		-- Prevent enabling Shift Lock when CameraType is Scriptable
		return
	end

	if not active then
		active = runservice.RenderStepped:Connect(function()
			EnableShiftlock()
		end)
	else
		DisableShiftlock()
	end
end

local ShiftLockButton = CAS:BindAction("ShiftLOCK", ShiftLock, false, "On")
CAS:SetPosition("ShiftLOCK", UDim2.new(0.8, 0, 0.8, 0))

local isDiving = false
local initiallyActive = false

button.MouseButton1Click:Connect(function()
	if camera.CameraType == Enum.CameraType.Scriptable then
		-- Prevent enabling Shift Lock when CameraType is Scriptable
		return
	end

	if not isDiving then
		if not active then
			if humanoid.SeatPart == nil then
				active = runservice.RenderStepped:Connect(function()
					EnableShiftlock()
				end)
			end
		else
			DisableShiftlock()
		end
	end
end)

script.Parent.Parent:WaitForChild("DisableShiftLock").Event:Connect(function(disable)
	--[[
	if disable then
		isDiving = true
		initiallyActive = active
		DisableShiftlock()
	else
		isDiving = false
		if not active and initiallyActive then
			active = runservice.RenderStepped:Connect(function()
				EnableShiftlock()
			end)
		end
	end
	--]]
	if ismobile then
		DisableShiftlock()
	end
end)

-- Disable Shift Lock when CameraType becomes Scriptable
workspace.CurrentCamera:GetPropertyChangedSignal("CameraType"):Connect(function()
	if ismobile and active and workspace.CurrentCamera.CameraType == Enum.CameraType.Scriptable then
		DisableShiftlock()
	end
end)

return MobileCameraFramework
