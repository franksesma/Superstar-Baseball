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

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart)
	-- Play VFX
	task.spawn(function()
		camPart.Parent.letterboxbot.Transparency = 1
		camPart.Parent.letterboxtop.Transparency = 1
		
		local VFX = script:WaitForChild("VFX")

		local TweenService = game:GetService("TweenService")
		local vfxFolder = workspace:WaitForChild("VFXFolder")

		local vfxBaseballTemplate = VFX:FindFirstChild("VFXBaseball")
		local baseballMotorTemplate = VFX:FindFirstChild("Baseball")
		local auraTemplate = VFX:FindFirstChild("Aura")
		local eyeVFXTemplate = VFX:FindFirstChild("EyeVFX")
		local impactSmokeTemplate = VFX:FindFirstChild("ImpactSmoke")

		local function tweenBoxTransparency(box, transparency, duration)
			local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

			for _, obj in ipairs(box:GetDescendants()) do
				if obj:IsA("BasePart") then
					TweenService:Create(obj, tweenInfo, {
						Transparency = transparency
					}):Play()
				end
			end
		end

		local function setParticleEmittersEnabled(instance, enabled, color)
			for _, obj in ipairs(instance:GetDescendants()) do
				if obj:IsA("ParticleEmitter") then
					if color then
						obj.Color = ColorSequence.new(color)
					end
					obj.Enabled = enabled
				end
			end
		end

		local function emitParticles(instance, color)
			for _, obj in ipairs(instance:GetDescendants()) do
				if obj:IsA("ParticleEmitter") then
					if color then
						obj.Color = ColorSequence.new(color)
					end

					local emitCount = obj:GetAttribute("EmitCount")
					if typeof(emitCount) == "number" then
						obj:Emit(emitCount)
					end
				end
			end
		end

		local function emitParticlesFixed(instance, amount, color)
			for _, obj in ipairs(instance:GetDescendants()) do
				if obj:IsA("ParticleEmitter") then
					if color then
						obj.Color = ColorSequence.new(color)
					end
					obj:Emit(amount)
				end
			end
		end

		local function getDeadeye()
			local head = char and char:FindFirstChild("Head")
			if not head then return nil end

			local eyeAttachment = head:FindFirstChild("EyeAttachment")
			if not eyeAttachment then return nil end

			return eyeAttachment:FindFirstChild("Deadeye")
		end

		local greenColor = Color3.fromRGB(79, 241, 90)

		-- Clone core VFX once
		local Box = VFX:WaitForChild("Box"):Clone()
		local HalfSphere = VFX:WaitForChild("HalfSphere"):Clone()
		local Shoot = VFX:WaitForChild("Shoot"):Clone()

		Box.Parent = vfxFolder
		HalfSphere.Parent = vfxFolder
		Shoot.Parent = vfxFolder

		-- Baseball weld/motor setup
		local humanoidRootPart = char and char:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart and vfxBaseballTemplate and baseballMotorTemplate then
			local fakeBaseball = vfxBaseballTemplate:Clone()
			fakeBaseball.Name = "Baseball"
			fakeBaseball.Parent = char

			local baseballMotor = baseballMotorTemplate:Clone()
			baseballMotor.Part0 = humanoidRootPart
			baseballMotor.Part1 = fakeBaseball
			baseballMotor.Parent = humanoidRootPart
		end

		-- Start aura
		if auraTemplate and eyeVFXTemplate then
			CinematicUtils.PlayCharacterAura(char, auraTemplate, eyeVFXTemplate, 15)
		end

		-- Box fade in / out
		task.delay(0.5, function()
			--CinematicUtils.PlayAudioSound("GravitySound")
			tweenBoxTransparency(Box, 0, 2)

			task.delay(3.08, function()
				tweenBoxTransparency(Box, 1, 1.64)
			end)
		end)

		-- Box particles
		task.delay(1.03, function()
			setParticleEmittersEnabled(Box, true, greenColor)

			task.delay(3.54, function()
				setParticleEmittersEnabled(Box, false)
			end)
		end)

		-- HalfSphere burst
		task.delay(5, function()
			CinematicUtils.PlayAudioSound("SlowMotion")

			task.delay(5.30, function()
				emitParticlesFixed(HalfSphere, 1, greenColor)
			end)
		end)

		-- Shoot burst
		task.delay(13, function()
			CinematicUtils.PlayAudioSound("Swoosh")

			task.delay(1.11, function()
				emitParticles(Shoot)
				CinematicUtils.HitImpactEffects(impactSmokeTemplate, char)
				CinematicUtils.PlayAudioSound("FireLaunch")
			end)
		end)

		-- Eye effect
		task.delay(3.24, function()
			local deadeye = getDeadeye()
			if deadeye then
				deadeye.Enabled = true
			end

			task.delay(7.29, function()
				local laterDeadeye = getDeadeye()
				if laterDeadeye then
					laterDeadeye.Enabled = false
				end
			end)
		end)
	end)
end

return animPlayer