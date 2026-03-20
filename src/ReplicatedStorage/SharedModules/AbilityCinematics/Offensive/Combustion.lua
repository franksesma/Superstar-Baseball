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

animPlayer.camRig = SharedObjects:WaitForChild("CameraRig")
animPlayer.requiresCinematicFrame = true
animPlayer.facePitcherMound = true
animPlayer.fieldOfView = 70

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart)
	-- Play VFX
	task.spawn(function()
		local bombPart1 = script.VFX.Bomb:Clone()
		local bombPart2 = script.VFX.Bomb:Clone()
		local motor6D = script.VFX.Handle:Clone()
		local motor6D2 = script.VFX.Motor6DHRP:Clone()

		if char and char:FindFirstChild("RightHand") and char:FindFirstChild("HumanoidRootPart") then
			motor6D.Parent = char.RightHand
			motor6D2.Parent = char.HumanoidRootPart

			bombPart1.Parent = char
			bombPart1.Name = "Handle"
			motor6D.Part0 = char.RightHand
			motor6D.Part1 = bombPart1

			bombPart2.Parent = char
			bombPart2.Name = "BombPart"
			motor6D2.Part0 = char.HumanoidRootPart
			motor6D2.Part1 = bombPart2
		end
		
		task.wait(0.1)
		CinematicUtils.PlayCharacterAura(char, script.VFX.Aura, script.VFX.EyeVFX, 6.2)

		task.wait(6)
		local explosion = script.VFX.Explosion.Main:Clone()
		--explosion.CFrame = camPart.CFrame
		explosion.Parent = camPart
		CinematicUtils.PlayAudioSound("Explosion")
		CinematicUtils.HitImpactEffects(script.VFX.ImpactSmoke, char)
		CinematicUtils.PlayAudioSound("FireLaunch")
		
		-- Return everything to normal
		if bombPart1 then
			bombPart1:Destroy()
		end
		if bombPart2 then
			bombPart2:Destroy()
		end

		if motor6D then
			motor6D:Destroy()
		end
		if motor6D2 then
			motor6D2:Destroy()
		end
	end)
end

return animPlayer