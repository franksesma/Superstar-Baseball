local animPlayer = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local ContentProvider = game:GetService("ContentProvider")

local SharedObjects = ReplicatedStorage.SharedObjects
local SharedModules = ReplicatedStorage.SharedModules
local AbilityFolder = ReplicatedStorage.Abilities

local CinematicUtils = require(SharedModules.AbilityCinematics.CinematicUtils)
local ClientVFXHandler = require(SharedModules.ClientVFXHandler)
local ClientFunctions = require(SharedModules.ClientFunctions)

local humAnim = script:WaitForChild("Hum")
local camAnim = script:WaitForChild("Cam")

animPlayer.camRig = SharedObjects:WaitForChild("CameraRig3")
animPlayer.requiresCinematicFrame = true
animPlayer.faceHomePlate = true
animPlayer.fieldOfView = 50

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart)
	task.spawn(function()
		local hrp = char:FindFirstChild("HumanoidRootPart")
		
		task.wait(0.2)

		-- Slam 1
		CinematicUtils.RumbleGround(hrp.Position)
		CinematicUtils.PlayAudioSound("SeismicSlam1")
		CinematicUtils.PlayImpactFrame()
		ClientVFXHandler.CameraShake(0.5, 2)

		local burst1 = script.VFX.ImpactSmoke:Clone()
		burst1.Parent = workspace.VFXFolder
		burst1:PivotTo(hrp.CFrame)
		CinematicUtils.PlayParticlesInPart(burst1, 80, 0, 2)
		CinematicUtils.PlayAudioSound("Quake")
		Debris:AddItem(burst1, 3)

		task.wait(0.6)

		-- Slam 2 (stronger)
		CinematicUtils.RumbleGround(hrp.Position)
		CinematicUtils.PlayAudioSound("SeismicSlam1")
		CinematicUtils.PlayImpactFrame()
		ClientVFXHandler.CameraShake(0.5, 2)

		local burst2 = script.VFX.ImpactSmoke:Clone()
		burst2.Parent = workspace.VFXFolder
		burst2:PivotTo(hrp.CFrame)
		CinematicUtils.PlayParticlesInPart(burst2, 80, 0, 2)
		CinematicUtils.PlayAudioSound("Quake")
		Debris:AddItem(burst2, 3)

		task.wait(0.8)

		-- Lift-off
		local tornado = script.VFX.Tornado:Clone()
		tornado.Parent = workspace.VFXFolder

		local weld = Instance.new("Weld")
		weld.Part0 = tornado
		weld.Part1 = hrp
		weld.C1 = CFrame.new(0, -3, 0)
		weld.Parent = tornado

		CinematicUtils.PlayParticlesInPart(tornado)
		CinematicUtils.PlayAudioSound("SeismicLiftOff")

		task.wait(1.2)

		-- ⚡ Final ThrowPop
		local rightHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
		if rightHand then
			local throwPop = script.VFX.ThrowPop:Clone()
			throwPop.Parent = workspace.VFXFolder
			CinematicUtils.PlayAttachmentModelOnPart(throwPop, rightHand, 60, 0, 2)
			--CinematicUtils.PlayAudioSound("PortalAppear")
		end
		
		task.wait(1.4)
		
		local burst3 = script.VFX.ImpactSmoke:Clone()
		burst3.Parent = workspace.VFXFolder
		burst3:PivotTo(rightHand.CFrame)
		CinematicUtils.PlayParticlesInPart(burst3, 80, 0, 2)
		--CinematicUtils.PlayAudioSound("Quake")
		Debris:AddItem(burst3, 3)
		
		CinematicUtils.PlayAudioSound("SeismicBlast")
	end)
end

return animPlayer
