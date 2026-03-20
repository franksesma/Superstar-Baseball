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
animPlayer.facePitcherMound = false
animPlayer.fieldOfView = 70

local camRig = SharedObjects:WaitForChild("CameraRig2") -- Change rig depending on anim creator... smh

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart)
	-- Play VFX
	task.spawn(function()
		wait(0.1)
		CinematicUtils.PlayCharacterAura(char, script.VFX.Aura, script.VFX.EyeVFX, 4.5)
		wait(1.8)
		CinematicUtils.PlayCameraBarVFX(script.VFX.ElasticBars, camPart, 2)
		script.VFX.GroundVFX:Clone().Parent = workspace.VFXFolder
		CinematicUtils.PlayAudioSound("RockSmash")
		wait(0.8)
		
		wait(1.4)
		CinematicUtils.HitImpactEffects(script.VFX.ImpactSmoke, char)
		CinematicUtils.PlayAudioSound("FireLaunch")
	end)
end

return animPlayer