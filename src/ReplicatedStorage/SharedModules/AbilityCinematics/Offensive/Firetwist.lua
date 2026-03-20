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
animPlayer.facePitcherMound = true
animPlayer.fieldOfView = 30

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart)
	-- Play VFX
	task.spawn(function()
		if char and char:FindFirstChild("PlayerBat") and char:FindFirstChild("RightHand") then
			local fakeBat = char.PlayerBat:Clone()
			
			for _, part in pairs(char.PlayerBat:GetDescendants()) do
				if part:IsA("BasePart") or part:IsA("MeshPart") then
					part.Transparency = 1
				end
				
				if part:IsA("Texture") or part:IsA("Decal") then
					part.Transparency = 1
				end
				
				if part:IsA("ParticleEmitter") then
					part.Enabled = false
				end
			end
			
			local motor6D = script.VFX.BatMotor6D:Clone()
			local vfxBat = script.VFX.VFXBat:Clone()
			vfxBat.Transparency = 1
			motor6D.Part0 = char.RightHand
			motor6D.Part1 = vfxBat
			motor6D.Parent = vfxBat
			vfxBat.Name = "placeholderbat"
			vfxBat.Parent = char
			
			local fakeHandle = fakeBat:FindFirstChild("Handle")
			local placeholderHandle = vfxBat:FindFirstChild("Handle")

			if fakeHandle and placeholderHandle then
				fakeBat.PrimaryPart = fakeBat.Handle
				fakeBat:SetPrimaryPartCFrame(placeholderHandle.CFrame * fakeBat.PrimaryPart.CFrame:ToObjectSpace(fakeHandle.CFrame):Inverse())

				fakeBat.Name = "FakeBat"
				fakeBat.Parent = workspace.VFXFolder

				local weld = Instance.new("WeldConstraint")
				weld.Part0 = fakeHandle
				weld.Part1 = placeholderHandle
				weld.Parent = fakeHandle
			end
			
			task.spawn(function()
				wait(2)
				if vfxBat:FindFirstChild("Trail") then
					vfxBat.Trail.Enabled = true
				end
			end)
		end
		task.wait(0.5)
		CinematicUtils.PlayAudioSound("FireIgnite")
		wait(0.5)
		local heatAura = script.VFX.HeatAura:Clone()
		heatAura.Parent = workspace.VFXFolder
		CinematicUtils.ShrinkParticles(heatAura, 1)
		
		CinematicUtils.PlayGroundCircleVFX(char, script.VFX.FireGround, 2.5)
		CinematicUtils.PlayCharacterAura(char, script.VFX.Aura, script.VFX.EyeVFX, 5)
		CinematicUtils.PlayParticleSpin(char, script.VFX.FireCircle, 5)
		
		
		wait(5)
		CinematicUtils.HitImpactEffects(script.VFX.ImpactSmoke, char)
		CinematicUtils.PlayAudioSound("FireLaunch")
		
		if char and char:FindFirstChild("placeholderbat") then
			char.placeholderbat:Destroy()
		end

		if char and char:FindFirstChild("PlayerBat") then
			for _, part in pairs(char.PlayerBat:GetDescendants()) do
				if (part:IsA("BasePart") or part:IsA("MeshPart")) and part.Name ~= "Handle" then
					part.Transparency = 0
				end

				if part:IsA("Texture") or part:IsA("Decal") then
					part.Transparency = 0
				end
			end
		end
	end)
end

return animPlayer