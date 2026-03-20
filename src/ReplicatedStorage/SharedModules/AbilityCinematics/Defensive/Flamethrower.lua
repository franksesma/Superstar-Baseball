local animPlayer = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

function animPlayer.Execute(char, camPart)
	task.spawn(function()
		local hrp = char:FindFirstChild("HumanoidRootPart")
		
		CinematicUtils.PlayAudioSound("FireIgnite")
		-- 🔥 Attach FireAura to matching body parts
		local fireAura = script.VFX:WaitForChild("FireAura")
		local attachedAura = CinematicUtils.AttachVFXModelToCharacter(fireAura, char)

		-- 🔥 Attach Fire beam/stream to LeftHand
		local leftHand = char:FindFirstChild("LeftHand")
		if leftHand then
			local fire = script.VFX:WaitForChild("Fire")
			CinematicUtils.PlayAttachmentModelOnPart(fire, leftHand, 60, 0, 2)
		end

		-- 💥 Spawn explosion after 1 second
		task.delay(2.3, function()
			local explosion = script.VFX:WaitForChild("Explosion-01"):Clone()
			explosion.Parent = workspace.VFXFolder

			local frontCFrame = hrp.CFrame * CFrame.new(0, 0, -5) -- 5 studs in front
			explosion:PivotTo(frontCFrame)

			CinematicUtils.PlayAudioSound("FireLaunch")
			CinematicUtils.PlayParticlesInPart(explosion, 60, 0, 1.5)
			Debris:AddItem(explosion, 2)
		end)
		
		for _, obj in attachedAura do
			pcall(function() obj:Destroy() end)
		end
	end)
end

return animPlayer
