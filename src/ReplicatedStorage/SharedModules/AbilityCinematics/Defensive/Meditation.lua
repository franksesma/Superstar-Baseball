local animPlayer = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
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
animPlayer.faceHomePlate = false
animPlayer.fieldOfView = 70

local camRig = SharedObjects:WaitForChild("CameraRig2")

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart)
	task.spawn(function()
		local hrp = char:FindFirstChild("HumanoidRootPart")

		-- Strike zone reference for later launches
		local strikeZone = workspace:FindFirstChild("Pitching") and workspace.Pitching:FindFirstChild("StrikeZone")

		-- orbit VFX handles
		local orbitFolder = nil
		local orbitConn = nil
		local orbitBalls = {}

		local particleAdded = {}
		local timer = 9
		local AttTrail = script.VFX.Trail.At0
		local dots = script.VFX.Trail.Torso

		local function removeParticle()
			for i = #particleAdded, 1, -1 do
				local particle = particleAdded[i]
				particle:Destroy()
				table.remove(particleAdded, i)
			end
		end

		local function addParticle()
			if char and char:FindFirstChild("RightHand") and char:FindFirstChild("LeftHand") and char:FindFirstChild("UpperTorso") then
				for _, Part in pairs(char:GetChildren()) do
					if Part:IsA("MeshPart") then
						for _, Particle in pairs(script.VFX.Aura:GetChildren()) do
							if Particle:IsA("ParticleEmitter") then
								local particleClone = Particle:Clone()
								particleClone.Parent = Part
								table.insert(particleAdded, particleClone)
							end
						end
					end
				end

				local attclone1 = AttTrail:Clone()
				attclone1.Parent = char["RightHand"]
				local attclone2 = AttTrail:Clone()
				attclone2.Parent = char["LeftHand"]
				local attclone3 = dots:Clone()
				attclone3.Parent = char.UpperTorso
				table.insert(particleAdded, attclone1)
				table.insert(particleAdded, attclone2)
				table.insert(particleAdded, attclone3)

				task.delay(timer, removeParticle)
			end
		end

		addParticle()
		task.wait(1.8)

		local partWithParticle = script.VFX.Tela:Clone()
		partWithParticle.Parent = workspace.VFXFolder

		local duration = 2.99

		local function emitAndTween()
			for _,item in pairs(partWithParticle:GetDescendants())do
				if item:IsA("BasePart")then
					TweenService:Create(item,TweenInfo.new(0.3),{Transparency=0}):Play()
					task.delay(duration,function()
						TweenService:Create(item,TweenInfo.new(0.5),{Transparency=1}):Play()
					end)
				elseif item:IsA("Beam")then
					item.Enabled=true
					task.delay(duration,function()item.Enabled=false end)
				end
			end
		end

		emitAndTween()

		task.wait(2.99)

		-- === Meditation: spawn 6 orbiting FakeBalls 90° to the RIGHT of the pitcher ===
		do
			orbitFolder = Instance.new("Folder")
			orbitFolder.Name = "MeditationOrbs"
			orbitFolder.Parent = workspace:FindFirstChild("VFXFolder") or workspace

			local fakeBallTemplate = ReplicatedStorage:FindFirstChild("VFX") and ReplicatedStorage.VFX:FindFirstChild("FakeBall")
			local cf = hrp and hrp.CFrame or CFrame.new(char:GetPivot().Position)

			local ballsCount = 6
			local radius     = 3.0     -- ring radius
			local heightOff  = 1.6     -- lift the ring
			local sideOff    = 3.2     -- how far to the RIGHT of pitcher
			local orbitSpeed = math.rad(60)

			local function makeBall()
				if fakeBallTemplate then
					local inst = fakeBallTemplate:Clone()
					inst.Parent = orbitFolder
					if inst:IsA("BasePart") then
						inst.Anchored = true
						inst.CanCollide = false
					else
						for _,bp in ipairs(inst:GetDescendants()) do
							if bp:IsA("BasePart") then
								bp.Anchored = true
								bp.CanCollide = false
							end
						end
					end
					return inst
				end
				-- fallback sphere
				local p = Instance.new("Part")
				p.Shape = Enum.PartType.Ball
				p.Size = Vector3.new(1.25, 1.25, 1.25)
				p.Color = Color3.fromRGB(245, 245, 245)
				p.Material = Enum.Material.SmoothPlastic
				p.CastShadow = false
				p.Anchored = true
				p.CanCollide = false
				p.Parent = orbitFolder
				return p
			end

			-- initial placement (right side ring)
			for i = 1, ballsCount do
				local b = makeBall()
				table.insert(orbitBalls, b)

				local angle = (2*math.pi) * (i-1)/ballsCount
				local forward = cf.LookVector
				local up      = cf.UpVector
				local right   = cf.RightVector
				local center  = (cf.Position + right*sideOff) + Vector3.new(0, heightOff, 0)
				local offset  = (forward * math.cos(angle) * radius) + (up * math.sin(angle) * (radius*0.65))
				local pos     = center + offset

				if b:IsA("Model") then
					local primary = b.PrimaryPart or b:FindFirstChildWhichIsA("BasePart")
					if primary then b:PivotTo(CFrame.new(pos)) end
				else
					b.CFrame = CFrame.new(pos)
				end
			end

			-- orbit animation
			local theta = 0
			orbitConn = RunService.RenderStepped:Connect(function(dt)
				theta += orbitSpeed * dt
				if not hrp or not hrp.Parent then return end
				local cframe  = hrp.CFrame
				local forward = cframe.LookVector
				local up      = cframe.UpVector
				local right   = cframe.RightVector
				local center  = (cframe.Position + right*sideOff) + Vector3.new(0, heightOff, 0)

				for i, b in ipairs(orbitBalls) do
					if b and b.Parent then
						local a = theta + (2*math.pi) * (i-1)/#orbitBalls
						local offset = (forward * math.cos(a) * radius) + (up * math.sin(a) * (radius*0.65))
						local pos = center + offset
						local selfSpin = CFrame.Angles(0, theta*2, 0)
						if b:IsA("Model") then
							local primary = b.PrimaryPart or b:FindFirstChildWhichIsA("BasePart")
							if primary then b:PivotTo(CFrame.new(pos) * selfSpin) end
						else
							b.CFrame = CFrame.new(pos) * selfSpin
						end
					end
				end
			end)
		end

		-- Space wall + particles
		local path = script.VFX.Space:Clone()
		path.Parent = workspace.VFXFolder

		local duration2 = 2.7
		local originalClockTime = Lighting.ClockTime
		local VfxDuration = 1.7

		local function cloneParticlesToRig()
			for _,item in pairs(path.Vfx:GetDescendants())do
				if item:IsA("ParticleEmitter")then
					local count=item:GetAttribute("EmitCount")
					if count then item:Emit(count)end
					item.Enabled=true
					local LastLifeTime=item.Lifetime
					task.delay(VfxDuration,function()
						item.Lifetime=NumberRange.new(0.1,0.1)
						item.Enabled=false
						item.Lifetime=LastLifeTime
					end)
				end
			end
		end

		local function emitAndTween2()
			Lighting.ClockTime = 0
			for _,item in pairs(path.Wall:GetDescendants())do
				if item:IsA("BasePart")then
					TweenService:Create(item,TweenInfo.new(0.3),{Transparency=0}):Play()
					task.delay(duration2,function()
						TweenService:Create(item,TweenInfo.new(0.5),{Transparency=1}):Play()
					end)
				elseif item:IsA("ParticleEmitter")then
					local count=item:GetAttribute("EmitCount")
					if count then item:Emit(count)end
					item.Enabled=true
					local LastLifeTime=item.Lifetime
					task.delay(VfxDuration,function()
						item.Lifetime=NumberRange.new(0.1,0.1)
						item.Enabled=false
						item.Lifetime=LastLifeTime
					end)
				elseif item:IsA("Beam")then
					item.Enabled=true
					task.delay(duration2,function()item.Enabled=false end)
				end
			end
			task.delay(duration2,function()
				Lighting.ClockTime = originalClockTime
			end)
		end

		emitAndTween2()
		cloneParticlesToRig()

		task.wait(2.97)

		local hitEffects = script.VFX.Hit:Clone()
		hitEffects.Parent = workspace.VFXFolder

		local function emitHit(pathToEmit)
			for _, particle in pairs(pathToEmit:GetDescendants()) do
				if particle:IsA("ParticleEmitter") then
					local emitCount = particle:GetAttribute("EmitCount")
					local emitDelay = particle:GetAttribute("EmitDelay") or 0
					local emitDuration = particle:GetAttribute("EmitDuration")

					task.delay(emitDelay, function()
						if emitCount then
							particle:Emit(emitCount)
						end
						if emitDuration then
							particle.Enabled = true
							task.delay(emitDuration, function()
								particle.Enabled = false
							end)
						end
					end)
				end
			end
		end

		emitHit(hitEffects)

		-- === NEW: Launch each orbit ball toward StrikeZone, staggered by 0.1s, then destroy ===
		do
			-- stop orbiting so they don't get repositioned while launching
			if orbitConn then orbitConn:Disconnect(); orbitConn = nil end

			-- pick a sensible target
			local targetPos = nil
			if strikeZone and strikeZone:IsA("BasePart") then
				targetPos = strikeZone.Position
			else
				-- fallback: in front of pitcher
				local cf = hrp and hrp.CFrame or CFrame.new(char:GetPivot().Position)
				targetPos = (cf.Position + cf.LookVector * 20)
			end

			local launchTime = 0.5 -- seconds to travel
			for i, b in ipairs(orbitBalls) do
				task.delay((i-1) * 0.1, function()
					if not b or not b.Parent then return end
					-- resolve a tweenable part and a mover for models
					if b:IsA("BasePart") then
						local tween = TweenService:Create(b, TweenInfo.new(launchTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { CFrame = CFrame.new(targetPos) })
						tween:Play()
						tween.Completed:Connect(function() if b then b:Destroy() end end)
					else
						local primary = b.PrimaryPart or b:FindFirstChildWhichIsA("BasePart")
						if not primary then b:Destroy(); return end
						local startTime = tick()
						local startPos  = primary.Position
						local rsConn
						rsConn = RunService.RenderStepped:Connect(function()
							local t = math.clamp((tick() - startTime)/launchTime, 0, 1)
							local pos = startPos:Lerp(targetPos, t)
							b:PivotTo(CFrame.new(pos))
							if t >= 1 then
								rsConn:Disconnect()
								if b then b:Destroy() end
							end
						end)
					end
				end)
			end
		end

		-- cleanup orbit (any survivors)
		if orbitConn then orbitConn:Disconnect() orbitConn = nil end
		if orbitFolder then orbitFolder:Destroy() orbitFolder = nil end
	end)
end

return animPlayer
