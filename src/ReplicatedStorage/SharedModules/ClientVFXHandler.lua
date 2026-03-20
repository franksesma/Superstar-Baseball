local ClientVFXHandler = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local VFXParticlesFB = ReplicatedStorage.VFXParticlesFB

local camera = workspace.CurrentCamera
local speedlinesParticle = VFXParticlesFB.Speedlines

local player = Players.LocalPlayer

local viewportSize = camera.ViewportSize
local aspectRatio = viewportSize.X / viewportSize.Y
local offset = 10

function ClientVFXHandler.StartSpeedlines(rate : number, speed : number)
	if not camera then
		return
	end
	
	if rate == nil then
		rate = 1500
	end
	
	if speed == nil then
		speed = 20
	end
	
	local character = player.Character
	local humanoid = character.Humanoid
	
	speedlinesParticle.Attachment.ParticleEmitter.Enabled = true
	speedlinesParticle.Parent = camera
	
	task.spawn(function()
		RunService:BindToRenderStep("Speedlines", Enum.RenderPriority.Camera.Value, function()
			if humanoid.MoveDirection.Magnitude > 0 then
				speedlinesParticle.CFrame = camera.CFrame + camera.CFrame.LookVector * (offset / (camera.FieldOfView / 70))
				speedlinesParticle.Attachment.ParticleEmitter.Rate = (humanoid.WalkSpeed / speed) * rate

				if not speedlinesParticle.Attachment.ParticleEmitter.Enabled then
					speedlinesParticle.Attachment.ParticleEmitter.Enabled = true
				end
			else
				speedlinesParticle.Position = speedlinesParticle.Position - Vector3.new(0, 500, 0)

				if speedlinesParticle.Attachment.ParticleEmitter.Enabled then
					speedlinesParticle.Attachment.ParticleEmitter.Enabled = false
				end
			end
		end)
	end)
end

function ClientVFXHandler.StopSpeedlines()
	RunService:UnbindFromRenderStep("Speedlines")
	speedlinesParticle.Position = speedlinesParticle.Position - Vector3.new(0, 500, 0)
	speedlinesParticle.Attachment.ParticleEmitter.Enabled = false
end

function ClientVFXHandler.CameraShake(intensity: number, duration: number)
	intensity = intensity or 0.5
	duration = duration or 1
	
	local startTime = tick()
	local connection
	
	local originalCFrame = camera.CFrame
	
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		local progress = math.min(elapsed / duration, 1)
		
		if elapsed >= duration then
			connection:Disconnect()
			camera.CFrame = originalCFrame
			return
		end
		
		local offset = Vector3.new(
			(math.random() - 0.5) * intensity, 
			(math.random() - 0.5) * intensity, 
			0
		)
		
		local shakeCFrame = originalCFrame * CFrame.new(offset)
		camera.CFrame = originalCFrame:Lerp(shakeCFrame, progress)
	end)
end

function ClientVFXHandler.PlaceModel(model, position)
	if model.PrimaryPart then
		model:SetPrimaryPartCFrame(CFrame.new(position))
	end
end

function ClientVFXHandler.ShrinkModel(model, duration)
	local originalSizes = {}
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			originalSizes[part] = part.Size
			local Tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0, 0, 0)})
			Tween:Play()
		end
	end
end

function ClientVFXHandler.GrowModel(model, duration)
	local originalSizes = {}
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			originalSizes[part] = part.Size
			part.Size = Vector3.new(0, 0, 0)
		end
	end
	for part, originalSize in pairs(originalSizes) do
		local Tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = originalSize})
		Tween:Play()
	end
end

function ClientVFXHandler.FadeModel(model, fadeIn, duration)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local Goal = {Transparency = fadeIn and 0 or 1}
			local Tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Goal)
			Tween:Play()
			if not fadeIn then
				Tween.Completed:Connect(function()
					if model then
						model:Destroy()
					end
				end)
			end
		end
	end
end

function ClientVFXHandler.SpinModel(model, speed)
	if model.PrimaryPart then
		local connection
		connection = RunService.Heartbeat:Connect(function(deltaTime)
			if not model.Parent then
				connection:Disconnect()
			else
				local rotation = CFrame.Angles(0, math.rad(speed * deltaTime), 0)
				model:SetPrimaryPartCFrame(model.PrimaryPart.CFrame * rotation)
			end
		end)
	end
end

function ClientVFXHandler.SpinMotor(motor, speed)
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not motor.Parent then
			connection:Disconnect()
		else
			motor.C0 = motor.C0 * CFrame.Angles(0, math.rad(speed), 0)
		end
	end)
end


function ClientVFXHandler.TransferEffects(model, targetPart, duration)
	local sourcePart
	for _, obj in ipairs(model:GetChildren()) do
		if obj:IsA("BasePart") then
			sourcePart = obj
			break
		end
	end
	if sourcePart and targetPart then
		for _, obj in ipairs(sourcePart:GetChildren()) do
			if obj:IsA("Attachment") or obj:IsA("ParticleEmitter") then
				local clone = obj:Clone()
				clone.Parent = targetPart
				if obj:IsA("ParticleEmitter") or obj:IsA("Attachment") then
					if duration then
						task.delay(duration, function()
							clone:Destroy()
						end)
					end
				end
			end
		end
	end
end
function ClientVFXHandler.ShockwaveSpikeExpand(partTemplate, centerCFrame, growScale, growTime, delayBetween)
	growScale = growScale or 6 -- Bigger impact
	growTime = growTime or 0.7
	delayBetween = delayBetween or 0.3

	if not partTemplate:IsA("BasePart") then
		warn("Expected BasePart as spike template")
		return
	end

	for i = 1, 3 do
		local clone = partTemplate:Clone()
		clone.Anchored = true
		clone.CanCollide = false
		clone.Color = Color3.fromRGB(101, 67, 33) -- brown
		clone.Transparency = 0
		clone.Size = partTemplate.Size * 0.2

		-- Angle and offset placement around feet
		local angle = math.rad((i - 1) * 120)
		local offset = CFrame.Angles(0, angle, 0) * CFrame.new(3, 0, 0)
		clone.CFrame = centerCFrame * offset * CFrame.new(0, clone.Size.Y / 2, 0) -- keep grounded
		clone.Parent = workspace

		task.delay((i - 1) * delayBetween, function()
			local goalSize = Vector3.new(
				clone.Size.X * growScale,
				clone.Size.Y * (growScale * 1.5), -- grow taller than wide
				clone.Size.Z * growScale
			)

			local tween = TweenService:Create(clone, TweenInfo.new(growTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = goalSize,
				Transparency = 1
			})
			tween:Play()
			game:GetService("Debris"):AddItem(clone, growTime + 0.2)
		end)
	end
end

local AuraSourceFolder = ReplicatedStorage:WaitForChild("Auras")
local Debris = game:GetService("Debris")

local R6_TO_R15 = {
	["Head"] = "Head",
	["Left Arm"] = "UpperLeftArm",
	["Right Arm"] = "UpperRightArm",
	["Left Leg"] = "UpperLeftLeg",
	["Right Leg"] = "UpperRightLeg",
	["Torso"] = "UpperTorso",
	["HumanoidRootPart"] = "HumanoidRootPart"
}

function ClientVFXHandler.ApplyAuraFromNPC(player, npcName, auratime)
	auratime = auratime or 2
	local character = player.Character
	if not character then return end

	local npcAuraModel = AuraSourceFolder:FindFirstChild(npcName)
	if not npcAuraModel then
		warn("Aura NPC model not found:", npcName)
		return
	end

	for r6Part, r15Part in pairs(R6_TO_R15) do
		local sourcePart = npcAuraModel:FindFirstChild(r6Part)
		local targetPart = character:FindFirstChild(r15Part)

		if sourcePart and targetPart then
			for _, obj in ipairs(sourcePart:GetChildren()) do
				if obj:IsA("Attachment") then
					local attachmentClone = obj:Clone()
					attachmentClone:SetAttribute("AuraName", npcName)
					attachmentClone.Parent = targetPart

					for _, child in ipairs(attachmentClone:GetDescendants()) do
						if child:IsA("ParticleEmitter") then
							child.Enabled = true
							child:Emit(10)
						end
					end

					Debris:AddItem(attachmentClone, auratime)

				elseif obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") then
					local clone = obj:Clone()
					clone:SetAttribute("AuraName", npcName)
					clone.Parent = targetPart

					if clone:IsA("ParticleEmitter") then
						clone.Enabled = true
						clone:Emit(10)
					end

					Debris:AddItem(clone, auratime)
				end
			end
		end
	end
end

function ClientVFXHandler.EmitAura(player, auraName)
	local character = player.Character
	if not character then return end

	for _, emitter in ipairs(character:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") and emitter:GetAttribute("AuraName") == auraName then
			-- Store original properties
			local originalSpeed = emitter.Speed
			local originalSize = emitter.Size
			local originalSpread = emitter.SpreadAngle

			-- Temporarily flare it up
			emitter.Speed = NumberRange.new(6, 10)
			emitter.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 2),
				NumberSequenceKeypoint.new(1, 0)
			})
			emitter.SpreadAngle = Vector2.new(360, 360)

			-- Emit burst
			emitter:Emit(15)

			-- Restore after short delay
			task.delay(0.15, function()
				emitter.Speed = originalSpeed
				emitter.Size = originalSize
				emitter.SpreadAngle = originalSpread
			end)
		end
	end
end


function ClientVFXHandler.ApplyAuraFromFolder(targetPart, folderName, auratime)
	auratime = auratime or 2
	if not targetPart or not targetPart:IsA("BasePart") then
		warn("ApplyAuraFromFolder: Invalid target part.")
		return
	end

	local auraFolder = AuraSourceFolder:FindFirstChild(folderName)
	if not auraFolder or not auraFolder:IsA("Folder") then
		warn("Aura folder not found or not a Folder:", folderName)
		return
	end

	-- Use the folder's CFrame as a reference point (based on first part)
	local originPart = auraFolder:FindFirstChildWhichIsA("BasePart")
	if not originPart then
		warn("Aura folder has no parts to apply.")
		return
	end
	local folderOriginCFrame = originPart.CFrame

	for _, auraPart in ipairs(auraFolder:GetChildren()) do
		if auraPart:IsA("BasePart") then
			local partClone = auraPart:Clone()
			partClone.Anchored = true
			partClone.CanCollide = false
			partClone.CanTouch = false
			partClone.CanQuery = false

			-- Preserve relative offset to the folder's origin part
			partClone.Position = targetPart.Position

			partClone.Parent = targetPart

			-- Emit instantly
			for _, descendant in ipairs(partClone:GetDescendants()) do
				if descendant:IsA("ParticleEmitter") then
					descendant.Enabled = true
					descendant:Emit(10)
				end
			end

			Debris:AddItem(partClone, auratime)
		end
	end
end


return ClientVFXHandler

