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
animPlayer.faceHomePlate = true
animPlayer.fieldOfView = 50

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart)
	task.spawn(function()
		local attachedAuraRefs 

		local auraTemplate = script.VFX:WaitForChild("Aura"):Clone()
		auraTemplate.Name = "KamehamehaAura"

		-- Attach (this clones internals into the character)
		attachedAuraRefs = CinematicUtils.AttachVFXModelToCharacter(auraTemplate, char)

		-- The template we cloned from is not needed in workspace
		auraTemplate:Destroy()

		-- Play VFX
		local fakeBall = ReplicatedStorage:WaitForChild("VFX"):FindFirstChild("FakeBall")
		local rightHand = char:FindFirstChild("RightHand")
		if fakeBall and rightHand then
			for _, offset in ipairs({0.35, -0.35}) do
				local clone = fakeBall:Clone()
				local weld = Instance.new("Weld")
				weld.Part0 = rightHand
				weld.Part1 = clone
				weld.C0 = CFrame.new(0, -0.25, offset)
				weld.Parent = clone
				clone.Name = "FakeBall"
				clone.Parent = workspace.VFXFolder
			end
		end

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