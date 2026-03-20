local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local OffensiveAbilities = {}

local AbilityFolder = ReplicatedStorage.Abilities
local Remotes = ReplicatedStorage.RemoteEvents
local VFX = ReplicatedStorage.VFX
local VFXParticlesFB = ReplicatedStorage.VFXParticlesFB
local Gamevalues = ReplicatedStorage.GameValues
local SharedModules = ReplicatedStorage.SharedModules
local Modules = ServerScriptService.Modules
local OnBase = Gamevalues.OnBase
local BasePlates = workspace.Plates

local CollisionGroups = require(SharedModules.CollisionGroups)
local VFXHandler = require(Modules.VFXHandler)
local BaseSequence = require(SharedModules.BaseSequence)
local TransformationEffects = require(Modules.TransformationEffects)
local AntiExploit = require(Modules.AntiExploit)
local ClientFunctions = require(SharedModules.ClientFunctions)

local function setupAbilityCamera(pitcher, hitter, styleName, styleType, bat)
	Remotes.AbilityCamera:FireAllClients(pitcher, hitter, styleName, styleType, bat)
end

OffensiveAbilities.Heat = {
	
	Modifiers = {
		MinDist = 200,
		MaxDist = 300,
		IgnoreUlts = true,
		XAngleMin = 20,
		XAngleMax = 40,
	},
	
	EffectOnBall = function(ball)
		local Pitcher = Gamevalues.CurrentPitcher.Value
        local Hitter = Gamevalues.CurrentBatter.Value
		local fireEmitter = AbilityFolder.BallFireEffect:Clone()
		for i, v in ipairs(fireEmitter:GetChildren()) do
			local clonedEffect = v:Clone()
			clonedEffect.Parent = ball
		end

		ball:SetAttribute("TimeScale", 0.7)
	end,

	EffectOnBat = function(player, bat)
		local Pitcher = Gamevalues.CurrentPitcher.Value
        local Hitter = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Heat", "Offensive", bat)
		wait(3.5)
		TransformationEffects.ShowHittingAura(Hitter)
	end,

	BatDuration = 2,
	BatHand = "Right",
	
	PowerDistance = 10
}


OffensiveAbilities.Gardener = {
	Modifiers = {
		MinDist = 175,
		MaxDist = 250,
		IgnoreUlts = true,
		XAngleMin = 30,
		XAngleMax = 90,
	},

	EffectOnBall = function(ball, predictedLocation)
		task.delay(2, function()
			local size = math.max(ball.Size.X, ball.Size.Y, ball.Size.Z)
			local garden = ReplicatedStorage.VFX.Garden:Clone()
			garden:PivotTo(CFrame.new(predictedLocation))

			for _, wall in garden.Walls:GetChildren() do
				if wall:IsA("BasePart") then
					wall.CollisionGroup = CollisionGroups.DEFENSE_BLOCKING_ULT_WALLS 
				end
			end

			garden.Parent = workspace
			garden.Script.Enabled = true

			task.delay(20, function()
				if garden.Parent then
					garden:SetAttribute("Free", true)
					task.wait(3)
					garden:Destroy()
				end
			end)

			local conn
			conn = game:GetService("RunService").Stepped:Connect(function()
				if ball.Parent and not garden:GetAttribute("Free") then
					local parts = workspace:GetPartBoundsInRadius(ball.Position, size + 1)

					for _, v in ipairs(parts) do
						local model = v:FindFirstAncestorOfClass("Model")
						local human = model and model:FindFirstChildOfClass("Humanoid")

						if v ~= ball
							and not v:IsDescendantOf(garden)
							and not human
							and (v:IsA("BasePart") or v:IsA("UnionOperation"))
							and v.Transparency < 1
							and v.CanCollide
							and (v:IsDescendantOf(workspace.Field) or v:IsDescendantOf(workspace.Plates))
						then
							print("🌱 GARDENER HIT:", v:GetFullName())

							conn:Disconnect()

							task.delay(3, function()
								if garden and garden.Parent then
									garden:SetAttribute("Free", true)

									task.delay(3, function()
										if garden and garden.Parent then
											garden:Destroy()
										end
									end)
								end
							end)

							break
						end
					end
				else
					conn:Disconnect()
				end
			end)
		end)
	end,

	EffectOnBat = function(player, bat)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Gardener", "Offensive", bat)
		wait(5.6)
		TransformationEffects.ShowHittingAura(Hitter)
	end,

	BatDuration = 2,
	BatHand = "Right",
	BatSide = "Left",
	
	ContactDistance = 20,
	PowerDistance = -10
}


OffensiveAbilities.Blizzard = {
	Modifiers = {
		MinDist = 200,
		MaxDist = 275,
		IgnoreUlts = true,
		XAngleMin = 20,
		XAngleMax = 30,
	},

	EffectOnBall = function(ball, predictedLocation)
		local Players = game:GetService("Players")

		local landingPos = predictedLocation
		if typeof(landingPos) ~= "Vector3" then
			local attr = ball:GetAttribute("PredictedLanding")
			if typeof(attr) == "Vector3" then
				landingPos = attr
			else
				landingPos = ball.Position
			end
		end

		local field = workspace:FindFirstChild("Field")
		if not field then
			warn("[Blizzard] workspace.Field not found")
			return
		end

		local stripeParts = {}
		local originalStates = {}

		local DARK_ICE_COLOR   = Color3.fromRGB(144, 220, 210)
		local LIGHT_ICE_COLOR  = Color3.fromRGB(159, 243, 233)
		local DIRT_BLIZZARD    = Color3.fromRGB(223, 223, 222)

		local DARK_RESTORE     = field:FindFirstChild("DarkStripe") and field.DarkStripe.Color
		local LIGHT_RESTORE    = field:FindFirstChild("LightStripe") and field.LightStripe.Color
		local DIRT_RESTORE     = field:FindFirstChild("Dirt") and field.Dirt.Color

		for _, part in ipairs(field:GetDescendants()) do
			if part:IsA("BasePart") and (part.Name == "DarkStripe" or part.Name == "LightStripe" or part.Name == "Dirt") then
				table.insert(stripeParts, part)
				table.insert(originalStates, {
					part     = part,
					material = part.Material,
				})

				if part.Name == "DarkStripe" then
					part.Material = Enum.Material.Ice
					part.Color = DARK_ICE_COLOR
				elseif part.Name == "LightStripe" then
					part.Material = Enum.Material.Ice
					part.Color = LIGHT_ICE_COLOR
				elseif part.Name == "Dirt" then
					part.Color = DIRT_BLIZZARD
				end
			end
		end

		local iceTemplate = VFX:FindFirstChild("IceCube")
		local iceCubes = {}
		local frozenChars = {}

		local function freezeCharacter(char: Model, cubePos: Vector3, cubePart: BasePart)
			if frozenChars[char] then return end

			local hum = char:FindFirstChildOfClass("Humanoid")
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hum or not hrp then return end

			local plr = Players:GetPlayerFromCharacter(char)
			if plr then
				AntiExploit.Ignore(plr, 2)
			end

			frozenChars[char] = {
				hum      = hum,
				ws       = hum.WalkSpeed,
				jp       = hum.JumpPower,
				anchored = hrp.Anchored,
			}

			local insidePos = cubePos + Vector3.new(0, 3, 0)
			hrp.CFrame = CFrame.new(insidePos, insidePos + hrp.CFrame.LookVector)
			hum.WalkSpeed = 0
			hum.JumpPower = 0
			hrp.Anchored = true

			task.delay(2, function()
				local data = frozenChars[char]
				if data and data.hum and data.hum.Parent and hrp.Parent then
					data.hum.WalkSpeed = data.ws
					data.hum.JumpPower = data.jp
					hrp.Anchored = data.anchored
				end
				frozenChars[char] = nil

				if cubePart and cubePart.Parent then
					cubePart:Destroy()
				end
			end)
		end

		if iceTemplate and iceTemplate:IsA("BasePart") then
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Blacklist
			rayParams.FilterDescendantsInstances = {ball}

			local NUM_CUBES = 5
			local RADIUS = 10

			for i = 1, NUM_CUBES do
				local angle = (i - 1) * (2 * math.pi / NUM_CUBES)
				local offset = Vector3.new(math.cos(angle) * RADIUS, 0, math.sin(angle) * RADIUS)

				local start = landingPos + offset + Vector3.new(0, 40, 0)
				local result = workspace:Raycast(start, Vector3.new(0, -200, 0), rayParams)
				local basePos = result and result.Position or (landingPos + offset)

				local cube = iceTemplate:Clone()
				cube.Name = "BlizzardIceCube"
				cube.Anchored = true
				cube.CanCollide = false
				cube.CanQuery = true
				cube.CanTouch = true
				cube.Parent = workspace
				table.insert(iceCubes, cube)

				local pos = basePos + Vector3.new(0, cube.Size.Y / 2, 0)
				cube.CFrame = CFrame.new(pos)

				cube.Touched:Connect(function(hit)
					if not hit or not hit:IsA("BasePart") then return end
					local model = hit:FindFirstAncestorOfClass("Model")
					if not model then return end
					local hum = model:FindFirstChildOfClass("Humanoid")
					if not hum then return end
					freezeCharacter(model, basePos, cube)
				end)
			end
		else
			warn("[Blizzard] ReplicatedStorage.VFX.IceCube not found or not a BasePart")
		end

		task.delay(15, function()
			for _, info in ipairs(originalStates) do
				if info.part and info.part.Parent then
					info.part.Material = info.material
					if info.part.Name == "DarkStripe" then
						info.part.Color = DARK_RESTORE
					elseif info.part.Name == "LightStripe" then
						info.part.Color = LIGHT_RESTORE
					elseif info.part.Name == "Dirt" then
						info.part.Color = DIRT_RESTORE
					end
				end
			end

			for _, cube in ipairs(iceCubes) do
				if cube and cube.Parent then
					cube:Destroy()
				end
			end
		end)
	end,

	EffectOnBat = function(player, bat)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter  = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Blizzard", "Offensive", bat)
		wait(11)
		TransformationEffects.ShowHittingAura(Hitter)
	end,

	BatDuration = 2,
	BatHand = "Right",
	BatSide = "Right",
	PowerDistance = 20,
	PowerAccuracy = .45,
	ContactAccuracy = .8,
}


OffensiveAbilities.Deadeye = {

	Modifiers = {
		MinDist = 200,
		MaxDist = 300,
		IgnoreUlts = true,
		XAngleMin = 20,
		XAngleMax = 40,
	},

	EffectOnBall = function(ball)
		
	end,

	EffectOnBat = function(player, bat)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Deadeye", "Offensive", bat)
		wait(14)
		TransformationEffects.ShowHittingAura(Hitter)
	end,

	BatDuration = 2,
	BatHand = "Right",

	PowerDistance = 10
}

OffensiveAbilities.Portal = {
	Modifiers = {
		OverrideHit = true,
	},

	EffectOnBall = function(ball, predictedLocation)		
		local regions = workspace.OutfieldRegions:GetChildren()
		local chosen = regions[math.random(#regions)]
		local size = chosen.Size / 2
		local cf = chosen.CFrame * CFrame.new(math.random(-size.X, size.X), 0, math.random(-size.Z, size.Z))

		local dropHeight = 50

		ball.CFrame = CFrame.new(cf.X, dropHeight, cf.Z)
		--ball.Anchored = true
		ball.Transparency = 1
		ball.Velocity = Vector3.new(0, -1, 0)

		task.delay(2.15, function()
			local portal = ReplicatedStorage.VFX.Portal:Clone()
			portal:PivotTo(CFrame.new(cf.X, dropHeight, cf.Z))
			portal.Parent = workspace.VFXFolder

			ball.Anchored = false
			ball.CanCollide = true
			ball.Transparency = 0
			ball.Velocity = Vector3.new(0, -1, 0)

			task.delay(0.35, function()
				portal:Destroy()
			end)
		end)
	end,

	EffectOnBat = function(player, bat)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Portal", "Offensive", bat)
		wait(4.1)
		TransformationEffects.ShowHittingAura(Hitter)
	end,

	BatDuration = 2,
	BatHand = "Right",
	BatSide = "Right",
	
	ContactAccuracy = .8
}


OffensiveAbilities.Boomerang = {
	Modifiers = {
		MinDist = 160,
		MaxDist = 330,
		IgnoreUlts = true,
		XAngleMin = 50,
		XAngleMax = 90,
	},

	EffectOnBall = function(ball, predictedLocation, xClickOffset)
		if predictedLocation.Z > ClientFunctions.GetFoulWallPos("FairZ") or predictedLocation.X > ClientFunctions.GetFoulWallPos("FairX") then
			print ("foul")
			Gamevalues.BallFouled.Value = true
		end

		task.spawn(function()
			local indicator = workspace.LandingIndicators:WaitForChild("Indicator", 10)
			if indicator then
				print (indicator)
				indicator.FollowBall.Enabled = true
			end
		end)
		task.delay(3, function()
			print ("BALL MOVE")
			local dir = CFrame.new(Vector3.new(ball.Position.X, predictedLocation.Y, ball.Position.Z), predictedLocation)
			local force = Instance.new("BodyForce", ball)
			force.Force = dir.RightVector * xClickOffset * 1.05
		end)
	end,

	EffectOnBat = function(player, bat)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Boomerang", "Offensive", bat)
		TransformationEffects.UltimateActivateEffect(player, true)
		wait(7)
	end,

	BatDuration = 2,
	BatHand = "Left",
	BatSide = "Left",

	ContactDistance = 20,
	PowerDistance = -10
}



OffensiveAbilities.Combustion = {
	Modifiers = {
		MinDist   = 140,   -- shorter so HRs are effectively off
		MaxDist   = 220,
		XAngleMin = 45,
		XAngleMax = 60,
		IgnoreUlts = true,
	},

	EffectOnBall = function(ball)
		local rs = game:GetService("RunService")
		local Debris = game:GetService("Debris")

		-- ensure VFX folder exists (safe parent for the bomb model/part)
		local vfxFolder = workspace:FindFirstChild("VFXFolder")
		if not vfxFolder then
			vfxFolder = Instance.new("Folder")
			vfxFolder.Name = "VFXFolder"
			vfxFolder.Parent = workspace
		end

		-- clone bomb (supports Model or Part; we only use it as a visual)
		local bombTemplate = ReplicatedStorage:WaitForChild("VFX"):FindFirstChild("Bomb")
		local bomb = bombTemplate and bombTemplate:Clone() or Instance.new("Part")
		if bomb:IsA("Part") then
			bomb.Shape = Enum.PartType.Ball
			bomb.Material = Enum.Material.Metal
			bomb.Color = Color3.fromRGB(255, 120, 60)
			bomb.Size = Vector3.new(2.5, 2.5, 2.5)
		end
		bomb.Name = "CombustionBomb"
		bomb.Parent = vfxFolder

		-- find a BasePart to weld (PrimaryPart if Model, or the Part itself)
		local function getPrimaryPart(modelOrPart)
			if modelOrPart:IsA("BasePart") then
				return modelOrPart
			elseif modelOrPart:IsA("Model") then
				if not modelOrPart.PrimaryPart then
					for _, c in ipairs(modelOrPart:GetDescendants()) do
						if c:IsA("BasePart") then
							modelOrPart.PrimaryPart = c
							break
						end
					end
				end
				return modelOrPart.PrimaryPart
			end
		end

		local bombPart = getPrimaryPart(bomb)
		if not bombPart then
			warn("[Combustion] Bomb has no BasePart to weld!")
			bomb:Destroy()
			return
		end

		-- place, unanchor, weld to ball
		bomb:PivotTo(CFrame.new(ball.Position))
		bombPart.Anchored = false
		bombPart.CanCollide = false

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = ball
		weld.Part1 = bombPart
		weld.Parent = ball

		-- slightly dampen bounciness so it doesn't pogo forever
		do
			local pp: PhysicalProperties = ball.CurrentPhysicalProperties
			ball.CustomPhysicalProperties = PhysicalProperties.new(
				pp.Density, pp.Friction, 0.4, pp.FrictionWeight, pp.ElasticityWeight
			)
		end

		local exploded = false
		local function explode()
			if exploded or not ball.Parent then return end
			exploded = true

			-- core Roblox Explosion
			local ex = Instance.new("Explosion")
			ex.BlastPressure = 0                -- no physics nuke; we'll do gentle knockback manually
			ex.DestroyJointRadiusPercent = 0
			ex.BlastRadius = 10
			ex.Position = ball.Position
			ex.Parent = workspace

			-- gentle knockback to nearby players
			local radius = 12
			local parts = workspace:GetPartBoundsInRadius(ex.Position, radius)
			local hitModels = {}
			for _, p in ipairs(parts) do
				local m = p:FindFirstAncestorOfClass("Model")
				local hum = m and m:FindFirstChildOfClass("Humanoid")
				local hrp = m and m:FindFirstChild("HumanoidRootPart")
				if hum and hrp and not hitModels[m] then
					hitModels[m] = true
					local dir = (hrp.Position - ex.Position)
					if dir.Magnitude < 0.01 then dir = Vector3.new(0,1,0) end
					dir = dir.Unit
					hrp.AssemblyLinearVelocity += dir * 28 + Vector3.new(0, 14, 0)
				end
			end

			-- cleanup bomb & weld
			if weld.Parent then weld:Destroy() end
			if bomb.Parent then bomb:Destroy() end
		end

		-- explode only when touching these field pieces
		local VALID_NAMES = {
			Dirt = true,
			LightStripe = true,
			DarkStripe = true,
		}

		local touchConn
		touchConn = ball.Touched:Connect(function(hit)
			if exploded then
				touchConn:Disconnect()
				return
			end
			-- Only those specific ground parts/unions should trigger
			if hit and hit:IsA("BasePart") and VALID_NAMES[hit.Name] then
				touchConn:Disconnect()
				explode()
			end
		end)

		-- absolute failsafe: auto-explode after 7 seconds
		task.delay(7, function()
			if not exploded then
				if touchConn then touchConn:Disconnect() end
				explode()
			end
		end)
	end,

	EffectOnBat = function(player, bat)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter  = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Combustion", "Offensive", bat)
		wait(6.1)
		TransformationEffects.ShowHittingAura(Hitter)
	end,

	BatDuration = 3,
	BatHand = "Right",
	BatSide = "Right",

	PowerDistance = 10,
	PowerAccuracy = .35,
}

OffensiveAbilities.SlimeSwing = {
	Effect = function(ball)
		local slimeEmitter = nil
		slimeEmitter.Parent = ball

		local velocity = ball.AssemblyLinearVelocity
		ball.AssemblyLinearVelocity = velocity * 0.8

		game:GetService("RunService").Stepped:Connect(function()
			if ball.Parent then
				ball.AssemblyLinearVelocity = ball.AssemblyLinearVelocity + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
			end
		end)
	end
}


--// Whirlwind Ability
OffensiveAbilities.Whirlwind = {
	Modifiers = {
		MinDist = 150,
		MaxDist = 250,
		IgnoreUlts = true,
		XAngleMin = 15,
		XAngleMax = 25, 
	},

	EffectOnBall = function(ball)
		local tornado = ReplicatedStorage.VFX.Tornado2:Clone()

		tornado.Position = ball.Position

		local weld = Instance.new("Weld")
		weld.Part0 = ball
		weld.Part1 = tornado
		weld.Parent = tornado

		ball.Transparency = 0
		tornado.CanCollide = false
		tornado.Parent = workspace.VFXFolder

		local runService = game:GetService("RunService")
		local startTime = tick()
		local checkRadius = math.max(ball.Size.X, ball.Size.Y, ball.Size.Z) + 3 -- a little padding
		VFXHandler.TransferEffects(VFX.TornadoEffect, ball)
		-- Continuously check for player collisions or time expiry
		local conn
		conn = runService.Stepped:Connect(function()
			if not ball.Parent then
				conn:Disconnect()
				return
			end

			-- Remove tornado after 4 seconds
			if tick() - startTime > 4 then
				conn:Disconnect()
				tornado:Destroy()
				print ("How")
				ball.Transparency = 0
				return
			end

			-- Check if ball+tornado hits a player
			local parts = workspace:GetPartBoundsInRadius(ball.Position, checkRadius)
			for _, part in ipairs(parts) do
				if part ~= ball and part.Parent and part.Name == "HumanoidRootPart" then
					local character = part.Parent
					local humanoid = character:FindFirstChild("Humanoid")
					
					local playerHit = Players:GetPlayerFromCharacter(character)
					
					if playerHit and ClientFunctions.PlayerIsOffense(playerHit) then
						continue
					end
					
					if humanoid then
						-- Knock the player back
						local knockDirection = (part.Position - ball.Position).Unit
						-- Add a little upward force
						part.Velocity = knockDirection * 40 + Vector3.new(0, 25, 0)

						-- Optionally slow them down briefly
						local oldWS = humanoid.WalkSpeed
						local oldJP = humanoid.JumpPower
						humanoid.WalkSpeed = 0
						humanoid.JumpPower = 0
						task.delay(2, function()
							humanoid.WalkSpeed = oldWS
							humanoid.JumpPower = oldJP
						end)

						-- Break the weld and destroy the tornado
						conn:Disconnect()
						weld:Destroy()
						tornado:Destroy()
						ball.Transparency = 0
						print ("DESTROYED")
						return
					end
				end
			end
		end)
	end,

	EffectOnBat = function(player, bat)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Whirlwind", "Offensive", bat)
		TransformationEffects.UltimateActivateEffect(player, true)
		wait (6)
	end,

	BatDuration = 2,
	BatHand = "Left",
	BatSide = "Left",

	ContactAccuracy = .8
}



--// BouncyBall Ability
OffensiveAbilities.Elastic = {
	Modifiers = {
		MinDist = 100,
		MaxDist = 200,
		IgnoreUlts = true,
		XAngleMin = 5,
		XAngleMax = 80,
	},

	EffectOnBall = function(ball)
		local bounceCount   = 0
		local maxBounces    = 3
		local MIN_SPEED     = 70    -- keep the chaos lively
		local MAX_SPEED     = 180   -- but not insane
		local HORIZ_BIAS    = 0.85  -- 0..1: closer to 1 = flatter bounces
		local SPEED_DECAY   = 0.85  -- lose a little speed each bounce
		local CONTACT_COOLD = 0.06  -- ignore rapid multi-fires from same touch

		local lastBounceTime = 0
		local lastTouched    = nil

		local function randUnitHoriz()
			-- random horizontal dir; never zero
			local x,z = math.random(-100,100)/100, math.random(-100,100)/100
			if x == 0 and z == 0 then x = 1 end
			return (Vector3.new(x, 0, z)).Unit
		end

		local function pickRandomDir()
			-- Strong horizontal bias, with some upward Y
			local horiz = randUnitHoriz() * HORIZ_BIAS
			local upY   = math.random(15, 55) / 100  -- 0.15..0.55 upward
			local v     = Vector3.new(horiz.X, upY, horiz.Z)
			return v.Unit
		end

		local function clampSpeed(v)
			local m = v.Magnitude
			if m < 1e-6 then
				return pickRandomDir() * MIN_SPEED
			end
			local target = math.clamp(m * SPEED_DECAY, MIN_SPEED, MAX_SPEED)
			return v.Unit * target
		end

		local bouncedConnection
		bouncedConnection = ball.Touched:Connect(function(hit)
			-- basic sanity + debounce
			if not hit or not hit:IsA("BasePart") then return end
			local now = time()
			if hit == lastTouched and (now - lastBounceTime) < CONTACT_COOLD then return end

			-- only care about surfaces that act like ground-ish (not walls it just grazed)
			local upDot = hit.CFrame.UpVector:Dot(Vector3.new(0, 1, 0))
			if upDot <= 0.5 then return end

			-- count & stop if done
			bounceCount += 1
			lastTouched = hit
			lastBounceTime = now

			if bounceCount > maxBounces then
				if bouncedConnection then
					bouncedConnection:Disconnect()
				end
				return
			end

			-- choose a new “random-everywhere (but not straight up)” direction
			-- with a little dependence on current speed so it feels snappy
			local cur = ball.AssemblyLinearVelocity
			local dir = pickRandomDir()

			-- mix in some of the incoming direction to feel less teleporty
			if cur.Magnitude > 1 then
				local blend = 0.25 -- 0=fully random, 1=mostly reflect-y
				dir = (dir * (1 - blend) + cur.Unit * blend).Unit
			end

			-- apply with sensible speed
			local newV = clampSpeed(dir * math.max(cur.Magnitude, MIN_SPEED))
			ball.AssemblyLinearVelocity = newV
		end)
	end,

	EffectOnBat = function(player, bat)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter  = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Elastic", "Offensive", bat)
		task.wait(4.1)
		TransformationEffects.ShowHittingAura(Hitter)
	end,

	BatDuration = 2,
	BatHand = "Left",
	BatSide = "Left",

	ContactAccuracy = 0.8,
	PowerDistance  = -10,
}

--// SeismicHit Ability
OffensiveAbilities.Impact = {
	Modifiers = {
		MinDist = 250,
		MaxDist = 375,
		IgnoreUlts = true,
		XAngleMin = 20,
		XAngleMax = 40,
	},

	EffectOnBall = function(ball)
		local TweenService = game:GetService("TweenService")
		local Debris = game:GetService("Debris")

		local maxRocks = 30
		local interval = 0.1
		local spawned = 0
		local isActive = true

		local knockForce = 60
		local knockUp = 25
		local sitTime = 0.8

		local function addKnockback(rock)
			local hitCooldown = {}
			rock.Touched:Connect(function(part)
				if part.Name ~= "HumanoidRootPart" then return end
				local character = part.Parent
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if not humanoid or not root then return end
				if hitCooldown[character] then return end
				hitCooldown[character] = true

				-- Knockback direction
				local dir = (root.Position - rock.Position).Unit
				if dir.Magnitude < 0.001 then dir = Vector3.new(1,0,0) end
				root.Velocity = dir * knockForce + Vector3.new(0, knockUp, 0)

				-- Sit briefly
				humanoid.Sit = true
				task.delay(sitTime, function()
					if humanoid and humanoid.Parent then
						humanoid.Sit = false
					end
					hitCooldown[character] = nil
				end)
			end)
		end

		-- Spawn rocks under the ball as it travels
		task.spawn(function()
			while isActive and spawned < maxRocks do
				if not ball or not ball.Parent then break end

				local origin = ball.Position
				local direction = Vector3.new(0, -100, 0)
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
				raycastParams.FilterDescendantsInstances = {ball}

				local result = workspace:Raycast(origin, direction, raycastParams)

				if result and result.Instance then
					local character = result.Instance:FindFirstAncestorOfClass("Model")
					local isHumanoidCharacter = character and character:FindFirstChildOfClass("Humanoid")

					if not isHumanoidCharacter then
						local pos = result.Position

						local rock = ReplicatedStorage.VFX.SpikyRock:Clone()
						rock.Position = pos + Vector3.new(0, rock.Size.Y / 2, 0)
						rock.Anchored = true
						rock.CanCollide = false
						rock.Parent = workspace.VFXFolder

						rock.Size = Vector3.new(1, 1, 1)
						local growTween = TweenService:Create(rock, TweenInfo.new(0.3, Enum.EasingStyle.Elastic), {
							Size = Vector3.new(5, 5, 5)
						})
						growTween:Play()

						addKnockback(rock)
						Debris:AddItem(rock, 2)
						spawned += 1
					end
				end

				task.wait(interval)
			end
		end)

		-- Stop spawning if the ball touches the ground
		ball.Touched:Connect(function(hit)
			if hit:IsA("BasePart") and hit.Position.Y < ball.Position.Y then
				isActive = false
			end
		end)
	end,

	EffectOnBat = function(player, bat)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Impact", "Offensive", bat)
		task.wait(5.6)
		TransformationEffects.ShowHittingAura(Hitter)
	end,

	BatDuration = 2,
	BatHand = "Right",
	BatSide = "Left",

	PowerDistance = 30,
	PowerAccuracy = .3
}


OffensiveAbilities.Firetwist = {
	Modifiers = {
		MinDist = 200,
		MaxDist = 400,
		IgnoreUlts = true,
		XAngleMin = 20,
		XAngleMax = 50,
	},

	EffectOnBall = function(ball)
		-- Ensure a workspace holder for VFX
		local vfxFolder = workspace:FindFirstChild("VFXFolder")
		if not vfxFolder then
			vfxFolder = Instance.new("Folder")
			vfxFolder.Name = "VFXFolder"
			vfxFolder.Parent = workspace
		end

		-- Base flame on the ball (clone the emitters, not just the folder)
		for _, child in ipairs(AbilityFolder.BallFireEffect:GetChildren()) do
			child:Clone().Parent = ball
		end

		-- Follower settings (tweak here)
		local sideOffset     = 9.0   -- further out from the ball (was 5)
		local verticalOffset = 1.25  -- a little above center
		local trailLength    = 6.0   -- seconds to keep following

		local function makeFireFollower(side) -- side = +1 (right) or -1 (left)
			local p = Instance.new("Part")
			p.Name = (side > 0) and "FiretwistRight" or "FiretwistLeft"
			p.Size = Vector3.new(3.5, 3.5, 3.5)   -- bigger + easier to see
			p.Shape = Enum.PartType.Ball
			p.Material = Enum.Material.Neon
			p.Color = Color3.fromRGB(255, 100, 20)
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Transparency = 0
			p.Parent = vfxFolder

			-- Make it pop visually
			local light = Instance.new("PointLight")
			light.Range = 20
			light.Brightness = 2.5
			light.Parent = p

			-- Add the same fire emitters the ball uses (clone children so they render)
			for _, child in ipairs(AbilityFolder.BallFireEffect:GetChildren()) do
				local e = child:Clone()
				e.Parent = p
				if e:IsA("ParticleEmitter") then
					-- Slightly juiced so they’re obvious
					e.Rate = math.max(e.Rate, 120)
					e.Size = NumberSequence.new({
						NumberSequenceKeypoint.new(0.0, 2.2),
						NumberSequenceKeypoint.new(1.0, 0.8)
					})
					e.Enabled = true
				end
			end

			-- Follow the ball until timeout or ball is gone
			local start = time()
			local conn
			conn = RunService.Heartbeat:Connect(function()
				if not ball or not ball.Parent then
					if conn then conn:Disconnect() end
					if p then p:Destroy() end
					return
				end

				-- Position to the side of the ball, in ball-local space
				p.CFrame = ball.CFrame * CFrame.new(side * sideOffset, verticalOffset, 0)

				if time() - start > trailLength then
					if conn then conn:Disconnect() end
					if p then p:Destroy() end
				end
			end)
		end

		-- Two followers: left and right
		makeFireFollower(1)
		makeFireFollower(-1)
	end,

	EffectOnBat = function(player, bat)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter  = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Firetwist", "Offensive", bat)
		wait(6)
		TransformationEffects.ShowHittingAura(Hitter)
	end,

	BatDuration = 2,
	BatHand = "Left",
	BatSide = "Right",
	PowerDistance = 10
}

OffensiveAbilities.Overdrive = {
	Modifiers = {
		MinDist = 150,
		MaxDist = 250,
		IgnoreUlts = true,
		XAngleMin = 20,
		XAngleMax = 30,
	},

	EffectOnBall = function(ball)
		local pitcher = Gamevalues.CurrentPitcher.Value
		local hitter  = Gamevalues.CurrentBatter.Value

		-- 1) Add electric aura attachment to the ball (always on until first touch)
		local vfx = ReplicatedStorage:WaitForChild("VFX")
		local auraRoot = vfx:FindFirstChild("ElectricAura") or vfx:FindFirstChild("EletricAura") -- typo-safe
		local auraAttach = auraRoot and auraRoot:FindFirstChildWhichIsA("Attachment", true)

		local auraClone
		if auraAttach then
			auraClone = auraAttach:Clone()
			auraClone.Name = "OverdriveBallAura"
			auraClone.Parent = ball
			for _, d in ipairs(auraClone:GetDescendants()) do
				if d:IsA("ParticleEmitter") or d:IsA("Beam") then
					d.Enabled = true
				end
			end
		else
			warn("[Overdrive] ElectricAura attachment not found under ReplicatedStorage.VFX")
		end

		-- Ball is electrified until FIRST touch by any player
		ball:SetAttribute("OverdriveElectrified", true)
		
		-- 2) Remote to tell the zapped player to play anim + audio
		local ZapRemote = Remotes:FindFirstChild("OverdriveZap")
		if not ZapRemote then
			warn("[Overdrive] Missing RemoteEvents.OverdriveZap")
		end

		-- Helper to mark a player as zapped (server-side flag lets pickup code block)
		local function markZapped(plr, duration)
			duration = duration or 1.25
			if not plr then return end
			plr:SetAttribute("OverdriveZapped", true)
			local char = plr.Character
			if char then char:SetAttribute("OverdriveZapped", true) end
			task.delay(duration, function()
				if plr then plr:SetAttribute("OverdriveZapped", false) end
				if char and char.Parent then char:SetAttribute("OverdriveZapped", false) end
			end)
		end

		-- 3) First-touch zap + aura transfer to HRP for 2s
		local consumed = false
		local function tryZapPlayerFromHit(hit)
			if consumed then return end
			if not ball:GetAttribute("OverdriveElectrified") then return end
			if not hit or not hit:IsA("BasePart") then return end

			local model = hit:FindFirstAncestorOfClass("Model")
			local hum   = model and model:FindFirstChildOfClass("Humanoid")
			local hrp   = model and model:FindFirstChild("HumanoidRootPart")
			if not hum or not hrp then return end

			local plr = game.Players:GetPlayerFromCharacter(model)
			if not plr then return end

			-- Consume: mark player zapped, client FX, and move aura to HRP for 2s
			consumed = true
			markZapped(plr)
			if ZapRemote then
				ZapRemote:FireClient(plr)
			end

			-- move the SAME aura attachment from ball -> player's HRP for 2 seconds
			local movedAura = nil
			if auraClone and auraClone.Parent then
				auraClone.Parent = hrp
				movedAura = auraClone
			elseif auraAttach then
				-- fallback: if for some reason the ball aura is gone, clone a fresh one
				local newAura = auraAttach:Clone()
				newAura.Name = "OverdriveBallAura"
				newAura.Parent = hrp
				for _, d in ipairs(newAura:GetDescendants()) do
					if d:IsA("ParticleEmitter") or d:IsA("Beam") then
						d.Enabled = true
					end
				end
				movedAura = newAura
			end

			task.delay(2, function()
				if movedAura and movedAura.Parent then
					movedAura:Destroy()
				end
			end)

			-- Permanently disable the ball zap after first touch
			ball:SetAttribute("OverdriveElectrified", false)
		end

		-- Hook for zap on touch
		local touchConn = ball.Touched:Connect(tryZapPlayerFromHit)

		-- 4) Zig-zag (visual/motion only) after 0.5s for 4s, alternating L/R every 0.5s
		task.delay(0.5, function()
			if not ball or not ball.Parent then return end
			ball:SetAttribute("OverdriveZigzag", true) -- informational; not used for zap gating

			local sign = (math.random(1,2) == 1) and 1 or -1
			local TOGGLES = 8            -- every 0.5s for 4s
			local STEP    = 0.5
			local KICK    = 28           -- lateral velocity nudge per toggle

			for _ = 1, TOGGLES do
				if not ball or not ball.Parent then break end
				local v = ball.AssemblyLinearVelocity
				local up = Vector3.new(0,1,0)
				local side = v:Cross(up)
				if side.Magnitude < 0.001 then side = Vector3.new(1,0,0) end
				side = side.Unit
				ball.AssemblyLinearVelocity = v + (side * (sign * KICK))
				sign = -sign
				task.wait(STEP)
			end

			ball:SetAttribute("OverdriveZigzag", false)
		end)

		-- 5) Cleanup
		ball.Destroying:Connect(function()
			if touchConn then touchConn:Disconnect() end
		end)
	end,

	EffectOnBat = function(player, bat)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter  = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Overdrive", "Offensive", bat)
		wait(8.06)
		TransformationEffects.ShowHittingAura(Hitter)
	end,

	BatDuration = 2,
	BatHand = "Left",
	BatSide = "Left",
	ContactAccuracy = .8,
}

OffensiveAbilities.Harvest = {
	Modifiers = {
		MinDist = 200,
		MaxDist = 275,
		IgnoreUlts = true,
		XAngleMin = 20,
		XAngleMax = 30,
	},

	EffectOnBall = function(ball, predictedLocation)
		local Debris     = game:GetService("Debris")
		local hitter      = Gamevalues.CurrentBatter.Value
		local vfxRoot     = ReplicatedStorage:WaitForChild("VFX")
		local cornFieldTemplate = vfxRoot:FindFirstChild("CornField")

		if not cornFieldTemplate then
			warn("[Harvest] Missing ReplicatedStorage.VFX.CornField model")
			return
		end

		-- Where should the cornfield spawn?
		local landingPos = predictedLocation
		if typeof(landingPos) ~= "Vector3" then
			local attr = ball:GetAttribute("PredictedLanding")
			if typeof(attr) == "Vector3" then
				landingPos = attr
			else
				landingPos = ball.Position
			end
		end

		-- Raycast down to the ground
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist
		rayParams.FilterDescendantsInstances = {ball}

		local origin   = landingPos + Vector3.new(0, 60, 0)
		local result   = workspace:Raycast(origin, Vector3.new(0, -200, 0), rayParams)
		local fieldPos = result and result.Position or landingPos

		-- Sink it ~2 studs into the ground so the stalks are buried a bit
		fieldPos = fieldPos - Vector3.new(0, 2, 0)

		local cornField = cornFieldTemplate:Clone()
		cornField.Name = "HarvestCornField"
		cornField.Parent = workspace

		if cornField:IsA("Model") and cornField.PrimaryPart then
			cornField:PivotTo(CFrame.new(fieldPos))
		elseif cornField:IsA("BasePart") then
			cornField.Position = fieldPos
		end

		local FIELD_LIFETIME = 12 -- seconds the corn stays around

		----------------------------------------------------------------------
		-- SLOWING LOGIC (WalkSpeed scaling, but fully restored afterwards)
		----------------------------------------------------------------------

		-- [humanoid] = current contact count
		local slowContacts = {}

		local SLOW_FACTOR = 0.3 -- keep 30% of original WalkSpeed (70% slow)

		local function getCharacterFromHit(hit: BasePart)
			if not hit then return nil end

			local character = hit.Parent
			local hum = character and character:FindFirstChildOfClass("Humanoid")

			if not hum and hit.Parent then
				character = hit.Parent.Parent
				hum = character and character:FindFirstChildOfClass("Humanoid")
			end

			if hum and hum.Health > 0 then
				return character, hum
			end
			return nil, nil
		end

		local function applySlow(humanoid: Humanoid)
			-- store base speed once per humanoid
			if humanoid:GetAttribute("HarvestSlowBaseWS") == nil then
				humanoid:SetAttribute("HarvestSlowBaseWS", humanoid.WalkSpeed)
			end

			local baseWS = humanoid:GetAttribute("HarvestSlowBaseWS") or humanoid.WalkSpeed
			local newWS = baseWS * SLOW_FACTOR

			-- don't spam if already at or below target
			if math.abs(humanoid.WalkSpeed - newWS) > 0.1 then
				humanoid.WalkSpeed = newWS
			end
		end

		local function clearSlow(humanoid: Humanoid)
			local baseWS = humanoid:GetAttribute("HarvestSlowBaseWS")
			if baseWS then
				humanoid.WalkSpeed = baseWS
				humanoid:SetAttribute("HarvestSlowBaseWS", nil)
			end
			slowContacts[humanoid] = nil
		end

		local function onCornTouched(hit)
			local character, hum = getCharacterFromHit(hit)
			if not character or not hum then return end

			-- optional: don't slow the batter who used Harvest
			local plr = game.Players:GetPlayerFromCharacter(character)
			if plr and hitter and plr == hitter then
				return
			end

			local count = (slowContacts[hum] or 0) + 1
			slowContacts[hum] = count

			-- First contact → apply slow
			if count == 1 then
				applySlow(hum)
			end
		end

		local function onCornTouchEnded(hit)
			local character, hum = getCharacterFromHit(hit)
			if not character or not hum then return end

			local count = (slowContacts[hum] or 0) - 1
			if count < 0 then count = 0 end
			slowContacts[hum] = count

			-- No more corn touching this humanoid → restore speed
			if count == 0 then
				clearSlow(hum)
			end
		end

		-- Make all corn parts non-collide but touchable + hook events
		for _, obj in ipairs(cornField:GetDescendants()) do
			if obj:IsA("BasePart") then
				obj.CanCollide = false      -- walk through
				obj.CanQuery  = true
				obj.CanTouch  = true

				obj.Touched:Connect(onCornTouched)
				obj.TouchEnded:Connect(onCornTouchEnded)
			end
		end

		-- Cleanup corn + restore anyone still slowed (failsafe)
		task.delay(FIELD_LIFETIME, function()
			if cornField and cornField.Parent then
				cornField:Destroy()
			end
			for hum, _ in pairs(slowContacts) do
				if hum and hum.Parent then
					clearSlow(hum)
				end
			end
		end)

		Debris:AddItem(cornField, FIELD_LIFETIME + 1)
	end,

	EffectOnBat = function(player, bat)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter  = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Harvest", "Offensive", bat)
		wait(13.6)
		TransformationEffects.ShowHittingAura(Hitter)
	end,

	BatDuration = 2,
	BatHand = "Left",
	BatSide = "Left",
	PowerDistance = 20,
}

OffensiveAbilities.Shadow = {
	Modifiers = {
		MinDist = 200,
		MaxDist = 350,
		IgnoreUlts = true,
		XAngleMin = 20,
		XAngleMax = 50,
	},

	EffectOnBall = function(ball)
		-- Flag this flight to suppress indicators/markers
		ball:SetAttribute("NoIndicator", true)

		-- (optional) a small speed bump
		ball.AssemblyLinearVelocity *= 1.15

		-- your VFX
		task.spawn(function()
			local shadowVFX = ReplicatedStorage.SharedModules.AbilityCinematics.Offensive.Shadow.VFX.BaseballVFX
			for _, v in pairs(shadowVFX:GetChildren()) do
				v:Clone().Parent = ball
			end
		end)

		-- Clean, periodic blink (no random flicker)
		local RunService = game:GetService("RunService")
		local period, duty = 0.28, 0.5  -- ~3–4 blinks/sec, 50% on
		local t0 = time()
		local hb
		hb = RunService.Heartbeat:Connect(function()
			if not ball or not ball.Parent then
				if hb then hb:Disconnect() end
				return
			end
			local phase = (time() - t0) % period
			ball.Transparency = (phase < period * duty) and 0 or 1
		end)

		-- Stop blinking on land/touch OR after a cap (failsafe)
		local function cleanup()
			if hb then hb:Disconnect() end
			if ball and ball.Parent then
				ball.Transparency = 0
			end
			-- keep NoIndicator on; this flight shouldn’t ever show a marker
		end
		ball.Touched:Once(function() cleanup() end)
		task.delay(5.5, cleanup)
	end,

	EffectOnBat = function(player, bat)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter  = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Shadow", "Offensive", bat)
		wait(6.75)
		TransformationEffects.ShowHittingAura(Hitter)
	end,

	BatDuration = 2,
	BatHand = "Left",
	BatSide = "Left",
	PowerDistance = 10
}

OffensiveAbilities.Skybound = {
	Ability = function(player)
		TransformationEffects.StartAbilityAura(player)

		if player.Character and player.Character:FindFirstChild("Humanoid") then
			local character = player.Character
			local humanoid = player.Character.Humanoid 

			AntiExploit.Ignore(player, 2)
			
			Remotes.PlayClientVFXAnimation:FireClient(player, "Frontflip", true)

			humanoid.JumpPower = 100
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			humanoid.Jump = true

			task.delay(0.2, function()
				if humanoid then
					humanoid.JumpPower = 50
				end
			end)
		end
	end,

	AbilityConditionMet = function(player)
		local character = player.Character

		if character and character:FindFirstChild("Humanoid") then
			if character.Humanoid.FloorMaterial == Enum.Material.Air then
				return false
			else
				return true
			end
		end

		return false
	end,

	Ultimate = function(player)
		Remotes.EnableSpeedlinesVFX:FireClient(player, true)

		if player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.WalkSpeed = 25
		end

		TransformationEffects.StartUltimateAura(player)

		task.delay(6, function()
			Remotes.EnableSpeedlinesVFX:FireClient(player, false)

			if player.Character then
				if player.Character:FindFirstChild("Humanoid") then
					player.Character.Humanoid.WalkSpeed = 18
				end

				TransformationEffects.RemoveAuras(player)
			end
		end)
	end,

	UltimateConditionMet = function(player)
		return true
	end,

	Clear = function(player)
		Remotes.EnableSpeedlinesVFX:FireClient(player, false)

		if player.Character then
			if player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid.WalkSpeed = 18
			end

			TransformationEffects.RemoveAuras(player)
		end
	end,
}

OffensiveAbilities.Slipstream = {
	Ability = function(player)
		Remotes.EnableSpeedlinesVFX:FireClient(player, true)

		if player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.WalkSpeed = 25
		end
		
		TransformationEffects.StartAbilityAura(player)
		
		task.delay(3, function()
			Remotes.EnableSpeedlinesVFX:FireClient(player, false)

			if player.Character then
				if player.Character:FindFirstChild("Humanoid") then
					player.Character.Humanoid.WalkSpeed = 18
				end

				TransformationEffects.RemoveAuras(player)
			end
		end)
	end,
	
	AbilityConditionMet = function(player)
		return true
	end,

	Ultimate = function(player)
		Remotes.SuperSlide:FireClient(player)
	end,
	
	UltimateConditionMet = function(player)
		local character = player.Character
		
		if character and character:FindFirstChild("Humanoid") then
			if character.Humanoid.FloorMaterial == Enum.Material.Air then
				return false
			else
				return true
			end
		end
		
		return false
	end,

	Clear = function(player)
		Remotes.EnableSpeedlinesVFX:FireClient(player, false)

		if player.Character then
			if player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid.WalkSpeed = 18
			end

			TransformationEffects.RemoveAuras(player)
		end
	end,
}

OffensiveAbilities.Quantum = {
	QuantumWarp = function(player, nextBase, powerType)
		local currentBaseTracker = OnBase[player.Name]
		Remotes.QuantumTeleportEffect:FireClient(player, BasePlates[nextBase].Position)

		local warpStartSound = VFXParticlesFB.WarpEnd:Clone()
		warpStartSound.Parent = player.Character.HumanoidRootPart
		
		task.wait(1.1)
		
		if warpStartSound then
			warpStartSound:Destroy()
		end
		
		if not OnBase:FindFirstChild(player.Name) then
			return
		end
		
		if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local cframePos = CFrame.new(BasePlates[nextBase].Position) * CFrame.Angles(0, player.Character.HumanoidRootPart.Orientation.Y * math.pi/180, 0)
			
			Remotes.CancelSlideDive:FireClient(player)

			player.Character.HumanoidRootPart.Anchored = true
			
			AntiExploit.Ignore(player, 2)

			player.Character:PivotTo(cframePos)
			Remotes.CFramePlayerCharacter:FireClient(player, cframePos)			

			player.Character.HumanoidRootPart.Anchored = false
		end
		
		if powerType == "Ability" and not Gamevalues.Homerun.Value then
			currentBaseTracker.Value = "First Base"
			currentBaseTracker.LockedInBase.BaseElapseTime.Value = 3
			currentBaseTracker.LockedInBase.Value = true
		end
	end,
	
	Ability = function(player)
		OffensiveAbilities.Quantum.QuantumWarp(player, "First Base", "Ability")
	end,
	
	Ultimate = function(player)
		local currentBaseTracker = OnBase[player.Name]
		
		local nextBase = BaseSequence[currentBaseTracker.Value]
		
		if nextBase then
			OffensiveAbilities.Quantum.QuantumWarp(player, nextBase, "Ultimate")
		end
	end,
	
	AbilityConditionMet = function(player)
		local currentBaseTracker = OnBase[player.Name]
		
		if currentBaseTracker.LockedInBase.Value then return false end
		
		if currentBaseTracker.Value ~= "Home Base" then 
			Remotes.Notification:FireClient(player, "You’ve already reached first base!", "Alert")
			return false
		end
		
		return true
	end,
	
	UltimateConditionMet = function(player)
		local currentBaseTracker = OnBase[player.Name]
		
		if currentBaseTracker.LockedInBase.Value then return false end

		if currentBaseTracker.Value == "Third Base" then 
			Remotes.Notification:FireClient(player, "You can’t teleport — there are no more bases ahead!", "Alert")
			return false
		end

		
		return true
	end,
}

OffensiveAbilities.Phaser = {
	Ability = function(player)
		TransformationEffects.RemoveAuras(player)
		local flickerVFX = VFXParticlesFB.FlickerVFX.FlickerVFX:Clone()
		flickerVFX.Parent = player.Character.HumanoidRootPart
		
		local characterVisible = true
		
		-- Store original transparency states so they can be restored later
		local originalTransparency = {}
		for _, part in ipairs(player.Character:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("MeshPart") then
				originalTransparency[part] = part.Transparency
			elseif part:IsA("SurfaceGui") and part.Parent.Name == "JerseyInfo" then
				originalTransparency[part] = true
			end
		end
		
		while player 
			and player.Character 
			and player.Character:FindFirstChild("HumanoidRootPart")
			and Gamevalues.BallHit.Value 
		do
			for _, particle in pairs(flickerVFX:GetChildren()) do
				particle:Emit(2)
			end
			
			if characterVisible then
				characterVisible = false
				player.Character:SetAttribute("Untaggable", true)
				
				-- Hide character
				for _, part in ipairs(player.Character:GetDescendants()) do
					if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("MeshPart") then
						part.Transparency = 1
					elseif part:IsA("SurfaceGui") and part.Parent.Name == "JerseyInfo" then
						part.Enabled = false
					end
				end
				
				wait(1)
			else
				characterVisible = true
				player.Character:SetAttribute("Untaggable", false)
				
				-- Restore visibility
				for part, trans in pairs(originalTransparency) do
					if part and part.Parent then
						if part:IsA("SurfaceGui") then
							part.Enabled = true
						else
							part.Transparency = trans
						end
					end
				end
				--[[
				for _, part in ipairs(player.Character:GetDescendants()) do
					if part:IsA("ParticleEmitter") then
						part.Enabled = true
					end
				end
				--]]
				
				wait(1)
			end
		end
		
		if player.Character then
			player.Character:SetAttribute("Untaggable", false)
		end
		
		for part, trans in pairs(originalTransparency) do
			if part and part.Parent then
				if part:IsA("SurfaceGui") then
					part.Enabled = true
				else
					part.Transparency = trans
				end
			end
		end

		if flickerVFX then
			flickerVFX:Destroy()
		end

	end,
	
	AbilityConditionMet = function(player)
		return true
	end,

	Ultimate = function(player)
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			TransformationEffects.RemoveAuras(player)
			local shieldVFX = VFXParticlesFB.UntouchableVFX.ShieldVFX:Clone()
			shieldVFX.Parent =  player.Character.HumanoidRootPart
			
			player.Character:SetAttribute("Untaggable", true)
		end
		
		task.delay(2.5, function()			
			if player.Character then
				player.Character:SetAttribute("Untaggable", false)
				
				if player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart:FindFirstChild("ShieldVFX") then
					player.Character.HumanoidRootPart.ShieldVFX:Destroy()
				end
			end
		end)
	end,

	UltimateConditionMet = function(player)
		return true
	end,

	Clear = function(player)
		Remotes.EnableSpeedlinesVFX:FireClient(player, false)

		if player.Character then
			if player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart:FindFirstChild("ShieldVFX") then
				player.Character.HumanoidRootPart.ShieldVFX:Destroy()
			end

			TransformationEffects.RemoveAuras(player)
		end
	end,
}

return OffensiveAbilities