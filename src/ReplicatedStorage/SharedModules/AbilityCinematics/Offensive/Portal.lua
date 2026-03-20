local animPlayer = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local SharedObjects = ReplicatedStorage.SharedObjects
local SharedModules = ReplicatedStorage.SharedModules
local AbilityFolder = ReplicatedStorage.Abilities

local CinematicUtils = require(SharedModules.AbilityCinematics.CinematicUtils)
local ClientVFXHandler = require(SharedModules.ClientVFXHandler)
local ClientFunctions = require(SharedModules.ClientFunctions)

local humAnim = script:WaitForChild("Hum")
local camAnim = script:WaitForChild("Cam")

animPlayer.camRig = SharedObjects:WaitForChild("CameraRig2")
animPlayer.requiresCinematicFrame = true
animPlayer.facePitcherMound = true
animPlayer.fieldOfView = 70

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart)
	-- Play VFX
	task.spawn(function()
		task.wait(0.4)
		CinematicUtils.PlayCharacterAura(char, script.VFX.Aura, script.VFX.EyeVFX, 4.2)
		task.wait(1.8)
		CinematicUtils.PlayAudioSound("PortalAppear")
		task.wait(0.4)
		CinematicUtils.PlayImpactBeam(script.VFX.ImpactBeam, 1.7)
		CinematicUtils.PlayCameraBarVFX(script.VFX.PortalBars, camPart, 1.7)
		
		local portal = script.VFX.Portal:Clone()
		portal.Parent = workspace.VFXFolder
		for _, obj in pairs(portal:GetDescendants()) do
			if obj:IsA("ParticleEmitter") then
				obj.Enabled = true
			end
		end
		
		wait(1.05)
		local baseballVFXCframe = CFrame.new(-0.75, -2.75, 0) * CFrame.Angles(0, math.rad(180), 0)
		CinematicUtils.PlayBaseballImpact(script.VFX.BaseballVFX, char, baseballVFXCframe)
		wait(0.45)
		if workspace.VFXFolder:FindFirstChild("BaseballVFX") then
			workspace.VFXFolder.BaseballVFX:Destroy()
		end
		CinematicUtils.HitImpactEffects(script.VFX.ImpactSmoke, char)
		CinematicUtils.PlayAudioSound("FireLaunch")
		CinematicUtils.PlayAudioSound("PortalDisappear")
		CinematicUtils.ShrinkParticles(portal, 1)
	end)
end

return animPlayer