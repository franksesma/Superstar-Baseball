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

animPlayer.camRig = SharedObjects:WaitForChild("CameraRig3")
animPlayer.requiresCinematicFrame = true
animPlayer.faceHomePlate = true
animPlayer.fieldOfView = 30

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart)
	-- Play VFX
	task.spawn(function()
		task.wait(0.1)

		-- Aura build-up + Eye glow
		CinematicUtils.PlayCharacterAura(char, script.VFX.GreenAura, script.VFX.EyeVFX, 5)
		CinematicUtils.PlayAudioSound("WhirlwindCharge") -- wind rising SFX

		task.wait(0.8)

		-- Tornado spirals around pitcher
		CinematicUtils.PlayTornadoVFX(script.VFX.Tornado, char)
		CinematicUtils.PlayAudioSound("TornadoWhoosh") -- swirling wind SFX

		task.wait(0.6)

		-- Stronger secondary tornado for emphasis
		CinematicUtils.PlayTornadoVFX(script.VFX.Tornado2, char)

		task.wait(0.7)

		-- Dramatic pitch wind-up moment (like a pressure build)
		--CinematicUtils.PlayImpactBeam(script.VFX.BaseballVFX, 1.5) -- this acts as a wind vortex around the ball
		CinematicUtils.PlayAudioSound("WhirlwindPulse")

		task.wait(0.4)

		-- Optional: Rumble ground before pitch
		CinematicUtils.RumbleGround(char.HumanoidRootPart.Position)

		-- Launch audio cue (happens during actual pitch throw)
		CinematicUtils.PlayAudioSound("WhirlwindPitchLaunch")

		task.wait(1)

		-- Optional smoke burst at end of animation
		CinematicUtils.HitImpactEffects(script.VFX.ImpactSmoke)
	end)
end

return animPlayer