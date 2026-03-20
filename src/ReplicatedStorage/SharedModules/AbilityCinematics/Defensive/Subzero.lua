local animPlayer = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
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
animPlayer.faceHomePlate = false
animPlayer.fieldOfView = 70

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart)
	task.spawn(function()
		local vfx = script:FindFirstChild("VFX")
		if not vfx then return end

		task.spawn(function()
			if not workspace.CurrentCamera then return end
			local fovFolder = vfx:FindFirstChild("FOV")
			if not fovFolder then return end

			local frames = fovFolder:GetChildren()
			if #frames == 0 then return end

			table.sort(frames, function(a, b)
				return tonumber(a.Name) < tonumber(b.Name)
			end)

			for _, frame in ipairs(frames) do
				print("Ran")
				if frame:IsA("NumberValue") then
					workspace.CurrentCamera.FieldOfView = frame.Value
				end
				task.wait(.01)
			end

			workspace.CurrentCamera.FieldOfView = 70
		end)

		local Snowball = vfx.Snowball:Clone()
		local SnowballMotor6D = vfx.SnowballMotor6D:Clone()
		local Wind = vfx.Wind:Clone()
		local ScreenEffect = vfx.ScreenEffect:Clone()
		local BlizzardEffect = vfx.BlizzardEffect:Clone()
		local PartWithParticle = vfx.Aura
		local EyesParticle = vfx.Eyes
		local TorsoParticle = vfx.AuraTorso.Torso

		SnowballMotor6D.Name = "Snowball"
		SnowballMotor6D.Parent = char.HumanoidRootPart
		SnowballMotor6D.Part0 = char.HumanoidRootPart
		SnowballMotor6D.Part1 = Snowball
		Snowball.Parent = char
		Wind.Parent = workspace.VFXFolder
		BlizzardEffect.Parent = workspace.VFXFolder
		ScreenEffect.Parent = workspace.VFXFolder

		local ParticleAdded = {}
		local Timer = 11.12

		local function removeParticle()
			for i = #ParticleAdded, 1, -1 do
				local particle = ParticleAdded[i]
				particle:Destroy()
				table.remove(ParticleAdded, i)
			end
		end

		local function addParticle()
			for _, Part in pairs(char:GetChildren()) do
				if Part:IsA("MeshPart") then
					for _, Particle in pairs(PartWithParticle:GetDescendants()) do
						if Particle:IsA("ParticleEmitter") then
							local particleClone = Particle:Clone()
							particleClone.Parent = Part
							table.insert(ParticleAdded, particleClone)
						end
					end
				end
			end
			local attclone = EyesParticle.A:Clone()
			attclone.Parent = char.Head
			table.insert(ParticleAdded, attclone)
			local attclone2 = EyesParticle.B:Clone()
			attclone2.Parent = char.Head
			table.insert(ParticleAdded, attclone2)
			local attclone3 = TorsoParticle:Clone()
			attclone3.Parent = char.UpperTorso
			table.insert(ParticleAdded, attclone3)
			task.delay(Timer, removeParticle)
		end

		CinematicUtils.PlayAudioSound("Blizzard")
		removeParticle()
		addParticle()
		CinematicUtils.Emit(Snowball)

		task.wait(4.23)

		CinematicUtils.Emit(Wind)

		task.wait(1.08)

		CinematicUtils.Emit(Wind)

		task.wait(2.02)

		local ScreenEffectP0 = ScreenEffect.P0
		ScreenEffectP0.Parent = camPart
		local ScreenEffectP1 = ScreenEffect.P1
		ScreenEffectP1.Parent = camPart
		local SnowSpec = vfx.ScreenEffect.SnowSpec:Clone()
		SnowSpec.Parent = camPart
		CinematicUtils.PlayAudioSound("IceImpact")

		task.wait(1.83)

		ScreenEffectP0:Destroy()
		ScreenEffectP1:Destroy()
		SnowSpec:Destroy()

		CinematicUtils.Emit(Snowball.Impact)
		CinematicUtils.PlayAudioSound("FireLaunch")

		task.wait(2.33)

		Snowball:Destroy()
		SnowballMotor6D:Destroy()
	end)
end

return animPlayer
