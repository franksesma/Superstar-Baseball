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
animPlayer.facePitcherMound = false
animPlayer.fieldOfView = 70

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart)
	-- Play VFX
	task.spawn(function()
		if not char or not char.Parent then return end

		local vfxFolder = workspace:FindFirstChild("VFXFolder")
		if not vfxFolder then return end

		local vfx = script:FindFirstChild("VFX")
		if not vfx then return end

		local humRoot = char:FindFirstChild("HumanoidRootPart")
		if not humRoot then return end

		local createdInstances = {}

		local function track(inst)
			table.insert(createdInstances, inst)
			return inst
		end

		local function cleanup()
			for i = #createdInstances, 1, -1 do
				local inst = createdInstances[i]
				if inst and inst.Parent then inst:Destroy() end
				createdInstances[i] = nil
			end
		end

		pcall(function()

			local vfxBaseball = vfx:FindFirstChild("VFXBaseball")
			local baseballMotorTemplate = vfx:FindFirstChild("Baseball")

			if vfxBaseball and baseballMotorTemplate then
				local fakeBaseball = track(vfxBaseball:Clone())
				fakeBaseball.Name = "Baseball"
				fakeBaseball.Parent = char

				local baseballMotor = track(baseballMotorTemplate:Clone())
				baseballMotor.Part0 = humRoot
				baseballMotor.Part1 = fakeBaseball
				baseballMotor.Parent = humRoot
			end

			task.spawn(function()
				if not workspace.CurrentCamera then return end
				local fovFolder = vfx:FindFirstChild("FOV")
				if not fovFolder then return end

				local frames = fovFolder:GetChildren()
				if #frames == 0 then return end

				table.sort(frames, function(a, b)
					return tonumber(a.Name) < tonumber(b.Name)
				end)

				for _, frame in ipairs(frames) do
					if frame:IsA("NumberValue") then
						workspace.CurrentCamera.FieldOfView = frame.Value
					end
					task.wait(.01)
				end

				workspace.CurrentCamera.FieldOfView = 70
			end)

			local function cloneToFolder(obj)
				if not obj then return nil end
				local c = obj:Clone()
				c.Parent = vfxFolder
				return c
			end

			local GroundParticle = cloneToFolder(vfx:FindFirstChild("GroundParticle"))
			local IceExplosion  = cloneToFolder(vfx:FindFirstChild("IceExplosion"))
			local Blizzard      = cloneToFolder(vfx:FindFirstChild("Blizzard"))
			local BeamsEffect   = cloneToFolder(vfx:FindFirstChild("BeamsEffect"))
			local ScreenEffect  = cloneToFolder(vfx:FindFirstChild("ScreenEffect"))

			local Aura = vfx:FindFirstChild("Aura")
			local Eyes = vfx:FindFirstChild("Eyes")

			local auraObjects = {}

			local function clearAura()
				for i = #auraObjects, 1, -1 do
					local a = auraObjects[i]
					if a and a.Parent then a:Destroy() end
					auraObjects[i] = nil
				end
			end

			local function applyAura()
				if not char or not char.Parent then return end

				if Aura then
					for _, limb in ipairs(char:GetChildren()) do
						if limb:IsA("MeshPart") then
							for _, emit in ipairs(Aura:GetDescendants()) do
								if emit:IsA("ParticleEmitter") then
									local clone = emit:Clone()
									clone.Parent = limb
									table.insert(auraObjects, clone)
								end
							end
						end
					end
				end

				if Eyes and char:FindFirstChild("Head") then
					local head = char.Head
					local A = Eyes:FindFirstChild("A")
					local B = Eyes:FindFirstChild("B")

					if A then
						local c = A:Clone()
						c.Parent = head
						table.insert(auraObjects, c)
					end

					if B then
						local c = B:Clone()
						c.Parent = head
						table.insert(auraObjects, c)
					end
				end
			end

			clearAura()
			applyAura()
			task.delay(11.12, clearAura)

			if GroundParticle then
				CinematicUtils.Emit(GroundParticle:FindFirstChild("Way1"))

				task.wait(0.31)
				CinematicUtils.PlayAudioSound("IceImpact")

				CinematicUtils.Emit(GroundParticle:FindFirstChild("Way2"))
				task.wait(0.85)
				CinematicUtils.PlayAudioSound("IceImpact")

				CinematicUtils.Emit(GroundParticle:FindFirstChild("Way3"))
			end

			CinematicUtils.PlayAudioSound("Blizzard")

			task.wait(4.9)

			local TorsoBeam = vfx:FindFirstChild("TorsoBeam")

			if TorsoBeam and BeamsEffect and char:FindFirstChild("UpperTorso") then
				local torsoClone = TorsoBeam:Clone()
				local upper = char.UpperTorso

				for _, obj in ipairs(torsoClone:GetChildren()) do
					obj.Parent = upper
					track(obj)
				end

				torsoClone:Destroy()

				for _, beam in ipairs(BeamsEffect:GetDescendants()) do
					if beam:IsA("Beam") then
						beam.Enabled = true
						local original = beam.Transparency
						local keys = original.Keypoints

						task.spawn(function()
							local start = tick()
							local dur = 5

							while tick() - start < dur do
								local alpha = (tick() - start) / dur
								local newKeys = {}

								for _, k in keys do
									local v = k.Value + (1 - k.Value) * alpha
									table.insert(newKeys, NumberSequenceKeypoint.new(k.Time, v))
								end

								beam.Transparency = NumberSequence.new(newKeys)
								RunService.Heartbeat:Wait()
							end

							beam.Enabled = false
							beam.Transparency = original
						end)
					end
				end

				task.wait(1.41)
				if ScreenEffect then CinematicUtils.Emit(ScreenEffect) end

				task.wait(0.58)
				if IceExplosion then CinematicUtils.Emit(IceExplosion) end
				CinematicUtils.PlayAudioSound("FireSplash")

				task.wait(1.23)
				if IceExplosion then CinematicUtils.Emit(IceExplosion) end
				CinematicUtils.PlayAudioSound("IceLaunch")
			end
		end)

		cleanup()
	end)
end

return animPlayer