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
animPlayer.facePitcherMound = true
animPlayer.fieldOfView = 70

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart)
	-- Play VFX
	task.spawn(function()
		task.spawn(function() -- footsteps
			task.wait(0.75)
			local leftFoot1 = script.VFX.FoostepVFX.Attachment:Clone()
			if char and char:FindFirstChild("LeftFoot") then
				leftFoot1.Parent = char.LeftFoot
				CinematicUtils.PlayParticlesInPart(leftFoot1)
			end
			CinematicUtils.PlayAudioSound("BigFootstep")
			task.wait(0.5)
			local rightFoot1 = script.VFX.FoostepVFX.Attachment:Clone()
			if char and char:FindFirstChild("RightFoot") then
				rightFoot1.Parent = char.RightFoot
				CinematicUtils.PlayParticlesInPart(rightFoot1)
			end
			CinematicUtils.PlayAudioSound("BigFootstep")
			task.wait(0.5)
			local leftFoot2 = script.VFX.FoostepVFX.Attachment:Clone()
			if char and char:FindFirstChild("LeftFoot") then
				leftFoot2.Parent = char.LeftFoot
				CinematicUtils.PlayParticlesInPart(leftFoot2)
			end
			CinematicUtils.PlayAudioSound("BigFootstep")
			task.wait(0.5)
			local rightFoot2 = script.VFX.FoostepVFX.Attachment:Clone()
			if char and char:FindFirstChild("RightFoot") then
				rightFoot2.Parent = char.RightFoot
				CinematicUtils.PlayParticlesInPart(rightFoot2)
			end
			CinematicUtils.PlayAudioSound("BigFootstep")
			task.wait(0.5)
			if leftFoot1 then leftFoot1:Destroy() end
			if leftFoot2 then leftFoot2:Destroy() end
			if rightFoot1 then rightFoot1:Destroy() end
			if rightFoot2 then rightFoot2:Destroy() end
		end)
		
		task.wait(0.5)
		CinematicUtils.PlayVFXWall(script.VFX.ShadowWall, 3.4)
		CinematicUtils.PlayCharacterAura(char, script.VFX.Aura, script.VFX.EyeVFX, 8)
		wait(3)
		CinematicUtils.PlayCameraBarVFX(script.VFX.ShadowBars, camPart, 3.4)
		wait(2.5)
		CinematicUtils.PlayAudioSound("ShadowImpact")
		local baseballVFXCframe = CFrame.new(0, -2.75, -0.75) * CFrame.Angles(0, math.rad(180), 0)
		CinematicUtils.PlayBaseballImpact(script.VFX.BaseballVFX, char, baseballVFXCframe)
		wait(0.75)
		if workspace.VFXFolder:FindFirstChild("BaseballVFX") then
			workspace.VFXFolder.BaseballVFX:Destroy()
		end
		CinematicUtils.HitImpactEffects(script.VFX.ImpactSmoke, char)
		CinematicUtils.PlayAudioSound("FireLaunch")
	end)
end

return animPlayer