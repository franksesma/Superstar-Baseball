local PlayerService = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MemoryService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local Remotes = ReplicatedStorage.RemoteEvents
local Modules = ServerScriptService.Modules
local SharedModules = ReplicatedStorage.SharedModules
local ServerGUIs = ServerStorage.ServerGUIs
local GameValues = ReplicatedStorage.GameValues

local RankedSystem = require(Modules.RankedSystem)
local ClientFunctions = require(SharedModules.ClientFunctions)
local ServerFunctions = require(Modules.ServerFunctions)
local RankedUtilities = require(SharedModules.RankedUtilities)

local DURATION = 1800
local RANKED_PLACE_ID = 101432174163538

local rankedLobbyJoinParts = workspace.RankedLobbyJoinParts
local partyTeleports = rankedLobbyJoinParts.PartyTeleports

local RankToTier = {}
for index, rankInfo in ipairs(RankedUtilities.RankedRatings) do
	RankToTier[rankInfo.Name] = index
end

GameValues.ServerType.Value = ServerFunctions.GetServerType()

local function GetRankTolerance(waitTime)
	if waitTime > 60 then
		return 6
	elseif waitTime > 30 then
		return 3
	elseif waitTime > 15 then
		return 1
	end
	return 0
end

for _, part in pairs(rankedLobbyJoinParts:GetChildren()) do
	if part:IsA("BasePart") then
		local lobbyType = part.Name

		RankedSystem.RankedLobbyParties[lobbyType] = {Players = {}, FriendsOnly = false, LobbyQueued = false, Teleporting = false, QueueStartTime = os.time()}

		part.Touched:Connect(function(hit)
			local character = hit.Parent

			if character == nil then return end 

			if ServerFunctions.GetServerType() == "ReservedServer" then return end

			local player = PlayerService:GetPlayerFromCharacter(character)

			if player == nil or ClientFunctions.PlayerIsInGame(player) then return end

			if RankedSystem.PlayerIsInLobbyParty(player) then return end

			if #RankedSystem.RankedLobbyParties[lobbyType].Players >= RankedUtilities.LobbyTypes[lobbyType].Size then
				Remotes.Notification:FireClient(player, "This party is currently full!", "Alert")
				return
			end 

			if RankedSystem.RankedLobbyParties[lobbyType].LobbyQueued then
				Remotes.Notification:FireClient(player, "This party is currently in a queue!", "Alert")
				return
			end

			local partyHost = RankedSystem.RankedLobbyParties[lobbyType].Players[1]

			if partyHost then
				local isFriendsOnly = RankedSystem.RankedLobbyParties[lobbyType].FriendsOnly

				if isFriendsOnly then
					if partyHost:IsFriendsWith(player.userId) then
						table.insert(RankedSystem.RankedLobbyParties[lobbyType].Players, player)
					else
						Remotes.Notification:FireClient(player, "This party is locked for friends only!", "Alert")
						return 
					end
				else
					table.insert(RankedSystem.RankedLobbyParties[lobbyType].Players, player)
				end
			else
				table.insert(RankedSystem.RankedLobbyParties[lobbyType].Players, player)
			end
			
			part.SurfaceGui.Frame.FillLabel.Text = `({#RankedSystem.RankedLobbyParties[lobbyType].Players}/{RankedUtilities.LobbyTypes[lobbyType].Size} PLAYERS)`

			ServerFunctions.TeleportPlayerCharacter(player, partyTeleports[lobbyType].In.CFrame)
			ServerGUIs.RankedPartyGui:Clone().Parent = player.PlayerGui
			
			task.wait()
			
			for _, partyPlayer in pairs(RankedSystem.RankedLobbyParties[lobbyType].Players) do
				if partyPlayer then
					Remotes.UpdateRankedLobbyPartyUI:FireClient(partyPlayer, RankedSystem.RankedLobbyParties[lobbyType], lobbyType)
				end
			end
		end)
	end
end

Remotes.ToggleRankedPartyFriendsOnly.OnServerEvent:Connect(function(player)
	local lobbyType = RankedSystem.GetLobbyTypeFromPlayerHost(player)
	
	if lobbyType == nil then return end
	
	RankedSystem.RankedLobbyParties[lobbyType].FriendsOnly = not RankedSystem.RankedLobbyParties[lobbyType].FriendsOnly
	
	for _, partyPlayer in pairs(RankedSystem.RankedLobbyParties[lobbyType].Players) do
		if partyPlayer then
			Remotes.ToggleRankedPartyFriendsOnly:FireClient(partyPlayer, RankedSystem.RankedLobbyParties[lobbyType].FriendsOnly)
		end
	end
end)

Remotes.LeaveRankedLobbyParty.OnServerEvent:Connect(function(player)
	local lobbyType = RankedSystem.PlayerIsInLobbyParty(player)

	if lobbyType == nil then return end
	
	ServerFunctions.TeleportPlayerCharacter(player, partyTeleports[lobbyType].Out.CFrame)
	task.wait(0.2)
	RankedSystem.LeaveLobbyParty(player, lobbyType)
	Remotes.Notification:FireClient(player, "You left the "..lobbyType.." ranked lobby", "Alert")
	rankedLobbyJoinParts[lobbyType].SurfaceGui.Frame.FillLabel.Text = `({#RankedSystem.RankedLobbyParties[lobbyType].Players}/{RankedUtilities.LobbyTypes[lobbyType].Size} PLAYERS)`
end)

Remotes.KickFromRankedLobbyParty.OnServerEvent:Connect(function(player, kickedPlayer)
	local lobbyType = RankedSystem.PlayerIsInLobbyParty(player)
	
	if lobbyType == nil then return end
	if kickedPlayer == player then return end
	
	if player == RankedSystem.RankedLobbyParties[lobbyType].Players[1] then
		RankedSystem.LeaveLobbyParty(kickedPlayer, lobbyType)
		Remotes.Notification:FireClient(kickedPlayer, "You were kicked from the "..lobbyType.." ranked lobby", "Alert")
		Remotes.DestroyGui:FireClient(kickedPlayer, "RankedPartyGui")
		ServerFunctions.TeleportPlayerCharacter(kickedPlayer, partyTeleports[lobbyType].Out.CFrame)
	end
end)

Remotes.ToggleRankedQueue.OnServerEvent:Connect(function(player)
	local lobbyType = RankedSystem.GetLobbyTypeFromPlayerHost(player)

	if lobbyType == nil then return end
	if RankedSystem.RankedLobbyParties[lobbyType].Teleporting then return end
	if #RankedSystem.RankedLobbyParties[lobbyType].Players ~= RankedUtilities.LobbyTypes[lobbyType].Size then
		Remotes.Notification:FireClient(player, "Not enough players to start queue", "Alert")
		return
	end

	if not RankedSystem.RankedLobbyParties[lobbyType].LobbyQueued then -- queue started, ready'd up
		local success, result = pcall(function()
			return RankedSystem.RankedQueueStore:GetAsync(lobbyType)
		end)

		local highestRank = RankedSystem.GetHighestRankedPlayer(lobbyType)

		if highestRank == nil then return end

		if success and result == nil then --nothing in queue
			local data = {
				[tostring(game.JobId)] = { ServerID = game.JobId, LobbyType = lobbyType, LobbyRank = highestRank.Rank, QueueStartTime = nil }
			}

			local queueSuccess, queueError = pcall(function()
				RankedSystem.RankedQueueStore:SetAsync(lobbyType, data, DURATION)
			end)

			if not queueSuccess then
				print("Error while updating ranked queue")
			else
				RankedSystem.RankedLobbyParties[lobbyType].LobbyQueued = true
				RankedSystem.RankedLobbyParties[lobbyType].QueueStartTime = os.time()
				
				for _, partyPlayer in pairs(RankedSystem.RankedLobbyParties[lobbyType].Players) do
					if partyPlayer then
						Remotes.ToggleRankedQueue:FireClient(partyPlayer, true)
					end
				end
			end
		elseif success then
			local matchedParty

			for i, data in pairs(result) do
				if data.LobbyRank == highestRank.Rank and data.ServerID ~= game.JobId and data.ServerID ~= "" then
					result[i] = nil

					local queueSuccess, queueError = pcall(function()
						RankedSystem.RankedQueueStore:SetAsync(lobbyType, result, DURATION)
					end)

					matchedParty = data

					break
				end
			end
			
			if matchedParty then -- matched party found, trigger messagingservice
				local teleportData = {
					matchedParty.ServerID;
					game.JobId;
					lobbyType;
					TeleportService:ReserveServer(RANKED_PLACE_ID)
				}

				local encodedData = HttpService:JSONEncode(teleportData)

				local publishSuccess, publishError = pcall(function()
					MessagingService:PublishAsync("matchfound", encodedData)
				end)

				if publishSuccess then
					RankedSystem.RankedLobbyParties[lobbyType].LobbyQueued = true
					RankedSystem.RankedLobbyParties[lobbyType].QueueStartTime = os.time()
					
					for _, partyPlayer in pairs(RankedSystem.RankedLobbyParties[lobbyType].Players) do
						if partyPlayer then
							Remotes.ToggleRankedQueue:FireClient(partyPlayer, true)
						end
					end
				else
					warn(publishError)
				end
			else -- reinsert back into queue, matched party not found
				local partyQueueData = { 
					ServerID = game.JobId, 
					LobbyType = lobbyType, 
					LobbyRank = highestRank.Rank,
					QueueStartTime = os.time()
				}

				result[tostring(game.JobId)] = partyQueueData

				local queueSuccess, queueError = pcall(function()
					RankedSystem.RankedQueueStore:SetAsync(lobbyType, result, DURATION)
				end)
				
				if queueSuccess then
					RankedSystem.RankedLobbyParties[lobbyType].LobbyQueued = true
					RankedSystem.RankedLobbyParties[lobbyType].QueueStartTime = os.time()

					for _, partyPlayer in pairs(RankedSystem.RankedLobbyParties[lobbyType].Players) do
						if partyPlayer then
							Remotes.ToggleRankedQueue:FireClient(partyPlayer, true)
						end
					end
				end
			end
		else
			Remotes.Notification:FireClient(player, "There was an error with matchmaking, please try again later", "Alert")
			warn("Couldn't get ranked queue from memory store. Lobby Type: "..lobbyType)
		end
	else -- remove from queue if canceled
		RankedSystem.RankedLobbyParties[lobbyType].LobbyQueued = false
		RankedSystem.RankedLobbyParties[lobbyType].QueueStartTime = nil

		RankedSystem.RemovePartiesFromQueue(lobbyType)
		
		for _, partyPlayer in pairs(RankedSystem.RankedLobbyParties[lobbyType].Players) do
			if partyPlayer then
				Remotes.ToggleRankedQueue:FireClient(partyPlayer, false)
			end
		end
	end
end)

--[[
local function SafeTeleport(players, placeId, teleportOptions)
	local maxRetries = 3
	for attempt = 1, maxRetries do
		local success, err = pcall(function()
			TeleportService:TeleportAsync(placeId, players, teleportOptions)
		end)

		if success then
			return true
		else
			warn("Teleport failed, attempt " .. attempt .. ": " .. err)
			task.wait(2) -- small backoff
		end
	end
	return false
end


MessagingService:SubscribeAsync("matchfound", function(message)
	local decodedMessage = HttpService:JSONDecode(message.Data)

	local teleportOption = Instance.new("TeleportOptions")
	teleportOption.ReservedServerAccessCode = decodedMessage[4]

	if game.JobId == decodedMessage[1] or game.JobId == decodedMessage[2] then
		local lobbyType = decodedMessage[3]
		
		if not RankedSystem.RankedLobbyParties[lobbyType].Teleporting then
			local team = RankedSystem.RankedLobbyParties[lobbyType].Players
			
			local teleportData = {
				TeamNames = {},
				ServerID = game.JobId,
				HostName = team[1].Name,
				LobbyType = lobbyType,
			}
			
			for _, teammatePlayer in pairs(team) do
				table.insert(teleportData.TeamNames, teammatePlayer.Name)
			end
			
			teleportOption:SetTeleportData(teleportData)
			
			local teleportSuccess = SafeTeleport(team, RANKED_PLACE_ID, teleportOption)

			if teleportSuccess then
				-- TODO: Notify teleportation in progress, blur effect?
				RankedSystem.RankedLobbyParties[lobbyType].Teleporting = true

				local success, result = pcall(function() 
					return RankedSystem.RankedQueueStore:GetAsync(lobbyType)
				end)

				if success and result then
					RankedSystem.RemovePartiesFromQueue(lobbyType)
				end

				task.wait(5)

				RankedSystem.RankedLobbyParties[lobbyType] = {Players = {}, FriendsOnly = false, LobbyQueued = false, Teleporting = false, QueueStartTime = nil}
			else
				local success, result = pcall(function() 
					return RankedSystem.RankedQueueStore:GetAsync(lobbyType)
				end)

				if success and result then
					RankedSystem.RemovePartiesFromQueue(lobbyType)
				end
			end
		end
	end
end)
--]]


local function IsPlayerReady(player)
	return player 
		and player.Parent == PlayerService
		and player.Character 
		and player.Character:FindFirstChild("HumanoidRootPart")
end

local function GetReadyPlayers(players)
	local ready = {}
	for _, p in ipairs(players) do
		if IsPlayerReady(p) then
			table.insert(ready, p)
		end
	end
	return ready
end

local function SafeTeleport(players, placeId, teleportOptions)
	local maxRetries = 3
	for attempt = 1, maxRetries do
		local success, err = pcall(function()
			TeleportService:TeleportAsync(placeId, players, teleportOptions)
		end)

		if success then
			return true
		else
			warn("Teleport failed, attempt " .. attempt .. ": " .. err)
			task.wait(2)
		end
	end
	return false
end

TeleportService.TeleportInitFailed:Connect(function(player, result, err)
	--warn("TeleportInitFailed for " .. player.Name .. " | " .. tostring(result) .. " | " .. tostring(err))
	
	if player and player.Parent == PlayerService and player:GetAttribute("ReservedCode") then
		local retryOptions = Instance.new("TeleportOptions")
		retryOptions.ReservedServerAccessCode = player:GetAttribute("ReservedCode")
		SafeTeleport({player}, RANKED_PLACE_ID, retryOptions)
	end
end)

MessagingService:SubscribeAsync("matchfound", function(message)
	local decodedMessage = HttpService:JSONDecode(message.Data)

	local reservedCode = decodedMessage[4]
	local teleportOption = Instance.new("TeleportOptions")
	teleportOption.ReservedServerAccessCode = reservedCode

	if game.JobId == decodedMessage[1] or game.JobId == decodedMessage[2] then
		local lobbyType = decodedMessage[3]

		if not RankedSystem.RankedLobbyParties[lobbyType].Teleporting then
			local team = RankedSystem.RankedLobbyParties[lobbyType].Players
			local readyPlayers = GetReadyPlayers(team)

			if #readyPlayers == 0 then return end

			-- Store reserved code per player (for TeleportInitFailed retries)
			for _, p in ipairs(readyPlayers) do
				p:SetAttribute("ReservedCode", reservedCode)
			end

			-- TeleportData payload
			local teleportData = {
				TeamNames = {},
				ServerID = game.JobId,
				HostName = readyPlayers[1].Name,
				LobbyType = lobbyType,
			}
			for _, teammatePlayer in pairs(readyPlayers) do
				table.insert(teleportData.TeamNames, teammatePlayer.Name)
			end
			teleportOption:SetTeleportData(teleportData)

			-- Main teleport attempt
			local teleportSuccess = SafeTeleport(readyPlayers, RANKED_PLACE_ID, teleportOption)

			if not teleportSuccess then
				-- Retry stragglers one-by-one with same reserved code
				for _, player in ipairs(readyPlayers) do
					SafeTeleport({player}, RANKED_PLACE_ID, teleportOption)
				end
			end

			-- Mark as teleporting and cleanup queue
			RankedSystem.RankedLobbyParties[lobbyType].Teleporting = true
			local success, result = pcall(function() 
				return RankedSystem.RankedQueueStore:GetAsync(lobbyType)
			end)
			if success and result then
				RankedSystem.RemovePartiesFromQueue(lobbyType)
			end

			-- After some buffer, clear the lobby party
			task.delay(8, function()
				RankedSystem.RankedLobbyParties[lobbyType] = {
					Players = {},
					FriendsOnly = false,
					LobbyQueued = false,
					Teleporting = false,
					QueueStartTime = nil
				}
			end)
		end
	end
end)


-- Background matchmaking loop
task.spawn(function()
	while true do
		task.wait(10 + math.random(0, 5)) -- wait 10–15s

		-- Update global queue UI
		for lobbyType, _ in pairs(RankedUtilities.LobbyTypes) do
			local success, queueData = pcall(function()
				return RankedSystem.RankedQueueStore:GetAsync(lobbyType)
			end)

			local count = 0
			if success then
				for _ in pairs(queueData or {}) do
					count = count + 1
				end
			end

			local label = rankedLobbyJoinParts.PartiesAvailable[lobbyType].SurfaceGui.Frame.TextLabel
			label.Text = count.." Parties in Global Queue"
			label.TextColor3 = (count > 0) and Color3.fromRGB(85, 255, 0) or Color3.fromRGB(255, 0, 0)
		end

		-- Matchmake queued parties
		for lobbyType, partyData in pairs(RankedSystem.RankedLobbyParties) do
			if partyData.LobbyQueued and #partyData.Players > 0 then
				local highestRank = RankedSystem.GetHighestRankedPlayer(lobbyType)
				if not highestRank then continue end

				local currentTier = RankToTier[highestRank.Rank]
				if not currentTier then continue end

				local success, queueData = pcall(function()
					return RankedSystem.RankedQueueStore:GetAsync(lobbyType)
				end)
				if not success then
					warn("Could not access RankedQueueStore for lobby:", lobbyType)
					continue
				end

				local matchedParty
				for key, queuedParty in pairs(queueData or {}) do
					if queuedParty.ServerID ~= game.JobId and queuedParty.ServerID ~= "" then
						local queuedTier = RankToTier[queuedParty.LobbyRank]
						if not queuedTier then continue end

						local tierDiff = math.abs(currentTier - queuedTier)

						-- Calculate wait times for both parties
						local selfWaitTime = os.time() - (partyData.QueueStartTime or os.time())
						local queuedWaitTime = os.time() - (queuedParty.QueueStartTime or os.time())
						
						-- Calculate individual tolerances
						local selfTolerance = GetRankTolerance(selfWaitTime)
						local queuedTolerance = GetRankTolerance(queuedWaitTime)

						if tierDiff <= selfTolerance and tierDiff <= queuedTolerance then
							matchedParty = queuedParty
							queueData[key] = nil

							pcall(function()
								RankedSystem.RankedQueueStore:SetAsync(lobbyType, queueData, DURATION)
							end)

							break
						end
					end
				end

				if matchedParty then
					-- Teleport both teams to a reserved server
					local teleportOption = Instance.new("TeleportOptions")
					teleportOption.ReservedServerAccessCode = TeleportService:ReserveServer(RANKED_PLACE_ID)

					local team = partyData.Players
					local matchedServerId = matchedParty.ServerID
					local encodedData = HttpService:JSONEncode({matchedServerId, game.JobId, lobbyType, teleportOption.ReservedServerAccessCode})

					local publishSuccess, publishError = pcall(function()
						MessagingService:PublishAsync("matchfound", encodedData)
					end)

					if not publishSuccess then
						warn("Error publishing matchfound:", publishError)
					end
				else
					--[[
					-- Insert/update self in queue if no match
					queueData = queueData or {}
					queueData[tostring(game.JobId)] = {
						ServerID = game.JobId,
						LobbyType = lobbyType,
						LobbyRank = highestRank.Rank,
						QueueStartTime = partyData.QueueStartTime or os.time()
					}

					pcall(function()
						RankedSystem.RankedQueueStore:SetAsync(lobbyType, queueData, DURATION)
					end)
					--]]
				end
			end
		end
	end
end)
