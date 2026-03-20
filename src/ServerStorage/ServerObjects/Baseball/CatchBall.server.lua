local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = ServerScriptService.Modules
local SharedModules = ReplicatedStorage.SharedModules

local ClientFunctions = require(SharedModules.ClientFunctions)
local ServerFunctions = require(Modules.ServerFunctions)
local BaseballFunctions = require(Modules.BaseballFunctions)

local Remotes = game.ReplicatedStorage.RemoteEvents
local GameValues = ReplicatedStorage.GameValues

local currentBatter = GameValues.CurrentBatter
local basePlates = workspace.Plates

local CHECK_RADIUS = 80
local AUTO_CATCH_RADIUS = 8
local AUTO_PICK_UP_RADIUS = 8
local ANTI_MAG_CHECK_RADIUS = 15
local currentFieldersInRange = {}
local ballPickedUp = false
local pitcherCanCatchFlyball = false
local fielderCanCatchBall = false
local ignoreBallDistanceFromHome = false

local function isTouchingPlate(character, basePart)
	local partsInBase = workspace:GetPartsInPart(basePart)
	for _, part in ipairs(partsInBase) do
		if part and part.Parent == character then
			return true
		end
	end
	return false
end

local function ballPossessed(player, Glove)
	-- Block pickup if the ball is electrified OR the player is currently zapped.
	local ball = script.Parent
	
	local throwerId = ball:GetAttribute("LastThrower")
	local throwTime = ball:GetAttribute("ThrowTime")
	if throwerId == player.UserId and throwTime and (tick() - throwTime) < 1.2 then
		return
	end
	
	local playerZapped =
		(player:GetAttribute("OverdriveZapped") == true)
		or (player.Character and player.Character:GetAttribute("OverdriveZapped") == true)

	local ballZapped =
		(ball:GetAttribute("OverdriveElectrified") == true)

	if playerZapped or ballZapped then
		return
	end

	if not ballPickedUp
		and player.Character
		and player.Character:FindFirstChild("Humanoid")
		and player.Character:FindFirstChild("HumanoidRootPart")
		and player.Character.Humanoid.Health > 0
		and Glove:FindFirstChild("MeshPart") then

		if GameValues.Homerun.Value then return end
		
		--[[
		-- Anti snap-catch: require them to still be near the ball after a short delay
		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local startDist = (hrp.Position - ball.Position).Magnitude

		task.wait(0.125) -- slightly longer than your exploit check tick

		-- ball or character could be gone now
		if not ball or not ball.Parent then return end
		if not player.Character or not player.Character.Parent then return end
		hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local endDist = (hrp.Position - ball.Position).Magnitude

		-- Must be close both before AND after the wait (prevents 1-frame TP grabs)
		if startDist > ANTI_MAG_CHECK_RADIUS or endDist > ANTI_MAG_CHECK_RADIUS then
			return
		end
		--]]
		
		if GameValues.FlyBall.Value then
			if ServerFunctions.PlayerIsInGame(currentBatter.Value) then
				if GameValues.CurrentPitcher.Value == player and not pitcherCanCatchFlyball then
					return
				end
				if GameValues.Putout.Value then
					return
				end
				BaseballFunctions.PlayerOut(currentBatter.Value)
				GameValues.Putout.Value = true
				workspace.LandingIndicators:ClearAllChildren()
				ServerFunctions.AddStat(player, "Outfield", "Putouts", 1)
			end
		end
		
		if not GameValues.Putout.Value then
			GameValues.FlyBall.Value = false
			if not ball:GetAttribute("TouchedAfterHit") then
				ball:SetAttribute("TouchedAfterHit", true)
			end
		end

		ballPickedUp = true

		local catchSound = Instance.new("Sound")
		catchSound.SoundId = "rbxassetid://9125376382"
		catchSound.Volume = 1
		catchSound.PlayOnRemove = false
		catchSound.Parent = Glove
		catchSound:Play()
		game:GetService("Debris"):AddItem(catchSound, 2)

		local newBaseball = game.ServerStorage.ServerObjects["Baseball"]:Clone()
		newBaseball.CFrame = Glove.MeshPart.CFrame * CFrame.new(0, 0, -0.5)
		newBaseball.CanCollide = false
		newBaseball.Massless = true
		newBaseball.Parent = Glove

		newBaseball.GravityOn.Value = false
		newBaseball.GravityChanger:Destroy()

		GameValues.BaseballObj.Value = newBaseball

		local ballWeld = Instance.new("Weld")
		ballWeld.Part0 = Glove.MeshPart
		ballWeld.Part1 = newBaseball
		ballWeld.C0 = CFrame.new(0, .2, -.1)
		ballWeld.Parent = newBaseball

		Remotes.GrabBall:FireClient(player, newBaseball)

		for _, fielder in pairs(currentFieldersInRange) do
			ServerFunctions.ResetArms(fielder)
		end

		if GameValues.AssistsTracker:FindFirstChild(player.Name) == nil then
			local trackerVal = Instance.new("ObjectValue")
			trackerVal.Name = player.Name
			trackerVal.Value = player
			trackerVal.Parent = GameValues.AssistsTracker
		end

		if isTouchingPlate(player.Character, basePlates["First Base"].TouchPart) then
			Remotes.CheckBaseTagging:Fire(player, basePlates["First Base"])
		elseif isTouchingPlate(player.Character, basePlates["Second Base"].TouchPart) then
			Remotes.CheckBaseTagging:Fire(player, basePlates["Second Base"])
		elseif isTouchingPlate(player.Character, basePlates["Third Base"].TouchPart) then
			Remotes.CheckBaseTagging:Fire(player, basePlates["Third Base"])
		end

		wait()
		script.Parent:Destroy()
	end
end

local function armBallTrackingForNearbyDefenders()
	local nearbyParts = workspace:GetPartBoundsInRadius(script.Parent.Position, CHECK_RADIUS)

	for _, part in ipairs(nearbyParts) do
		local character = part:FindFirstAncestorOfClass("Model")
		if character then
			local player = Players:GetPlayerFromCharacter(character)
			if player and ClientFunctions.PlayerIsDefender(player) and currentFieldersInRange[player] == nil then
				currentFieldersInRange[player] = {}

				local leftUpperArm = character:FindFirstChild("LeftUpperArm")
				local upperTorso = character:FindFirstChild("UpperTorso")

				local lShoulder
				if leftUpperArm and leftUpperArm:FindFirstChild("LeftShoulder") then
					lShoulder = leftUpperArm["LeftShoulder"]
				end

				if lShoulder and upperTorso then
					currentFieldersInRange[player]["la0"] = lShoulder.C0
					currentFieldersInRange[player]["la1"] = lShoulder.C1

					local offset = CFrame.new(0,0,-0.5)*CFrame.Angles(math.pi/2,0,0)

					local weld1 = Instance.new("Weld", upperTorso) do
						weld1.Name = "LAWeld"
						weld1.C0 = currentFieldersInRange[player]["la0"]
						weld1.Part0 = upperTorso
						weld1.Part1 = leftUpperArm
					end

					task.spawn(function()
						while script.Parent ~= nil
							and not ballPickedUp
							and upperTorso ~= nil
							and not script.Parent:GetAttribute("TouchedAfterHit")
							and not GameValues.Putout.Value
							and (upperTorso.Position - script.Parent.Position).Magnitude <= CHECK_RADIUS
						do
							local p0c0 = upperTorso:GetRenderCFrame() * weld1.C0
							weld1.C1 = (CFrame.new(p0c0.p, script.Parent.Position)*offset):inverse()*p0c0

							local Glove = character:FindFirstChild("PlayerGlove")
							if script.Parent
								and (upperTorso.Position - script.Parent.Position).Magnitude <= AUTO_CATCH_RADIUS
								and Glove
								and script.Parent.Catchable.Value then
								ballPossessed(player, Glove)
							end

							wait()
						end

						lShoulder.C0 = currentFieldersInRange[player]["la0"]
						lShoulder.C1 = currentFieldersInRange[player]["la1"]

						weld1:Destroy()
						currentFieldersInRange[player] = nil
						ServerFunctions.ResetArms(player)
					end)
				else
					currentFieldersInRange[player] = nil
				end
			end
		end
	end
end

local function autoPickupTracking()
	local nearbyParts = workspace:GetPartBoundsInRadius(script.Parent.Position, AUTO_PICK_UP_RADIUS)

	for _, part in ipairs(nearbyParts) do
		local character = part:FindFirstAncestorOfClass("Model")
		if character then
			local player = Players:GetPlayerFromCharacter(character)
			if player and ClientFunctions.PlayerIsDefender(player) then
				local Glove = character:FindFirstChild("PlayerGlove")
				if Glove and not ballPickedUp then
					ballPossessed(player, Glove)
					break
				end
			end
		end
	end
end

task.spawn(function()
	task.wait(2)
	pitcherCanCatchFlyball = true
end)

task.spawn(function()
	task.wait(0.5)
	fielderCanCatchBall = true
end)

script.Parent.Touched:Connect(function(hit)
	if not hit then return end

	local character = hit:FindFirstAncestorOfClass("Model")
	local isCharacter = character and character:FindFirstChild("Humanoid")

	local ball = script.Parent
	local homeBase = workspace.Plates:FindFirstChild("Home Base")
	if not homeBase then return end

	local distanceFromHome = (ball.Position - homeBase.Position).Magnitude

	if not isCharacter then
		if GameValues.BallHit.Value
			and hit.Parent
			and (hit.Parent.Name == "Plates" or hit.Parent.Name == "Field" or hit.Parent.Name == "FieldGreenBorders")
			and not ball:GetAttribute("TouchedAfterHit")
			and not GameValues.BallFouled.Value
			and (distanceFromHome >= 25 or ignoreBallDistanceFromHome)
		then
			GameValues.FlyBall.Value = false
			ball:SetAttribute("TouchedAfterHit", true)
			
			if hit:GetAttribute("IsMound") or hit.Parent.Name == "FieldGreenBorders" then
				ball.AssemblyLinearVelocity *= 0.5
				ball.AssemblyAngularVelocity *= 0.5
				ball.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
			end
		end
	end
end)

task.wait(0.25) -- SMALL DELAY TO NOT SELF-CATCH BALL

ignoreBallDistanceFromHome = true

script.Parent.Touched:Connect(function(hit)
	if not hit or not hit.Parent then return end
	if not GameValues.FlyBall.Value and not fielderCanCatchBall then return end

	if script.Parent.Catchable.Value and GameValues.BallHit.Value and not GameValues.Homerun.Value then
		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then return end

		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			local player = game.Players:GetPlayerFromCharacter(character)
			if player then
				local Glove = character:FindFirstChild("PlayerGlove")
				if Glove and ClientFunctions.PlayerIsDefender(player) then
					ballPossessed(player, Glove)
				end
			end
		end
	end
end)

while true do
	if script.Parent and script.Parent.Parent == workspace.BallHolder then
		if not script.Parent:GetAttribute("TouchedAfterHit") then
			armBallTrackingForNearbyDefenders()
		else
			autoPickupTracking()
		end
	end
	wait(1)
end
