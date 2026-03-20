local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local GameValues = ReplicatedStorage.GameValues
local SharedModules = ReplicatedStorage.SharedModules
local OnBase = GameValues.OnBase
local BallHolder = workspace.BallHolder
local Remotes = ReplicatedStorage.RemoteEvents

local ClientFunctions = require(SharedModules.ClientFunctions)
local GuiAnimationModule = require(SharedModules.GuiAnimation)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local AbilityPower = playerGui:WaitForChild("AbilityPower")
local AbilityButtons = AbilityPower:WaitForChild("AbilityButtons")

local char = script.Parent

local slideAnim = Instance.new("Animation")
slideAnim.AnimationId = "rbxassetid://106988472245697" 

local humanoid = char:WaitForChild("Humanoid")
local playAnim = humanoid:LoadAnimation(slideAnim)

local canslide = true

local DEFAULT_FORCE = 40000
local slippery = true
local jumpedRecently = false
local velocityFalloff = 0.7
local cooldown = 3
local originalProperties = {}

local function isFoul()
	if GameValues.BallFouled.Value then
		return true
	else
		return false
	end
end

local function dive(force)
	if player.TeamColor == Teams.Lobby.TeamColor then return end
	if not ClientFunctions.PlayerIsDefender(player) and not ClientFunctions.PlayerIsBaserunner(player) and GameValues.CurrentBatter.Value ~= player then return end
	if not GameValues.BallHit.Value then
		if isFoul() then
			if not ClientFunctions.PlayerIsDefender(player)  then
				ClientFunctions.Notification(player, "You cannot use "..AbilityButtons.Dive.AbilityLabel.Text.." until the ball is in play", "Alert")
				return
			end
		else
			ClientFunctions.Notification(player, "You cannot use "..AbilityButtons.Dive.AbilityLabel.Text.." until the ball is in play", "Alert")
			return
		end
	end
	
	if not canslide or not GameValues.BallHit.Value or (OnBase:FindFirstChild(player.Name) and (humanoid.FloorMaterial == Enum.Material.Air)) then 
		if isFoul() then
			if not ClientFunctions.PlayerIsDefender(player)  then
				return
			end
		else
			return
		end
	end
	
	if GameValues.ScoreboardValues.PitchClockEnabled.Value then
		return
	end
	
	local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
	
	if humanoidRootPart and humanoidRootPart:FindFirstChild("TsunamiVelocity") then return end
	
	canslide = false
	
	GuiAnimationModule.DisplayAbilityUnusable(player, "Dive")
	
	-- Disable jumping
	humanoid.JumpPower = 0
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)		

	originalProperties = {}
	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			originalProperties[part] = part.CustomPhysicalProperties
			if slippery then
				part.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0.5, 100, 1)
			end
		end
	end

	playAnim:Play()
	
	Remotes.PlaySlidingVFX:FireServer(true)
	
	if humanoidRootPart then
		local slide = Instance.new("BodyVelocity")
		slide.Name = "SlideBodyVelocity"
		slide.MaxForce = Vector3.new(1, 0, 1) * force
		slide.Velocity = humanoidRootPart.CFrame.LookVector * 100
		slide.Parent = humanoidRootPart

		for count = 1, 10 do
			wait(0.1)
			
			if slide == nil then
				break
			end
			
			slide.Velocity *= velocityFalloff
		end
		
		if slide then
			wait(0.5)
			slide:Destroy()
		end
	end

	playAnim:Stop()

	for part, props in pairs(originalProperties) do
		part.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0.5, 1, 0.3)
	end

	-- Re-enable jumping
	humanoid.JumpPower = 50 -- Default jump power
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	
	GuiAnimationModule.DisplayAbilityCooldown(player, "Dive", cooldown)
	task.wait(cooldown)
	AbilityButtons.Dive.Disabled.Visible = false
	canslide = true
end

local function cancelSlideDive()
	local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart and humanoidRootPart:FindFirstChild("SlideBodyVelocity") then
		humanoidRootPart.SlideBodyVelocity:Destroy()

		playAnim:Stop()
		Remotes.PlaySlidingVFX:FireServer(false)

		for part, props in pairs(originalProperties) do
			part.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0.5, 1, 0.3)
		end
	end
end

humanoid.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
		jumpedRecently = true
		task.delay(0.5, function()
			jumpedRecently = false
		end)
	end
end)

Remotes.TsunamiKnockdown.OnClientEvent:Connect(function(startCF)
	local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
	
	if not humanoidRootPart then return end 
	
	cancelSlideDive()
	
	local bv = Instance.new("BodyVelocity")
	bv.Name = "TsunamiVelocity"
	bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bv.P = 5000
	bv.Velocity = startCF.LookVector * 55 + Vector3.new(0, 25, 0)
	bv.Parent = char.HumanoidRootPart
	Debris:AddItem(bv, 0.20)

	--humanoid.PlatformStand = true
	--task.delay(1, function()
	--	if humanoid then humanoid.PlatformStand = false end
	--end)
end)

Remotes.CancelSlideDive.OnClientEvent:Connect(function()
	cancelSlideDive()
end)

UIS.InputBegan:Connect(function(input, gameprocessed)
	if gameprocessed then return end

	if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonL2 then
		dive(DEFAULT_FORCE, false)
	end
end)

AbilityButtons.Dive.MouseButton1Click:Connect(function()
	dive(DEFAULT_FORCE, false)
end)

local buddyJumpCooldown = 5
local canBuddyJump = true
local BUDDY_JUMP_RANGE = 4
local BUDDY_JUMP_FORCE = 100
local buddyJumpClickDebounce = false

local function isOnBuddyJumpFloor()
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	local buddyJumpFloors = workspace:WaitForChild("BuddyJumpFloor"):GetChildren()
	for _, floorPart in ipairs(buddyJumpFloors) do
		local size = floorPart.Size / 2
		local min = floorPart.Position - size
		local max = floorPart.Position + size
		local pos = hrp.Position

		if (pos.X >= min.X and pos.X <= max.X) and (pos.Z >= min.Z and pos.Z <= max.Z) and (pos.Y >= min.Y and pos.Y <= max.Y + 3) then
			return true
		end
	end
	return false
end

local function findNearbyDefenderTeammate()
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	for _, otherPlayer in ipairs(ClientFunctions.GetPlayersInGame()) do
		if otherPlayer ~= player
			and ClientFunctions.PlayerIsDefender(otherPlayer)
			and otherPlayer.Character
			and otherPlayer.Character:FindFirstChild("HumanoidRootPart")
		then
			local otherHRP = otherPlayer.Character.HumanoidRootPart
			if (hrp.Position - otherHRP.Position).Magnitude <= BUDDY_JUMP_RANGE then
				return otherPlayer
			end
		end
	end
	return nil
end

local function updateBuddyJumpVisibility()
	if not canBuddyJump then
		AbilityButtons.BuddyJump.Visible = false
		return
	end

	if not ClientFunctions.PlayerIsDefender(player) then
		AbilityButtons.BuddyJump.Visible = false
		return
	end

	if not GameValues:FindFirstChild("FlyBall") or not GameValues.FlyBall.Value then
		AbilityButtons.BuddyJump.Visible = false
		return
	end

	if isOnBuddyJumpFloor() and findNearbyDefenderTeammate() then
		AbilityButtons.BuddyJump.Visible = true
	else
		AbilityButtons.BuddyJump.Visible = false
	end
end

local function buddyJump()
	if buddyJumpClickDebounce then return end
	buddyJumpClickDebounce = true

	if not canBuddyJump and not ClientFunctions.PlayerIsDefender(player) then
		buddyJumpClickDebounce = false
		return
	end

	if not isOnBuddyJumpFloor() then
		buddyJumpClickDebounce = false
		return
	end

	if not GameValues:FindFirstChild("FlyBall") or not GameValues.FlyBall.Value then
		ClientFunctions.Notification(player, "You can only Buddy Jump during fly balls!", "Alert")
		buddyJumpClickDebounce = false
		return
	end

	local targetPlayer = findNearbyDefenderTeammate()
	if not targetPlayer then
		ClientFunctions.Notification(player, "No nearby teammate to Buddy Jump!", "Alert")
		buddyJumpClickDebounce = false
		return
	end

	canBuddyJump = false
	AbilityButtons.BuddyJump.Visible = false
	GuiAnimationModule.DisplayAbilityUnusable(player, "BuddyJump")

	local targetCharacter = targetPlayer.Character
	local targetHumanoid = targetCharacter and targetCharacter:FindFirstChild("Humanoid")

	if targetHumanoid then
		Remotes.BuddyJump:FireServer(targetPlayer)
	end

	GuiAnimationModule.DisplayAbilityCooldown(player, "BuddyJump", buddyJumpCooldown)

	task.delay(buddyJumpCooldown, function()
		AbilityButtons.BuddyJump.Disabled.Visible = false
		canBuddyJump = true
		buddyJumpClickDebounce = false
	end)
end


UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonR1 then
		if ClientFunctions.PlayerIsDefender(player) then
			buddyJump()
		end
	end
end)

AbilityButtons.BuddyJump.MouseButton1Click:Connect(function()
	buddyJump()
end)

Remotes.SuperSlide.OnClientEvent:Connect(function(mode)
	if mode == "FishDive" then
		dive(DEFAULT_FORCE * 3, false)
	else
		dive(DEFAULT_FORCE * 2, false)
	end
end)

-- Continuous check every 0.2 seconds to update visibility
task.spawn(function()
	while true do
		updateBuddyJumpVisibility()
		task.wait(0.2)
	end
end)

Remotes.BuddyJumpResult.OnClientEvent:Connect(function(success, msg)
	-- If server rejected, immediately clear the local click debounce so the user can try again
	if not success then
		ClientFunctions.Notification(player, msg or "Buddy Jump failed.", "Alert")
		-- allow immediate retry on failure
		buddyJumpClickDebounce = false
		return
	end

	-- On success, show the toast. Cooldown UI is already handled below.
	ClientFunctions.Notification(player, msg or "Buddy Jump success! 🚀", "Success")
end)