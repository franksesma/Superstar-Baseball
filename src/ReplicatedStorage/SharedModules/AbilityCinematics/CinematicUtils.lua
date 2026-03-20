local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


local SharedModules = ReplicatedStorage.SharedModules
local ClientFunctions = require(SharedModules.ClientFunctions)
local Remotes = ReplicatedStorage.RemoteEvents
local SoundEffects = script.SoundEffects

local module = {}

local LocalPlayer = Players.LocalPlayer

function module.PlayAudioSound(soundName)
	if SoundEffects:FindFirstChild(soundName) then
		SoundEffects[soundName]:Play()
	end
end

function module.SafeLoadAnimation(animator, anim, retries, waitTime)
	retries = retries or 3
	waitTime = waitTime or 0.2

	local track
	for i = 1, retries do
		track = animator:LoadAnimation(anim)
		if track.Length > 0 then
			return track
		end
		task.wait(waitTime)
	end
	return track
end

function module.WaitForAnimTrack(track, timeout)
	local start = tick()

	while track.Length == 0 and tick() - start < (timeout or 3) do
		RunService.Heartbeat:Wait()
	end
	
	return track.Length > 0
end

function module.PlayHypeMusic(soundId, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1
	sound.Looped = false
	sound.Name = "HypeMusic"
	sound.Parent = workspace
	sound:Play()
	return sound
end

function module.FadeHypeMusic(soundObj)
	if soundObj then
		spawn(function()
			local fadeTime = 3 
			local step = 0.0125
			local waitTime = fadeTime * step / soundObj.Volume

			for vol = soundObj.Volume, 0, -step do
				if soundObj then
					soundObj.Volume = math.max(0, vol)
				end
				wait(waitTime)
			end

			if soundObj then
				soundObj:Stop()
				soundObj:Destroy()
			end
		end)
	end

end

function module.GetCamRigPart(camRig)
	for _, part in pairs(camRig:GetChildren()) do
		if part:GetAttribute("Camera") then
			return part
		end
	end
end

function module.RemoveParticles(particlesList)
	for i = #particlesList, 1, -1 do
		local particle = particlesList[i]
		particle:Destroy()
	end
end

function module.EmitSpecificParticle(particle, emitDelay, emitCount)
	task.delay(particle:GetAttribute("EmitDelay"),function()
		particle:Emit(particle:GetAttribute("EmitCount"))
		if particle:GetAttribute("EmitDuration") then
			particle.Enabled = true
			task.delay(particle:GetAttribute("EmitDuration"),function()
				particle.Enabled = false
			end)
		end
	end)
end

function module.EnableParticles(EffectPart, enabled)
	for _,v:ParticleEmitter in pairs(EffectPart:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = enabled
		end
	end
end

function module.Emit(EffectPart:BasePart)
	for _,v:ParticleEmitter in pairs(EffectPart:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			task.delay(v:GetAttribute("EmitDelay"),function()
				v:Emit(v:GetAttribute("EmitCount"))
				if v:GetAttribute("EmitDuration") then
					v.Enabled = true
					task.delay(v:GetAttribute("EmitDuration"),function()
						v.Enabled = false
					end)
				end
			end)
		elseif v:IsA("Sound") then
			v:Play()
		end
	end
end

-- Impact screen flash
function module.PlayImpactFrame()
	local gui = Instance.new("ScreenGui")
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Name = "ImpactFrame"
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	frame.BackgroundTransparency = 0.35
	frame.ZIndex = 100
	frame.Parent = gui

	local inTween = TweenService:Create(frame, TweenInfo.new(0.05), {BackgroundTransparency = 0.35})
	inTween:Play()
	inTween.Completed:Wait()

	local outTween = TweenService:Create(frame, TweenInfo.new(0.05), {BackgroundTransparency = 1})
	outTween:Play()
	outTween.Completed:Wait()

	gui:Destroy()
end


function module.AddEyeGlowAndFlare(character)
	local head = character:FindFirstChild("Head")
	if not head then return end

	local glow = Instance.new("ParticleEmitter")
	glow.Name = "GhostEyeGlow"
	glow.Texture = "rbxassetid://259248902"
	glow.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
	glow.LightEmission = 1
	glow.Rate = 25
	glow.Lifetime = NumberRange.new(0.6)
	glow.Speed = NumberRange.new(0)
	glow.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0)})
	glow.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
	glow.Parent = head

	local flare = Instance.new("BillboardGui")
	flare.Size = UDim2.new(4, 0, 4, 0)
	flare.LightInfluence = 0
	flare.AlwaysOnTop = true
	flare.Name = "LensFlare"
	flare.Adornee = head
	flare.Parent = head

	local flareImage = Instance.new("ImageLabel")
	flareImage.Size = UDim2.new(1, 0, 1, 0)
	flareImage.BackgroundTransparency = 1
	flareImage.Image = "rbxassetid://138036401143666"
	flareImage.ImageColor3 = Color3.fromRGB(160, 200, 255)
	flareImage.ImageTransparency = 0.3
	flareImage.Parent = flare

	local trail = Instance.new("ParticleEmitter")
	trail.Name = "GhostDrift"
	trail.Texture = "rbxassetid://82104870020794"
	trail.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
	trail.LightEmission = 0.5
	trail.Lifetime = NumberRange.new(0.8, 1.1)
	trail.Rate = 12
	trail.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)})
	trail.Speed = NumberRange.new(0.5, 1)
	trail.VelocitySpread = 40
	trail.VelocityInheritance = 0.2
	trail.Rotation = NumberRange.new(-60, 60)
	trail.RotSpeed = NumberRange.new(-40, 40)
	trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
	trail.EmissionDirection = Enum.NormalId.Top
	trail.Parent = head

	local flashLineGui = Instance.new("ScreenGui")
	flashLineGui.IgnoreGuiInset = true
	flashLineGui.Name = "AnimeFlashLine"
	flashLineGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local flash = Instance.new("ImageLabel")
	flash.Size = UDim2.new(1.5, 0, 0, 14)
	flash.Position = UDim2.new(-0.1, 0, 0.5, 0)
	flash.BackgroundTransparency = 1
	flash.Image = "rbxassetid://132235126977079"
	flash.ImageColor3 = Color3.fromRGB(180, 220, 255)
	flash.ImageTransparency = 0.15
	flash.Parent = flashLineGui

	local tweenIn = TweenService:Create(flash, TweenInfo.new(0.05), {ImageTransparency = 0.15})
	local tweenOut = TweenService:Create(flash, TweenInfo.new(0.4), {ImageTransparency = 1})
	tweenIn:Play()
	tweenIn.Completed:Wait()
	tweenOut:Play()

	Debris:AddItem(glow, 1.5)
	Debris:AddItem(trail, 1.5)
	Debris:AddItem(flare, 1.5)
	Debris:AddItem(flashLineGui, 1.5)
end


-- Remove the catcher from workspace
function module.RemoveCatcher()
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs and npcs:FindFirstChild("Catcher") then
		npcs.Catcher.Parent = ReplicatedStorage
	end
	
	if npcs and npcs:FindFirstChild("Umpire") then
		npcs.Umpire.Parent = ReplicatedStorage
	end
end

-- Restore the catcher to workspace
function module.RestoreCatcher()
	if ReplicatedStorage:FindFirstChild("Catcher") and workspace:FindFirstChild("NPCs") then
		ReplicatedStorage.Catcher.Parent = workspace.NPCs
	end
	
	if ReplicatedStorage:FindFirstChild("Umpire") and workspace:FindFirstChild("NPCs") then
		ReplicatedStorage.Umpire.Parent = workspace.NPCs
	end
end

function module.ShowUIVisibility(enabled)
	local player = Players.LocalPlayer
	local PlayerGui = player:WaitForChild("PlayerGui")
	local ScoreboardGui = PlayerGui:WaitForChild("Scoreboard")
	local AbilityPowerGui = PlayerGui:WaitForChild("AbilityPower")
	local GameStatus = PlayerGui:WaitForChild("GameStatus")
	local MainGui = PlayerGui:WaitForChild("MainGui")
	local CoinsDisplay = PlayerGui:WaitForChild("CoinsDisplay")
	local BattingPracticeGui = PlayerGui:WaitForChild("BattingPracticeGui")
	
	ScoreboardGui.Enabled = enabled
	AbilityPowerGui.Enabled = enabled
	MainGui.Enabled = enabled
	CoinsDisplay.Enabled = enabled
	GameStatus.Enabled = enabled
	BattingPracticeGui.Enabled = enabled
end

function module.FadeScreen(direction, duration)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local fadeFrame = playerGui:WaitForChild("Cinematic"):WaitForChild("FadeFrame")

	fadeFrame.Visible = true

	if direction == "Out" then
		fadeFrame.BackgroundTransparency = 1
	elseif direction == "In" then
		fadeFrame.BackgroundTransparency = 0
	end

	local targetTransparency = direction == "Out" and 0 or 1
	local tween = TweenService:Create(
		fadeFrame,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{ BackgroundTransparency = targetTransparency }
	)

	tween:Play()
	tween.Completed:Wait()

	if direction == "In" then
		fadeFrame.Visible = false
	end
end


function module.RumbleGround(position)
	local rumble = Instance.new("ParticleEmitter")
	rumble.Texture = "rbxassetid://6996321125" -- dirt puff or shock texture
	rumble.Lifetime = NumberRange.new(0.5)
	rumble.Rate = 0
	rumble.Speed = NumberRange.new(3, 5)
	rumble.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0)})
	rumble.Rotation = NumberRange.new(0, 360)
	rumble.RotSpeed = NumberRange.new(50)
	rumble.SpreadAngle = Vector2.new(360, 360)

	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(1, 1, 1)
	part.Position = position
	part.Transparency = 1
	part.Parent = workspace

	rumble.Parent = part
	rumble:Emit(30)

	game:GetService("Debris"):AddItem(part, 2)
end

function module.GrowBranchBetween(startPos, endPos)
	local branchModel = Instance.new("Model")
	branchModel.Name = "GrowingBranch"
	branchModel.Parent = workspace

	local totalDistance = (endPos - startPos).Magnitude
	local direction = (endPos - startPos).Unit
	local stepSize = 1.5
	local delayBetweenSteps = 0.07

	local amplitude = 1
	local frequency = 0.5
	local sideAxis = Vector3.new(0, 1, 0):Cross(direction).Unit

	local previousPos = startPos

	for i = 0, totalDistance, stepSize do
		local squiggleOffset = math.sin(i * frequency) * amplitude
		local offsetPos = sideAxis * squiggleOffset
		local currentPos = startPos + direction * i + offsetPos

		local lookDir = (currentPos - previousPos).Unit
		local lookCF = CFrame.new(previousPos, currentPos)
		previousPos = currentPos

		local segment = Instance.new("Part")
		segment.Size = Vector3.new(0.5, 0.5, stepSize)
		segment.Anchored = true
		segment.CanCollide = false
		segment.Material = Enum.Material.WoodPlanks
		segment.BrickColor = BrickColor.new("Reddish brown")
		segment.CFrame = lookCF * CFrame.new(0, 0, -stepSize / 2)
		segment.Parent = branchModel

		local camPos = currentPos - lookDir * 6 + Vector3.new(0, 2, 0)
		local camLookAt = currentPos + lookDir * 3
		workspace.CurrentCamera.CFrame = CFrame.new(camPos, camLookAt)
		
		task.wait(delayBetweenSteps)
	end

	game:GetService("Debris"):AddItem(branchModel, 6)
end

function module.BloomFlowersOnBall(ball)
	if not ball then return end

	local flowerAssets = ReplicatedStorage:WaitForChild("VFX"):WaitForChild("FlowerPops"):GetChildren()
	local bloomDelays = {0.4, 0.3, 0.2, 0.1, 0.05, 0.03, 0.02}

	local attachments = {}
	for i = 1, 8 do
		local offset = CFrame.Angles(0, math.rad(i * 45), 0) * CFrame.new(0, 0, -0.5)
		table.insert(attachments, offset)
	end

	local origin = ball.Position

	for i = 1, #bloomDelays do
		local flower = flowerAssets[math.random(1, #flowerAssets)]:Clone()
		local offsetCF = attachments[(i - 1) % #attachments + 1]

		flower.CFrame = CFrame.new(origin) * offsetCF
		flower.Parent = workspace
		flower.Size = Vector3.new(0.1, 0.1, 0.1)

		TweenService:Create(flower, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = Vector3.new(1, 1, 1)
		}):Play()

		game:GetService("Debris"):AddItem(flower, 5)
		task.wait(bloomDelays[i])
	end
end

function module.SpiralPetalEffect(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	for i = 1, 12 do
		local petal = Instance.new("Part")
		petal.Size = Vector3.new(0.4, 0.4, 0.4)
		petal.Anchored = true
		petal.CanCollide = false
		petal.Shape = Enum.PartType.Ball
		petal.BrickColor = BrickColor.new("Bright green")
		petal.Material = Enum.Material.Neon
		petal.Transparency = 0
		petal.Position = root.Position + Vector3.new(math.cos(i) * 2, 0.2 + i * 0.1, math.sin(i) * 2)
		petal.Parent = workspace

		local finalPos = petal.Position + Vector3.new(0, 2 + math.random(), 0)
		local finalTween = TweenService:Create(petal, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Position = finalPos,
			Transparency = 1
		})
		finalTween:Play()
		game:GetService("Debris"):AddItem(petal, 1.5)
	end
end

function module.AttachVFXModelToCharacter(vfxModel, character)
	local attachedObjects = {}

	for _, auraPart in ipairs(vfxModel:GetChildren()) do
		if auraPart:IsA("BasePart") then
			local targetPart = character:FindFirstChild(auraPart.Name)
			if targetPart then
				for _, descendant in ipairs(auraPart:GetDescendants()) do
					if descendant:IsA("Attachment") then
						local clonedAttachment = descendant:Clone()
						clonedAttachment.Parent = targetPart
						table.insert(attachedObjects, clonedAttachment)

						for _, nested in ipairs(descendant:GetChildren()) do
							local clonedNested = nested:Clone()
							clonedNested.Parent = clonedAttachment
							if clonedNested:IsA("ParticleEmitter") then
								clonedNested:Emit(50)
							end
							table.insert(attachedObjects, clonedNested)
						end
					elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") or descendant:IsA("Light") then
						local clonedVFX = descendant:Clone()
						clonedVFX.Parent = targetPart
						if clonedVFX:IsA("ParticleEmitter") then
							clonedVFX:Emit(50)
						end
						table.insert(attachedObjects, clonedVFX)
					end
				end
			end
		end
	end

	return attachedObjects
end


function module.TriggerGreenShockwave(position)
	local shock = Instance.new("Part")
	shock.Anchored = true
	shock.CanCollide = false
	shock.Shape = Enum.PartType.Ball
	shock.Size = Vector3.new(1, 1, 1)
	shock.Position = position
	shock.Material = Enum.Material.Neon
	shock.BrickColor = BrickColor.new("Bright green")
	shock.Transparency = 0.4
	shock.Parent = workspace

	local tween = TweenService:Create(shock, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Size = Vector3.new(20, 0.5, 20),
		Transparency = 1
	})
	tween:Play()

	game:GetService("Debris"):AddItem(shock, 1)
end

function module.PlayCharacterAura(character, auraFolder, eyeVFX, timer)
	local particlesAdded = {}
	
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("MeshPart") then
			for _, Particle in pairs(auraFolder:GetDescendants()) do
				if Particle:IsA("ParticleEmitter") then
					local particleClone = Particle:Clone()
					particleClone.Parent = part
					table.insert(particlesAdded, particleClone)
				end
			end
		end
	end
	
	for _, attachment in pairs(eyeVFX:GetChildren()) do
		local attclone = attachment:Clone()
		if string.match(attclone.Name, "Torso") then
			attclone.Parent = character.UpperTorso
		else
			attclone.Parent = character.Head
		end
		table.insert(particlesAdded, attclone)
	end
	
	task.delay(timer, function()
		module.RemoveParticles(particlesAdded)
	end)
end

function module.PlayImpactBeam(impactBeam, timer)
	local cylindricalBeam = impactBeam:Clone()
	
	cylindricalBeam.Parent = workspace.VFXFolder
	
	for _, beam in pairs(cylindricalBeam:GetDescendants()) do
		if beam:IsA("Beam") then
			beam.Enabled = true
		end
	end
	
	task.delay(timer, function()
		cylindricalBeam:Destroy()
	end)
end

function module.PlayBaseballImpact(baseball, batter, cframe)
	local baseballVFX = baseball:Clone()
	baseballVFX.Parent = workspace.VFXFolder
	
	if batter and batter:FindFirstChild("PlayerBat") and batter.PlayerBat:FindFirstChild("Handle") then
		local weld = Instance.new("Weld")
		weld.Part0 = batter.PlayerBat.Handle
		weld.Part1 = baseballVFX
		weld.C1 = cframe
		weld.Parent = baseballVFX
	end
	
	for _, particle in pairs(baseballVFX:GetDescendants()) do
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
end

function module.HitImpactEffects(impactSmoke)
	local impactSmokeClone = impactSmoke:Clone()
	impactSmokeClone.Parent = workspace.VFXFolder
	
	for _, particle in pairs(impactSmokeClone:GetDescendants()) do
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
end

function module.PlayParticlesInPart(particleObj, EmitCount, EmitDelay, EmitDuration)
	for _, particle in pairs(particleObj:GetDescendants()) do
		if particle:IsA("ParticleEmitter") then
			local emitCount = EmitCount or particle:GetAttribute("EmitCount") or 1
			local emitDelay = EmitDelay or particle:GetAttribute("EmitDelay") or 0
			local emitDuration = EmitDuration or particle:GetAttribute("EmitDuration") or 2

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

		elseif particle:IsA("Beam") then
			local emitDelay = EmitDelay or particle:GetAttribute("EmitDelay") or 0
			local emitDuration = EmitDuration or particle:GetAttribute("EmitDuration") or 2

			task.delay(emitDelay, function()
				particle.Enabled = true
				task.delay(emitDuration, function()
					particle.Enabled = false
				end)
			end)
		end
	end
end

function module.PlayAttachmentModelOnPart(model, targetPart, emitCount, emitDelay, emitDuration)
	if not model or not targetPart then return end

	local clone = model:Clone()

	-- Find the first Attachment inside the model
	local attachment = clone:FindFirstChildWhichIsA("Attachment", true)
	if not attachment then return end

	-- Reparent the Attachment directly to the target part (e.g., LeftHand)
	attachment.Parent = targetPart

	-- Emit everything inside that attachment
	for _, child in ipairs(attachment:GetChildren()) do
		if child:IsA("ParticleEmitter") then
			local count = emitCount or child:GetAttribute("EmitCount") or 1
			local delay = emitDelay or child:GetAttribute("EmitDelay") or 0
			local duration = emitDuration or child:GetAttribute("EmitDuration") or 2

			task.delay(delay, function()
				child:Emit(count)
				child.Enabled = true
				task.delay(duration, function()
					child.Enabled = false
				end)
			end)

		elseif child:IsA("Beam") then
			local delay = emitDelay or child:GetAttribute("EmitDelay") or 0
			local duration = emitDuration or child:GetAttribute("EmitDuration") or 2

			task.delay(delay, function()
				child.Enabled = true
				task.delay(duration, function()
					child.Enabled = false
				end)
			end)
		end
	end

	-- Optional: Clean it up after a few seconds
	game:GetService("Debris"):AddItem(attachment, emitDuration or 2.5)
end



function module.ShrinkParticles(particleObj, duration)
	for _, descendant in ipairs(particleObj:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			local emitter = descendant
			local originalSize = emitter.Size

			local startTime = tick()
			local connection
			connection = RunService.Heartbeat:Connect(function()
				local elapsed = tick() - startTime
				local alpha = math.clamp(elapsed / duration, 0, 1)

				-- Interpolate size
				local newKeypoints = {}
				for _, keypoint in ipairs(originalSize.Keypoints) do
					local newValue = keypoint.Value * (1 - alpha)
					table.insert(newKeypoints, NumberSequenceKeypoint.new(keypoint.Time, newValue))
				end
				emitter.Size = NumberSequence.new(newKeypoints)

				if alpha >= 1 then
					connection:Disconnect()
				end
			end)
		end
	end

end

function module.PlayCameraBarVFX(barVFX, cameraBars, timer)
	local particlesAdded = {}
	
	for _, att in pairs(barVFX:GetChildren()) do
		if att:IsA("Attachment") then
			local particleClone = att:Clone()
			particleClone.Parent = cameraBars
			table.insert(particlesAdded, particleClone)
		end
	end
	
	task.delay(timer, function()
		module.RemoveParticles(particlesAdded)
	end)
end

function module.PlayBatChargeVFX(batVFX, batter, cframe)
	local clonedbatVFX = batVFX:Clone()
	clonedbatVFX.Parent = workspace.VFXFolder

	if batter and batter:FindFirstChild("PlayerBat") and batter.PlayerBat:FindFirstChild("Handle") then
		local weld = Instance.new("Weld")
		weld.Part0 = batter.PlayerBat.Handle
		weld.Part1 = clonedbatVFX
		weld.C1 = cframe
		weld.Parent = clonedbatVFX
	end

	for _, particle in pairs(clonedbatVFX:GetDescendants()) do
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
end

function module.PlayVFXWall(vfxWall, timer)
	local vfxWallClone = vfxWall:Clone()
	vfxWallClone.Parent = workspace.VFXFolder
	
	for _, item in pairs(vfxWallClone:GetDescendants()) do
		if item:IsA("BasePart") then
			local tweenIn = TweenService:Create(item, TweenInfo.new(0.3), {Transparency = 0})
			tweenIn:Play()

			task.delay(timer, function()
				local tweenOut = TweenService:Create(item, TweenInfo.new(0.5), {Transparency = 1})
				tweenOut:Play()
			end)
		elseif item:IsA("ParticleEmitter") then
			local emitCount = item:GetAttribute("EmitCount")
			local emitDelay = item:GetAttribute("EmitDelay") or 0
			local emitDuration = item:GetAttribute("EmitDuration") or timer
			task.delay(emitDelay, function()
				if emitCount then
					item:Emit(emitCount)
				end
				if emitDuration then
					item.Enabled = true
					task.delay(emitDuration, function()
						item.Enabled = false
					end)
				end
			end)
		elseif item:IsA("Beam") then
			local emitDelay = item:GetAttribute("EmitDelay") or 0
			local emitDuration = item:GetAttribute("EmitDuration") or 2.3

			task.delay(emitDelay, function()
				if emitDuration then
					item.Enabled = true
					task.delay(emitDuration, function()
						item.Enabled = false
					end)
				end
			end)
		end
	end
end

function module.PlayTornadoVFX(tornado, batter)
	if batter == nil then return end
	if batter:FindFirstChild("UpperTorso") == nil then return end

	local tornadoClone = tornado:Clone()
	tornadoClone.Parent = workspace.VFXFolder
	
	local weld = Instance.new("Weld")
	weld.Part0 = tornadoClone
	weld.Part1 = batter.UpperTorso
	weld.C1 = CFrame.new(0, -2, 0)
	weld.Parent = tornadoClone
	
	for _, particle in pairs(tornadoClone:GetDescendants()) do
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
		elseif particle:IsA("Beam") then
			local emitDelay = particle:GetAttribute("EmitDelay") or 0
			local emitDuration = particle:GetAttribute("EmitDuration")

			task.delay(emitDelay, function()
				if emitDuration then
					particle.Enabled = true
					task.delay(emitDuration, function()
						particle.Enabled = false
					end)
				end
			end)
		end
	end
end

function module.PlayParticleSpin(char, spinPart, timer)
	if char == nil then return end
	if char:FindFirstChild("UpperTorso") == nil then return end
	
	local spinPartClone = spinPart:Clone()
	spinPartClone.Parent = workspace.VFXFolder
	
	spinPartClone.CFrame = char.UpperTorso.CFrame

	local weld = Instance.new("Weld")
	weld.Part0 = spinPartClone
	weld.Part1 = char.UpperTorso
	--weld.C1 = CFrame.new(0, -2, 0)
	weld.Parent = spinPartClone
	
	task.delay(timer, function()
		for _, particle in pairs(spinPartClone:GetDescendants()) do
			if particle:IsA("ParticleEmitter") then
				particle.Enabled = false
			end
		end

		task.wait(1)

		if spinPartClone then
			spinPartClone:Destroy()
		end
	end)
end

function module.PlayGroundCircleVFX(char, groundCircle, timer)
	if char == nil then return end
	if char:FindFirstChild("HumanoidRootPart") == nil then return end

	local groundCircleClone = groundCircle:Clone()
	groundCircleClone.Parent = workspace.VFXFolder

	groundCircleClone.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, -3, 0)
	
	for _, particle in pairs(groundCircleClone:GetDescendants()) do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = true
		end
	end
	
	task.delay(timer, function()
		for _, particle in pairs(groundCircleClone:GetDescendants()) do
			if particle:IsA("ParticleEmitter") then
				particle.Enabled = false
			end
		end
	end)
end

function module.EmitParticle(EffectPart:  BasePart)
	for _, v in pairs(EffectPart:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			local delayTime = v:GetAttribute("EmitDelay") or 0
			local count = v:GetAttribute("EmitCount") or 1
			local duration = v:GetAttribute("EmitDuration")

			task.delay(delayTime, function()
				v:Emit(count)
				if typeof(duration) == "number" and duration > 0 then
					v.Enabled = true
					task.delay(duration, function()
						v.Enabled = false
					end)
				end
			end)
		elseif v:IsA("Sound") then
			if not v.IsPlaying then
				v:Play()
			end
		end
	end
end

return module


