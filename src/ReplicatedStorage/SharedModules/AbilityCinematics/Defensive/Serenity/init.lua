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
animPlayer.fieldOfView = 50

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart)
	-- Play VFX
	task.spawn(function()
		task.wait(0.1)

		-- 🌿 Aura + Eye Glow
		CinematicUtils.PlayCharacterAura(char, script.VFX.GreenAura, script.VFX.EyeVFX, 6)
		CinematicUtils.PlayAudioSound("SerenityAura")

		-- 🌸 Stronger Flower Burst
		local flower = script.VFX.Flower:Clone()
		flower.Parent = char.HumanoidRootPart
		if flower:FindFirstChildOfClass("ParticleEmitter") then
			flower:FindFirstChildOfClass("ParticleEmitter"):Emit(50) -- Stronger
		end
		game:GetService("Debris"):AddItem(flower, 3)

		task.wait(2)
		CinematicUtils.PlayAudioSound("Swoosh")
		task.wait(1)
		-- 💥 ThrowForcefield on body parts
		local limbs = {}
		for _, part in ipairs(char:GetChildren()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				table.insert(limbs, part)
			end
		end

		for i = 1, 8 do
			local limb = limbs[math.random(1, #limbs)]
			local burst = script.VFX.ThrowForcefield.Main:Clone()
			burst.Parent = limb
			CinematicUtils.PlayParticlesInPart(burst)
			game:GetService("Debris"):AddItem(burst, 2)
			CinematicUtils.PlayAudioSound("PulseEffect")
			CinematicUtils.PlayImpactFrame()
			task.wait(0.1)
		end

		--CinematicUtils.PlayAudioSound("PulseEffect")
		
		ClientVFXHandler.CameraShake(0.4, 2)
		CinematicUtils.PlayAudioSound("LongThrowSound")

		task.wait(1)

		-- 🌼 Final Bloom Garden Effect
		local garden = script.VFX.Garden:Clone()
		garden.Parent = workspace.VFXFolder
		
		local bloomScript = garden:FindFirstChild("Script")
		if bloomScript then
			bloomScript.Disabled = false
		end
		
		CinematicUtils.PlayImpactFrame()
		local rightHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
		if rightHand then
			print ("HERE")
			local throwPop = script.VFX.ThrowPop:Clone()
			throwPop.Parent = rightHand

			for _, emitter in throwPop:GetDescendants() do
				if emitter:IsA("ParticleEmitter") then
					emitter:Emit(50) -- force emit regardless of attributes
				end
			end

			game:GetService("Debris"):AddItem(throwPop, 2)
		end
	end)
end

return animPlayer