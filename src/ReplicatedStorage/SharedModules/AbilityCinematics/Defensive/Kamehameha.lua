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
animPlayer.faceHomePlate = true
animPlayer.fieldOfView = 50

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart, camTrack, humTrack)
	-- Play VFX
	task.spawn(function()
		local attachedAuraRefs
		
		task.wait(.3)
		CinematicUtils.PlayAudioSound("Aura")
		task.spawn(function()
			local auraTemplate = script.VFX:WaitForChild("Aura"):Clone()
			auraTemplate.Name = "KamehamehaAura"

			-- Attach (this clones internals into the character)
			attachedAuraRefs = CinematicUtils.AttachVFXModelToCharacter(auraTemplate, char)

			-- The template we cloned from is not needed in workspace
			auraTemplate:Destroy()

			task.wait(4)
			CinematicUtils.PlayAudioSound("BlastCharge")
			-- Beam blast
			task.wait(4.2) -- adjust timing based on when beam should fire
			CinematicUtils.PlayAudioSound("BlastFire")
			local beam = script.VFX:WaitForChild("Beam"):Clone()
			beam.Name = "KamehamehaBeam"
			beam.Parent = workspace.VFXFolder

			game:GetService("Debris"):AddItem(beam, 4)
			--game:GetService("Debris"):AddItem(aura, 4)
		end)

		task.spawn(function()
			local duration = camTrack.Length
			task.wait(duration - 1.1)

			-- Pause both camera and humanoid animation tracks
			camTrack:AdjustSpeed(0)
			humTrack:AdjustSpeed(0)

			task.wait(2) -- pause duration

			-- Resume
			camTrack:AdjustSpeed(1)
			humTrack:AdjustSpeed(1)
		end)
		
		-- Return everything to normal

		if attachedAuraRefs then
			for _, inst in ipairs(attachedAuraRefs) do
				if inst and inst.Parent then
					inst:Destroy()
				end
			end
			attachedAuraRefs = nil
		end	
	end)
end

return animPlayer