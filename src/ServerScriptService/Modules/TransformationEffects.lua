local TransformationEffects = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFX = ReplicatedStorage.VFX
local VFXParticlesFB = ReplicatedStorage.VFXParticlesFB

local SharedModules = ReplicatedStorage.SharedModules
local ClientFunctions = require(SharedModules.ClientFunctions)
local Styles = require(SharedModules.Styles)
local OnBase = ReplicatedStorage.GameValues.OnBase

function TransformationEffects.AbilityActivateEffect(player, leaveAura)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		spawn(function()
			local transformationEffect = VFXParticlesFB.AbilityTransformationEffects:Clone()
			ClientFunctions.Weld(transformationEffect, player.Character.HumanoidRootPart)
			transformationEffect.Parent = player.Character.HumanoidRootPart
			transformationEffect.Sound:Play()
			wait(3)
			if transformationEffect then
				for _, object in pairs(transformationEffect:GetDescendants()) do
					if object:IsA("ParticleEmitter") or object:IsA("PointLight") then
						object.Enabled = false
					elseif object:IsA("Attachment") then
						for _, particle in pairs(object:GetDescendants()) do
							if particle:IsA("ParticleEmitter") then
								particle.Enabled = false
							end
						end
					end
				end
			end
			if leaveAura and OnBase:FindFirstChild(player.Name) then
				TransformationEffects.StartAbilityAura(player)
			end
			wait(2)
			if transformationEffect then
				transformationEffect:Destroy()
			end
		end)
	end
end

function TransformationEffects.UltimateActivateEffect(player, leaveAura)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		spawn(function()
			local transformationEffect = VFXParticlesFB.UltimateTransformationEffects:Clone()
			ClientFunctions.Weld(transformationEffect, player.Character.HumanoidRootPart)
			transformationEffect.Parent = player.Character.HumanoidRootPart
			transformationEffect.Sound:Play()
			wait(3)
			if transformationEffect then
				for _, object in pairs(transformationEffect:GetDescendants()) do
					if object:IsA("ParticleEmitter") or object:IsA("PointLight") then
						object.Enabled = false
					elseif object:IsA("Attachment") then
						for _, particle in pairs(object:GetDescendants()) do
							if particle:IsA("ParticleEmitter") then
								particle.Enabled = false
							end
						end
					end
				end
			end
			if leaveAura and OnBase:FindFirstChild(player.Name) then
				TransformationEffects.StartUltimateAura(player)
			end
			wait(2)
			if transformationEffect then
				transformationEffect:Destroy()
			end
		end)
	end
end

function TransformationEffects.StartAbilityAura(player)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local auraEffect = VFXParticlesFB.VFXAbilityAura:Clone()
		auraEffect.Parent = player.Character.HumanoidRootPart
		ClientFunctions.Weld(auraEffect, player.Character.HumanoidRootPart)
	end
end

function TransformationEffects.StartUltimateAura(player)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local auraEffect = VFXParticlesFB.VFXUltimateAura:Clone()
		auraEffect.Parent = player.Character.HumanoidRootPart
		ClientFunctions.Weld(auraEffect, player.Character.HumanoidRootPart)
	end
end

function TransformationEffects.ShowHittingAura(player)
	if player and _G.sessionData[player] then
		local equippedStyle = Styles.GetEquippedStyleName(player, "Offensive")
		
		if equippedStyle then
			local styleFolder = ReplicatedStorage.SharedModules.AbilityCinematics.Offensive:FindFirstChild(equippedStyle)
			
			if styleFolder:FindFirstChild("VFX") and styleFolder.VFX:FindFirstChild("Aura") and player.Character then
				for _, part in pairs(player.Character:GetChildren()) do
					if part:IsA("MeshPart") then
						for _, Particle in pairs(styleFolder.VFX.Aura:GetDescendants()) do
							if Particle:IsA("ParticleEmitter") then
								local particleClone = Particle:Clone()
								particleClone.Name = "HittingAuraVFX"
								particleClone.Parent = part
							end
						end
						
						if styleFolder.VFX:FindFirstChild("EyeVFX") and player.Character:FindFirstChild("Head") then
							for _, attachment in pairs(styleFolder.VFX.EyeVFX:GetChildren()) do
								if attachment.Name == "Attachment" then
									local eyeVFXAttachment = styleFolder.VFX.EyeVFX.Attachment:Clone()
									eyeVFXAttachment.Name = "HittingAuraVFX"
									eyeVFXAttachment.Parent = player.Character.Head
								end
							end
						end
					end
				end
			end
		end
	end
end

function TransformationEffects.RemoveAuras(player)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		if player.Character.HumanoidRootPart:FindFirstChild("VFXUltimateAura") then
			player.Character.HumanoidRootPart.VFXUltimateAura:Destroy()
		end
		
		if player.Character.HumanoidRootPart:FindFirstChild("VFXAbilityAura") then
			player.Character.HumanoidRootPart.VFXAbilityAura:Destroy()
		end
		
		for _, part in pairs(player.Character:GetDescendants()) do
			if part and part.Name == "HittingAuraVFX" then
				part:Destroy()
			end
		end
	end
end

return TransformationEffects
