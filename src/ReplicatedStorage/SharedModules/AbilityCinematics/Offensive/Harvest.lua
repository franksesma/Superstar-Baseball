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
		if not char or not char.Parent then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local VFX = script:FindFirstChild("VFX")
		if not VFX then return end


		local function safeClone(name)
			local obj = VFX:FindFirstChild(name)
			if obj then
				local clone = obj:Clone()
				if clone then
					clone.Parent = workspace:FindFirstChild("VFXFolder") or workspace
					return clone
				end
			end
			return nil
		end

		local baseballVFX = safeClone("Baseball")
		local baseballMotor6D = safeClone("BaseballMotor6D")
		if baseballMotor6D and hrp and baseballVFX then
			baseballMotor6D.Parent = hrp
			baseballMotor6D.Part0 = hrp
			baseballMotor6D.Part1 = baseballVFX
		end

		local flowerVFX = safeClone("Flower")
		local hungryVFX = safeClone("Hungry")
		local hungry2VFX = safeClone("Hungry2")
		local waypoints = safeClone("WayPoints")
		local impactVFX = safeClone("ImpactVfx")
		local starVFX = safeClone("Star")

		if flowerVFX then
			CinematicUtils.Emit(flowerVFX)
		end

		local AuraBat = VFX:FindFirstChild("AuraBat") and VFX.AuraBat:FindFirstChild("P0")
		local Aura = VFX:FindFirstChild("Aura") and VFX.Aura:FindFirstChild("P0")

		local particleObjects = {}
		local PARTICLE_LIFETIME = 14.44

		local function cleanupParticles()
			for _, obj in ipairs(particleObjects) do
				if obj and obj.Parent then
					obj:Destroy()
				end
			end
			table.clear(particleObjects)
		end

		local function addAuraParticles()
			if not char or not char.Parent then return end

			if Aura then
				local auraClone = Aura:Clone()
				auraClone.Parent = char:FindFirstChild("UpperTorso")
				table.insert(particleObjects, auraClone)
			end

			if AuraBat and char:FindFirstChild("PlayerBat") and char.PlayerBat:FindFirstChild("Handle") then
				local auraBatClone = AuraBat:Clone()
				auraBatClone.Parent = char.PlayerBat.Handle
				table.insert(particleObjects, auraBatClone)
			end

			task.delay(PARTICLE_LIFETIME, cleanupParticles)
		end

		addAuraParticles()

		task.wait(2.03)
		if hungryVFX then CinematicUtils.Emit(hungryVFX) end

		CinematicUtils.PlayAudioSound("Hungry")

		task.wait(4.1)
		if hungry2VFX then CinematicUtils.Emit(hungry2VFX) end

		CinematicUtils.PlayAudioSound("Eating")

		task.wait(1.22)
		if waypoints and waypoints:FindFirstChild("WayPoint1") then CinematicUtils.Emit(waypoints.WayPoint1) end
		CinematicUtils.PlayAudioSound("DirtFootstep")
		task.wait(0.77)
		if waypoints and waypoints:FindFirstChild("WayPoint2") then CinematicUtils.Emit(waypoints.WayPoint2) end
		CinematicUtils.PlayAudioSound("DirtFootstep")
		task.wait(0.43)
		if waypoints and waypoints:FindFirstChild("WayPoint3") then CinematicUtils.Emit(waypoints.WayPoint3) end
		CinematicUtils.PlayAudioSound("DirtFootstep")
		task.wait(0.82)
		if waypoints and waypoints:FindFirstChild("WayPoint4") then CinematicUtils.Emit(waypoints.WayPoint4) end
		CinematicUtils.PlayAudioSound("DirtFootstep")
		task.wait(0.72)
		if waypoints and waypoints:FindFirstChild("WayPoint5") then CinematicUtils.Emit(waypoints.WayPoint5) end
		CinematicUtils.PlayAudioSound("DirtFootstep")
		task.wait(0.37)

		local telaPart = VFX:FindFirstChild("Tela")
		if telaPart and camPart and camPart.Parent then
			local ParticleAdded2 = {}
			local function cleanup2()
				for _, p in ipairs(ParticleAdded2) do
					if p and p.Parent then p:Destroy() end
				end
				table.clear(ParticleAdded2)
			end

			for _, att in ipairs(telaPart:GetChildren()) do
				local clone = att:Clone()
				if clone then
					clone.Parent = camPart
					table.insert(ParticleAdded2, clone)
				end
			end

			task.delay(1.6, cleanup2)
		end

		cleanupParticles()
		addAuraParticles()

		task.wait(1.86)
		if baseballVFX then 
			CinematicUtils.Emit(baseballVFX) 
		end
		CinematicUtils.PlayAudioSound("FireSplash")

		task.wait(0.91)
		if impactVFX then CinematicUtils.Emit(impactVFX) end
		if starVFX then CinematicUtils.Emit(starVFX) end
		CinematicUtils.PlayAudioSound("FireLaunch")

		task.wait(2)

		-- Cleanup all VFX safely
		for _, v in ipairs({baseballVFX, baseballMotor6D, flowerVFX, hungryVFX, hungry2VFX, waypoints, impactVFX, starVFX}) do
			if v and v.Parent then
				v:Destroy()
			end
		end

		cleanupParticles()
	end)
end

return animPlayer