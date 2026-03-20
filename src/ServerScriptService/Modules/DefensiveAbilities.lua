local DefensiveAbilities = {}

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Modules = ServerScriptService.Modules
local SharedModules = ReplicatedStorage.SharedModules
local SharedData = ReplicatedStorage.SharedData

local AbilityFolder = game.ServerStorage.ServerObjects.Abilities
local VFXHandler = require(Modules.VFXHandler)
local ClientFunctions = require(SharedModules.ClientFunctions)
local CollisionGroups = require(SharedModules.CollisionGroups)
local TransformationEffects = require(Modules.TransformationEffects)
local AntiExploit = require(Modules.AntiExploit)
local BaseSequence = require(SharedModules.BaseSequence)

local VFX = ReplicatedStorage.VFX
local VFXParticlesFB = ReplicatedStorage.VFXParticlesFB

local BasePlates = workspace.Plates
local ServerObjects = ServerStorage.ServerObjects
local Remotes = ReplicatedStorage.RemoteEvents
local Gamevalues = ReplicatedStorage.GameValues
local OnBaseFolder = Gamevalues.OnBase

local function setupAbilityCamera(pitcher, hitter, styleName, styleType)
	Remotes.AbilityCamera:FireAllClients(pitcher, hitter, styleName, styleType)
end

DefensiveAbilities.Meditation = {
	EffectOnBall = function(player, ball)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Meditation", "Defensive")
	end,

	Curve = 2,
	Arc = 5,
	Power = 0.2,
	GloveHand = "Left"
}

DefensiveAbilities.Softball = {
	EffectOnBall = function(player, ball)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Softball", "Defensive")

		task.spawn(function()
			
		end)
	end,

	Curve = 2,
	Arc = 10,
	Power = 0.25,
	GloveHand = "Left",
}

DefensiveAbilities.Blight = {
	EffectOnBall = function(player, ball)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Blight", "Defensive")

		-- Spawn dirt 22 seconds after ult starts (after cinematic + throw)
		task.spawn(function()
			task.wait(9)
			DefensiveAbilities.Blight.SpawnDirtVFX()
		end)
	end,

	SpawnDirtVFX = function()
		local blightDirt = VFX:FindFirstChild("BlightDirt")
		if not blightDirt then return end

		local vfxFolder = workspace:FindFirstChild("VFXFolder")
		if not vfxFolder then
			vfxFolder = Instance.new("Folder")
			vfxFolder.Name = "VFXFolder"
			vfxFolder.Parent = workspace
		end

		local clone = blightDirt:Clone()
		clone.Parent = vfxFolder

		local emitters = {}
		for _, desc in ipairs(clone:GetDescendants()) do
			if desc:IsA("ParticleEmitter") then
				table.insert(emitters, desc)
			end
		end

		local BURST_INTERVAL = 0.3
		local DURATION = 3
		local BURST_COUNT = 25

		task.spawn(function()
			local elapsed = 0
			while elapsed < DURATION and clone.Parent do
				for _, emitter in ipairs(emitters) do
					if emitter.Parent then
						emitter:Emit(BURST_COUNT)
					end
				end
				task.wait(BURST_INTERVAL)
				elapsed += BURST_INTERVAL
			end
		end)

		Debris:AddItem(clone, DURATION)
	end,

	Curve = 2,
	Arc = 5,
	Power = 0.2,
	GloveHand = "Left",
	Direct = true,
	Speed = 0.85,
}

DefensiveAbilities.Flamethrower = {
	EffectOnBall = function(player, ball)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Flamethrower", "Defensive")
		local fireEmitter = AbilityFolder.BallFireEffect:Clone()
		for i, v in ipairs(fireEmitter:GetChildren()) do
			local clonedEffect = v:Clone()
			clonedEffect.Parent = ball
		end
	end,

	Curve = 2,
	Arc = 5,
	Power = 0.2,
	GloveHand = "Left"
}

DefensiveAbilities.Whirlwind = {
	EffectOnBall = function(player, ball)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value

		setupAbilityCamera(Pitcher, Hitter, "Whirlwind", "Defensive")
	end,

	Curve = 2,
	Arc = 5,
	Power = -0.6,
}

DefensiveAbilities.Seismic = {
	EffectOnBall = function(player, ball)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value

		setupAbilityCamera(Pitcher, Hitter, "Seismic", "Defensive")

		wait (5)

		local SeismicFolder = VFX.SeismicFolder:Clone()
		SeismicFolder.Parent = workspace.VFXFolder
		Debris:AddItem(SeismicFolder, 5)
		VFXHandler.SeismicRocksEffect(SeismicFolder, 10, 1.5, 2, 0.05)
	end,

	Curve = 2,
	Arc = 5,
	Power = 0,
}

DefensiveAbilities.Ascension = {
	EffectOnBall = function(player, ball)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value

		setupAbilityCamera(Pitcher, Hitter, "Ascension", "Defensive")
	end,

	Curve = 2,
	Arc = 30,
	Power = 0,
}

DefensiveAbilities.Kamehameha = {
	EffectOnBall = function(player, ball)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value

		setupAbilityCamera(Pitcher, Hitter, "Kamehameha", "Defensive")
	end,

	Curve = 2,
	Arc = 5,
	Power = 0.3,
}

DefensiveAbilities.Subzero = {
	EffectOnBall = function(player, ball)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value
		setupAbilityCamera(Pitcher, Hitter, "Subzero", "Defensive")

		if Hitter and Hitter:IsA("Player") then
			Remotes.SnowballEffect:FireClient(Hitter, 5)
		end

		wait(5)
	end,

	Curve = 2,
	Arc = 5,
	Power = 0.2,
	GloveHand = "Left"
}
DefensiveAbilities.Deceiver = {
	EffectOnBall = function(
		player: Player,
		ball: typeof(game.ServerStorage.ServerObjects.Baseball),
		_from: Vector3,
		_target: Vector3,
		curve: number,
		arc: number,
		power: number
	)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value

		setupAbilityCamera(Pitcher, Hitter, "Deceiver", "Defensive")

		local fake = ball:Clone()
		fake:SetAttribute("Fake", true)
		fake.Name = "FakeBall"
		fake.Parent = workspace.BallHolder
		fake:SetNetworkOwner(nil)

		local strikeZone: BasePart = workspace:WaitForChild("Batting"):WaitForChild("StrikeZone")
		local range = strikeZone.Size / 2

		local from = (player.Character.LeftHand.CFrame * CFrame.new(.35, 0, 0)).Position
		local target: Vector3
		local iters = 0
		while (not target or (target - _target).Magnitude < .35) and iters < 5 do
			iters += 1
			target = (strikeZone.CFrame * CFrame.new(math.random(-range.X, range.X), math.random(-range.Y, range.Y), 0)).Position
		end

		local middle = ((target + from) / curve) + Vector3.new(0, arc, 0)

		wait(3)

		Remotes.CinematicFinished.OnServerEvent:Wait()

		task.wait(.1)
		Remotes.PitchBall:FireAllClients(fake, from, middle, target, power, fake:GetAttribute("Ability"))
	end,

	Curve = 2,
	Arc = 5,
	Power = 0,
}


DefensiveAbilities.Serenity = {
	Modifiers = {
		MaxDist = 10,
		XAngleMin = 85,
		XAngleMax = 200,
		IgnoreUlts = true,
	},

	EffectOnBall = function(player, ball)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value
		-- Remove the Flower part after 0.5 seconds

		ball:SetAttribute("MaxDist", 10)
		ball:SetAttribute("XAngleMin", 85)
		ball:SetAttribute("XAngleMax", 200)

		setupAbilityCamera(Pitcher, Hitter, "Serenity", "Defensive")
	end,

	Curve = 2,
	Arc = 5,
	Power = 0,

	Direct = true,
	Speed = 0.7,
}

DefensiveAbilities.Boomerang = {
	EffectOnBall = function(player, ball)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value

		setupAbilityCamera(Pitcher, Hitter, "Boomerang", "Defensive")
	end,

	Curve = 2.5,
	Arc = 5,
	Power = 0,
}


DefensiveAbilities.Growth = {
	EffectOnBall = function(player, ball)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value

		setupAbilityCamera(Pitcher, Hitter, "Growth", "Defensive")
	end,

	Curve = 2,
	Arc = 10,
	Power = 0,
	GloveHand = "Right",

}

DefensiveAbilities.Ghost = {
	EffectOnBall = function(player, ball)
		local Pitcher = Gamevalues.CurrentPitcher.Value
		local Hitter = Gamevalues.CurrentBatter.Value

		-- Fire cinematic camera on clients
		setupAbilityCamera(Pitcher, Hitter, "Ghost", "Defensive")
	end,

	Curve = 2,
	Arc = 5,
	Power = 0,
	GloveHand = "Left",
}


DefensiveAbilities.Magma = {
	Ability = function(player)
		Remotes.EnableSpeedlinesVFX:FireClient(player, true)

		if player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.WalkSpeed = 30
		end

		if player.Character:FindFirstChild("LeftFoot") then
			VFXParticlesFB.FireBoots1:Clone().Parent = player.Character.LeftFoot
			VFXParticlesFB.FireBoots2:Clone().Parent = player.Character.LeftFoot
		end

		if player.Character:FindFirstChild("RightFoot") then
			VFXParticlesFB.FireBoots1:Clone().Parent = player.Character.RightFoot
			VFXParticlesFB.FireBoots2:Clone().Parent = player.Character.RightFoot
		end

		if player.Character:FindFirstChild("HumanoidRootPart") then
			local flameSound = VFXParticlesFB.FlameSound:Clone()
			flameSound.Parent = player.Character.HumanoidRootPart
			flameSound:Play()
		end
	end,

	AbilityConditionMet = function(player)
		return true
	end,

	Ultimate = function(player)
		TransformationEffects.StartUltimateAura(player)
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

			if player.Character:FindFirstChild("LeftFoot") then
				for _, object in pairs(player.Character.LeftFoot:GetChildren()) do
					if object:IsA("ParticleEmitter") then
						object:Destroy()
					end
				end
			end

			if player.Character:FindFirstChild("RightFoot") then
				for _, object in pairs(player.Character.RightFoot:GetChildren()) do
					if object:IsA("ParticleEmitter") then
						object:Destroy()
					end
				end
			end

			if player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart:FindFirstChild("FlameSound") then
				player.Character.HumanoidRootPart.FlameSound:Destroy()
			end

			TransformationEffects.RemoveAuras(player)
		end
	end,
}

DefensiveAbilities.Acrobat = {
	Ability = function(player)
		Remotes.EnableSpeedlinesVFX:FireClient(player, true)

		if player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.WalkSpeed = 30
		end

		TransformationEffects.StartAbilityAura(player)
	end,

	AbilityConditionMet = function(player)
		return true
	end,

	Ultimate = function(player)
		--[[
		if player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.JumpPower = 140
		end
		--]]

		TransformationEffects.StartUltimateAura(player)

		if player.Character and player.Character:FindFirstChild("Humanoid") then
			local character = player.Character
			local humanoid = player.Character.Humanoid 

			AntiExploit.Ignore(player, 2)

			humanoid.JumpPower = 140
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			humanoid.Jump = true

			task.delay(0.2, function()
				if humanoid then
					humanoid.JumpPower = 50
				end
			end)
		end
	end,

	UltimateConditionMet = function(player)
		return true
	end,

	Clear = function(player)
		Remotes.EnableSpeedlinesVFX:FireClient(player, false)

		if player.Character then
			if player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid.WalkSpeed = 18
				player.Character.Humanoid.JumpPower = 50
			end

			TransformationEffects.RemoveAuras(player)
		end
	end,
}

DefensiveAbilities.Warden = {
	Ability = function(player)
		local closestBaseTarget = nil
		local closestDistance = math.huge 
		local potentialTargets = {BasePlates["First Base"], BasePlates["Second Base"], BasePlates["Home Base"], BasePlates["Third Base"]}
		local humanoidRootPart = player.Character.HumanoidRootPart
		local bolt = nil
		local GrappleGyro = nil
		local BodyPosition = nil

		for _, target in pairs(potentialTargets) do
			local distance = (humanoidRootPart.Position - target.TouchPart.Position).Magnitude
			if distance < closestDistance then
				closestDistance = distance
				closestBaseTarget = target
			end
		end

		if closestBaseTarget then
			AntiExploit.Ignore(player, 5)
			TransformationEffects.StartAbilityAura(player)

			local attachment1 = VFXParticlesFB.WardenAuras.WardenAuraAttachment1:Clone()
			attachment1.Parent = humanoidRootPart
			local attachment2 = VFXParticlesFB.WardenAuras.WardenAuraAttachment2:Clone()
			attachment2.Parent = humanoidRootPart
			local attachment3 = VFXParticlesFB.WardenAuras.WardenAuraAttachment3:Clone()
			attachment3.Parent = humanoidRootPart
			local attachment4 = VFXParticlesFB.WardenAuras.WardenAuraAttachment4:Clone()
			attachment4.Parent = humanoidRootPart
			attachment3.Beam.Attachment1 = attachment1
			attachment4.Beam.Attachment1 = attachment2

			Remotes.EnableSpeedlinesVFX:FireClient(player, true)
			Remotes.PlayClientVFXAnimation:FireClient(player, "Chain Grab", true)

			bolt = VFXParticlesFB.Bolt:Clone()
			bolt.CFrame =  closestBaseTarget.CFrame
			bolt.Transparency = 0
			bolt.CanCollide = false
			bolt.Velocity = bolt.CFrame.lookVector * 70
			humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, closestBaseTarget.Position)
			bolt.Parent = workspace	

			local Force = Instance.new("BodyForce")
			Force.Force = Vector3.new(0, 50, 0)
			Force.Parent = bolt

			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.AutoRotate = false
			end

			if humanoidRootPart:FindFirstChild("GrappleGyro") == nil then
				GrappleGyro = Instance.new("BodyGyro")
				GrappleGyro.Name = "GrappleGyro"
				GrappleGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
				GrappleGyro.CFrame = humanoidRootPart.CFrame
				GrappleGyro.Parent = humanoidRootPart
			else
				GrappleGyro.CFrame = humanoidRootPart.CFrame
			end

			if humanoidRootPart:FindFirstChild("GrapplePosition") == nil then
				BodyPosition = Instance.new("BodyPosition")
				BodyPosition.D = 1e+003
				BodyPosition.P = 3e+003
				BodyPosition.maxForce = Vector3.new(1e+006, 1e+006, 1e+006)
				BodyPosition.Name = "GrapplePosition"
				BodyPosition.Parent = humanoidRootPart
				BodyPosition.Position = closestBaseTarget.TouchPart.Position
			else
				BodyPosition.Position = closestBaseTarget.TouchPart.Position
			end

			local hrpAttachment = bolt.ChainAttachment:Clone()
			hrpAttachment.Name = "ChainAttachment"
			hrpAttachment.Parent = player.Character.RightHand

			bolt.ChainBeam.Attachment0 = hrpAttachment
			bolt.ChainBeam.Attachment1 = bolt.ChainAttachment
			bolt.ChainSound.Parent = hrpAttachment
			bolt.AttachSound:Play()
			hrpAttachment.ChainSound:Play()

			local startTime = tick()

			while (humanoidRootPart.Position - bolt.Position).Magnitude > 10 
				and ClientFunctions.PlayerIsDefender(player) 
				and Gamevalues.BallHit.Value 
				and tick() - startTime < 4 do
				--bolt.CFrame = closestBaseTarget.CFrame
				--BodyPosition.Position = bolt.Position
				--GrappleGyro.CFrame = humanoidRootPart.CFrame
				wait(0.1)
			end

			if humanoidRootPart then
				if humanoidRootPart and humanoidRootPart:FindFirstChild("GrappleGyro") then
					humanoidRootPart.GrappleGyro:Destroy()
				end

				if humanoidRootPart:FindFirstChild("GrapplePosition") then
					humanoidRootPart.GrapplePosition:Destroy()
				end

				for _, wardenAura in pairs(humanoidRootPart:GetChildren()) do
					if string.match(wardenAura.Name, "WardenAuraAttachment") then
						wardenAura:Destroy()
					end
				end
			end

			if player.Character.RightHand:FindFirstChild("ChainAttachment") then
				player.Character.RightHand.ChainAttachment:Destroy()
			end

			if humanoid then
				humanoid.AutoRotate = true
			end

			if bolt ~= nil then
				bolt:Destroy()
			end

			if hrpAttachment ~= nil then
				hrpAttachment:Destroy()
			end

			Remotes.EnableSpeedlinesVFX:FireClient(player, false)
			Remotes.PlayClientVFXAnimation:FireClient(player, "Chain Grab", false)
			TransformationEffects.RemoveAuras(player)
		end
	end,

	AbilityConditionMet = function(player)
		return true
	end,

	Ultimate = function(player)
		local closestBaseTarget = nil
		local closestDistance = math.huge 
		local potentialTargets = {BasePlates["First Base"], BasePlates["Second Base"], BasePlates["Home Base"], BasePlates["Third Base"]}
		local humanoidRootPart = player.Character.HumanoidRootPart

		for _, target in pairs(potentialTargets) do
			local distance = (humanoidRootPart.Position - target.TouchPart.Position).Magnitude
			if distance < closestDistance then
				closestDistance = distance
				closestBaseTarget = target
			end
		end

		TransformationEffects.StartUltimateAura(player)
		local attachment1 = VFXParticlesFB.WardenAuras.WardenAuraAttachment1:Clone()
		attachment1.Parent = humanoidRootPart
		local attachment2 = VFXParticlesFB.WardenAuras.WardenAuraAttachment2:Clone()
		attachment2.Parent = humanoidRootPart
		local attachment3 = VFXParticlesFB.WardenAuras.WardenAuraAttachment3:Clone()
		attachment3.Parent = humanoidRootPart
		local attachment4 = VFXParticlesFB.WardenAuras.WardenAuraAttachment4:Clone()
		attachment4.Parent = humanoidRootPart
		attachment3.Beam.Attachment1 = attachment1
		attachment4.Beam.Attachment1 = attachment2

		local wardenCage = ServerObjects.WardenCage:Clone()

		local hiddenPosition = closestBaseTarget.Position - Vector3.new(0, wardenCage.PrimaryPart.Size.Y, 0)

		wardenCage.PrimaryPart.Position = hiddenPosition

		wardenCage.Parent = workspace

		for _, part in pairs(wardenCage:GetChildren()) do
			part.CollisionGroup = CollisionGroups.FIELD_WALLS_GROUP
		end

		local tweenInfo = TweenInfo.new(
			3,  -- Time in seconds to complete the tween
			Enum.EasingStyle.Linear,  -- Easing style (you can change this)
			Enum.EasingDirection.Out,  -- Easing direction
			0,  -- Repeat count (0 means no repeat)
			false  -- If true, the tween will reverse once completed
		)

		local targetPosition = closestBaseTarget.Position + Vector3.new(0, wardenCage.PrimaryPart.Size.Y / 2, 0)

		local goal = {Position = targetPosition}

		local tween = TweenService:Create(wardenCage.PrimaryPart, tweenInfo, goal)
		tween:Play()

		wardenCage.PrimaryPart.CageSound:Play()

		Remotes.PlayClientVFXAnimation:FireClient(player, "Warden Yank", true)

		local bolt = VFXParticlesFB.Bolt:Clone()
		bolt.CFrame =  closestBaseTarget.CFrame
		bolt.Transparency = 1
		bolt.CanCollide = false
		bolt.Velocity = bolt.CFrame.lookVector * 70
		humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, closestBaseTarget.Position)
		bolt.Parent = workspace	

		local hrpAttachment = bolt.ChainAttachment:Clone()
		hrpAttachment.Name = "ChainAttachment"
		hrpAttachment.Parent = player.Character.RightHand

		bolt.ChainBeam.Attachment0 = hrpAttachment
		bolt.ChainBeam.Attachment1 = bolt.ChainAttachment
		bolt.ChainSound.Parent = hrpAttachment

		task.spawn(function()
			wait(2)
			if bolt ~= nil then
				bolt:Destroy()
			end

			if hrpAttachment ~= nil then
				hrpAttachment:Destroy()
			end
		end)

		wait(3)

		wardenCage.PrimaryPart.CageCountdown.Marker.Enabled = true

		for i = 3, 0, -0.1 do
			if not Gamevalues.BallHit.Value then
				break
			end

			wardenCage.PrimaryPart.CageCountdown.Marker.Label.Text = string.format("%.1f", i)

			wait(0.1)
		end

		wardenCage.PrimaryPart.CageCountdown.Marker.Enabled = false

		goal = {Position = hiddenPosition}

		tween = TweenService:Create(wardenCage.PrimaryPart, tweenInfo, goal)
		tween:Play()
		wardenCage.PrimaryPart.CageSound:Play()

		wait(3)

		wardenCage:Destroy()

		if humanoidRootPart then
			for _, wardenAura in pairs(humanoidRootPart:GetChildren()) do
				if string.match(wardenAura.Name, "WardenAuraAttachment") then
					wardenAura:Destroy()
				end
			end
		end
		TransformationEffects.RemoveAuras(player)
	end,

	UltimateConditionMet = function(player)
		return true
	end,
}

DefensiveAbilities.Magnetism = {
	Ability = function(player)
		local magneticFieldParticle = VFXParticlesFB.MagneticFieldSmall:Clone()
		magneticFieldParticle.Name = "MagneticField"
		magneticFieldParticle.Parent = player.Character.HumanoidRootPart

		local intakeParticle = VFXParticlesFB.VFXIntakeParticle:Clone()
		intakeParticle.Parent = player.Character.HumanoidRootPart

		local magnetSound = VFXParticlesFB.MagnetSound:Clone()
		magnetSound.Parent = player.Character.HumanoidRootPart
		magnetSound:Play()

		while player 
			and player.Character 
			and player.Character:FindFirstChild("HumanoidRootPart")
			and Gamevalues.BallHit.Value 
			and workspace.BallHolder:FindFirstChild("Baseball") do

			local distance = (player.Character.HumanoidRootPart.Position - workspace.BallHolder.Baseball.Position).Magnitude

			if distance <= 10 then
				workspace.BallHolder.Baseball.CFrame = player.Character.HumanoidRootPart.CFrame
				break
			end

			wait()
		end

		if magneticFieldParticle then
			magneticFieldParticle:Destroy()
		end 

		if magnetSound then
			magnetSound:Destroy()
		end
	end,

	AbilityConditionMet = function(player)
		return true
	end,

	Ultimate = function(player)
		local magneticFieldParticle = VFXParticlesFB.MagneticFieldLarge:Clone()
		magneticFieldParticle.Name = "MagneticField"
		magneticFieldParticle.Parent = player.Character.HumanoidRootPart

		local intakeParticle = VFXParticlesFB.VFXIntakeParticle:Clone()
		intakeParticle.Parent = player.Character.HumanoidRootPart

		local magnetSound = VFXParticlesFB.MagnetSound:Clone()
		magnetSound.Parent = player.Character.HumanoidRootPart
		magnetSound:Play()

		while player 
			and player.Character 
			and player.Character:FindFirstChild("HumanoidRootPart")
			and Gamevalues.BallHit.Value 
			and workspace.BallHolder:FindFirstChild("Baseball") do

			local distance = (player.Character.HumanoidRootPart.Position - workspace.BallHolder.Baseball.Position).Magnitude

			if distance <= 20 then
				workspace.BallHolder.Baseball.CFrame = player.Character.HumanoidRootPart.CFrame
				break
			end

			wait()
		end

		if magneticFieldParticle then
			magneticFieldParticle:Destroy()
		end 

		if magnetSound then
			magnetSound:Destroy()
		end
	end,

	UltimateConditionMet = function(player)
		return true
	end,

	Clear = function(player)
		if player.Character then
			if player.Character:FindFirstChild("HumanoidRootPart") then
				if player.Character.HumanoidRootPart:FindFirstChild("MagneticField") then
					player.Character.HumanoidRootPart.MagneticField:Destroy()
				end

				if player.Character.HumanoidRootPart:FindFirstChild("VFXIntakeParticle") then
					player.Character.HumanoidRootPart.VFXIntakeParticle:Destroy()
				end
			end

			TransformationEffects.RemoveAuras(player)
		end
	end,
}


DefensiveAbilities.Buccaneer = {
	Ability = function(player)
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local ServerStorage = game:GetService("ServerStorage")
		local Players = game:GetService("Players")
		local RunService = game:GetService("RunService")

		local VFXParticlesFB = ReplicatedStorage:WaitForChild("VFXParticlesFB")

		local character = player.Character
		if not character then return end

		local casterHRP = character:FindFirstChild("HumanoidRootPart")
		local casterRightHand = character:FindFirstChild("RightHand")
		if not casterHRP or not casterRightHand then return end

		-- 1) Find nearest valid enemy target in range
		local MAX_RANGE = 80
		local best, bestDist = nil, math.huge
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character and plr.Character.Parent and plr.Team ~= player.Team then
				local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
				local hum = plr.Character:FindFirstChildOfClass("Humanoid")
				if hrp and hum and hum.Health > 0 then
					local d = (hrp.Position - casterHRP.Position).Magnitude
					if d < MAX_RANGE and d < bestDist and (ClientFunctions.PlayerIsBaserunner(plr) or Gamevalues.CurrentBatter.Value == plr) then
						best, bestDist = plr, d
					end
				end
			end
		end
		if not best then return end

		local targetChar = best.Character
		local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
		local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
		if not targetHum or not targetHRP then return end

		-- 2) Chain VFX (same look as Warden)
		local bolt, handAttach, followConn
		if VFXParticlesFB:FindFirstChild("Bolt") then
			bolt = VFXParticlesFB.Bolt:Clone()
			bolt.Transparency = 0
			bolt.CanCollide = false
			bolt.CFrame = targetHRP.CFrame
			bolt.Parent = workspace

			handAttach = bolt.ChainAttachment:Clone()
			handAttach.Name = "PirateChainHandAttach"
			handAttach.Parent = casterRightHand

			if bolt:FindFirstChild("ChainBeam") and bolt:FindFirstChild("ChainAttachment") then
				bolt.ChainBeam.Attachment0 = handAttach
				bolt.ChainBeam.Attachment1 = bolt.ChainAttachment
			end

			if bolt:FindFirstChild("AttachSound") then bolt.AttachSound:Play() end

			followConn = RunService.Heartbeat:Connect(function()
				if not bolt or not bolt.Parent or not targetHRP or not targetHRP.Parent then
					if followConn then followConn:Disconnect() end
					return
				end
				bolt.CFrame = targetHRP.CFrame
			end)
		end

		local DURATION = 1.5
		local MAX_H_SPEED = 6            -- studs/sec cap while snared
		local DRAG_COEFF = 40            -- extra slowdown feel (try 40–120)
		local MAX_FORCE_PER_KG = 1e9     -- effectively "no cap" for clamps

		-- Attachment on the target
		local attach = Instance.new("Attachment")
		attach.Name = "PirateAnchorAttachment"
		attach.Parent = targetHRP

		-- Horizontal speed clamp (authoritative)
		local lv = Instance.new("LinearVelocity")
		lv.Name = "PirateSpeedClamp"
		lv.Attachment0 = attach
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.MaxForce = MAX_FORCE_PER_KG           -- ensure it wins vs Humanoid drive
		lv.Parent = targetHRP

		-- Optional drag for nicer feel (keeps momentum in check)
		local vf = Instance.new("VectorForce")
		vf.Name = "PirateAnchorForce"
		vf.Attachment0 = attach
		vf.RelativeTo = Enum.ActuatorRelativeTo.World
		vf.Force = Vector3.zero
		vf.Parent = targetHRP

		-- Optional: damp spin a bit
		local av = Instance.new("AngularVelocity")
		av.Name = "PirateAnchorAngularDamp"
		av.Attachment0 = attach
		av.RelativeTo = Enum.ActuatorRelativeTo.World
		av.MaxTorque = math.huge
		av.AngularVelocity = Vector3.zero
		av.Parent = targetHRP

		-- Make the server own the target so constraints take effect reliably
		local hadAuto = targetHRP:GetNetworkOwnershipAuto()
		targetHRP:SetNetworkOwnershipAuto(false)
		local ok, currentOwner = pcall(function() return targetHRP:GetNetworkOwner() end)
		targetHRP:SetNetworkOwner(nil) -- server owns for the duration

		local alive = true
		local t0 = tick()
		local dragConn

		local function cleanup()
			alive = false
			if dragConn   then dragConn:Disconnect();   dragConn = nil end
			if followConn then followConn:Disconnect(); followConn = nil end

			-- VFX teardown
			if bolt then bolt:Destroy(); bolt = nil end
			if handAttach and handAttach.Parent then handAttach:Destroy(); handAttach = nil end

			-- Constraint teardown
			if av     then av:Destroy();     av = nil end
			if vf     then vf:Destroy();     vf = nil end
			if lv     then lv:Destroy();     lv = nil end
			if attach and attach.Parent then attach:Destroy(); attach = nil end

			-- Restore network ownership
			targetHRP:SetNetworkOwner(nil)
			targetHRP:SetNetworkOwnershipAuto(hadAuto ~= false)
		end

		dragConn = RunService.Heartbeat:Connect(function(dt)
			if not alive then return end

			-- End conditions: target/caster validity
			if not character or not character.Parent or not casterRightHand or not casterRightHand.Parent then
				cleanup(); return
			end
			if not targetChar or not targetChar.Parent or not targetHRP or not targetHRP.Parent or not targetHum or targetHum.Health <= 0 then
				cleanup(); return
			end

			-- Current velocity
			local v  = targetHRP.AssemblyLinearVelocity
			local vh = Vector3.new(v.X, 0, v.Z)
			local speedH = vh.Magnitude

			-- Clamp horizontal speed; preserve vertical component
			if speedH > MAX_H_SPEED then
				local dirH = vh.Unit
				lv.VectorVelocity = Vector3.new(dirH.X * MAX_H_SPEED, v.Y, dirH.Z * MAX_H_SPEED)
			else
				lv.VectorVelocity = v
			end

			-- Extra drag for feel (opposes horizontal motion)
			if speedH > 1e-3 then
				local m = targetHRP.AssemblyMass
				vf.Force = -DRAG_COEFF * vh * m
			else
				vf.Force = Vector3.zero
				lv.VectorVelocity = v
			end

			-- End after duration
			if tick() - t0 >= DURATION then
				cleanup()
			end
		end)
	end,

	AbilityConditionMet = function(player)
		local character = player.Character
		if not character then return false end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return false end

		local MAX_RANGE = 80
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player and plr.Team ~= player.Team and plr.Character then
				local thrp = plr.Character:FindFirstChild("HumanoidRootPart")
				local hum = plr.Character:FindFirstChildOfClass("Humanoid")
				if thrp and hum and hum.Health > 0 then
					if (thrp.Position - hrp.Position).Magnitude <= MAX_RANGE and (ClientFunctions.PlayerIsBaserunner(plr) or Gamevalues.CurrentBatter.Value == plr) then
						return true -- found a valid enemy in range
					end
				end
			end
		end

		-- no enemies found -> notify player
		Remotes.Notification:FireClient(player, "No baserunners within 80 studs.")
		return false
	end,

	Ultimate = function(player)
		local ServerStorage      = game:GetService("ServerStorage")
		local ReplicatedStorage  = game:GetService("ReplicatedStorage")

		local Remotes            = ReplicatedStorage:WaitForChild("RemoteEvents")
		local StartCannonFlight  = Remotes:WaitForChild("StartCannonFlight")

		local ServerObjects = ServerStorage:WaitForChild("ServerObjects")
		local BasePlates    = workspace:WaitForChild("Plates")

		local cannonTemplate = ServerObjects:FindFirstChild("PlayerCannon")
		if not cannonTemplate then return end

		local character = player.Character
		if not character then return end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		-- Find home base
		local homeBase = BasePlates:FindFirstChild("Home Base")
		if not homeBase then return end

		-- Spawn cannon
		local cannon = cannonTemplate:Clone()
		cannon.Name = player.Name .. "_PirateCannon"

		-- Set PrimaryPart (prefer "Bottom", else first BasePart)
		local primary = cannon:FindFirstChild("Bottom") or cannon:FindFirstChildWhichIsA("BasePart")
		if not primary then
			warn("[PirateCannon] Cannon has no BasePart!")
			cannon:Destroy()
			return
		end
		cannon.PrimaryPart = primary

		-- Make cannon face home base
		local spawnPos = character:GetPivot().Position
		local lookAtCF = CFrame.lookAt(spawnPos, Vector3.new(homeBase.Position.X, spawnPos.Y, homeBase.Position.Z))

		cannon:SetPrimaryPartCFrame(lookAtCF)
		cannon.Parent = workspace
		cannon.PrimaryPart.Anchored = true

		-- Seat player in cannon
		root.Anchored = true
		root.CFrame   = cannon:WaitForChild("TP").CFrame + Vector3.new(0, 2, 0)

		-- Relax anti-exploit for flight window
		AntiExploit.Ignore(player, 5)

		task.delay(2, function()
			if not character or not character.Parent or not root.Parent then
				if cannon then cannon:Destroy() end
				return
			end

			local fireSound = cannon:FindFirstChild("Fire")
			if fireSound then fireSound:Play() end

			local smoke = cannon:FindFirstChild("SMOKE")
			if smoke and smoke:FindFirstChild("Explosion") then
				smoke.Explosion:Emit(100)
			end

			root.Anchored = false

			-- ---- Path params (server is source of truth) ----
			local p0  = root.Position
			local p2  = homeBase.Position + Vector3.new(0, 3, 0) -- target chest height
			local mid = (p0 + p2) * 0.5
			local arcHeight = math.clamp((p2 - p0).Magnitude * 0.35, 20, 65)
			local p1  = Vector3.new(mid.X, math.max(mid.Y, p0.Y, p2.Y) + arcHeight, mid.Z)

			local dist = (p2 - p0).Magnitude
			local flightTime = math.clamp(dist / 120, 0.9, 1.8)

			-- Prep ragdoll-ish state + disable collisions (client will mirror)
			local hum = character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.PlatformStand = true
				hum:ChangeState(Enum.HumanoidStateType.Freefall)
			end
			for _, bp in ipairs(character:GetDescendants()) do
				if bp:IsA("BasePart") then
					--bp.CanCollide = false
					bp.AssemblyLinearVelocity = Vector3.zero
					bp.AssemblyAngularVelocity = Vector3.zero
				end
			end

			-- Tell the client to animate the arc smoothly
			StartCannonFlight:FireClient(player, p0, p1, p2, flightTime)

			-- Server watchdog: restore state even if client never replies
			task.delay(flightTime + 1.0, function()
				if not character or not character.Parent then return end
				local hum2 = character:FindFirstChildOfClass("Humanoid")
				if hum2 then hum2.PlatformStand = false end
			end)

			-- Cleanup cannon prop
			task.delay(5, function()
				if cannon then cannon:Destroy() end
			end)
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

			if player.Character:FindFirstChild("LeftFoot") then
				for _, object in pairs(player.Character.LeftFoot:GetChildren()) do
					if object:IsA("ParticleEmitter") then
						object:Destroy()
					end
				end
			end

			if player.Character:FindFirstChild("RightFoot") then
				for _, object in pairs(player.Character.RightFoot:GetChildren()) do
					if object:IsA("ParticleEmitter") then
						object:Destroy()
					end
				end
			end

			if player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart:FindFirstChild("FlameSound") then
				player.Character.HumanoidRootPart.FlameSound:Destroy()
			end

			TransformationEffects.RemoveAuras(player)
		end
	end,

}

-- Fisherman: uses SuperSlide (client) for a longer dive, plus an ultimate that reels a nearby ground ball.
DefensiveAbilities.Fisherman = {
	----------------------------------------------------------------
	-- ABILITY (Fish Dive) -----------------------------------------
	----------------------------------------------------------------
	Ability = function(player)
		-- Just trigger the client pipeline and pass a mode flag
		Remotes.SuperSlide:FireClient(player, "FishDive")
	end,

	AbilityConditionMet = function(player)
		-- Move the usage checks here (so players are told BEFORE it fires)
		if not Gamevalues.BallHit.Value then
			Remotes.Notification:FireClient(player, "You can only Fish Dive when the ball is in play.", "Alert")
			return false
		end

		return true
	end,

	----------------------------------------------------------------
	-- ULTIMATE (Hook + Reel) --------------------------------------
	----------------------------------------------------------------
	Ultimate = function(player)
		-- Do the reel (assume all pre-checks already passed in UltimateConditionMet).
		local char = player.Character
		local hrp  = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local holder = workspace:FindFirstChild("BallHolder")
		local ball   = holder and holder:FindFirstChild("Baseball")
		if not ball or not ball:IsA("BasePart") then return end

		TransformationEffects.StartUltimateAura(player)

		-- Beam “fishing line” between hand (or HRP) and ball
		local hand = char:FindFirstChild("RightHand") or hrp
		local a0 = Instance.new("Attachment"); a0.Name = "Fisher_LineStart"; a0.Parent = hand
		local a1 = Instance.new("Attachment"); a1.Name = "Fisher_LineEnd";   a1.Parent = ball

		local beam = Instance.new("Beam")
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Width0, beam.Width1 = 0.15, 0.15
		beam.LightEmission = 0.7
		beam.Segments = 10
		beam.Enabled = true
		beam.Parent = hand

		-- Server owns ball while reeling
		local hadAuto = ball:GetNetworkOwnershipAuto()
		ball:SetNetworkOwnershipAuto(false)
		ball:SetNetworkOwner(nil)

		local targetPos = hrp.Position + Vector3.new(0, 2, 0)
		local reelTime  = 0.75
		local t0 = tick()

		-- Quiet the physics during the pull
		ball.AssemblyLinearVelocity  = Vector3.zero
		ball.AssemblyAngularVelocity = Vector3.zero

		local alive = true
		local hb
		hb = game:GetService("RunService").Heartbeat:Connect(function()
			if not alive then return end
			if not Gamevalues.BallHit.Value then alive = false end
			if not ball or not ball.Parent or not hrp or not hrp.Parent then alive = false end

			local alpha = math.clamp((tick() - t0) / reelTime, 0, 1)
			local newPos = ball.Position:Lerp(targetPos, alpha)

			ball.AssemblyLinearVelocity  = Vector3.zero
			ball.AssemblyAngularVelocity = Vector3.zero
			ball.CFrame = CFrame.new(newPos)

			if alpha >= 1 then alive = false end

			if not alive then
				if hb then hb:Disconnect() end
				if beam then beam:Destroy() end
				if a0 and a0.Parent then a0:Destroy() end
				if a1 and a1.Parent then a1:Destroy() end

				task.delay(0.15, function()
					if ball and ball.Parent then
						ball:SetNetworkOwner(nil)
						ball:SetNetworkOwnershipAuto(hadAuto ~= false)
					end
					TransformationEffects.RemoveAuras(player)
				end)
			end
		end)
	end,

	UltimateConditionMet = function(player)
		if not Gamevalues.BallHit.Value then
			Remotes.Notification:FireClient(player, "No live ball to reel.", "Alert")
			return false
		end

		-- Disallow pop flies
		if Gamevalues:FindFirstChild("FlyBall") and Gamevalues.FlyBall.Value == true then
			Remotes.Notification:FireClient(player, "Can't reel pop flies.", "Alert")
			return false
		end

		local char = player.Character
		local hrp  = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return false end

		local holder = workspace:FindFirstChild("BallHolder")
		local ball   = holder and holder:FindFirstChild("Baseball")
		if not ball then
			Remotes.Notification:FireClient(player, "No baseball found.", "Alert")
			return false
		end

		-- Range check (30 studs)
		if (hrp.Position - ball.Position).Magnitude > 55 then
			Remotes.Notification:FireClient(player, "Ball is out of reel range.", "Alert")
			return false
		end

		return true
	end,

	Clear = function(player)
		TransformationEffects.RemoveAuras(player)
	end,
}

DefensiveAbilities.Coverage = {
	CoverageWarp = function(player, destination)
		Remotes.QuantumTeleportEffect:FireClient(player, destination.Position)

		local warpStartSound = VFXParticlesFB.WarpEnd:Clone()
		warpStartSound.Parent = player.Character.HumanoidRootPart

		task.wait(1.1)

		if warpStartSound then
			warpStartSound:Destroy()
		end

		if not ClientFunctions.PlayerIsDefender(player) then
			return
		end

		if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local cframePos = CFrame.new(destination.Position) * CFrame.Angles(0, player.Character.HumanoidRootPart.Orientation.Y * math.pi/180, 0)

			Remotes.CancelSlideDive:FireClient(player)

			player.Character.HumanoidRootPart.Anchored = true

			AntiExploit.Ignore(player, 3)

			player.Character:PivotTo(cframePos)
			Remotes.CFramePlayerCharacter:FireClient(player, cframePos)			

			player.Character.HumanoidRootPart.Anchored = false
		end
	end,

	Ability = function(player)
		local BaseOrder = {
			["First Base"] = 1,
			["Second Base"] = 2,
			["Third Base"] = 3,
			["Home Base"] = 4,
		}

		local bestNextBaseName = nil
		local bestRank = -1

		for _, baseTracker in ipairs(OnBaseFolder:GetChildren()) do
			local currentBaseName = baseTracker.Value
			if currentBaseName and currentBaseName ~= "" then
				local nextBaseName = BaseSequence[currentBaseName]
				if nextBaseName then
					local rank = BaseOrder[nextBaseName]
					if rank and rank > bestRank then
						bestRank = rank
						bestNextBaseName = nextBaseName
					end
				end
			end
		end

		if not bestNextBaseName then
			return -- nobody on base / nothing valid found
		end

		local targetBase = workspace.Plates:FindFirstChild(bestNextBaseName)


		DefensiveAbilities.Coverage.CoverageWarp(player, targetBase)
	end,

	Ultimate = function(player)
		local ball = workspace.BallHolder:FindFirstChild("Baseball")

		if not ball then return end

		local outfieldAreas = workspace.BuddyJumpFloor:GetChildren() -- contains 3 parts, center, left, right

		local ballPos = ball:GetPivot().Position

		local closestPart = nil
		local closestDist = math.huge

		for _, area in ipairs(outfieldAreas) do
			if area:IsA("BasePart") then
				local dist = (area.Position - ballPos).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestPart = area
				end
			end
		end

		if not closestPart then return end

		DefensiveAbilities.Coverage.CoverageWarp(player, closestPart)
	end,

	AbilityConditionMet = function(player)
		local glove = player.Character:FindFirstChild("PlayerGlove")

		if glove and glove:FindFirstChild("Baseball") then
			Remotes.Notification:FireClient(player, "You cannot use this ability while holding the ball!", "Alert")
			return false
		end

		if #OnBaseFolder:GetChildren() == 0 then
			Remotes.Notification:FireClient(player, "No one is on base!", "Alert")
			return false
		end

		return true
	end,

	UltimateConditionMet = function(player)
		local glove = player.Character:FindFirstChild("PlayerGlove")

		if glove and glove:FindFirstChild("Baseball") then
			Remotes.Notification:FireClient(player, "You cannot use this ability while holding the ball!", "Alert")
			return false
		end

		if workspace.BallHolder:FindFirstChild("Baseball") == nil then
			Remotes.Notification:FireClient(player, "No ball in play!", "Alert")
			return false
		end

		return true
	end,
}

DefensiveAbilities.Poseidon = {
	Ability = function(player) end,

	AbilityConditionMet = function(player)
		return true
	end,

	Ultimate = function(player)
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		-- Clone wave (supports Part or Model)
		local wave = ServerObjects.Wave:Clone()
		wave.Name = "PoseidonWave"
		wave.Parent = workspace

		----------------------------------------------------------------
		-- Helper: set physics/visibility on all parts
		----------------------------------------------------------------
		local function configureParts(container, anchored, canCollide, canTouch, transparency)
			for _, d in ipairs(container:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = anchored
					d.CanCollide = canCollide
					d.CanTouch = canTouch
					if transparency ~= nil then d.Transparency = transparency end
				end
			end
			if container:IsA("BasePart") then
				container.Anchored = anchored
				container.CanCollide = canCollide
				container.CanTouch = canTouch
				if transparency ~= nil then container.Transparency = transparency end
			end
		end

		----------------------------------------------------------------
		-- Locate main movable part
		----------------------------------------------------------------
		local wavePart = wave
		if wave:IsA("Model") then
			wavePart = wave.PrimaryPart or wave:FindFirstChildWhichIsA("BasePart")
			if not wavePart then
				warn("[Poseidon] Wave has no BasePart/PrimaryPart")
				wave:Destroy()
				return
			end
		end

		-- Initial visual/physics config
		configureParts(wave, true, false, true, 0.25)

		----------------------------------------------------------------
		-- Lock direction at cast time, so it won't follow the player
		----------------------------------------------------------------
		local startCF = CFrame.lookAt(hrp.Position, hrp.Position + hrp.CFrame.LookVector)
		local spawnCF = startCF * CFrame.new(0, 0, -4) -- spawn in front of caster
		if wave:IsA("Model") then
			wave:PivotTo(spawnCF)
		else
			wave.CFrame = spawnCF
		end

		-- Optional VFX:
		-- local splash = VFXParticlesFB:FindFirstChild("TsunamiSpray")
		-- if splash then splash:Clone().Parent = (wave:IsA("Model") and wavePart or wave) end

		----------------------------------------------------------------
		-- Knockdown logic
		----------------------------------------------------------------
		local hitCache = {}

		local function knockdownEnemy(plr)
			if not plr or plr == player then return end
			if plr.Team == player.Team then return end
			if hitCache[plr] then return end

			local ch = plr.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			if not hum or not root or hum.Health <= 0 then return end
			if OnBaseFolder:FindFirstChild(plr.Name) and OnBaseFolder[plr.Name].IsSafe.Value then return end

			hitCache[plr] = true
			AntiExploit.Ignore(plr, 4)
			Remotes.TsunamiKnockdown:FireClient(plr, startCF)
		end

		----------------------------------------------------------------
		-- Overlap hitbox (robust vs. fast, anchored motion)
		----------------------------------------------------------------
		-- Cache bounding size once; adjust padding to taste
		local bboxCF, bboxSize = (wave:IsA("Model") and wave:GetBoundingBox()) or (wave.CFrame), wavePart.Size
		local hitboxPadding = Vector3.new(2, 2, 2)
		local querySize = bboxSize + hitboxPadding

		if wave:IsA("Model") then
			-- For complex models, use their aggregated bounds
			local _, sizeModel = wave:GetBoundingBox()
			querySize = sizeModel + hitboxPadding
		end

		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.FilterDescendantsInstances = { wave, character } -- ignore wave and the caster

		----------------------------------------------------------------
		-- Movement & fade
		----------------------------------------------------------------
		local totalDist   = 30     -- studs
		local travelTime  = 2      -- seconds
		local fadeStart   = 0.75   -- start fading at 75% progress
		local baseAlphaT  = 0.25   -- initial transparency

		local t0 = tick()
		local runConn

		runConn = game:GetService("RunService").Heartbeat:Connect(function()
			if not wave or not wave.Parent then
				if runConn then runConn:Disconnect() end
				return
			end

			local elapsed = tick() - t0
			local alpha = math.clamp(elapsed / travelTime, 0, 1)
			local offset = totalDist * alpha

			-- Move along locked direction
			local forwardCF = startCF * CFrame.new(0, 0, -(4 + offset))
			if wave:IsA("Model") then
				wave:PivotTo(forwardCF)
			else
				wave.CFrame = forwardCF
			end

			-- Overlap query at the wave's current transform
			local parts = workspace:GetPartBoundsInBox(forwardCF, querySize, params)
			for _, p in ipairs(parts) do
				local ch = p:FindFirstAncestorOfClass("Model")
				local plr = ch and Players:GetPlayerFromCharacter(ch)
				if plr then
					knockdownEnemy(plr)
				end
			end

			-- Fade out near the end
			if alpha >= fadeStart then
				local f = (alpha - fadeStart) / (1 - fadeStart) -- 0..1
				local t = baseAlphaT + (1 - baseAlphaT) * f     -- 0.25 -> 1
				configureParts(wave, true, false, true, t)
			end

			-- Cleanup
			if alpha >= 1 then
				if runConn then runConn:Disconnect() end
				wave:Destroy()
			end
		end)
	end,

	UltimateConditionMet = function(player)
		return true
	end,

	Clear = function(player)
		Remotes.EnableSpeedlinesVFX:FireClient(player, false)

		if player.Character then
			local char = player.Character

			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = 18 end

			local function clearFootEmitters(footName)
				local foot = char:FindFirstChild(footName)
				if not foot then return end
				for _, obj in pairs(foot:GetChildren()) do
					if obj:IsA("ParticleEmitter") then obj:Destroy() end
				end
			end
			clearFootEmitters("LeftFoot")
			clearFootEmitters("RightFoot")

			local hrp = char:FindFirstChild("HumanoidRootPart")
			local flame = hrp and hrp:FindFirstChild("FlameSound")
			if flame then flame:Destroy() end

			TransformationEffects.RemoveAuras(player)
		end
	end,
}


return DefensiveAbilities
