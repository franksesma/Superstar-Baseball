local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Remotes = ReplicatedStorage.RemoteEvents
local SharedData = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local GameValues = ReplicatedStorage.GameValues
local VFXParticlesFB = ReplicatedStorage.VFXParticlesFB

local ServerScriptService = game:GetService("ServerScriptService")
local Modules = ServerScriptService.Modules
local BaseballFunctions = require(Modules.BaseballFunctions)

local PlateDistance = require(SharedModules.PlateDistance)
local CollisionGroups = require(SharedModules.CollisionGroups)
local Styles = require(SharedModules.Styles)

local baseballHolder = workspace:FindFirstChild("BallHolder")

Remotes.AttachBallToHand.OnServerEvent:Connect(function(player)
	if player and player.Character then
		local glove = player.Character:FindFirstChild("PlayerGlove")
		local ball = glove and glove:FindFirstChild("Baseball")
		if not ball then return end
		if ball:FindFirstChild("Weld") then
			ball.Weld:Destroy()
		end

		local ballWeld = game.ServerStorage.ServerObjects.HoldBaseball:Clone()
		ballWeld.Part0 = ball
		ballWeld.Part1 = player.Character.RightHand
		ballWeld.Parent = ball
	end
end)

Remotes.ThrowBall.OnServerEvent:Connect(function(player, Target)
	if player and player.Character and GameValues.BallHit.Value then
		local glove = player.Character:FindFirstChild("PlayerGlove")
		local meshPart = glove and glove:FindFirstChild("MeshPart")
		local throwOrigin = meshPart and meshPart.Position or Target

		-- Clamp Y value and enforce max distance
		Target = Vector3.new(Target.X, 2, Target.Z)

		local maxDistance = 200
		local directionToTarget = Target - throwOrigin
		if directionToTarget.Magnitude > maxDistance then
			Target = throwOrigin + directionToTarget.Unit * maxDistance
			Target = Vector3.new(Target.X, 2, Target.Z) -- ensure Y stays clamped
		end

		local ball = glove and glove:FindFirstChild("Baseball")
		if not ball then return end
		if ball:FindFirstChild("Weld") then
			ball.Weld:Destroy()
		end

		ball.CanCollide = false
		ball.Catchable.Value = false
		ball:Destroy()

		local NewBall = game.ServerStorage.ServerObjects.Baseball:Clone()
		NewBall.Parent = workspace.BallHolder
		NewBall.Position = ball.Position
		NewBall.CollisionGroup = CollisionGroups.BASEBALL_GROUP_THROWING
		NewBall.Catchable.Value = false
		NewBall.CatchBall.Enabled = true
		NewBall:SetAttribute("Hit", true)
		NewBall:SetAttribute("LastThrower", player.UserId)
		NewBall:SetAttribute("ThrowTime", tick())

		local throwSound = Instance.new("Sound")
		throwSound.SoundId = "rbxassetid://2520065241"
		throwSound.Volume = 1
		throwSound.PlayOnRemove = false
		throwSound.Parent = NewBall
		throwSound:Play()
		Debris:AddItem(throwSound, 2)

		spawn(function()
			wait(0.15)
			if NewBall and NewBall:FindFirstChild("Catchable") then
				NewBall.Catchable.Value = true
			end
		end)

		print("ORIGIN POS: " .. tostring(NewBall.Position))
		print("TARGET POS: " .. tostring(Target))

		local position1 = NewBall.Position
		local position2 = Target
		local direction = position2 - position1
		local duration = math.clamp(direction.Magnitude / 80, 0.25, 1.25)
		direction = position2 - position1

		local archMultiplier = 0.2
		local forceMultiplier = 0.5
		
		if _G.sessionData[player]
			and Styles.GetEquippedStyleName(player, "Defensive") == "Magma"
			and SharedData[player.Name].ActivatedFBAbility.Value
			and SharedData[player.Name].ActivatedFBAbility.PowerActivated.Value == "Fire Throw"
		then
			-- MAGMA
			local firethrowParticle1 = VFXParticlesFB.FireBoots1:Clone()
			local firethrowParticle2 = VFXParticlesFB.FireBoots2:Clone()
			duration = duration * 0.4
			firethrowParticle1.Parent = NewBall
			firethrowParticle2.Parent = NewBall

		elseif _G.sessionData[player]
			and Styles.GetEquippedStyleName(player, "Defensive") == "Poseidon"
			and SharedData[player.Name].ActivatedFBAbility.Value
			and SharedData[player.Name].ActivatedFBAbility.PowerActivated.Value == "Trident Throw"
		then
			-- POSEIDON (fast throw, water VFX)
			duration = duration * 0.5 -- tune: 0.45–0.6 feels good

			-- optional water/trident trail on ball
			local waterTrail = VFXParticlesFB:FindFirstChild("TridentTrail") or VFXParticlesFB:FindFirstChild("WaterTrail")
			if waterTrail then
				local c = waterTrail:Clone()
				c.Parent = NewBall
			else
				-- fallback to your default trail if no water asset
				BaseballFunctions.SetUpTrail(player, NewBall)
			end

			-- consume the flag after use
			SharedData[player.Name].ActivatedFBAbility.Value = false
			SharedData[player.Name].ActivatedFBAbility.PowerActivated.Value = ""

		else
			-- default slightly-faster throw path you already have
			duration = duration * 0.7
			BaseballFunctions.SetUpTrail(player, NewBall)
		end

		local force = (direction / duration + Vector3.new(0, workspace.Gravity * duration * archMultiplier, 0)) * forceMultiplier

		local indicatorTemplate = ReplicatedStorage:WaitForChild("SharedGUIs"):FindFirstChild("BallIndicator")
		if indicatorTemplate then
			local indicatorClone = indicatorTemplate:Clone()
			indicatorClone.Adornee = NewBall
			indicatorClone.Parent = NewBall
		end
		
		local connection
		connection = NewBall.Touched:Connect(function(hit)
			if hit and hit.Parent and (hit.Parent.Name == "Field" or hit.Parent.Name == "Plates" or hit.Parent.Name == "InvisibleWalls") and not hit:IsDescendantOf(player.Character) then
				NewBall.AssemblyLinearVelocity *= 0.5
				NewBall.AssemblyAngularVelocity *= 0.5
				NewBall.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)

				if connection then
					connection:Disconnect()
					connection = nil
				end
			end
		end)

		NewBall:ApplyImpulse(force * NewBall.AssemblyMass)
		NewBall:SetNetworkOwner(nil)
	end
end)
