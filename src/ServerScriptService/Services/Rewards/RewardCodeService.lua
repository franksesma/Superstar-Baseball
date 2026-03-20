local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SharedData = ReplicatedStorage:WaitForChild("SharedData")
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local Services = ServerScriptService:WaitForChild("Services")

local CachedModules = require(ServerScriptService.Server.CachedModules)
local StaticRewardCodes = require(Services.Rewards.RewardCodes)

local RewardCodeService = {}

local latestLikes = 0
local currentProgressData = nil

RewardCodeService.BASE_AVAILABLE_CODE = "RELEASE"
RewardCodeService.LIKE_STEP = 10000
RewardCodeService.START_MILESTONE = 10000
RewardCodeService.DEFAULT_LIKE_REWARD = {
	Spins = 2
}


function RewardCodeService:GetLikeCodeName(milestone)
	return string.format("%dKLIKES", milestone / 1000)
end

function RewardCodeService:GetNextLikeGoal(likes)
	if likes < self.START_MILESTONE then
		return self.START_MILESTONE
	end

	return math.ceil((likes + 1) / self.LIKE_STEP) * self.LIKE_STEP
end

function RewardCodeService:GetPreviousLikeGoal(goal)
	return math.max(goal - self.LIKE_STEP, 0)
end

function RewardCodeService:GetProgressData(likes)
	local nextGoal = self:GetNextLikeGoal(likes)
	local previousGoal = self:GetPreviousLikeGoal(nextGoal)

	local progressMax = math.max(nextGoal - previousGoal, 1)
	local progress = math.clamp(likes - previousGoal, 0, progressMax)
	local percent = math.clamp(progress / progressMax, 0, 1)

	local currentCode
	if previousGoal >= self.START_MILESTONE then
		currentCode = self:GetLikeCodeName(previousGoal)
	else
		currentCode = self.BASE_AVAILABLE_CODE
	end

	return {
		likes = likes,
		previousGoal = previousGoal,

		goal = nextGoal,
		nextGoal = nextGoal,

		progress = progress,
		progressMax = progressMax,
		percent = percent,

		currentCode = currentCode,
		nextCode = self:GetLikeCodeName(nextGoal),
	}
end

function RewardCodeService:GetMilestoneFromCode(codeName)
	if not codeName then
		return nil
	end

	local normalized = string.upper(string.gsub(codeName, "%s+", ""))
	local amount = string.match(normalized, "^(%d+)KLIKES$")

	if not amount then
		return nil
	end

	return tonumber(amount) * 1000
end

function RewardCodeService:GetLikeCodeData(codeName, likes)
	local milestone = self:GetMilestoneFromCode(codeName)
	if not milestone then
		return nil
	end

	if milestone < self.START_MILESTONE then
		return nil
	end

	if milestone % self.LIKE_STEP ~= 0 then
		return nil
	end

	if likes < milestone then
		return nil
	end

	return {
		Active = true,
		IsLikeCode = true,
		Milestone = milestone,
		Spins = self.DEFAULT_LIKE_REWARD.Spins or 0,
		Coins = self.DEFAULT_LIKE_REWARD.Coins or 0,
		LuckySpins = self.DEFAULT_LIKE_REWARD.LuckySpins or 0,
	}
end

function RewardCodeService:GetCodeData(codeName, likes)
	if not codeName then
		return nil
	end

	local normalized = string.upper(string.gsub(codeName, "%s+", ""))

	local staticCode = StaticRewardCodes[normalized]
	if staticCode then
		if staticCode.MaxLikes and likes >= staticCode.MaxLikes then
			return nil -- expired
		end
		return staticCode
	end

	return self:GetLikeCodeData(normalized, likes)
end

function RewardCodeService:IsCodeValid(codeName, likes)
	local data = self:GetCodeData(codeName, likes)
	return data ~= nil and data.Active == true
end

local function broadcastLikes(player)
	if not currentProgressData then
		currentProgressData = RewardCodeService:GetProgressData(latestLikes)
	end

	if player then
		Remotes.UpdateLikes:FireClient(player, currentProgressData)
	else
		Remotes.UpdateLikes:FireAllClients(currentProgressData)
	end
end

local function fetchLikes()
	local universeId = game.GameId
	local url = "https://games.roproxy.com/v1/games/" .. universeId .. "/votes"

	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if success then
		local data = HttpService:JSONDecode(response)
		latestLikes = data.upVotes or 0
		currentProgressData = RewardCodeService:GetProgressData(latestLikes)

		ReplicatedStorage:SetAttribute("LatestGameLikes", latestLikes)

		print(
			"Likes:", currentProgressData.likes,
			"Goal:", currentProgressData.goal,
			"Percent:", currentProgressData.percent,
			"CurrentCode:", currentProgressData.currentCode,
			"NextCode:", currentProgressData.nextCode
		)

		broadcastLikes()
	else
		warn("Failed to fetch likes: " .. tostring(response))
	end
end

function RewardCodeService.init()
	Remotes.RewardCode.OnServerEvent:Connect(function(player, code)
		local ServerUtilFunctions = CachedModules.Cache.ServerUtilFunctions

		if typeof(code) ~= "string" then
			Remotes.Notification:FireClient(player, "Invalid or expired code", "Alert")
			return
		end

		local normalizedCode = string.upper(string.gsub(code, "%s+", ""))
		local codeData = RewardCodeService:GetCodeData(normalizedCode, latestLikes)

		if codeData and codeData.Active then
			if not table.find(_G.sessionData[player].RewardCodes, normalizedCode) then
				table.insert(_G.sessionData[player].RewardCodes, normalizedCode)

				if codeData.Coins and codeData.Coins > 0 then
					ServerUtilFunctions.CashTransaction(player, codeData.Coins, true)
					Remotes.Notification:FireClient(player, "You were rewarded " .. tostring(codeData.Coins) .. " Coins!", "Coins")
				end

				if codeData.Spins and codeData.Spins > 0 then
					_G.sessionData[player].StyleSpins = _G.sessionData[player].StyleSpins + codeData.Spins
					SharedData[player.Name].StyleSpins.Value = _G.sessionData[player].StyleSpins
					Remotes.Notification:FireClient(player, "You received " .. tostring(codeData.Spins) .. " free spin(s)!", "Spins")
				end

				if codeData.LuckySpins and codeData.LuckySpins > 0 then
					_G.sessionData[player].LuckySpins = _G.sessionData[player].LuckySpins + codeData.LuckySpins
					SharedData[player.Name].LuckySpins.Value = _G.sessionData[player].LuckySpins
					Remotes.Notification:FireClient(player, "You received " .. tostring(codeData.LuckySpins) .. " free lucky spin(s)!", "Lucky Spins")
				end

				if (not codeData.Coins or codeData.Coins == 0)
					and (not codeData.Spins or codeData.Spins == 0)
					and (not codeData.LuckySpins or codeData.LuckySpins == 0)
				then
					Remotes.Notification:FireClient(player, "This code has no rewards configured.", "Alert")
				end
			else
				Remotes.Notification:FireClient(player, "You already redeemed this code", "Alert")
			end
		else
			Remotes.Notification:FireClient(player, "Invalid or expired code", "Alert")
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		task.wait(1)
		broadcastLikes(player)
	end)

	task.spawn(function()
		fetchLikes()

		while true do
			task.wait(60)
			fetchLikes()
		end
	end)
end

return RewardCodeService