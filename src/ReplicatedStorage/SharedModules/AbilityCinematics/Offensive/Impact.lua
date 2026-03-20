local animPlayer = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
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
animPlayer.facePitcherMound = false
animPlayer.fieldOfView = 70

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart, camTrack, humTrack)
	-- Play VFX
	task.spawn(function()
		camTrack:AdjustSpeed(0.4)
		humTrack:AdjustSpeed(0.4)
		wait(0.1)
		CinematicUtils.PlayCharacterAura(char, script.VFX.Aura, script.VFX.EyeVFX, 5.5)
		wait(2.5)
		CinematicUtils.PlayCameraBarVFX(script.VFX.ImpactBars, camPart, 3)

		wait(3)		
		CinematicUtils.HitImpactEffects(script.VFX.ImpactSmoke, char)
		CinematicUtils.PlayAudioSound("FireLaunch")
		CinematicUtils.PlayAudioSound("Quake")
		if char and char:FindFirstChild("HumanoidRootPart") then
			local spikeTemplate = ReplicatedStorage.VFX:WaitForChild("ShockwaveRing").Spikes
			ClientVFXHandler.ShockwaveSpikeExpand(spikeTemplate, char.HumanoidRootPart.CFrame * CFrame.new(0, -2.5, 0))

			-- === Rock Debris (now falls after 0.5s) ===
			for _ = 1, 16 do
				local rock = Instance.new("Part")
				rock.Size = Vector3.new(0.3, 0.3, 0.3)
				rock.Shape = Enum.PartType.Block
				rock.Material = Enum.Material.Slate
				rock.Color = Color3.fromRGB(101, 67, 33)
				rock.Anchored = false
				rock.CanCollide = false
				rock.Position = char.HumanoidRootPart.Position + Vector3.new(0, 2, -1)
				rock.Parent = workspace

				local bv = Instance.new("BodyVelocity")
				bv.Velocity = Vector3.new(math.random(-10, 10), math.random(10, 15), math.random(-10, 10))
				bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
				bv.Parent = rock
				Debris:AddItem(rock, 2)

				task.delay(0.5, function()
					if bv then bv:Destroy() end
				end)
			end

			-- === Earthquake Finish: Giant Spikes + Ripple ===
			local plate = workspace.Plates:FindFirstChild("Home Base")
			if plate then
				-- Central spike
				for i = 1, 5 do
					local spike = Instance.new("Part")
					spike.Size = Vector3.new(1, math.random(10, 15), 1)
					spike.Anchored = true
					spike.CanCollide = true
					spike.Material = Enum.Material.Slate
					spike.Color = BrickColor.new("Really black").Color
					spike.CFrame = plate.CFrame * CFrame.new(math.random(-2, 2), 0, math.random(-2, 2))
					spike.Position = spike.Position + Vector3.new(0, -spike.Size.Y/2, 0)
					spike.Parent = workspace
					TweenService:Create(spike, TweenInfo.new(0.4), {Position = spike.Position + Vector3.new(0, spike.Size.Y, 0)}):Play()
					Debris:AddItem(spike, 2)
				end

				-- Ripple debris forward
				for _, dir in ipairs({
					Vector3.new(8, 8, 0), Vector3.new(6, 8, 4), Vector3.new(4, 9, 6),
					Vector3.new(0, 7, 8), Vector3.new(-4, 9, 6), Vector3.new(-6, 8, 4)
					}) do
					local ripple = Instance.new("Part")
					ripple.Size = Vector3.new(1, 1, 1)
					ripple.Anchored = false
					ripple.CanCollide = true
					ripple.Position = plate.Position + Vector3.new(0, 1, 0)
					ripple.BrickColor = BrickColor.new("Brown")
					ripple.Material = Enum.Material.Slate
					ripple.Parent = workspace

					local bv = Instance.new("BodyVelocity")
					bv.Velocity = dir
					bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
					bv.Parent = ripple
					game:GetService("Debris"):AddItem(bv, 0.3)
					Debris:AddItem(ripple, 2)
				end
			end
		end
	end)
end

return animPlayer