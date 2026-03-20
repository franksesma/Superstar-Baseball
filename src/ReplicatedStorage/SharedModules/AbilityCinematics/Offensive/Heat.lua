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
		task.wait(0.1)
		CinematicUtils.PlayCharacterAura(char, script.VFX.Aura, script.VFX.EyeVFX, 4.5)
		CinematicUtils.PlayAudioSound("HeatingUp")
		task.wait(1.9)
		CinematicUtils.PlayImpactBeam(script.VFX.ImpactBeam, 1.5)
		CinematicUtils.PlayCameraBarVFX(script.VFX.FireBars, camPart, 1.5)
		task.wait(0.3)
		local baseballVFXCframe = CFrame.new(-0.75, -2.75, 0) * CFrame.Angles(0, math.rad(180), 0)
		CinematicUtils.PlayBaseballImpact(script.VFX.BaseballVFX, char, baseballVFXCframe)
		CinematicUtils.PlayAudioSound("FireSplash")
		wait(1.2)
		CinematicUtils.HitImpactEffects(script.VFX.ImpactSmoke, char)
		CinematicUtils.PlayAudioSound("FireLaunch")
	end)
end

return animPlayer