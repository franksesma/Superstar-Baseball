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
		CinematicUtils.PlayCharacterAura(char, script.VFX.Aura, script.VFX.EyeVFX, 5.3)
		wait(1.75)
		CinematicUtils.PlayTornadoVFX(script.VFX.Tornado, char)
		CinematicUtils.PlayAudioSound("Tornado")
		wait(1.9)
		local baseballVFXCframe = CFrame.new(-0.75, -2.75, 0) * CFrame.Angles(0, math.rad(180), 0)
		CinematicUtils.PlayBaseballImpact(script.VFX.BaseballVFX, char, baseballVFXCframe)
		wait(0.7)
		if workspace.VFXFolder:FindFirstChild("BaseballVFX") then
			workspace.VFXFolder.BaseballVFX:Destroy()
		end
		CinematicUtils.HitImpactEffects(script.VFX.ImpactSmoke, char)
		CinematicUtils.PlayAudioSound("FireLaunch")
	end)
end

return animPlayer