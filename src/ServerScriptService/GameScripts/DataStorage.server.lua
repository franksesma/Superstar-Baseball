local MarketplaceService = game:GetService("MarketplaceService")
local BadgeService = game:GetService("BadgeService")
local DataStoreService = game:GetService("DataStoreService")
local ChatService = game:GetService("Chat")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local TeamsService = game:GetService("Teams")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local MessagingService = game:GetService("MessagingService")
local TeleportService = game:GetService("TeleportService")

local VERSION_DATA = 38 -- PRODUCTION VERSION 38
local MAX_DATA_LOAD_ATTEMPTS = 3
local MAX_SAVE_RETRIES = 3
local RETRY_DELAY = 0.5
local SPIN_REWARD_TIME = 1800 -- 30 mins
local JOIN_BADGE = 3416713816817410

if not RunService:IsStudio() then
	VERSION_DATA = 38
end

local PlayerData = DataStoreService:GetDataStore("GameData_Version_"..VERSION_DATA)
local SessionStore = DataStoreService:GetDataStore("SessionLocks")
local LeagueServerStore = DataStoreService:GetDataStore("LeagueServers")

local GLOBAL_DATA_VERSION = 1
local GLOBAL_RANKED_DATA_VERSION = 1
-- Hitting
local RBIOrderedDataStore = DataStoreService:GetOrderedDataStore("RBI_Version_"..GLOBAL_DATA_VERSION)
-- Pitching
local StrikeoutsOrderedDataStore = DataStoreService:GetOrderedDataStore("Strikeouts_Version_"..GLOBAL_DATA_VERSION)
-- Outfield
local PutoutsOrderedDataStore = DataStoreService:GetOrderedDataStore("Putouts_Version_"..GLOBAL_DATA_VERSION)
-- Highest Elo
local EloOrderedDataStore = DataStoreService:GetOrderedDataStore("Elo_Version_"..GLOBAL_RANKED_DATA_VERSION)

local Remotes = ReplicatedStorage.RemoteEvents
local SharedDataFolder = ReplicatedStorage.SharedData
local Modules = ServerScriptService.Modules
local SharedModules = ReplicatedStorage.SharedModules
local ServerObjects = ServerStorage.ServerObjects
local GlobalLeaderboards = workspace.GlobalLeaderboards
local SharedObjects = ReplicatedStorage.SharedObjects
local GameValues = ReplicatedStorage.GameValues
local CameraValues = GameValues.CameraValues
local ServerGUIs = ServerStorage.ServerGUIs
local ScoreboardValues = GameValues.ScoreboardValues
local SharedGUIs = ReplicatedStorage.SharedGUIs
local OnBase = GameValues.OnBase

local GamePassModule = require(SharedModules.GamePasses)
local ServerFunctions = require(Modules.ServerFunctions)
local TeamsModule = require(SharedModules.Teams)
local StylesModule = require(SharedModules.Styles)
local CollisionGroups = require(SharedModules.CollisionGroups)
local ClientFunctions = require(SharedModules.ClientFunctions)
local BaseballFunctions = require(Modules.BaseballFunctions)
local RankedSystem = require(Modules.RankedSystem)
local ServerUtilFunctions = require(ServerScriptService.Services.Utilities.ServerUtilFunctions)

local gameShuttingDown = false

_G.sessionData = {}

local function dataTemplate()
	return {
		Banned = false,
		DataLoaded = true, -- if false, then this player's data was not loaded due to datastore failure
		ReceivedGroupJoinBonus = false,
		ReceivedVIPBonus = false,
		OpenedTutorial = false,
		OpenedStylesMenu = false,
		TutorialSeen1 = false,
		TutorialCompleted1 = false,
		GiftCodes = {},
		UpdateNoticeVersion = "v0.0",

		DailyRewards = {
			LastClaimed = 0, 
			CurrentDay = 1, 
		},

		BatInventory = {
			["Wooden Bat"] = 1,
		},
		TrailInventory = {
			["Normal Trail"] = 1,
		},
		GloveInventory = {
			["Old Glove"] = 1,	
		},
		ExplosionInventory = {
			["Fireworks"] = 1,	
		},

		WristbandInventory = {},
		BattingGloveInventory = {},

		BatPackRolls = {},
		TrailPackRolls = {},
		GlovePackRolls = {},
		EmotePackRolls = {},
		ExplosionPackRolls = {},

		EmoteInventory = {
			["Applaud"] = 1,
		},
		AbilitiesInventory = {},

		EquippedBat = "Wooden Bat",
		EquippedGlove = "Old Glove",
		EquippedTrail = "Normal Trail",
		EquippedEmote = "Applaud",
		EquippedExplosion = "Fireworks",
		EquippedWristband = "",
		EquippedBattingGlove = "",

		DefensiveSpinPreference = "",
		OffensiveSpinPreference = "",

		EquippedOffensiveLimitedStyle = nil,
		EquippedDefensiveLimitedStyle = nil,
		EquippedOffensiveStyle = "",
		EquippedDefensiveStyle = "",
		OffensiveStyleSlots = 1,
		DefensiveStyleSlots = 1,
		OffensiveStyleInventory = {},
		LimitedOffensiveStyleInventory = {},
		DefensiveStyleInventory = {},
		LimitedDefensiveStyleInventory = {},
		SpinRewardTimer = SPIN_REWARD_TIME,
		StyleSpins = 4,
		PityStyleSpinsCount = 0,
		LuckySpins = 0,
		PityLuckySpinsCount = 0,

		LegacyHittingResetV1 = false,

		RewardCodes = {},
		Jersey = {Name = "", Number = ""},
		WalkUpSongID = "",

		Settings = {GameMusic = true, WalkUpSongs = true, Narration = true, MobileCursor = false, ConsolePCI = 1, CrowdMotion = true, LegacyHitting = true},

		RankedSeasonData = {ELO = 0, Season = 1, Wins = 0, Losses = 0},
		OVRProgress = {OVR = 1, XP = 0},
		HittingStats = {["At-Bats"] = 0, Hits = 0, Runs = 0, RBI = 0, HR = 0, Doubles = 0, Triples = 0, Walks = 0, Strikeouts = 0},
		PitchingStats = {Pitches = 0, Strikes = 0, Strikeouts = 0, WalksAllowed = 0, HitsAllowed = 0, RunsAllowed = 0},
		OutfieldStats = {Putouts = 0, Assists = 0},
		GameStats = {GamesPlayed = 0, Wins = 0, Losses = 0, MVPAwards = 0, BestHitter = 0, BestPitcher = 0, BestOutfielder = 0},

		Cash = 0,

		DataId = 1,
	}
end

local function migrateOldStyleData(playerSaveData, styleType)
	if playerSaveData[styleType.."StyleInventory"][1] == nil then
		local slotsFilled = 0

		for i = 1, playerSaveData[styleType.."StyleSlots"] do
			for styleName, styleData in pairs(playerSaveData[styleType.."StyleInventory"]) do
				if typeof(styleName) == "string" then
					playerSaveData[styleType.."StyleInventory"][i] = {["StyleName"] = styleName, ["Reserved"] = playerSaveData[styleType.."StyleInventory"][styleName].Reserved}

					if playerSaveData["Equipped"..styleType.."Style"] == styleName then
						playerSaveData["Equipped"..styleType.."Style"] = i
					end

					playerSaveData[styleType.."StyleInventory"][styleName] = nil

					slotsFilled = slotsFilled + 1
					break
				end
			end
		end 

		if slotsFilled < playerSaveData[styleType.."StyleSlots"] then
			for i = slotsFilled + 1, playerSaveData[styleType.."StyleSlots"] do
				if styleType == "Offensive" then
					playerSaveData[styleType.."StyleInventory"][i] = {["StyleName"] = "Heat", ["Reserved"] = false}
				elseif styleType == "Defensive" then
					playerSaveData[styleType.."StyleInventory"][i] = {["StyleName"] = "Acrobat", ["Reserved"] = false}
				end
			end
		end
	end

	if typeof(playerSaveData["Equipped"..styleType.."Style"]) == "string" then -- just in case it still isnt set
		playerSaveData["Equipped"..styleType.."Style"] = 1
	end
end

local function cleanPackDataFromCorruption(playerSaveData)
	for i = #playerSaveData.BatPackRolls, 1, -1 do
		if typeof(i) == "number" then
			table.remove(playerSaveData.BatPackRolls, i)
		end
	end

	for i = #playerSaveData.TrailPackRolls, 1, -1 do
		if typeof(i) == "number" then
			table.remove(playerSaveData.TrailPackRolls, i)
		end
	end

	for i = #playerSaveData.EmotePackRolls, 1, -1 do
		if typeof(i) == "number" then
			table.remove(playerSaveData.EmotePackRolls, i)
		end
	end

	for i = #playerSaveData.ExplosionPackRolls, 1, -1 do
		if typeof(i) == "number" then
			table.remove(playerSaveData.ExplosionPackRolls, i)
		end
	end

	for i = #playerSaveData.GlovePackRolls, 1, -1 do
		if typeof(i) == "number" then
			table.remove(playerSaveData.GlovePackRolls, i)
		end
	end
end

local function displayShutdownNotice(player)
	if player and player:FindFirstChild("PlayerGui") then
		ServerGUIs.ShutdownNotice:Clone().Parent = player.PlayerGui
	end
end

local function loadPlayerData(player)
	local playerSaveKey = "ID: "..player.UserId

	local success, playerSaveData = pcall(function()
		return PlayerData:GetAsync(playerSaveKey)
	end)

	if success and playerSaveData then
		local templateData = dataTemplate()

		for i, v in pairs(templateData) do
			if playerSaveData[i] == nil then
				playerSaveData[i] = v
			end
		end

		playerSaveData.Settings = playerSaveData.Settings or {}

		if playerSaveData.LegacyHittingResetV1 == nil then
			playerSaveData.LegacyHittingResetV1 = false
		end

		if not playerSaveData.LegacyHittingResetV1 then
			playerSaveData.Settings.LegacyHitting = true
			playerSaveData.LegacyHittingResetV1 = true
		end

		if playerSaveData.Settings["MobileCursor"] == nil then
			playerSaveData.Settings["MobileCursor"] = false
		end

		if playerSaveData.Settings["ConsolePCI"] == nil then
			playerSaveData.Settings["ConsolePCI"] = 1
		end

		if playerSaveData.Settings["CrowdMotion"] == nil then
			playerSaveData.Settings["CrowdMotion"] = true
		end

		if playerSaveData.Settings["LegacyHitting"] == nil then
			-- Existing players default to legacy controls unless they opt into the new mode.
			playerSaveData.Settings["LegacyHitting"] = true
		end

		migrateOldStyleData(playerSaveData, "Offensive")
		migrateOldStyleData(playerSaveData, "Defensive")
		cleanPackDataFromCorruption(playerSaveData)

		_G.sessionData[player] = playerSaveData
	elseif success then
		_G.sessionData[player] = dataTemplate()

		_G.sessionData[player].EquippedOffensiveStyle = 1
		_G.sessionData[player].EquippedDefensiveStyle = 1

		_G.sessionData[player].OffensiveStyleInventory[1] = {["StyleName"] = "Heat", ["Reserved"] = false}
		_G.sessionData[player].DefensiveStyleInventory[1] = {["StyleName"] = "Acrobat", ["Reserved"] = false}

		Remotes.InitialStyleRoll:FireClient(player)
	end

	return success
end

local function rewardSpin(player)	
	while player and player.Parent do
		wait(1) -- Wait 30 minutes
		if _G.sessionData[player] then
			if _G.sessionData[player].SpinRewardTimer > 0 then
				_G.sessionData[player].SpinRewardTimer = _G.sessionData[player].SpinRewardTimer - 1

				if SharedDataFolder:FindFirstChild(player.Name) and SharedDataFolder[player.Name]:FindFirstChild("SpinRewardTimer") then
					SharedDataFolder[player.Name].SpinRewardTimer.Value = _G.sessionData[player].SpinRewardTimer
				end
			end
		end
	end
end

local function setupAdmin(player)
	if player.Name == "VRYLLION" or player.Name == "Randy_Moss" or player.UserId < 0 then
		player.Chatted:Connect(function(message)
			if message == "/admin" then
				local adminGui = ServerGUIs.AdminGui:Clone()
				adminGui.Parent = player.PlayerGui
			end
		end)
	end
end

local function dropBallOnRemoving(character)
	if character 
		and character:FindFirstChild("PlayerGlove") 
		and character.PlayerGlove:FindFirstChild("Baseball")
		and GameValues.BallHit.Value 
		and not GameValues.Putout.Value
		and workspace.BallHolder:FindFirstChild("Baseball") == nil
	then
		local ballPos = character.PlayerGlove.Baseball.Position

		local NewBall = game.ServerStorage.ServerObjects.Baseball:Clone()
		NewBall.Parent = workspace.BallHolder
		NewBall.Position = ballPos
		NewBall.CollisionGroup = CollisionGroups.BASEBALL_GROUP_THROWING
		NewBall.CatchBall.Enabled = true
		NewBall.Catchable.Value = false
		NewBall:SetAttribute("Hit", true)
		GameValues.BallHit.Value = true

		local indicatorTemplate = ReplicatedStorage.SharedGUIs:FindFirstChild("BallIndicator")
		if indicatorTemplate then
			local indicatorClone = indicatorTemplate:Clone()
			indicatorClone.Adornee = NewBall
			indicatorClone.Parent = NewBall
		end

		spawn(function()
			wait(0.15)
			if NewBall and NewBall:FindFirstChild("Catchable") then
				NewBall.Catchable.Value = true
			end
		end)
	end
end

-- Session Lock Helpers
local function acquireSessionLock(userId, timeoutSeconds)
	local start = os.clock()
	while os.clock() - start < timeoutSeconds do
		local success, currentOwner = pcall(function()
			return SessionStore:GetAsync("Session_"..userId)
		end)

		if success and (not currentOwner or RunService:IsStudio()) then
			pcall(function()
				SessionStore:SetAsync("Session_"..userId, game.JobId)
			end)
			return true
		end

		task.wait(2) -- Wait and retry
	end

	return false -- Timed out
end


local function clearSessionLock(userId)
	pcall(function()
		SessionStore:RemoveAsync("Session_" .. userId)
	end)
end

local function retrySetAsync(dataStore, key, value)
	for attempt = 1, MAX_SAVE_RETRIES do
		local success, err = pcall(function()
			dataStore:SetAsync(key, value)
			--[[
			dataStore:UpdateAsync(key, function(oldValue)
				local previousData = oldValue or {DataId = 0}
				
				if value.DataId == previousData.DataId or previousData.DataId == nil then
					value.DataId = value.DataId + 1
					return value
				else
					return nil
				end
			end)
			--]]
		end)

		if success then
			return true
		end

		--warn(`[DataStore] SetAsync failed for key "{key}" (attempt {attempt}): {err}`)
		task.wait(RETRY_DELAY)
	end

	warn(`[DataStore] SetAsync ultimately failed for key "{key}" after {MAX_SAVE_RETRIES} attempts`)
	return false
end

local function generateDisplayCharacter(player)
	local displayCharacter = ServerStorage.ServerObjects.StylesLockerCharacter:Clone()

	if SharedDataFolder:FindFirstChild(player.Name) then
		if SharedDataFolder[player.Name]:FindFirstChild("EmoteShopDisplayCharacter") then
			SharedDataFolder[player.Name].EmoteShopDisplayCharacter:Destroy()
		end

		displayCharacter.Parent = SharedDataFolder[player.Name]
	end

	pcall(function()
		local oldHumanoidDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)

		local newHumanoidDescription = Instance.new("HumanoidDescription")
		newHumanoidDescription.HeadColor = oldHumanoidDescription.HeadColor
		newHumanoidDescription.TorsoColor = oldHumanoidDescription.TorsoColor
		newHumanoidDescription.LeftArmColor = oldHumanoidDescription.LeftArmColor
		newHumanoidDescription.RightArmColor = oldHumanoidDescription.RightArmColor
		newHumanoidDescription.LeftLegColor = oldHumanoidDescription.LeftLegColor
		newHumanoidDescription.RightLegColor = oldHumanoidDescription.RightLegColor
		newHumanoidDescription.Face = oldHumanoidDescription.Face
		newHumanoidDescription.Head = oldHumanoidDescription.Head
		newHumanoidDescription.Shirt = oldHumanoidDescription.Shirt
		newHumanoidDescription.Pants = oldHumanoidDescription.Pants
		-- Accessories
		newHumanoidDescription.BackAccessory = oldHumanoidDescription.BackAccessory
		newHumanoidDescription.FaceAccessory = oldHumanoidDescription.FaceAccessory
		newHumanoidDescription.HairAccessory = oldHumanoidDescription.HairAccessory
		newHumanoidDescription.HatAccessory = oldHumanoidDescription.HatAccessory
		newHumanoidDescription.NeckAccessory = oldHumanoidDescription.NeckAccessory
		newHumanoidDescription.ShouldersAccessory = oldHumanoidDescription.ShouldersAccessory
		newHumanoidDescription.WaistAccessory = oldHumanoidDescription.WaistAccessory
		--
		newHumanoidDescription.MoodAnimation = oldHumanoidDescription.MoodAnimation
		newHumanoidDescription:SetAccessories(oldHumanoidDescription:GetAccessories(false), false)

		displayCharacter.Humanoid:ApplyDescription(newHumanoidDescription)
	end)

	if Players:FindFirstChild(player.Name) then
		if _G.sessionData[player] then
			ServerFunctions.EquipGear(displayCharacter, "Wristband", _G.sessionData[player].EquippedWristband)
		end
	end

	displayCharacter.Name = "EmoteShopDisplayCharacter"
end

local function handleJoinData(player)
	local serverType = ServerFunctions.GetServerType()

	if serverType == "ReservedServer" then
		local joinData = player:GetJoinData()
		local teleportData = joinData.TeleportData

		if teleportData then
			if RankedSystem.JoinedTeams[teleportData.ServerID] == nil then
				RankedSystem.JoinedTeams[teleportData.ServerID] = {}
			end

			if RankedSystem.HostPlayerNames[teleportData.ServerID] == nil then
				RankedSystem.HostPlayerNames[teleportData.ServerID] = teleportData.HostName
			end

			table.insert(RankedSystem.JoinedTeams[teleportData.ServerID], player)

			if RankedSystem.LobbyType == nil then
				RankedSystem.LobbyType = teleportData.LobbyType
			end

			player.TeamColor = TeamsService["No Team"].TeamColor
		end
	elseif serverType == "PrivateServer" then
		local joinData = player:GetJoinData()
		local teleportData = joinData.TeleportData

		if teleportData and teleportData.LeagueOwnerUserId then
			GameValues.LeagueServerOwnerID.Value = teleportData.LeagueOwnerUserId
			GameValues.LeagueServerCode.Value = teleportData.ShortServerCode
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:connect(function(character)
		if _G.sessionData[player] == nil or SharedDataFolder:FindFirstChild(player.Name) == nil then
			repeat
				wait()
				if player == nil or Players:FindFirstChild(player.Name) == nil then
					return
				end
			until _G.sessionData[player] and SharedDataFolder:FindFirstChild(player.Name)
		end

		if _G.sessionData[player].UpdateNoticeVersion ~= ReplicatedFirst.Version.Value then
			_G.sessionData[player].UpdateNoticeVersion = ReplicatedFirst.Version.Value
			local UpdateNoticeGui = ServerGUIs.UpdateNotice:Clone()
			UpdateNoticeGui.Frame.Background.Description.Text = ReplicatedFirst.VersionDescription.Value
			UpdateNoticeGui.Frame.Background.Version.Text = ReplicatedFirst.Version.Value.." Update!"
			UpdateNoticeGui.Parent = player.PlayerGui
		end

		RunService.Stepped:Wait()

		if CameraValues.PlayerSelectCam.Value and player.Team and player.Team.Name ~= "Lobby" then
			if player.Team and player.Team.Name == "No Team" then
				ServerFunctions.SetupPlayerSelectPositioning(player)
			end

			if player:FindFirstChild("PlayerGui") then
				ServerGUIs.PlayerSelectGui:Clone().Parent = player.PlayerGui
			end
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.Died:Connect(function()
				dropBallOnRemoving(character)
			end)

			pcall(function()
				humanoid.Health = math.huge
				ServerObjects.AnimeHighlight:Clone().Parent = character

				local oldHumanoidDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)

				local newHumanoidDescription = Instance.new("HumanoidDescription")
				newHumanoidDescription.HeadColor = oldHumanoidDescription.HeadColor
				newHumanoidDescription.TorsoColor = oldHumanoidDescription.TorsoColor
				newHumanoidDescription.LeftArmColor = oldHumanoidDescription.LeftArmColor
				newHumanoidDescription.RightArmColor = oldHumanoidDescription.RightArmColor
				newHumanoidDescription.LeftLegColor = oldHumanoidDescription.LeftLegColor
				newHumanoidDescription.RightLegColor = oldHumanoidDescription.RightLegColor
				newHumanoidDescription.Face = oldHumanoidDescription.Face
				newHumanoidDescription.Head = oldHumanoidDescription.Head
				newHumanoidDescription.Shirt = oldHumanoidDescription.Shirt
				newHumanoidDescription.Pants = oldHumanoidDescription.Pants
				-- Accessories
				newHumanoidDescription.BackAccessory = oldHumanoidDescription.BackAccessory
				newHumanoidDescription.FaceAccessory = oldHumanoidDescription.FaceAccessory
				newHumanoidDescription.HairAccessory = oldHumanoidDescription.HairAccessory
				newHumanoidDescription.HatAccessory = oldHumanoidDescription.HatAccessory
				newHumanoidDescription.NeckAccessory = oldHumanoidDescription.NeckAccessory
				newHumanoidDescription.ShouldersAccessory = oldHumanoidDescription.ShouldersAccessory
				newHumanoidDescription.WaistAccessory = oldHumanoidDescription.WaistAccessory
				--
				newHumanoidDescription.MoodAnimation = oldHumanoidDescription.MoodAnimation
				newHumanoidDescription:SetAccessories(oldHumanoidDescription:GetAccessories(false), false)

				humanoid:ApplyDescription(newHumanoidDescription)

				for _, accessory in pairs(character:GetChildren()) do
					if accessory:IsA("Accessory") then
						local handle = accessory:FindFirstChildOfClass("BasePart") or accessory:FindFirstChildOfClass("MeshPart")

						if handle then
							handle.CanQuery = false
						end
					end
				end
			end)
		end

		if character.Head:FindFirstChild('BaserunnerSafeIndicator') == nil then
			local baserunnerIndicator = SharedGUIs.BaserunnerSafeIndicator:Clone()
			baserunnerIndicator.Parent = character.Head
		end

		if character.Head:FindFirstChild('SkippedBillboard') == nil then
			local skippedBillboard = SharedGUIs.SkippedBillboard:Clone()
			skippedBillboard.Parent = character.Head
		end

		if character.Head:FindFirstChild('BattingOrderBillboard') == nil then
			local battingOrder = SharedGUIs.BattingOrderBillboard:Clone()
			--battingOrder.Label.Text = SharedDataFolder[player.Name].BattingOrder.Value
			battingOrder.PlayerName.Value = player.Name
			battingOrder.Parent = character.Head

			if ScoreboardValues.AtBat.Value ~= "" and player.Team and GameValues[ScoreboardValues.AtBat.Value.."TeamPicked"].Value == player.Team.Name then
				Remotes.EnableBattingOrderGui:FireAllClients(true, player.Team)
			end
		end

		if player.Team and player.Team.Name ~= "Lobby" then
			if GameValues.GameActive.Value then
				wait()
				if ClientFunctions.PlayerIsDefender(player) then
					ServerFunctions.TeleportPlayerCharacter(player, workspace.OutfieldTeleports.Teleport.CFrame)
					ServerFunctions.GiveGlove(player)
					ServerFunctions.SetupFieldingPower(player)
					Remotes.ToggleAbilityButtons:FireClient(player, true)

					for _, part in pairs(character:GetDescendants()) do
						if part:IsA("BasePart") or part:IsA("MeshPart") then
							part.CollisionGroup = CollisionGroups.DEFENSE_GROUP
						end
					end
				elseif ClientFunctions.PlayerIsOffense(player) then
					ServerFunctions.SetupBaserunningPower(player)
				end

				if player.Team then
					if player.Team.Name == GameValues.AwayTeamPicked.Value then
						ServerFunctions.GiveUniform(player, player.Team.Name, "Away")
					elseif player.Team.Name == GameValues.HomeTeamPicked.Value then
						ServerFunctions.GiveUniform(player, player.Team.Name, "Home")
					end
				end
			end
			Remotes.ShowReturnToLobby:FireClient(player, true)
		end

		spawn(function()
			wait(0.5)
			if player.Team and (player.Team.Name == "Lobby" or player.Team.Name == "No Team") then
				ServerFunctions.ShowOffBat(player, true)
			elseif not ClientFunctions.PlayerIsDefender(player) then
				ServerFunctions.ShowOffBat(player, true)

				if ClientFunctions.PlayerIsOffense(player) 
					and GameValues.GameActive.Value 
					and GameValues.CurrentBatter.Value ~= player 
				then
					BaseballFunctions.GiveBattingPracticeGui(player)
				end
			end
		end)

		-- Equip Gears
		ServerFunctions.EquipGear(character, "Wristband", _G.sessionData[player].EquippedWristband)
		
		ServerUtilFunctions.SetupFootsteps(character)
		
		-- Equip Accessories
		generateDisplayCharacter(player)
	end)

	player.CharacterRemoving:Connect(function(character)
		Remotes.ChangeCameraType:FireClient(player, Enum.CameraType.Custom, true)
		dropBallOnRemoving(character)
		ServerFunctions.RemoveBaseTracking(player)
	end)

	handleJoinData(player)

	local dataLoaded
	local attempts = 0

	local lockAcquired = acquireSessionLock(player.UserId, 15)
	if not lockAcquired then
		pcall(function()
			SessionStore:SetAsync("Session_"..player.UserId, game.JobId)
		end)
	end

	repeat 
		attempts = attempts + 1
		dataLoaded = loadPlayerData(player)
		if not dataLoaded then
			wait(2)
		end
	until dataLoaded or attempts >= MAX_DATA_LOAD_ATTEMPTS

	if not dataLoaded then
		warn("Error retrieving data! Key: "..player.UserId)
		local TemplateData = dataTemplate()
		TemplateData.DataLoaded = false
		_G.sessionData[player] = TemplateData
		--ServerGUIs.DataLoadFailed:Clone().Parent = player.PlayerGui
		player:Kick("Failed to load your data. Try reconnecting in a few seconds.")
		return
	end

	Remotes.PlayerDataLoaded:FireClient(player)

	local sharedData = ServerObjects.SharedDataTemplate:Clone()

	for statName, statValue in pairs(_G.sessionData[player].HittingStats) do
		local statVal = Instance.new("NumberValue")
		statVal.Name = statName
		statVal.Value = statValue
		statVal.Parent = sharedData.Stats.Hitting
	end

	for statName, statValue in pairs(_G.sessionData[player].PitchingStats) do
		local statVal = Instance.new("NumberValue")
		statVal.Name = statName
		statVal.Value = statValue
		statVal.Parent = sharedData.Stats.Pitching
	end

	for statName, statValue in pairs(_G.sessionData[player].OutfieldStats) do
		local statVal = Instance.new("NumberValue")
		statVal.Name = statName
		statVal.Value = statValue
		statVal.Parent = sharedData.Stats.Outfield
	end

	for statName, statValue in pairs(_G.sessionData[player].GameStats) do
		local statVal = Instance.new("NumberValue")
		statVal.Name = statName
		statVal.Value = statValue
		statVal.Parent = sharedData.Stats.Game
	end

	sharedData.DailyRewards.LastClaimed.Value = _G.sessionData[player].DailyRewards.LastClaimed
	sharedData.DailyRewards.CurrentDay.Value = _G.sessionData[player].DailyRewards.CurrentDay
	sharedData.Cash.Value = _G.sessionData[player].Cash
	sharedData.OVR.Value = _G.sessionData[player].OVRProgress["OVR"]
	sharedData.XP.Value = _G.sessionData[player].OVRProgress["XP"]
	sharedData.WalkUpSongID.Value = _G.sessionData[player].WalkUpSongID
	sharedData.StyleSpins.Value = _G.sessionData[player].StyleSpins
	sharedData.LuckySpins.Value = _G.sessionData[player].LuckySpins
	sharedData.OffensiveStyleSlots.Value = _G.sessionData[player].OffensiveStyleSlots
	sharedData.DefensiveStyleSlots.Value = _G.sessionData[player].DefensiveStyleSlots
	sharedData.SpinRewardTimer.Value = _G.sessionData[player].SpinRewardTimer
	sharedData.OpenedTutorial.Value = _G.sessionData[player].OpenedTutorial
	sharedData.OpenedStylesMenu.Value = _G.sessionData[player].OpenedStylesMenu
	sharedData.PityLuckySpinsCount.Value = _G.sessionData[player].PityLuckySpinsCount
	sharedData.PityStyleSpinsCount.Value = _G.sessionData[player].PityStyleSpinsCount

	-- Add TutorialSeen and TutorialCompleted if they don't exist
	if not sharedData:FindFirstChild("TutorialSeen") then
		local tutorialSeenValue = Instance.new("BoolValue")
		tutorialSeenValue.Name = "TutorialSeen"
		tutorialSeenValue.Parent = sharedData
	end
	sharedData.TutorialSeen.Value = _G.sessionData[player].TutorialSeen1 or false

	if not sharedData:FindFirstChild("TutorialCompleted") then
		local tutorialCompletedValue = Instance.new("BoolValue")
		tutorialCompletedValue.Name = "TutorialCompleted"
		tutorialCompletedValue.Parent = sharedData
	end
	sharedData.TutorialCompleted.Value = _G.sessionData[player].TutorialCompleted1 or false

	sharedData.RankedElo.Value = _G.sessionData[player].RankedSeasonData.ELO

	_G.sessionData[player].EmoteInventory["Applaud"] = 1

	for settingName, settingValue in pairs(_G.sessionData[player].Settings) do
		local existingSetting = sharedData.Settings:FindFirstChild(settingName)
		if existingSetting then
			existingSetting.Value = settingValue
		else
			local settingValueType = typeof(settingValue)
			local newSetting
			if settingValueType == "boolean" then
				newSetting = Instance.new("BoolValue")
			elseif settingValueType == "number" then
				newSetting = Instance.new("NumberValue")
			elseif settingValueType == "string" then
				newSetting = Instance.new("StringValue")
			end

			if newSetting then
				newSetting.Name = settingName
				newSetting.Value = settingValue
				newSetting.Parent = sharedData.Settings
			end
		end
	end

	sharedData.Name = player.Name	
	sharedData.Parent = SharedDataFolder

	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, JOIN_BADGE)
	end)

	if success and not hasBadge then
		local awardSuccess, result = pcall(function()
			return BadgeService:AwardBadge(player.UserId, JOIN_BADGE)
		end)
	end

	--[[
	if player.UserId > 0 and not BadgeService:UserHasBadge(player.UserId, JOIN_BADGE) then
		BadgeService:AwardBadge(player.userId, JOIN_BADGE)
	end
	--]]

	local success, playerHasVIPPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GamePassModule.PassIDs["Superstars VIP"])
	end)

	if playerHasVIPPass then
		if not _G.sessionData[player].ReceivedVIPBonus then
			_G.sessionData[player].ReceivedVIPBonus = true

			ServerFunctions.CashTransaction(player, 3000, true, false)
		end

		if _G.sessionData[player]["TrailInventory"]["Superstar Trail"] == nil then
			_G.sessionData[player]["TrailInventory"]["Superstar Trail"] = 1
		end

		if _G.sessionData[player]["BatInventory"]["Superstar Slugger"] == nil then
			_G.sessionData[player]["BatInventory"]["Superstar Slugger"] = 1
		end

		if _G.sessionData[player]["GloveInventory"]["Superstar Glove"] == nil then
			_G.sessionData[player]["GloveInventory"]["Superstar Glove"] = 1
		end
	end

	if not _G.sessionData[player].ReceivedGroupJoinBonus and not RunService:IsStudio() then
		local success, playerIsInGroup = pcall(function()
			return player:IsInGroup(10302151)
		end)


		if playerIsInGroup then
			_G.sessionData[player].ReceivedGroupJoinBonus = true
			ServerFunctions.CashTransaction(player, 500, true, false)
			Remotes.Notification:FireClient(player, "You earned a 500 coins reward for joining Metavision!", "Coins")
		else
			ServerGUIs.MetavisionAd:Clone().Parent = player.PlayerGui
		end
	end

	if game.PrivateServerOwnerId == player.UserId or GameValues.LeagueServerOwnerID.Value == player.UserId then
		ServerGUIs.PrivateServerOwnerNotice:Clone().Parent = player.PlayerGui
	end

	Remotes.ChangeJerseyInfo:FireClient(player, _G.sessionData[player].Jersey["Name"], _G.sessionData[player].Jersey["Number"])

	if gameShuttingDown then
		displayShutdownNotice(player)
	end

	Remotes.ShowDailyRewardsGui:FireClient(player)

	task.spawn(rewardSpin, player)

	setupAdmin(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	local playerSaveKey = "ID: "..userId
	local sharedData = SharedDataFolder:FindFirstChild(player.Name)

	ServerFunctions.RemovePlayerSelectPositioning(player)
	ServerFunctions.RemoveBaseTracking(player)

	local playerLeavingBattingOrder

	if sharedData then
		if sharedData:FindFirstChild("BattingOrder") then
			playerLeavingBattingOrder = sharedData.BattingOrder.Value

			ServerFunctions.ReadjustBattingOrders(playerLeavingBattingOrder, player.Team.Name)
		end

		if sharedData:FindFirstChild("PitcherVotes") then
			local pitcherVotedFor = sharedData.PitcherVotes.PitcherVotedFor.Value

			if SharedDataFolder:FindFirstChild(pitcherVotedFor) and SharedDataFolder[pitcherVotedFor].PitcherVotes.Value > 0 then 
				SharedDataFolder[pitcherVotedFor].PitcherVotes.Value = SharedDataFolder[pitcherVotedFor].PitcherVotes.Value - 1
			end

			sharedData.PitcherVotes.Value = 0
		end
	end

	if sharedData then
		sharedData:Destroy()
	end

	if ServerFunctions.GetServerType() == "ReservedServer" then
		if GameValues.GameActive.Value and not gameShuttingDown then
			RankedSystem.GameEndResult(player, false)

			RankedSystem.RemainingOpponentsCheck()
		end
	end

	if _G.sessionData[player] ~= nil and _G.sessionData[player].DataLoaded then		
		local saveSuccess = retrySetAsync(PlayerData, playerSaveKey, _G.sessionData[player])

		if saveSuccess then
			task.spawn(function()
				task.wait(5)
				clearSessionLock(userId)
			end)
		end
	end

	if not gameShuttingDown and _G.sessionData[player] ~= nil then
		pcall(function()
			RBIOrderedDataStore:SetAsync(player.UserId, _G.sessionData[player].HittingStats.RBI)
			StrikeoutsOrderedDataStore:SetAsync(player.UserId, _G.sessionData[player].PitchingStats.Strikeouts)
			PutoutsOrderedDataStore:SetAsync(player.UserId, _G.sessionData[player].OutfieldStats.Putouts)
			EloOrderedDataStore:SetAsync(player.UserId, _G.sessionData[player].RankedSeasonData.ELO)
		end)
	end

	if _G.sessionData[player] ~= nil  then
		_G.sessionData[player] = nil
	end

	if _G.giftTarget[player.UserId] ~= nil then
		_G.giftTarget[player.UserId] = nil
	end

	local inLobbyParty = RankedSystem.PlayerIsInLobbyParty(player)

	if inLobbyParty then
		RankedSystem.LeaveLobbyParty(player, inLobbyParty)
	end
end)

Remotes.ReturnToLobby.OnServerEvent:Connect(function(player)
	if GameValues.CurrentBatter.Value == player then return end

	if OnBase:FindFirstChild(player.Name) then return end

	if ServerFunctions.GetServerType() == "ReservedServer" then return end

	Remotes.EnableBattingOrderGui:FireClient(player, false)

	local returningPlayerTeam = player.Team.Name
	player.TeamColor = TeamsService.Lobby.TeamColor

	if GameValues.HomeCaptain.Value == player then
		GameValues.HomeCaptain.Value = nil
	elseif GameValues.AwayCaptain.Value == player then
		GameValues.AwayCaptain.Value = nil
	end

	local playerLeavingBattingOrder
	local sharedData = SharedDataFolder:FindFirstChild(player.Name)

	if sharedData and sharedData:FindFirstChild("BattingOrder") then
		playerLeavingBattingOrder = sharedData.BattingOrder.Value
		sharedData.BattingOrder.Value = 0
	end

	if sharedData and sharedData:FindFirstChild("PitcherVotes") then
		local pitcherVotedFor = sharedData.PitcherVotes.PitcherVotedFor.Value

		if SharedDataFolder:FindFirstChild(pitcherVotedFor) and SharedDataFolder[pitcherVotedFor].PitcherVotes.Value > 0 then 
			SharedDataFolder[pitcherVotedFor].PitcherVotes.Value = SharedDataFolder[pitcherVotedFor].PitcherVotes.Value - 1
		end

		sharedData.PitcherVotes.PitcherVotedFor.Value = ""
		sharedData.PitcherVotes.Value = 0
	end

	ServerFunctions.ReadjustBattingOrders(playerLeavingBattingOrder, returningPlayerTeam)

	ServerFunctions.RemovePlayerSelectPositioning(player)
	ServerFunctions.RemoveBaseTracking(player)

	if GameValues.CurrentBatter.Value == player then
		GameValues.CurrentBatter.Value = nil
	end

	if GameValues.CurrentPitcher.Value == player then
		GameValues.CurrentPitcher.Value = nil
	end

	Remotes.DisableMovement:FireClient(player, false)
	Remotes.EnableMouselock:FireClient(player, true)

	BaseballFunctions.UnSetupPlayer(player)
	Remotes.ToggleAbilityButtons:FireClient(player, false)

	player:LoadCharacter()
end)

Remotes.ClaimFreeSpin.OnServerEvent:Connect(function(player)
	if _G.sessionData[player].SpinRewardTimer == 0 then
		_G.sessionData[player].SpinRewardTimer = SPIN_REWARD_TIME
		--ServerFunctions.AwardSpin(player, 1)
		_G.sessionData[player].StyleSpins = _G.sessionData[player].StyleSpins + 1
		SharedDataFolder[player.Name].StyleSpins.Value = _G.sessionData[player].StyleSpins
		Remotes.Notification:FireClient(player, "You were awarded 1 Style Spin!")
	end
end)

local CONSOLE_PCI_MIN = 0.5
local CONSOLE_PCI_MAX = 5

Remotes.UpdateConsolePCI.OnServerEvent:Connect(function(player, newValue)
	if not _G.sessionData[player] then return end

	local num = tonumber(newValue)
	if not num then return end

	num = math.clamp(num, CONSOLE_PCI_MIN, CONSOLE_PCI_MAX)
	num = math.floor(num * 10 + 0.5) / 10

	_G.sessionData[player].Settings.ConsolePCI = num

	local sharedData = SharedDataFolder:FindFirstChild(player.Name)
	if sharedData and sharedData:FindFirstChild("Settings") and sharedData.Settings:FindFirstChild("ConsolePCI") then
		sharedData.Settings.ConsolePCI.Value = num
	end

	Remotes.UpdateConsolePCI:FireClient(player, num)
end)

Remotes.JoinGame.OnServerEvent:Connect(function(player, teamDesignation)
	if player 
		and player.TeamColor == TeamsService.Lobby.TeamColor
		and teamDesignation
	then
		local awayTeamName = GameValues.AwayTeamPicked.Value
		local homeTeamName = GameValues.HomeTeamPicked.Value

		local awayTeam = TeamsService[awayTeamName]
		local homeTeam = TeamsService[homeTeamName]

		local awayCount = 0
		local homeCount = 0

		for _, p in ipairs(Players:GetPlayers()) do
			if p.Team == awayTeam then
				awayCount += 1
			elseif p.Team == homeTeam then
				homeCount += 1
			end
		end

		-- Check if valid then
		if homeCount == awayCount then
			if awayCount > 7 and teamDesignation == "Away" then
				return
			elseif homeCount > 7 and teamDesignation == "Home" then
				return
			end

			player.Team = TeamsService[GameValues[teamDesignation.."TeamPicked"].Value]
		elseif awayCount <= homeCount and teamDesignation == "Away" then
			if awayCount > 7 then
				return
			end

			player.Team = awayTeam
		elseif homeCount <= awayCount and teamDesignation == "Home" then
			if homeCount > 7 then
				return
			end

			player.Team = homeTeam
		else
			return
		end

		Remotes.ShowReturnToLobby:FireClient(player, true)

		if TeamsService[GameValues.AwayTeamPicked.Value].TeamColor == player.TeamColor then
			ServerFunctions.CalculateBattingOrder(player)
		elseif TeamsService[GameValues.HomeTeamPicked.Value].TeamColor == player.TeamColor then
			ServerFunctions.CalculateBattingOrder(player)
		end

		if ScoreboardValues.AtBat.Value ~= "" 
			and GameValues[ScoreboardValues.AtBat.Value.."TeamPicked"].Value == player.Team.Name 
			and GameValues.GameActive.Value
		then
			Remotes.EnableBattingOrderGui:FireAllClients(true, player.Team)
		end

		player:LoadCharacter()

		ServerFunctions.SetupCurrentGameStatsTracking(player)

		if GameValues.PitcherAvailable.Value and ClientFunctions.PlayerIsDefender(player) then
			Remotes.ShowPitcherMoundCircle:FireClient(player, true, nil, true)
		end

		Remotes.DestroyGui:FireClient(player, "LobbyPickSideGui")
	end
end)

workspace.PlayCircle.PlayTouch.Touched:Connect(function(hit)
	if hit.Parent then
		local player = Players:GetPlayerFromCharacter(hit.Parent)

		if player 
			and player.TeamColor == TeamsService.Lobby.TeamColor 
		then
			if GameValues.GameActive.Value then
				Remotes.JoinGame:FireClient(player)
			else
				player.TeamColor = TeamsService["No Team"].TeamColor
				player:LoadCharacter()
				Remotes.ShowReturnToLobby:FireClient(player, true)
			end
		end
	end
end)

Remotes.PlayGame.OnServerEvent:Connect(function(player)
	if player 
		and player.TeamColor == TeamsService.Lobby.TeamColor 
	then
		if GameValues.GameActive.Value then
			Remotes.JoinGame:FireClient(player)
		else
			player.TeamColor = TeamsService["No Team"].TeamColor
			player:LoadCharacter()
			Remotes.ShowReturnToLobby:FireClient(player, true)
		end
	end
end)

Remotes.LeagueServer.CreateLeagueServer.OnServerEvent:Connect(function(player)
	local chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" -- 32 chars

	local function generateShortCode(len)
		local code = ""
		for i = 1, len do
			local rand = math.random(1, #chars)
			code ..= string.sub(chars, rand, rand)
		end
		return code
	end

	local function createUniqueCode()
		for i = 1, 10 do
			local code = generateShortCode(6)
			local success, exists = pcall(function()
				return LeagueServerStore:GetAsync(code)
			end)
			if success and not exists then
				return code
			end
		end
		return nil 
	end

	if ClientFunctions.PlayerIsInGame(player) then
		Remotes.Notification:FireClient(player, "Return to the lobby to create a league server", "Alert")
		return
	end

	local reservedCode
	local ok, err = pcall(function()
		reservedCode = TeleportService:ReserveServer(82183144153025)
	end)

	if not ok or not reservedCode then
		Remotes.Notification:FireClient(player, "Failed to create a league server. Please try again.", "Alert")
		return
	end

	local userAccessCode = createUniqueCode()
	if not userAccessCode then
		Remotes.Notification:FireClient(player, "Failed to generate a server code. Please try again.", "Alert")
		return
	end

	local success, dsErr = pcall(function()
		LeagueServerStore:SetAsync(userAccessCode, {
			ReservedCode = reservedCode,
			OwnerUserId = player.UserId,
			CreatedAt = os.time(),
		})
	end)

	if not success then
		Remotes.Notification:FireClient(player, "Failed to start league server. Please try again.", "Alert")
		return
	end

	local teleportData = {
		LeagueOwnerUserId = player.UserId,
		LeagueServerCode = reservedCode,
		ShortServerCode = userAccessCode,
	}

	Remotes.Notification:FireClient(player, "League server created!")

	local success, tpErr = pcall(function()
		TeleportService:TeleportToPrivateServer(82183144153025, reservedCode, { player }, nil, teleportData)
	end)

	if not success then
		Remotes.Notification:FireClient(player, "Failed to teleport to league server. Please try again.", "Alert")
	end
end)

Remotes.LeagueServer.JoinLeagueServer.OnServerEvent:Connect(function(player, serverCode)
	if ClientFunctions.PlayerIsInGame(player) then
		Remotes.Notification:FireClient(player, "Return to the lobby to join a league server", "Alert")
		return
	end

	if not serverCode or serverCode == "" then
		Remotes.Notification:FireClient(player, "Please enter a valid league server code.", "Alert")
		return
	end

	local success, result = pcall(function()
		return LeagueServerStore:GetAsync(serverCode)
	end)

	if not success or not result or not result.ReservedCode then
		Remotes.Notification:FireClient(player, "Invalid or expired league server code.", "Alert")
		return
	end

	local reservedCode = result.ReservedCode

	local successTp, tpErr = pcall(function()
		TeleportService:TeleportToPrivateServer(82183144153025, reservedCode, { player })
	end)

	if not successTp then
		Remotes.Notification:FireClient(player, "Failed to join that league server. Please try again.", "Alert")
	end

end)

game:BindToClose(function()
	if RunService:IsStudio() then
		print("Not saving data, in studio!")
		return
	else
		gameShuttingDown = true
	end

	for _, player in pairs(Players:GetPlayers()) do
		displayShutdownNotice(player)
	end

	wait(10)
	print("Shutdown Data Successfully Saved")
end)	

local RBIGlobal = {}
local StrikeoutsGlobal = {}
local PutoutsGlobal = {}
local EloGlobal = {}

Remotes.RetrieveGlobalStats.OnServerInvoke = function(player, statType)
	if statType == "Pitching" then
		return StrikeoutsGlobal
	elseif statType == "Hitting" then
		return RBIGlobal
	elseif statType == "Outfield" then
		return PutoutsGlobal
	else
		return nil
	end
end

local function getUsernameWithRetry(userId, maxRetries, delaySeconds)
	for i = 1, maxRetries do
		local success, result = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)

		if success then
			return result
		elseif i < maxRetries then
			task.wait(delaySeconds)
		end
	end

	return "[Unknown]"
end


local function updateGlobalLeaderboard()
	local success, err = pcall(function()
		local RBIs = RBIOrderedDataStore:GetSortedAsync(false, 50)
		local Strikeouts = StrikeoutsOrderedDataStore:GetSortedAsync(false, 50)
		local Putouts = PutoutsOrderedDataStore:GetSortedAsync(false, 50)
		local Elo = EloOrderedDataStore:GetSortedAsync(false, 50)

		-- RBIs
		RBIGlobal = {}

		local topPlayers = RBIs:GetCurrentPage()

		for rank, data in ipairs(topPlayers) do
			local userId = data.key
			local statValue = data.value

			-- Get player username
			local username = getUsernameWithRetry(userId, 3, 0.5)
			if username == "[Unknown]" then
				username = "[Unknown "..rank.."]"
			end

			table.insert(RBIGlobal, {username, statValue, userId})
		end

		-- Strikeouts
		StrikeoutsGlobal = {}

		local topPlayers = Strikeouts:GetCurrentPage()

		for rank, data in ipairs(topPlayers) do
			local userId = data.key
			local statValue = data.value

			-- Get player username
			local username = getUsernameWithRetry(userId, 3, 0.5)
			if username == "[Unknown]" then
				username = "[Unknown "..rank.."]"
			end

			table.insert(StrikeoutsGlobal, {username, statValue, userId})
		end

		-- Putouts
		PutoutsGlobal = {}

		local topPlayers = Putouts:GetCurrentPage()

		for rank, data in ipairs(topPlayers) do
			local userId = data.key
			local statValue = data.value

			-- Get player username
			local username = getUsernameWithRetry(userId, 3, 0.5)
			if username == "[Unknown]" then
				username = "[Unknown "..rank.."]"
			end

			table.insert(PutoutsGlobal, {username, statValue, userId})
		end

		-- Elo
		EloGlobal = {}

		local topPlayers = Elo:GetCurrentPage()

		for rank, data in ipairs(topPlayers) do
			local userId = data.key
			local statValue = data.value

			-- Get player username
			local username = getUsernameWithRetry(userId, 3, 0.5)
			if username == "[Unknown]" then
				username = "[Unknown "..rank.."]"
			end

			table.insert(EloGlobal, {username, statValue, userId})
		end
	end)
end

updateGlobalLeaderboard()

local function displayPhysicalLeaderboard(statType, statCollection, globalStatType)
	GlobalLeaderboards[statType].Board.SurfaceGui.Container.GlobalTitleFrame.StatLabelFrame.Label.Text = globalStatType
	GlobalLeaderboards[statType].Board.SurfaceGui.Container.LoadingLabel:Destroy()

	for rank, data in pairs(statCollection) do
		local playerStatsTemplate = ServerGUIs.PlayerGlobalStatsTemplate:Clone()
		playerStatsTemplate.Name = data[1]
		playerStatsTemplate.PlayerLabelFrame.Label.Text = data[1]
		playerStatsTemplate.StatLabelFrame.Label.Text = data[2]
		playerStatsTemplate.RankLabelFrame.Label.Text = rank

		if rank == 1 then
			playerStatsTemplate.RankLabelFrame.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
			pcall(function()
				ServerFunctions.LoadRobloxCharacterOutfit(GlobalLeaderboards[statType][tostring(rank)].Humanoid, data[3])
			end)
			ServerObjects.NameLabel:Clone().Parent = GlobalLeaderboards[statType][tostring(rank)].Head
			GlobalLeaderboards[statType][tostring(rank)].Head.NameLabel.Label.Text = data[1]
		elseif rank == 2 then
			playerStatsTemplate.RankLabelFrame.BackgroundColor3 = Color3.fromRGB(170, 170, 255)
			pcall(function()
				ServerFunctions.LoadRobloxCharacterOutfit(GlobalLeaderboards[statType][tostring(rank)].Humanoid, data[3])
			end)
			ServerObjects.NameLabel:Clone().Parent = GlobalLeaderboards[statType][tostring(rank)].Head
			GlobalLeaderboards[statType][tostring(rank)].Head.NameLabel.Label.Text = data[1]
		elseif rank == 3 then
			playerStatsTemplate.RankLabelFrame.BackgroundColor3 = Color3.fromRGB(170, 85, 0)
			pcall(function()
				ServerFunctions.LoadRobloxCharacterOutfit(GlobalLeaderboards[statType][tostring(rank)].Humanoid, data[3])
			end)
			ServerObjects.NameLabel:Clone().Parent = GlobalLeaderboards[statType][tostring(rank)].Head
			GlobalLeaderboards[statType][tostring(rank)].Head.NameLabel.Label.Text = data[1]
		end

		playerStatsTemplate.Parent = GlobalLeaderboards[statType].Board.SurfaceGui.Container	
	end
end

displayPhysicalLeaderboard("BestHitters", RBIGlobal, "RBIs")
displayPhysicalLeaderboard("BestPitchers", StrikeoutsGlobal, "Strikeouts")
displayPhysicalLeaderboard("BestFielders", PutoutsGlobal, "Putouts")
displayPhysicalLeaderboard("HighestElo", EloGlobal, "Elo")
