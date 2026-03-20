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

animPlayer.camRig = SharedObjects:WaitForChild("CameraRig4")
animPlayer.customCamPivot = animPlayer.camRig.PrimaryPart.CFrame
animPlayer.requiresCinematicFrame = true
animPlayer.faceHomePlate = true
animPlayer.CustomFixedPos = Vector3.new(-127.807, 5.9, 87.285)
animPlayer.fieldOfView = 70
animPlayer.adjustSpeed = 1.6667

-- Half all waits/delays/timings
local TIME_SCALE = 0.6

local function waitScaled(t)
	if t == nil then
		return task.wait()
	end
	return task.wait(t * TIME_SCALE)
end

local function delayScaled(t, fn)
	return task.delay((t or 0) * TIME_SCALE, fn)
end

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart, camTrack, humTrack)
	-- Play VFX
	task.spawn(function()
		local decoration = script.VFX.decoration:Clone()
		decoration.Parent = workspace.VFXFolder
		local beam = script.VFX["beam "]:Clone()
		beam.Parent = workspace.VFXFolder
		local sandsVfx = script.VFX["SANDS VFX"]:Clone()
		sandsVfx.Parent = workspace.VFXFolder
		local sandsMao = script.VFX["sand mao"]:Clone()
		sandsMao.Parent = workspace.VFXFolder
		local sand = script.VFX.sand:Clone()
		sand.Parent = workspace.VFXFolder
		local explosionStar = script.VFX["alt exploson star"]:Clone()
		explosionStar.Parent = workspace.VFXFolder
		local EyesParticle = script.VFX.Eyes
		local TorsoParticle = script.VFX.AuraTorso.Torso
		local PartWithParticle = script.VFX.Aura

		local ParticleAdded = {}
		local Timer = 1.02 * TIME_SCALE

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

			-- Timer already scaled, so plain task.delay is fine
			task.delay(Timer, removeParticle)
		end

		CinematicUtils.PlayAudioSound("Blizzard")

		waitScaled(0.09)

		CinematicUtils.Emit(decoration)
		CinematicUtils.Emit(decoration)

		waitScaled(1.45)

		CinematicUtils.Emit(beam)

		waitScaled(1.85)

		CinematicUtils.Emit(sandsVfx.sand)

		waitScaled(2.1)

		CinematicUtils.PlayAudioSound("SandPickup")
		CinematicUtils.Emit(sandsMao)

		waitScaled(2.6)
		CinematicUtils.PlayAudioSound("Blizzard")
		--eyes

		waitScaled(1.05)

		-- power up vfx

		waitScaled(2.04)

		CinematicUtils.Emit(sand)
		CinematicUtils.PlayAudioSound("SandKick")

		waitScaled(1.85)

		CinematicUtils.Emit(explosionStar)
		CinematicUtils.PlayAudioSound("FireIgnite")

		waitScaled(0.35)

		removeParticle()
		addParticle()

		local TweenService = game:GetService("TweenService")
		local Lighting = game:GetService("Lighting")
		local Workspace = game:GetService("Workspace")
		local RunService = game:GetService("RunService")

		-- === CONFIGURAÇÕES DE BELEZA ===
		local settings = {
			buildUpTime = 0.45 * TIME_SCALE,    -- Tempo de "inspiração" (escurecendo)
			impactTime = 0.8 * TIME_SCALE,      -- Tempo de "expiração" (explosão e fade)

			-- Cores
			mainColor = Color3.fromRGB(0, 190, 255), -- Azul Ciano Elétrico
			secondaryColor = Color3.fromRGB(80, 100, 255), -- Azul meio roxo

			-- Intensidades
			shakeIntensity = 1.2,  -- Tremida forte
			bloomIntensity = 2.5,  -- Brilho suave
			sunRayIntensity = 0.6, -- Raios de luz
		}

		-- ====================================================================
		--                       ALVO: PITCHER NA PASTA ULT
		-- ====================================================================

		-- Tenta encontrar a pasta ULT e depois o pitcher
		local targetChar = char
		local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

		if not targetChar then
			return
		end

		-- ====================================================================
		--                       PREPARAÇÃO DOS EFEITOS (SETUP)
		-- ====================================================================

		local effectsFolder = Instance.new("Folder")
		effectsFolder.Name = "ImpactVFX_Temp"
		effectsFolder.Parent = Lighting

		-- 1. Bloom (Faz brilhar bonito)
		local bloom = Instance.new("BloomEffect")
		bloom.Intensity = 0
		bloom.Size = 30 
		bloom.Threshold = 0.8
		bloom.Parent = effectsFolder

		-- 2. SunRays (Raios de Deus)
		local sunRays = Instance.new("SunRaysEffect")
		sunRays.Intensity = 0
		sunRays.Spread = 0.8
		sunRays.Parent = effectsFolder

		-- 3. Blur (Desfoque de movimento)
		local blur = Instance.new("BlurEffect")
		blur.Size = 0
		blur.Parent = effectsFolder

		-- 4. ColorCorrection (Contraste)
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Parent = effectsFolder

		-- ====================================================================
		--                       FUNÇÕES AUXILIARES
		-- ====================================================================

		-- Função para criar Partículas no Peito do Pitcher
		local function spawnParticles(rootPart)
			if not rootPart then return end

			local attachment = Instance.new("Attachment")
			attachment.Parent = rootPart

			-- Partícula 1: Onda de Choque (Anel)
			local shockwave = Instance.new("ParticleEmitter")
			shockwave.Texture = "rbxassetid://292289455" -- Textura de anel/onda
			shockwave.Color = ColorSequence.new(settings.mainColor)
			shockwave.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 15)} -- Cresce muito
			shockwave.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}
			shockwave.Lifetime = NumberRange.new(0.3)
			shockwave.Rate = 0
			shockwave.Speed = NumberRange.new(0)
			shockwave.Rotation = NumberRange.new(0, 360)
			shockwave.Orientation = Enum.ParticleOrientation.VelocityParallel
			shockwave.Parent = attachment

			-- Partícula 2: Faíscas Rápidas
			local sparks = Instance.new("ParticleEmitter")
			sparks.Texture = "rbxassetid://243663153" -- Faísca
			sparks.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), 
				ColorSequenceKeypoint.new(1, settings.secondaryColor)
			}
			sparks.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)}
			sparks.Lifetime = NumberRange.new(0.4, 0.7)
			sparks.Rate = 0
			sparks.Speed = NumberRange.new(30, 50) -- Explosão rápida
			sparks.SpreadAngle = Vector2.new(180, 180) -- Para todo lado
			sparks.Drag = 5 
			sparks.Parent = attachment

			-- Emitir explosão
			shockwave:Emit(2) -- 2 ondas de choque
			sparks:Emit(35)   -- 35 faíscas

			delayScaled(1, function()
				attachment:Destroy()
			end)
		end

		-- ====================================================================
		--                       SEQUÊNCIA DE ANIMAÇÃO
		-- ====================================================================

		-- >>> FASE 1: PREPARAÇÃO (Dark Mode) <<<
		local buildUpInfo = TweenInfo.new(settings.buildUpTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

		-- Escurecer o mundo
		TweenService:Create(cc, buildUpInfo, {
			Brightness = -0.3,
			Contrast = 0.4,
			Saturation = -1,
			TintColor = Color3.fromRGB(150, 150, 200)
		}):Play()

		-- Highlight no Pitcher (aparece como um fantasma)
		local highlight = nil
		if targetChar then
			highlight = Instance.new("Highlight")
			highlight.Parent = targetChar
			highlight.FillColor = settings.mainColor
			highlight.OutlineColor = Color3.new(1,1,1)
			highlight.FillTransparency = 1
			highlight.OutlineTransparency = 1

			TweenService:Create(highlight, buildUpInfo, {
				FillTransparency = 0.5,
				OutlineTransparency = 0.2
			}):Play()
		end

		waitScaled(settings.buildUpTime) -- Espera o momento do chute...

		-- >>> FASE 2: O IMPACTO (BOOM!) <<<

		-- Efeitos de tela explosivos
		cc.Brightness = 0.8
		cc.Contrast = 0.3
		cc.Saturation = 0.2
		cc.TintColor = settings.mainColor

		bloom.Intensity = settings.bloomIntensity
		sunRays.Intensity = settings.sunRayIntensity
		blur.Size = 18

		-- Física e Partículas
		spawnParticles(targetRoot) -- Partículas saem do pitcher

		-- Zoom Punch da Câmera
		local camera = Workspace.CurrentCamera
		local baseFOV = camera.FieldOfView
		camera.FieldOfView = baseFOV - 6
		TweenService:Create(camera, TweenInfo.new(settings.impactTime, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
			FieldOfView = baseFOV
		}):Play()

		-- >>> FASE 3: VOLTAR AO NORMAL (Fade Out) <<<
		local fadeInfo = TweenInfo.new(settings.impactTime, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

		TweenService:Create(cc, fadeInfo, {
			Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1,1,1)
		}):Play()

		TweenService:Create(bloom, fadeInfo, { Intensity = 0 }):Play()
		TweenService:Create(sunRays, fadeInfo, { Intensity = 0 }):Play()
		TweenService:Create(blur, fadeInfo, { Size = 0 }):Play()

		if highlight then
			TweenService:Create(highlight, fadeInfo, {
				FillTransparency = 1, OutlineTransparency = 1
			}):Play()
		end

		-- Limpeza total
		delayScaled(settings.impactTime + 0.5, function()
			effectsFolder:Destroy()
			if highlight then highlight:Destroy() end
		end)

		waitScaled(1.5)

		CinematicUtils.PlayAudioSound("LongThrowSound")
	end)
end

return animPlayer
