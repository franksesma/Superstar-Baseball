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

animPlayer.camRig = SharedObjects:WaitForChild("CameraRig3")
animPlayer.requiresCinematicFrame = true
animPlayer.faceHomePlate = true
animPlayer.fieldOfView = 50

local humAnim = script:WaitForChild("Hum")
local camAnim = script:WaitForChild("Cam")

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart)
	-- Play VFX
	task.spawn(function()
		task.wait(0.2)

		-- 🧤 Clone baseball to LeftHand
		local leftHand = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")
		if not leftHand then return end

		local ball = script.VFX.BaseballVFX:Clone()
		ball.Parent = leftHand
		ball.CFrame = leftHand.CFrame * CFrame.new(0, -0.5, 0)
		ball.Anchored = false
		ball.Name = "GrowthBall"

		local weld = Instance.new("Weld")
		weld.Part0 = leftHand
		weld.Part1 = ball
		weld.C1 = CFrame.new(0, -0.5, 0)
		weld.Parent = ball

		-- 🌱 Scale up baseball over 3 seconds to 5x5x5
		local growTween = game:GetService("TweenService"):Create(
			ball,
			TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Size = Vector3.new(3, 3, 3) }
		)
		growTween:Play()

		for _, att in script.VFX.Growth:GetChildren() do
			if att:IsA("Attachment") then
				local clone = att:Clone()
				clone.Parent = ball
				CinematicUtils.PlayParticlesInPart(clone, 50, 0, 3)
			end
		end

		-- 🧼 Auto-remove baseball after 4 seconds
		game:GetService("Debris"):AddItem(ball, 4)

		-- 💚 Apply GrowthAura to body parts
		local auraAttachments = {}
		for _, child in script.VFX.GrowthAura:GetDescendants() do
			if child:IsA("Attachment") then
				local target = char:FindFirstChild(child.Parent.Name)
				if target and target:IsA("BasePart") then
					local clone = child:Clone()
					clone.Parent = target
					table.insert(auraAttachments, clone)
				end
			elseif child:IsA("ParticleEmitter") then
				local clone = child:Clone()
				clone.Parent = hrp
				clone:Emit(60)
				table.insert(auraAttachments, clone)
			end
		end

		CinematicUtils.PlayAudioSound("GrowthCharge")

		task.wait(3.2)

		-- 💨 Wind effect finale
		local wind = script.VFX.Wind:Clone()
		wind.Parent = leftHand
		CinematicUtils.PlayAttachmentModelOnPart(script.VFX.Wind, leftHand, 60, 0, 2)


		-- 🧼 Fade and remove GrowthAura
		for _, obj in auraAttachments do
			if obj:IsA("ParticleEmitter") then
				obj.Enabled = false
			elseif obj:IsA("Attachment") then
				obj:Destroy()
			end
		end
	end)
end

return animPlayer