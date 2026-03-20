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
	-- Play VFX
	task.spawn(function()
		local hrp = char:FindFirstChild("HumanoidRootPart")
		
		task.wait(.6)
		local burst2 = script.VFX.ImpactSmoke:Clone()
		burst2.Parent = workspace.VFXFolder
		if hrp then
			burst2:PivotTo(hrp.CFrame)
		end
		CinematicUtils.PlayParticlesInPart(burst2, 80, 0, 2)
		CinematicUtils.PlayAudioSound("Quake")
		Debris:AddItem(burst2, 3)

		task.wait(2.6)
		local burst2 = script.VFX.Wind2:Clone()
		burst2.Parent = workspace.VFXFolder
		if hrp then
			burst2:PivotTo(hrp.CFrame)
		end
		CinematicUtils.PlayParticlesInPart(burst2, 80, 0, 2)
		CinematicUtils.PlayAudioSound("Swoosh")
		Debris:AddItem(burst2, 3)

		task.wait(1)
		
		task.spawn(function()
			for i = 1, 8 do
				local wind = script.VFX.Wind:Clone()
				if char then
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
						task.wait(0.1)
					end
				end
			end
		end)
		
		task.wait(1.5)

		local portalFolder = script.VFX.WindPortals
		local windPortals = {
			portalFolder:FindFirstChild("WindPortal1"),
			portalFolder:FindFirstChild("WindPortal2"),
			portalFolder:FindFirstChild("WindPortal3"),
			portalFolder:FindFirstChild("WindPortal4"),
		}

		local lastPortal = nil
		for _, portalTemplate in ipairs(windPortals) do
			if portalTemplate then
				local portal = portalTemplate:Clone()
				portal.Parent = workspace.VFXFolder

				-- Play all emitters in the portal
				CinematicUtils.PlayAudioSound("PortalAppear") -- OPTIONAL: Add matching sound

				-- Delete previous portal
				if lastPortal then
					lastPortal:Destroy()
				end
				lastPortal = portal

				task.wait(0.3)
			end
		end
	end)
end

return animPlayer