local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.RemoteEvents
local DailyRewards = require(ReplicatedStorage.SharedModules.DailyRewardsModule)
local Players = game:GetService("Players")

Remotes.ClaimDailyReward.OnServerInvoke = function(player)
	local sharedData = ReplicatedStorage.SharedData[player.Name]
	local lastClaim = sharedData.DailyRewards.LastClaimed.Value
	local currentDay = sharedData.DailyRewards.CurrentDay.Value
	local now = os.time()

	local cooldown = 86400 -- 24 hours cooldown

	if player.Name == "Randy_Moss" then
		cooldown = 3 -- Testing cooldown for Randy
	end

	if now - lastClaim >= cooldown or lastClaim == 0 then
		local reward = DailyRewards.Rewards[currentDay]
		local session = _G.sessionData[player]
		print (currentDay)
		print (reward.Type)

		-- Handle rewards
		if reward.Type == "Spins" then
			session.StyleSpins += reward.Amount
			sharedData.StyleSpins.Value = session.StyleSpins

		elseif reward.Type == "LuckySpins" then
			session.LuckySpins += reward.Amount
			sharedData.LuckySpins.Value = session.LuckySpins

		elseif reward.Type == "Coins" then
			session.Cash += reward.Amount
			sharedData.Cash.Value = session.Cash

		elseif reward.Type == "GlovePack" then
			session.GlovePackRolls["Standard Glove Pack"] = (session.GlovePackRolls["Standard Glove Pack"] or 0) + 1

		elseif reward.Type == "TrailPack" then
			session.TrailPackRolls["Standard Trail Pack"] = (session.TrailPackRolls["Standard Trail Pack"] or 0) + 1

		elseif reward.Type == "EliteBatPack" then
			session.BatPackRolls["Elite Bat Pack"] = (session.BatPackRolls["Elite Bat Pack"] or 0) + 1
		end

		session.DailyRewards.LastClaimed = now

		session.DailyRewards.CurrentDay = currentDay % 7 + 1

		sharedData.DailyRewards.LastClaimed.Value = now
		sharedData.DailyRewards.CurrentDay.Value = session.DailyRewards.CurrentDay

		Remotes.Notification:FireClient(player, "Reward Claimed!", "Check your inventory.")
		Remotes.UpdateInventory:FireClient(player, "Bat")
		Remotes.UpdateInventory:FireClient(player, "Trail")
		Remotes.UpdateInventory:FireClient(player, "Glove")
		Remotes.UpdateInventory:FireClient(player, "Coins")
		Remotes.UpdateInventory:FireClient(player, "StyleSpins")
		Remotes.UpdateInventory:FireClient(player, "LuckySpins")

		return true, reward
	else
		local timeLeft = cooldown - (now - lastClaim)
		local hrs = math.ceil(timeLeft / 3600)

		Remotes.Notification:FireClient(player, "Cannot Claim Yet!", "Time Left: "..hrs.." hours.")

		return false, timeLeft
	end
end
