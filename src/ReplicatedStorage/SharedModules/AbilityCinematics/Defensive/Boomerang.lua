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
		
		-- 🌪️ VFX: Spawn wind spam every 0.25s
		task.spawn(function()
			for i = 1, 12 do
				local wind = script.VFX.Wind:Clone()
				wind.Parent = hrp
				CinematicUtils.PlayAttachmentModelOnPart(wind, hrp, 20, 0, 1)
				task.wait(0.25)
			end
		end)

		CinematicUtils.PlayAudioSound("Woosh")

		-- 🎯 VFX: 8-part hit marker loop around player
		task.delay(1, function()
			local radius = 4
			for i = 1, 8 do
				local angle = math.rad((360 / 8) * i)
				local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
				local pos = hrp.Position + offset

				local hitMarker = script.VFX.HitMarker:Clone()
				hitMarker:PivotTo(CFrame.new(pos))
				hitMarker.Parent = workspace.VFXFolder
				CinematicUtils.PlayParticlesInPart(hitMarker, 25, 0, 1.5)
				Debris:AddItem(hitMarker, 2)
				CinematicUtils.PlayAudioSound("Swoosh")
			end
		end)

		-- 💥 VFX: Final wind burst after 2 seconds
		task.delay(2, function()
			CinematicUtils.PlayAudioSound("PulseEffect")
			local burst = script.VFX.WindBlast:Clone()
			burst.Parent = workspace.VFXFolder
			burst:PivotTo(hrp.CFrame)
			CinematicUtils.PlayParticlesInPart(burst, 80, 0, 2)
			Debris:AddItem(burst, 3)
		end)
		
		task.delay(6, function()
			CinematicUtils.PlayAudioSound("Quake")
			local burst = script.VFX.WindBlast:Clone()
			burst.Parent = workspace.VFXFolder
			burst:PivotTo(hrp.CFrame)
			CinematicUtils.PlayParticlesInPart(burst, 80, 0, 2)
			Debris:AddItem(burst, 3)
		end)
	end)
end

return animPlayer
