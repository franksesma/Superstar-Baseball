local animPlayer = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
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

local function attachFullGhostAura(auraModel, character)
	local attachedObjects = {}

	for _, auraPart in ipairs(auraModel:GetChildren()) do
		if auraPart:IsA("BasePart") then
			local targetPart = character:FindFirstChild(auraPart.Name)
			if targetPart then
				-- Attach all descendants under this part
				for _, descendant in ipairs(auraPart:GetDescendants()) do
					if descendant:IsA("Attachment") then
						local clonedAttachment = descendant:Clone()
						clonedAttachment.Parent = targetPart
						table.insert(attachedObjects, clonedAttachment)

						-- Attach all children (emitters, lights, etc.)
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

local function spawnGhostClone(position, directionVector, lookAt, originalChar)
	local clone = originalChar:Clone()
	clone.Name = originalChar.Name .. "_AfterImage"

	for _, part in ipairs(clone:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			part.Anchored = true
			part.CanCollide = false
			part.Transparency = 0.5
		elseif part:IsA("Humanoid") or part:IsA("Script") or part:IsA("LocalScript") then
			part:Destroy()
		end
	end

	clone.Parent = workspace
	clone:PivotTo(CFrame.new(position, lookAt))

	for _, part in ipairs(clone:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			local moveGoal = { Position = part.Position + directionVector * 2 }
			local fadeGoal = { Transparency = 1 }

			local moveTween = TweenService:Create(part, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), moveGoal)
			local fadeTween = TweenService:Create(part, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), fadeGoal)

			moveTween:Play()
			fadeTween:Play()
		end
	end

	Debris:AddItem(clone, 1.6)
end

function animPlayer.Execute(char, camPart)
	task.spawn(function()
		-- 👻 Attach GhostAura
		local auraModel = script.VFX:WaitForChild("GhostAura")
		local auraObjects = attachFullGhostAura(script.VFX:WaitForChild("GhostAura"), char)

		-- 🌬️ GhostlyWind VFX burst after 3 seconds
		task.delay(3, function()
			for i = 1, 8 do
				local wind = script.VFX.GhostlyWind:Clone()
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local offset = Vector3.new(
						math.random(-5, 5),
						math.random(-1, 3),
						math.random(-5, 5)
					)
					wind.Parent = workspace.VFXFolder
					wind:PivotTo(hrp.CFrame * CFrame.new(offset))

					CinematicUtils.PlayParticlesInPart(wind, 30, 0, 1.5)
					CinematicUtils.PlayAudioSound("Swoosh")

					game:GetService("Debris"):AddItem(wind, 2)
					task.wait(0.25)
				end
			end
		end)

		-- 👥 Spawn afterimage clones twice
		task.delay(0.5, function()
			CinematicUtils.PlayAudioSound("Swoosh")
			char.Archivable = true
			local rootCF = char:GetPivot()
			local rightVec = rootCF.RightVector
			local position = rootCF.Position

			spawnGhostClone(position + rightVec * 2, rightVec, position, char)
			spawnGhostClone(position - rightVec * 2, -rightVec, position, char)
			char.Archivable = false
		end)

		task.delay(1.0, function()
			CinematicUtils.PlayAudioSound("Swoosh")
			char.Archivable = true
			local rootCF = char:GetPivot()
			local rightVec = rootCF.RightVector
			local position = rootCF.Position

			spawnGhostClone(position + rightVec * 2, rightVec, position, char)
			spawnGhostClone(position - rightVec * 2, -rightVec, position, char)
			char.Archivable = false
		end)

		task.delay(5, function()
			CinematicUtils.PlayAudioSound("SwooshThrow")
		end)
		
		-- 🧼 Remove aura
		for _, obj in auraObjects do
			pcall(function()
				obj:Destroy()
			end)
		end
	end)
end

return animPlayer
