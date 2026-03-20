local RankedSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MemoryService = game:GetService("MemoryStoreService")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = ReplicatedStorage.RemoteEvents
local GameValues = ReplicatedStorage.GameValues
local SharedModules = ReplicatedStorage.SharedModules
local ServrGUIs = ServerStorage.ServerGUIs
local Modules = ServerScriptService.Modules

local RankedUtilities = require(SharedModules.RankedUtilities)
local ServerFunctions = require(Modules.ServerFunctions)

local DURATION = 1800

RankedSystem.RankedQueueStore = MemoryService:GetSortedMap("RankedQueue10")
RankedSystem.RankedLobbyParties = {}

RankedSystem.JoinedTeams = {}
RankedSystem.HostPlayerNames = {}
RankedSystem.LobbyType = nil

function RankedSystem.GetHighestRankedPlayer(lobbyType)
	local highestElo = -math.huge
	local highestPlayer = nil

	for _, player in ipairs(RankedSystem.RankedLobbyParties[lobbyType].Players) do
		local session = _G.sessionData[player]
		if session and session.RankedSeasonData and session.RankedSeasonData.ELO then
			local elo = session.RankedSeasonData.ELO
			if elo > highestElo then
				highestElo = elo
				highestPlayer = player
			end
		end
	end

	if highestPlayer then
		return {
			Player = highestPlayer,
			Elo = highestElo,
			Rank = RankedUtilities.GetRankByElo(highestElo)
		}
	end

	return nil 
end

function RankedSystem.GameEndResult(player, wonGame)
	local session = _G.sessionData[player]
	
	if session and session.RankedSeasonData and session.RankedSeasonData.ELO then
		local rank = RankedUtilities.GetRankByElo(session.RankedSeasonData.ELO)
		
		if rank then
			if wonGame then
				local eloEarned = RankedUtilities.RankProgression[rank]
				session.RankedSeasonData.ELO = session.RankedSeasonData.ELO + eloEarned
				session.RankedSeasonData.Wins = session.RankedSeasonData.Wins + 1
				
				Remotes.Notification:FireClient(player, `You earned {eloEarned} Elo for winning.`)
			else
				local eloLost = math.ceil(RankedUtilities.RankProgression[rank] / 2)
				
				if session.RankedSeasonData.ELO - eloLost >= 0 then
					session.RankedSeasonData.ELO = session.RankedSeasonData.ELO - eloLost
				end
				session.RankedSeasonData.Losses = session.RankedSeasonData.Losses + 1
				
				Remotes.Notification:FireClient(player, `You lost {eloLost} Elo for losing.`)
			end 
		end
	end
end

function RankedSystem.GetLobbyTypeFromPlayerHost(player)
	for lobbyName, party in pairs(RankedSystem.RankedLobbyParties) do
		local foundPlayer = table.find(party.Players, player) 
		if foundPlayer then
			if foundPlayer ~= 1 then return end

			return lobbyName
		end
	end

	return
end

function RankedSystem.PlayerIsInLobbyParty(player)
	for lobbyName, party in pairs(RankedSystem.RankedLobbyParties) do
		if table.find(party.Players, player) then
			return lobbyName
		end
	end
end

function RankedSystem.RemovePartiesFromQueue(lobbyType)	
	local success, result = pcall(function() 
		return RankedSystem.RankedQueueStore:GetAsync(lobbyType)
	end)
	
	if success and result then
		for i, data in pairs(result) do
			if i == tostring(game.JobId) then
				result[i] = nil

				local queueSuccess, queueError = pcall(function()
					RankedSystem.RankedQueueStore:SetAsync(lobbyType, result, DURATION)
				end)

				break
			end
		end
	end
end

function RankedSystem.LeaveLobbyParty(player, lobbyType)
	local foundIndex = table.find(RankedSystem.RankedLobbyParties[lobbyType].Players, player)

	if foundIndex then
		table.remove(RankedSystem.RankedLobbyParties[lobbyType].Players, foundIndex)
		
		for _, partyPlayer in pairs(RankedSystem.RankedLobbyParties[lobbyType].Players) do
			if partyPlayer then
				Remotes.UpdateRankedLobbyPartyUI:FireClient(partyPlayer, RankedSystem.RankedLobbyParties[lobbyType], lobbyType)
			end
		end
		
		if #RankedSystem.RankedLobbyParties[lobbyType].Players == 0 then
			RankedSystem.RankedLobbyParties[lobbyType] = {Players = {}, FriendsOnly = false, LobbyQueued = false, Teleporting = false}
			
			RankedSystem.RemovePartiesFromQueue(lobbyType)
		end
	end
end

function RankedSystem.RemainingOpponentsCheck()
	local homeTeamPlayersLeft = 0
	local awayTeamPlayersLeft = 0
	
	for _, player in pairs(Players:GetPlayers()) do
		if player.Team then
			if player.Team.Name == GameValues.AwayTeamPicked.Value then
				awayTeamPlayersLeft = awayTeamPlayersLeft + 1
			elseif player.Team.Name == GameValues.HomeTeamPicked.Value then
				homeTeamPlayersLeft = homeTeamPlayersLeft + 1
			end
		end 
	end
	
	if awayTeamPlayersLeft == 0 or homeTeamPlayersLeft == 0 then
		GameValues.GameActive.Value = false
		
		local gameOverNotice = ServrGUIs.ShutdownNotice:Clone()
		
		gameOverNotice.Frame.TitleLabel.Text = "Opponent team has left the game, teleporting back to lobby.."
		
		for _, player in pairs(Players:GetPlayers()) do
			gameOverNotice:Clone().Parent = player.PlayerGui
			
			RankedSystem.GameEndResult(player, true)
			
			task.delay(2, function()
				TeleportService:Teleport(101432174163538, player)
			end)
		end
	end
end

function RankedSystem.MercyRuleReached()
	if ServerFunctions.GetServerType() == "ReservedServer" then
		local homeScore = GameValues.ScoreboardValues.HomeScore.Value
		local awayScore = GameValues.ScoreboardValues.AwayScore.Value

		if homeScore - awayScore >= 15 then
			GameValues.GameActive.Value = false
			return "Home"
		elseif awayScore - homeScore >= 15 then
			GameValues.GameActive.Value = false
			return "Away"
		end
	end

	return nil
end

return RankedSystem