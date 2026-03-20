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
		wait(0.1)
		CinematicUtils.PlayCharacterAura(char, script.VFX.Aura, script.VFX.EyeVFX, 4.5)
		wait(4)
		local vfxCFrame = CFrame.new(0, -2.75, 0) --* CFrame.Angles(0, math.rad(180), 0)
		CinematicUtils.PlayBatChargeVFX(script.VFX.BatVFX, char, vfxCFrame)
		
		wait(1.5)
		local impactPink = script.VFX.ImpactPink:Clone()
		impactPink.Parent = workspace.VFXFolder
		for _, particle in pairs(impactPink:GetDescendants()) do
			if particle:IsA("ParticleEmitter") then
				local emitCount = particle:GetAttribute("EmitCount")
				local emitDelay = particle:GetAttribute("EmitDelay") or 0
				local emitDuration = particle:GetAttribute("EmitDuration")

				task.delay(emitDelay, function()
					if emitCount then
						particle:Emit(emitCount)
					end
					if emitDuration then
						particle.Enabled = true
						task.delay(emitDuration, function()
							particle.Enabled = false
						end)
					end
				end)
			end
		end
		
		CinematicUtils.HitImpactEffects(script.VFX.ImpactSmoke, char)
		CinematicUtils.PlayAudioSound("FireLaunch")
	end)
end

return animPlayer