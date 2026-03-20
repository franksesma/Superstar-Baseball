local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ServerScriptService.Modules
local Remotes = ReplicatedStorage.RemoteEvents

local AntiExploit = require(Modules.AntiExploit)

-- Track debounce per player
local playerDebounce = {}
local COOLDOWN = 5 -- seconds

Remotes.BuddyJump.OnServerEvent:Connect(function(player, targetPlayer)
	-- Debounce check
	if playerDebounce[player] then return end
	playerDebounce[player] = true

	-- Validate targetPlayer and their character parts
	if not targetPlayer 
		or not targetPlayer.Character 
		or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") 
		or not targetPlayer.Character:FindFirstChild("Humanoid") 
	then 
		playerDebounce[player] = nil
		return 
	end

	-- Validate player character
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not humanoid then
		playerDebounce[player] = nil
		return
	end

	AntiExploit.Ignore(player, 2)

	local oldJumpPower = humanoid.JumpPower

	humanoid.JumpPower = 150
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	humanoid.Jump = true

	task.delay(0.2, function()
		if humanoid then
			humanoid.JumpPower = 50--oldJumpPower
		end
	end)

	-- Clear debounce after cooldown
	task.delay(COOLDOWN, function()
		playerDebounce[player] = nil
	end)
end)
