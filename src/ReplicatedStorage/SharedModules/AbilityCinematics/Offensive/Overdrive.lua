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
		task.wait(0.27)
		CinematicUtils.PlayAudioSound("Electric")
		CinematicUtils.PlayCharacterAura(char, script.VFX.Aura, script.VFX.EyeVFX, 4.5)
		local torsoElectricity = script.VFX.EletricAura.TorsoElecricity:Clone()
		local rightLowerLegElectricity = script.VFX.EletricAura.RightLowerLeg:Clone()
		local batVFX = script.VFX.BaseballBatAuraAttach.P0:Clone()
		local dustArea = script.VFX.DustArea:Clone()
		local hitEffects = script.VFX.Hit:Clone()

		if char and char:FindFirstChild("UpperTorso") then
			torsoElectricity.Parent = char.UpperTorso
		end

		if char and char:FindFirstChild("RightLowerLeg") then
			rightLowerLegElectricity.Parent = char.RightLowerLeg
		end

		if char and char:FindFirstChild("PlayerBat") and char.PlayerBat:FindFirstChild("Handle") then
			batVFX.Parent = char.PlayerBat.Handle
		end

		task.wait(2.84)

		dustArea.Parent = workspace.VFXFolder

		for _, particle in pairs(dustArea:GetDescendants()) do
			if particle:IsA("ParticleEmitter") or particle:IsA("Beam") then
				particle.Enabled = true
			end
		end

		CinematicUtils.PlayAudioSound("ElectricSpin")
		if char and char:FindFirstChild("UpperTorso") then
			local tpEffect = script.VFX.Tp:Clone()
			tpEffect.Parent = workspace.VFXFolder
			tpEffect.Weld.Part0 = char.UpperTorso
			tpEffect.Weld.Part1 = tpEffect

			for i = 1, 16 do
				CinematicUtils.EmitParticle(tpEffect)
				task.wait(.2)
			end
		end

		for _, particle in pairs(dustArea:GetDescendants()) do
			if particle:IsA("ParticleEmitter") or particle:IsA("Beam") then
				particle.Enabled = false
			end
		end

		task.wait(0.25)

		local beams = script.VFX.Beams:Clone()
		beams.Parent = workspace.VFXFolder

		for _, particle in pairs(beams:GetDescendants()) do
			if particle:IsA("Beam") then
				particle.Enabled = true
			end
		end

		task.wait(1)

		for _, particle in pairs(beams:GetDescendants()) do
			if particle:IsA("Beam") then
				particle.Enabled = false
			end
		end

		hitEffects.Parent = workspace.VFXFolder
		CinematicUtils.EmitParticle(hitEffects)
		CinematicUtils.PlayAudioSound("FireLaunch")

		task.wait(0.5)

		if torsoElectricity then
			torsoElectricity:Destroy()
		end

		if rightLowerLegElectricity then
			rightLowerLegElectricity:Destroy()
		end
	end)
end

return animPlayer