local PlayerService = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")
local PhysicsService = game:GetService("PhysicsService")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local SharedGUIs = ReplicatedStorage.SharedGUIs
local ServerGUIs = ServerStorage.ServerGUIs
local SharedModules = ReplicatedStorage.SharedModules
local SharedData = ReplicatedStorage.SharedData
local Remotes = ReplicatedStorage.RemoteEvents
local Modules = ServerScriptService.Modules
local GameValues = ReplicatedStorage.GameValues
local Uniforms = ServerStorage.Uniforms
local ServerObjects = ServerStorage.ServerObjects
local SharedObjects = ReplicatedStorage.SharedObjects
local GearItems = ReplicatedStorage.Gear
local ShopPackItems = ReplicatedStorage.ShopItems
local CurrentGameStats = ReplicatedStorage.CurrentGameStats

local MessageValues = GameValues.MessageValues
local CameraValues = GameValues.CameraValues

local OnBase = GameValues.OnBase
local ScoreboardValues = GameValues.ScoreboardValues
local AtBat = ScoreboardValues.AtBat
local Outs = ScoreboardValues.Outs
local Strikes = ScoreboardValues.Strikes
local Fouls = ScoreboardValues.Fouls
local Balls = ScoreboardValues.Balls
local Inning = ScoreboardValues.Inning
local HomeScore = ScoreboardValues.HomeScore
local AwayScore = ScoreboardValues.AwayScore

local BallHolder = workspace.BallHolder
local OnDeckParts = workspace.OnDeckParts
local BasePlates = workspace.Plates
local OutfieldTeleports = workspace.OutfieldTeleports
local SelectPlayerFolder = workspace.SelectPlayers
local FieldCamerasFolder = workspace.FieldCameras
local PlayerIntroSpots = workspace.PlayerIntroSpots
local LeadBlockerWalls = workspace.LeadBlockerWalls
local LandingIndicators = workspace.LandingIndicators
local GlobalLeaderboards = workspace.GlobalLeaderboards 
local NPCs = workspace.NPCs
local Ballparks = ServerStorage.Ballparks
local LoadedBallparkFolder = workspace.LoadedBallpark
local Fields = ServerStorage.Fields

local ServerFunctions = require(Modules.ServerFunctions)
local BaseballFunctions = require(Modules.BaseballFunctions)
local TeamsModule = require(SharedModules.Teams)
local BaseSequence = require(SharedModules.BaseSequence)
local CollisionGroups = require(SharedModules.CollisionGroups)
local ClientFunctions = require(SharedModules.ClientFunctions)
local GamePassModule = require(SharedModules.GamePasses)
local StylesModule = require(SharedModules.Styles)
local PitchingAnimationsModule = require(SharedModules.PitchingAnimations)
local GameSettings = require(Modules.GameSettings)
local TransformationEffects = require(Modules.TransformationEffects)
local RankedSystem = require(Modules.RankedSystem)
local RankedUtilities = require(SharedModules.RankedUtilities)
local Styles = require(SharedModules.Styles)
local BallParkTypes = require(Modules.BallParkTypes)
local TitleCards = require(SharedModules.TitleCards)

pcall(function()
	BaseballFunctions.SetUpNPC(NPCs.Catcher)
end)

local GAME_START_COUNTDOWN = 10
local SELECT_TEAM_WAIT = 15
local VOTE_GAME_TIME_WAIT = 10
local MAX_INNINGS = GameSettings.MAX_INNINGS
local DEBUG_SKIP_INTRO = true
local PLAYERS_PER_TEAM = 7
local MAX_FOULS_BEFORE_OUT = 5

if not RunService:IsStudio() then
	DEBUG_SKIP_INTRO = false
end

PhysicsService:RegisterCollisionGroup(CollisionGroups.AI_OFFENSE_GROUP)
PhysicsService:RegisterCollisionGroup(CollisionGroups.OFFENSE_GROUP)
PhysicsService:RegisterCollisionGroup(CollisionGroups.DEFENSE_GROUP)
PhysicsService:RegisterCollisionGroup(CollisionGroups.FIELD_WALLS_GROUP)
PhysicsService:RegisterCollisionGroup(CollisionGroups.OUTFIELD_WALLS_GROUP)
PhysicsService:RegisterCollisionGroup(CollisionGroups.PITCHER_WALLS_GROUP)
PhysicsService:RegisterCollisionGroup(CollisionGroups.BASEBALL_GROUP)
PhysicsService:RegisterCollisionGroup(CollisionGroups.BASEBALL_GROUP_THROWING)
PhysicsService:RegisterCollisionGroup(CollisionGroups.DEFENSE_BLOCKING_ULT_WALLS)
PhysicsService:RegisterCollisionGroup(CollisionGroups.STADIUM_PARTS_GROUP)

PhysicsService:CollisionGroupSetCollidable(CollisionGroups.OFFENSE_GROUP, CollisionGroups.DEFENSE_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.AI_OFFENSE_GROUP, CollisionGroups.DEFENSE_GROUP, false)

PhysicsService:CollisionGroupSetCollidable(CollisionGroups.AI_OFFENSE_GROUP, CollisionGroups.DEFENSE_BLOCKING_ULT_WALLS, false)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.OFFENSE_GROUP, CollisionGroups.DEFENSE_BLOCKING_ULT_WALLS, false)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.DEFENSE_GROUP, CollisionGroups.DEFENSE_BLOCKING_ULT_WALLS, true)

PhysicsService:CollisionGroupSetCollidable(CollisionGroups.AI_OFFENSE_GROUP, CollisionGroups.FIELD_WALLS_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.OFFENSE_GROUP, CollisionGroups.FIELD_WALLS_GROUP, true)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.DEFENSE_GROUP, CollisionGroups.FIELD_WALLS_GROUP, false)

PhysicsService:CollisionGroupSetCollidable(CollisionGroups.AI_OFFENSE_GROUP, CollisionGroups.PITCHER_WALLS_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.OFFENSE_GROUP, CollisionGroups.PITCHER_WALLS_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.DEFENSE_GROUP, CollisionGroups.PITCHER_WALLS_GROUP, true)

PhysicsService:CollisionGroupSetCollidable(CollisionGroups.BASEBALL_GROUP, CollisionGroups.OUTFIELD_WALLS_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.BASEBALL_GROUP, CollisionGroups.FIELD_WALLS_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.BASEBALL_GROUP, CollisionGroups.PITCHER_WALLS_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.BASEBALL_GROUP, CollisionGroups.AI_OFFENSE_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.BASEBALL_GROUP, CollisionGroups.OFFENSE_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.BASEBALL_GROUP, CollisionGroups.DEFENSE_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.BASEBALL_GROUP, CollisionGroups.DEFENSE_BLOCKING_ULT_WALLS, false)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.BASEBALL_GROUP, CollisionGroups.STADIUM_PARTS_GROUP, false)

PhysicsService:CollisionGroupSetCollidable(CollisionGroups.BASEBALL_GROUP_THROWING, CollisionGroups.AI_OFFENSE_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.BASEBALL_GROUP_THROWING, CollisionGroups.OFFENSE_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.BASEBALL_GROUP_THROWING, CollisionGroups.DEFENSE_GROUP, false)

for _, part in pairs(workspace.FieldWalls:GetChildren()) do
	part.CollisionGroup = CollisionGroups.FIELD_WALLS_GROUP
end

for _, part in pairs(workspace.LeadBlockerWalls:GetChildren()) do
	part.CollisionGroup = CollisionGroups.FIELD_WALLS_GROUP
end

for _, part in pairs(workspace.PitcherWalls:GetChildren()) do
	part.CollisionGroup = CollisionGroups.PITCHER_WALLS_GROUP
end

workspace.FieldClipGuard.CollisionGroup = CollisionGroups.STADIUM_PARTS_GROUP


Ballparks["Classic Park"]:Clone().Parent = LoadedBallparkFolder
local classicField = Fields["Classic Field"]:Clone()
classicField.Name = "Field"
classicField.Parent = workspace


local gameTimeVotes = {}

local ballParkVotes = {}

---------------------------------------------------------------------------------------------------------------

local function changeGameStatus(status)
	MessageValues.Status.Value = status
end

local function changePlayerSelectStatus(status)
	MessageValues.PlayerSelectStatus.Value = status
end

local function toggleStadiumLights(enabled)
	if LoadedBallparkFolder:FindFirstChild("NightLights") then
		for _, lightPart in pairs(LoadedBallparkFolder.NightLights:GetChildren()) do
			lightPart.SurfaceLight.Enabled = enabled
		end
	end
end

local function voteBallPark()
	changeGameStatus("Voting for Ballpark")
	
	ballParkVotes = {}
	
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		local voteBallParkGui = ServerGUIs.VoteBallPark:Clone()
		voteBallParkGui.Parent = player.PlayerGui
	end

	if not DEBUG_SKIP_INTRO then
		for i = VOTE_GAME_TIME_WAIT, 0, -1 do
			Remotes.UICountdown:FireAllClients(i)
			task.wait(1)
		end
	end

	local votes = {
		["Classic Park"] = 0,
		["Metro Field"] = 0,
	}

	for player, vote in pairs(ballParkVotes) do
		if votes[vote] ~= nil then
			votes[vote] = votes[vote] + 1
		end
	end 

	local maxVotes = 0
	local mostVotedBallPark = nil
	for ballparkName, count in pairs(votes) do
		if count > maxVotes then
			maxVotes = count
			mostVotedBallPark = ballparkName
		end
	end

	if mostVotedBallPark == nil then
		mostVotedBallPark = "Metro Field"
	end

	LoadedBallparkFolder:ClearAllChildren()

	for _, model in pairs(Ballparks[mostVotedBallPark]:GetChildren()) do
		model:Clone().Parent = LoadedBallparkFolder
	end
	
	local loadedField = Fields[BallParkTypes[mostVotedBallPark].FieldName]:Clone()
	loadedField.Parent = workspace
	
	if workspace:FindFirstChild("Field") then
		workspace.Field:Destroy()
	end
	
	loadedField.Name = "Field"
	
	for setting, value in pairs(BallParkTypes[mostVotedBallPark].LightingSettings) do
		game.Lighting[setting] = value
	end
	
	for _, part in pairs(LoadedBallparkFolder.InvisibleWalls:GetChildren()) do
		part.CollisionGroup = CollisionGroups.OUTFIELD_WALLS_GROUP
	end
	
	for _, part in pairs(LoadedBallparkFolder.StadiumParts:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			part.CollisionGroup = CollisionGroups.STADIUM_PARTS_GROUP
		end
	end

	Remotes.DestroyGui:FireAllClients("VoteBallPark")
	Remotes.StartMovingCrowds:FireAllClients()
end

local function voteTimeOfDay()
	changeGameStatus("Voting Time of Day")
	
	gameTimeVotes = {}
	
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		local voteTimeGui = ServerGUIs.VoteTime:Clone()
		voteTimeGui.Parent = player.PlayerGui
	end
	
	if not DEBUG_SKIP_INTRO then
		for i = VOTE_GAME_TIME_WAIT, 0, -1 do
			Remotes.UICountdown:FireAllClients(i)
			wait(1)
		end
	end
	
	local votes = {
		Afternoon = 0,
		Evening = 0,
		Night = 0,
	}
	
	for player, vote in pairs(gameTimeVotes) do
		if votes[vote] ~= nil then
			votes[vote] = votes[vote] + 1
		end
	end 
	
	local maxVotes = 0
	local mostVotedTime = nil
	for timeOfDay, count in pairs(votes) do
		if count > maxVotes then
			maxVotes = count
			mostVotedTime = timeOfDay
		end
	end
	
	if mostVotedTime == nil then
		mostVotedTime = "Afternoon"
	end

	if mostVotedTime == "Afternoon" then
		game.Lighting.TimeOfDay = "10:00:00"
		toggleStadiumLights(false)
	elseif mostVotedTime == "Evening" then
		game.Lighting.TimeOfDay = "17:30:00" 
		toggleStadiumLights(true)
	elseif mostVotedTime == "Night" then
		game.Lighting.TimeOfDay = "22:00:00"
		toggleStadiumLights(true)
	end
	
	Remotes.DestroyGui:FireAllClients("VoteTime")
end

local function pickCaptains()
	changeGameStatus("Choosing Team Captains")
	
	if ServerFunctions.GetServerType() == "ReservedServer" then
		local captains = {}
		
		for serverID, team in pairs(RankedSystem.JoinedTeams) do
			local hostName = RankedSystem.HostPlayerNames[serverID]
			
			local foundHostPlayer = PlayerService:FindFirstChild(hostName)
			
			if foundHostPlayer then
				table.insert(captains, foundHostPlayer)
			else
				local randomCaptain = team[math.random(1, #team)]
				
				table.insert(captains, randomCaptain)
			end
		end
		
		return captains[1], captains[2]
	else
		local players = ClientFunctions.GetPlayersInGame()

		local passHolders = {}

		for _, player in pairs(players) do
			if player then
				local success, playerHasCaptainPass = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GamePassModule.PassIDs["Team Captain"])
				end)

				if success and playerHasCaptainPass then
					table.insert(passHolders, player)
				end
			end
		end

		if #passHolders >= 2 then
			local captain1 = passHolders[math.random(1, #passHolders)]

			for i, player in pairs(passHolders) do
				if captain1 == player then
					table.remove(passHolders, i)
					break
				end
			end

			local captain2 = passHolders[math.random(1, #passHolders)]

			return captain1, captain2
		elseif #passHolders == 1 then
			local captain1 = passHolders[1]

			for i, player in pairs(players) do
				if captain1 == player then
					table.remove(players, i)
					break
				end
			end

			local captain2
			if #players > 0 then
				captain2 = players[math.random(1, #players)]
			end

			return captain1, captain2
		elseif #players > 0 then
			local captain1 = players[math.random(1, #players)]

			for i, player in pairs(players) do
				if captain1 == player then
					table.remove(players, i)
					break
				end
			end

			local captain2
			if #players > 0 then
				captain2 = players[math.random(1, #players)]
			end

			return captain1, captain2
		end
	end
end

local function getListOfTeams(excludedTeam)
	local teamsList = {}
	
	for teamName, teamInfo in pairs(TeamsModule) do
		if excludedTeam and excludedTeam == teamName then
			continue
		else 
			table.insert(teamsList, teamName)
		end
	end
	
	return teamsList
end

local function pickRandomTeams()
	local teamsList = getListOfTeams()
	
	local homeTeam = teamsList[math.random(1, #teamsList)]

	for i, team in pairs(teamsList) do
		if team == homeTeam then
			table.remove(teamsList, i)
			break
		end
	end

	local awayTeam = teamsList[math.random(1, #teamsList)]
	
	return homeTeam, awayTeam
end

local function pickRandomTeam(givenTeamName)
	local teamsList = getListOfTeams(givenTeamName)

	local teamChosen = teamsList[math.random(1, #teamsList)]
	
	return teamChosen
end

local function selectTeams()
	changeGameStatus("Captains selecting Teams")
	
	local selectTeamsGui = ServerGUIs.SelectTeamsGui:Clone()
	
	for teamName, teamInfo in pairs(TeamsModule) do
		local teamSelect = ServerGUIs.TeamSelect:Clone()
		teamSelect.Name = teamName
		teamSelect.TeamName.Text = teamInfo.City
		teamSelect.BackgroundColor3 = teamInfo.PrimaryColor
		teamSelect.UIStroke.Color = teamInfo.SecondaryColor
		teamSelect.Parent = selectTeamsGui.Frame.Background[teamInfo.Country.."Container"]
	end
	
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		selectTeamsGui:Clone().Parent = player.PlayerGui
	end
	
	if not DEBUG_SKIP_INTRO then
		for i = SELECT_TEAM_WAIT, 0, -1 do
			Remotes.UICountdown:FireAllClients(i)
			wait(1)
		end
	end
	
	Remotes.DestroyGui:FireAllClients("SelectTeamsGui")
	changeGameStatus("")
	
	local homeTeam = GameValues.HomeTeamPicked.Value
	local awayTeam = GameValues.AwayTeamPicked.Value
	
	if homeTeam == "" and awayTeam == "" then
		homeTeam, awayTeam = pickRandomTeams()
		GameValues.HomeTeamPicked.Value = homeTeam
		GameValues.AwayTeamPicked.Value = awayTeam
	elseif homeTeam == "" then
		homeTeam = pickRandomTeam(awayTeam)
		GameValues.HomeTeamPicked.Value = homeTeam
	elseif awayTeam == "" then
		awayTeam = pickRandomTeam(homeTeam)
		GameValues.AwayTeamPicked.Value = awayTeam
	end
	
	return homeTeam, awayTeam
end

local function unpickedPlayerExists()
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		if player.TeamColor == Teams["No Team"].TeamColor then
			return true
		end
	end
	
	return false
end

local function getRandomUnpickedPlayer()
	local unpickedPlayers = {}
	
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		if player and player.TeamColor == Teams["No Team"].TeamColor then
			table.insert(unpickedPlayers, player)
		end
	end
	
	local randomPlayer
	
	if #unpickedPlayers > 0 then
		randomPlayer = unpickedPlayers[math.random(1, #unpickedPlayers)]
	end
	
	return randomPlayer
end

local function playerSelection()
	if ServerFunctions.GetServerType() == "ReservedServer" then -- Ranked Server
		local homeTeamServerID
		local awayTeamServerID
		
		for serverID, team in pairs(RankedSystem.JoinedTeams) do
			if table.find(team, GameValues.HomeCaptain.Value) then
				homeTeamServerID = serverID
			elseif table.find(team, GameValues.AwayCaptain.Value) then
				awayTeamServerID = serverID
			end
		end
		
		local function assignTeam(teamPlayers, teamKey, uniformType)
			for _, player in pairs(teamPlayers) do
				if not player then continue end
				player.TeamColor = Teams[GameValues[teamKey].Value].TeamColor
				if player.Team then
					ServerFunctions.GiveUniform(player, player.Team.Name, uniformType)
				end
			end
		end
		
		if homeTeamServerID and awayTeamServerID then
			-- Both teams known
			assignTeam(RankedSystem.JoinedTeams[homeTeamServerID], "HomeTeamPicked", "Home")
			assignTeam(RankedSystem.JoinedTeams[awayTeamServerID], "AwayTeamPicked", "Away")

		elseif homeTeamServerID then
			-- Only home known → assign all others to away
			assignTeam(RankedSystem.JoinedTeams[homeTeamServerID], "HomeTeamPicked", "Home")
			for serverID, team in pairs(RankedSystem.JoinedTeams) do
				if serverID ~= homeTeamServerID then
					assignTeam(team, "AwayTeamPicked", "Away")
				end
			end

		elseif awayTeamServerID then
			-- Only away known → assign all others to home
			assignTeam(RankedSystem.JoinedTeams[awayTeamServerID], "AwayTeamPicked", "Away")
			for serverID, team in pairs(RankedSystem.JoinedTeams) do
				if serverID ~= awayTeamServerID then
					assignTeam(team, "HomeTeamPicked", "Home")
				end
			end

		else
			-- Neither team known → arbitrarily split into first found as home, rest as away
			local firstAssigned = false
			for serverID, team in pairs(RankedSystem.JoinedTeams) do
				if not firstAssigned then
					assignTeam(team, "HomeTeamPicked", "Home")
					firstAssigned = true
				else
					assignTeam(team, "AwayTeamPicked", "Away")
				end
			end
		end
	else -- Public Server
		changeGameStatus("Captains are selecting Players")

		for _, player in pairs(ClientFunctions.GetPlayersInGame()) do	
			if player ~= nil then
				if player ~= GameValues.HomeCaptain.Value and player ~= GameValues.AwayCaptain.Value then
					ServerFunctions.SetupPlayerSelectPositioning(player)
				else
					Remotes.DisableMovement:FireClient(player, true)

					if player.Character then
						player.Character:MoveTo(BasePlates["Home Base"].Position)
						--ServerFunctions.TeleportPlayerCharacter(player, BasePlates["Home Base"].CFrame)	
					end
				end

				if player:FindFirstChild("PlayerGui") then
					ServerGUIs.PlayerSelectGui:Clone().Parent = player.PlayerGui
				end
			end
		end

		local currentChoice = "Home"

		while unpickedPlayerExists() do
			GameValues.PlayerSelectPhase.Value = currentChoice
			GameValues.PlayerPicked.Value = false

			if not DEBUG_SKIP_INTRO then
				for i = 12, 0, -0.5 do
					if math.floor(i) == i then
						changePlayerSelectStatus(TeamsModule[GameValues[currentChoice.."TeamPicked"].Value].City.." Pick ("..tostring(i - 6)..")")
					end

					if GameValues.PlayerPicked.Value then
						break
					end

					wait(0.5)

					if (i - 6) == 0 then
						break
					end
				end
			end

			if not GameValues.PlayerPicked.Value then
				GameValues.PlayerPicked.Value = true
				local chosenPlayer = getRandomUnpickedPlayer()

				if chosenPlayer ~= nil and chosenPlayer.Character and chosenPlayer.Character:FindFirstChild('Humanoid') then
					chosenPlayer.Character.Humanoid:MoveTo(FieldCamerasFolder.PlayerSelectedWalkTo.Position)

					chosenPlayer.TeamColor = Teams[GameValues[currentChoice.."TeamPicked"].Value].TeamColor
					ServerFunctions.RemovePlayerSelectPositioning(chosenPlayer)

					if chosenPlayer.Team then
						ServerFunctions.GiveUniform(chosenPlayer, chosenPlayer.Team.Name, currentChoice)
					end
				end
			end

			changePlayerSelectStatus("")

			if currentChoice == "Home" then
				currentChoice = "Away"
			else
				currentChoice = "Home"
			end
			wait(1)
		end

		Remotes.DestroyGui:FireAllClients("PlayerSelectGui")
		Remotes.DestroyGui:FireAllClients("PlayerSelectGamepad")

		for _, part in pairs(SelectPlayerFolder:GetChildren()) do
			part.Player.Value = nil
			part.CanQuery = false
		end
	end
end

local function resetGameValues()
	GameValues.AwayCaptain.Value = nil
	GameValues.HomeCaptain.Value = nil
	GameValues.AwayTeamPicked.Value = ""
	GameValues.HomeTeamPicked.Value = ""
	GameValues.PlayerPicked.Value = false
	
	for _, player in pairs(PlayerService:GetChildren()) do
		if SharedData:FindFirstChild(player.Name) then
			if SharedData[player.Name]:FindFirstChild("PitcherVotes") then
				SharedData[player.Name]["PitcherVotes"].Value = 0
				
				if SharedData[player.Name].PitcherVotes:FindFirstChild("PitcherVotedFor") then
					SharedData[player.Name].PitcherVotes["PitcherVotedFor"].Value = ""
				end
				
				SharedData[player.Name].ActivatedFBAbility.Value = false
				SharedData[player.Name].ActivatedFBAbility.PowerActivated.Value = ""
				SharedData[player.Name].FieldingPower.Value = 0
			end
		end
	end
	
	ScoreboardValues.HomeScore.Value = 0
	ScoreboardValues.AwayScore.Value = 0
	ScoreboardValues.AtBat.Value = ""
	
	for _, inningScore in pairs(ScoreboardValues.Home:GetChildren()) do
		inningScore.Value = 0
	end
	
	for _, inningScore in pairs(ScoreboardValues.Away:GetChildren()) do
		inningScore.Value = 0
	end
	
	ServerFunctions.DeleteCurrentGameStatsTracking()
	Remotes.EnableBattingOrderGui:FireAllClients(false)
end

local function setupTeamSpawns(homeTeamObj, awayTeamObj)
	local PlayerSpawns = LoadedBallparkFolder:FindFirstChild("PlayerSpawns")
	
	for _, spawnPoint in pairs(PlayerSpawns.Home:GetChildren()) do
		spawnPoint.TeamColor = homeTeamObj.TeamColor
		spawnPoint.Enabled = true
	end
	
	for _, spawnPoint in pairs(PlayerSpawns.Away:GetChildren()) do
		spawnPoint.TeamColor = awayTeamObj.TeamColor
		spawnPoint.Enabled = true
	end
end

local function startPlayerIntro(homeTeamObj, awayTeamObj)
	changeGameStatus("Starting Game!")
	
	local homeSpotTaken = 0
	local awaySpotTaken = 0
	
	for _, player in (ClientFunctions.GetPlayersInGame()) do
		local character = player.Character

		if character and character:FindFirstChild("UpperTorso") then
			if player.TeamColor == homeTeamObj.TeamColor then
				homeSpotTaken = homeSpotTaken + 1

				if player == GameValues.HomeCaptain.Value then
					ServerFunctions.TeleportPlayerCharacter(player, CFrame.new(PlayerIntroSpots.Home[tostring(6)].Position, FieldCamerasFolder.CamPlayerSelectOrigin.Position))	
				else
					if PlayerIntroSpots.Home:FindFirstChild(tostring(homeSpotTaken)) then
						ServerFunctions.TeleportPlayerCharacter(player, CFrame.new(PlayerIntroSpots.Home[tostring(homeSpotTaken)].Position, FieldCamerasFolder.CamPlayerSelectOrigin.Position))	
					end
				end
			elseif player.TeamColor == awayTeamObj.TeamColor then
				awaySpotTaken = awaySpotTaken + 1

				if player == GameValues.AwayCaptain.Value then
					ServerFunctions.TeleportPlayerCharacter(player, CFrame.new(PlayerIntroSpots.Away[tostring(6)].Position, FieldCamerasFolder.CamPlayerSelectOrigin.Position))	
				else
					if PlayerIntroSpots.Away:FindFirstChild(tostring(awaySpotTaken)) then
						ServerFunctions.TeleportPlayerCharacter(player, CFrame.new(PlayerIntroSpots.Away[tostring(awaySpotTaken)].Position, FieldCamerasFolder.CamPlayerSelectOrigin.Position))		
					end
				end
			end
		end
	end
	
	if not DEBUG_SKIP_INTRO then
	
		CameraValues.PlayerIntro.Value = true

		wait(8)

		CameraValues.PlayerIntro.Value = false
	end
	
	local PlayerSpawns = LoadedBallparkFolder:FindFirstChild("PlayerSpawns")
	
	for _, player in (ClientFunctions.GetPlayersInGame()) do
		local character = player.Character

		if character and character:FindFirstChild("UpperTorso") then
			if player.TeamColor == homeTeamObj.TeamColor then
				local homeSpawns = PlayerSpawns.Home:GetChildren()
				
				ServerFunctions.TeleportPlayerCharacter(player, homeSpawns[math.random(1, #homeSpawns)].CFrame)	
			else
				local awaySpawns = PlayerSpawns.Away:GetChildren()

				ServerFunctions.TeleportPlayerCharacter(player, awaySpawns[math.random(1, #awaySpawns)].CFrame)	
			end
		end
	end
end

local function shuffle(array)
	local shuffledArray = {}
	
	for i, v in ipairs(array) do
		shuffledArray[i] = v
	end

	local n = #shuffledArray
	
	for i = n, 2, -1 do
		local j = math.random(i)
		shuffledArray[i], shuffledArray[j] = shuffledArray[j], shuffledArray[i]
	end

	return shuffledArray
end

local function initializeBattingOrders(homeTeamObj, awayTeamObj)
	local homeTeamOrder = 1
	local awayTeamOrder = 1
	
	local allPlayers = shuffle(ClientFunctions.GetPlayersInGame())	

	local homeCaptain = GameValues.HomeCaptain.Value
	local awayCaptain = GameValues.AwayCaptain.Value
	
	if homeCaptain and SharedData:FindFirstChild(homeCaptain.Name) then
		SharedData[homeCaptain.Name].BattingOrder.Value = homeTeamOrder
		homeTeamOrder = homeTeamOrder + 1
		
		for i, player in pairs(allPlayers) do
			if player == homeCaptain then
				table.remove(allPlayers, i)
			end
		end
	end
	
	if awayCaptain and SharedData:FindFirstChild(awayCaptain.Name) then
		SharedData[awayCaptain.Name].BattingOrder.Value = awayTeamOrder
		awayTeamOrder = awayTeamOrder + 1
		
		for i, player in pairs(allPlayers) do
			if player == awayCaptain then
				table.remove(allPlayers, i)
			end
		end
	end
	
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		if player.TeamColor == homeTeamObj.TeamColor and player ~= homeCaptain then
			if SharedData:FindFirstChild(player.Name) then
				SharedData[player.Name].BattingOrder.Value = homeTeamOrder
				homeTeamOrder = homeTeamOrder + 1
			end
		elseif player.TeamColor == awayTeamObj.TeamColor then
			if SharedData:FindFirstChild(player.Name) and player ~= awayCaptain then
				SharedData[player.Name].BattingOrder.Value = awayTeamOrder
				awayTeamOrder = awayTeamOrder + 1
			end
		end
		
		if player.Character 
			and player.Character:FindFirstChild("Head")  
			and SharedData:FindFirstChild(player.Name)
		then
			if player.Character.Head:FindFirstChild('BattingOrderBillboard') == nil then
				local battingOrder = SharedGUIs.BattingOrderBillboard:Clone()
				--battingOrder.Label.Text = SharedData[player.Name].BattingOrder.Value
				battingOrder.PlayerName.Value = player.Name
				battingOrder.Adornee = player.Character.Head
				battingOrder.Parent = player.Character.Head
			--else
				--player.Character.Head.BattingOrderBillboard.Label.Text = SharedData[player.Name].BattingOrder.Value
			end
		end
	end
end

local function getNextBatter(teamObj, battingQueue, designation)
	local nextBatter = nil

	-- First check players
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		if player.TeamColor == teamObj.TeamColor 
			and SharedData:FindFirstChild(player.Name) 
			and OnBase:FindFirstChild(player.Name) == nil 
		then
			local battingOrder = SharedData[player.Name].BattingOrder.Value
			local foundPriority = GameValues[designation.."PriorityBattingQueue"]:FindFirstChild(player.Name)
			
			if battingOrder == battingQueue and foundPriority and not foundPriority.Value then
				nextBatter = player
				foundPriority.Value = true -- player got to bat
				return nextBatter
			end
		end
	end

	return nextBatter
end

local function getPitcher(teamObj, designation)
	local pitcherFound = ClientFunctions.GetMostVotedPitcher(teamObj.TeamColor)
	local nextPitcher
	
	if pitcherFound ~= nil and PlayerService:FindFirstChild(pitcherFound) then
		nextPitcher = PlayerService:FindFirstChild(pitcherFound)
	end
	
	if nextPitcher and ServerFunctions.PlayerIsInGame(nextPitcher) then
		return nextPitcher
	else
		for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
			if player.TeamColor == teamObj.TeamColor then
				return player
			end
		end
	end
end

local function resetCameras(nextBatter, pitcher)
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		if player ~= nextBatter and player ~= pitcher then
			Remotes.ChangeCameraType:FireClient(player, Enum.CameraType.Custom)
			Remotes.DisableMovement:FireClient(player, false)
			Remotes.EnableMouselock:FireClient(player, true)
		end
	end
end

local function playWalkUpSong(player)
	local baseVolume = 0.25
	
	SoundService.WalkUpMusic:ClearAllChildren()
	
	local soundObj = Instance.new("Sound")
	soundObj.Volume = baseVolume
	
	soundObj.Parent = SoundService.WalkUpMusic

	pcall(function()
		if player:GetAttribute("IsAI") or _G.sessionData[player].WalkUpSongID == "" then
			soundObj.SoundId = "rbxassetid://1836516704"
		else
			soundObj.SoundId = "rbxassetid://".._G.sessionData[player].WalkUpSongID
		end
		soundObj:Play()
	end)

	return soundObj
end

local function fadeWalkUpSong(soundObj)
	spawn(function()
		if soundObj ~= nil and soundObj:IsA("Sound") then
			local baseVolume = 0.25

			for i = baseVolume, 0, -.01 do
				soundObj.Volume = i
				wait(.05)
			end

			soundObj:Destroy()
		end
	end)
end

local function startOnDeckIntro(batter)
	local batterCharacter
	
	if batter:GetAttribute("IsAI") then
		batterCharacter = batter
	else
		batterCharacter = batter.Character
		
		BaseballFunctions.UnSetupPlayer(batter)
	end
	
	Remotes.DisableMovement:FireAllClients(true)
	CameraValues.OnDeckCam.Value = true
	Remotes.OnDeckCamera:FireAllClients(true, batterCharacter)
	local soundObj = playWalkUpSong(batter)
	
	wait()
	
	if batter and not batter:GetAttribute("IsAI") then
		Remotes.ShowOffBat:FireClient(batter, true)
	end
	
	if batterCharacter then
		if not batter:GetAttribute("IsAI") then
			Remotes.EnableFieldWalls:FireClient(batter, false)
		end
		
		if batterCharacter and batterCharacter:FindFirstChild("Humanoid") then
			if batterCharacter:FindFirstChild("HumanoidRootPart") and batterCharacter.HumanoidRootPart.Parent == workspace then
				batterCharacter.HumanoidRootPart:SetNetworkOwner(nil)
			end
			
			batterCharacter.Humanoid.WalkSpeed = 8
			batterCharacter.Humanoid:MoveTo(BasePlates["Home Base"].Position)
		end
	end
	
	wait(0.5)
	if batterCharacter and batterCharacter:FindFirstChild("Humanoid") then
		batterCharacter.Humanoid:MoveTo(BasePlates["Home Base"].Position)
	end
	wait(4.5)
	
	CameraValues.OnDeckCam.Value = false
	Remotes.OnDeckCamera:FireAllClients(false, batterCharacter)
	
	if batter and not batter:GetAttribute("IsAI") and batter.Character then
		if batter.Character and batter.Character:FindFirstChild("Humanoid") then
			if batter.Character:FindFirstChild("HumanoidRootPart") and batter.Character.HumanoidRootPart.Parent == workspace then
				batter.Character.HumanoidRootPart:SetNetworkOwner(batter)
			end
			
			batter.Character.Humanoid.WalkSpeed = 18
		end
	end
	
	fadeWalkUpSong(soundObj)
end

local function walkBatters(batter)
	Remotes.WalkBatterCamera:FireAllClients()
	ServerFunctions.EnableLeadBlockers(false)
	
	local baseOrder = {"First Base", "Second Base", "Third Base"}
	local runnersShifting = {["First Base"] = batter}
	
	if batter and not batter:GetAttribute("IsAI") then
		ServerFunctions.SubtractStat(batter, "Hitting", "At-Bats", 1)
	end
	
	-- get runners that need to shift/walk
	for _, base in pairs(baseOrder) do		
		for _, onBaseTracker in pairs(OnBase:GetChildren()) do
			if onBaseTracker.Value == base and runnersShifting[base] ~= nil then
				local runner = PlayerService:FindFirstChild(onBaseTracker.Name)
				local nextBase = BaseSequence[onBaseTracker.Value]
				
				if runner then
					runnersShifting[nextBase] = runner
				end
				
				break
			end
		end
	end
	
	-- get runners who aren't shifting and keep them in place during sequence
	for _, onBaseTracker in pairs(OnBase:GetChildren()) do
		local runnerFound = false
		
		for nextBase, runner in pairs(runnersShifting) do
			if onBaseTracker.Name == runner.Name then
				runnerFound = true
				break
			end
		end
		
		if not runnerFound then
			local runner = PlayerService:FindFirstChild(onBaseTracker.Name)
			
			if runner and runner.Character and runner.Character:FindFirstChild("Humanoid") then
				Remotes.DisableMovement:FireClient(runner, true) 
				ServerFunctions.TeleportPlayerCharacter(runner, BasePlates[onBaseTracker.Value].TouchPart.CFrame)	
			end
		end
	end
	

	-- show walking sequence
	for nextBase, runner in pairs(runnersShifting) do
		if runner and not runner:GetAttribute("IsAI") and runner.Character and runner.Character:FindFirstChild("Humanoid") then
			Remotes.DisableMovement:FireClient(runner, true) 
			Remotes.LockedInBaseNotification:FireClient(runner, false)
			
			if runner.Character:FindFirstChild("HumanoidRootPart") and runner.Character.HumanoidRootPart.Parent == workspace then
				runner.Character.HumanoidRootPart:SetNetworkOwner(nil)
			end
			
			runner.Character.Humanoid:MoveTo(BasePlates[nextBase].Position)
			
			local onBaseTracker = OnBase:FindFirstChild(runner.Name)
			
			if onBaseTracker then
				onBaseTracker.Value = nextBase
				onBaseTracker.StartingBase.Value = nextBase
				Remotes.ShowBaseMarker:FireClient(runner, true, BaseSequence[onBaseTracker.Value])
			end
		end
	end
	
	wait(7)

	for nextBase, runner in pairs(runnersShifting) do
		if runner and not runner:GetAttribute("IsAI") and runner.Character and runner.Character:FindFirstChild("Humanoid") then
			if nextBase == "Home Base" then
				ServerFunctions.TeleportPlayerCharacter(runner, BasePlates[nextBase].CFrame)	
				BaseballFunctions.PlayerScored(runner)
			else
				ServerFunctions.TeleportPlayerCharacter(runner, BasePlates[nextBase].TouchPart.CFrame)	
				Remotes.LockedInBaseNotification:FireClient(runner, true, BaseSequence[nextBase])
			end
		end
	end
end

local function returnPlayersToDugout(homeTeamObj, awayTeamObj)
	local PlayerSpawns = LoadedBallparkFolder:FindFirstChild("PlayerSpawns")
	local homeSpawns = PlayerSpawns.Home:GetChildren()
	local awaySpawns = PlayerSpawns.Away:GetChildren()
	
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		local character = player.Character
		
		BaseballFunctions.UnSetupPlayer(player)
		
		if character then
			if character:FindFirstChild("HumanoidRootPart") then
				if player.TeamColor == homeTeamObj.TeamColor then
					ServerFunctions.TeleportPlayerCharacter(player, homeSpawns[math.random(1, #homeSpawns)].CFrame)	
				elseif player.TeamColor == awayTeamObj.TeamColor then
					ServerFunctions.TeleportPlayerCharacter(player, awaySpawns[math.random(1, #awaySpawns)].CFrame)		
				end
			end
			
			for _, part in pairs(character:GetChildren()) do
				if part:IsA("BasePart") or part:IsA("MeshPart") then
					part.CollisionGroup = CollisionGroups.DEFENSE_GROUP
				end
				
				if part ~= nil and part.Name == "BattingGlove" then
					part:Destroy()
				end
				
				if part ~= nil and part:IsA("BasePart") and part.Name == "LeftHand" or part.Name == "RightHand" then
					part.Transparency = 0
				end
			end

			ServerFunctions.ResetArms(player)
			BaseballFunctions.DeleteGlove(player)
			TransformationEffects.RemoveAuras(player)
			ServerFunctions.ShowOffBat(player, true)
			
			if GameValues.GameActive.Value and ClientFunctions.PlayerIsOffense(player) then
				BaseballFunctions.GiveBattingPracticeGui(player)
			end
		end
	end
end

local function hasEnoughBatters(teamObj)
	local battersFound = false

	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		if player.TeamColor == teamObj.TeamColor and OnBase:FindFirstChild(player.Name) == nil then
			battersFound = true
			break
		end
	end
	
	return battersFound
end

local function setupOutfielders()
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		local character = player.Character

		if character and character:FindFirstChild("HumanoidRootPart") then
			if ClientFunctions.PlayerIsDefender(player) then
				ServerFunctions.SetupFieldingPower(player)
				ServerFunctions.ShowOffBat(player, false)
				Remotes.ToggleAbilityButtons:FireClient(player, true)

				for _, part in pairs(character:GetChildren()) do
					if part:IsA("BasePart") or part:IsA("MeshPart") then
						part.CollisionGroup = CollisionGroups.DEFENSE_GROUP
					end
				end
				
				ServerFunctions.GiveGlove(player)
				ServerFunctions.ResetArms(player)
			elseif ClientFunctions.PlayerIsOffense(player) then
				ServerFunctions.SetupBaserunningPower(player)
			end
		end
	end
end

local function positionOutfielders(onlyWanderedPlayers, ignorePitcher, specifiedTeleport)
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		local character = player.Character

		if character and character:FindFirstChild("HumanoidRootPart") and ClientFunctions.PlayerIsDefender(player) then
			if (not onlyWanderedPlayers) or (onlyWanderedPlayers and (character.HumanoidRootPart.Position - workspace.FielderPosResetReferencePoint.Position).Magnitude <= 83) then
				if (ignorePitcher == nil) or (ignorePitcher and player ~= GameValues.CurrentPitcher.Value) then
					local closestSpot = nil
					if specifiedTeleport then
						closestSpot = specifiedTeleport
					else
						local shortestDistance = math.huge

						for _, spot in pairs(OutfieldTeleports:GetChildren()) do
							if spot:IsA("BasePart") then
								local dist = (character.HumanoidRootPart.Position - spot.Position).Magnitude
								if dist < shortestDistance then
									shortestDistance = dist
									closestSpot = spot
								end
							end
						end
					end

					if closestSpot then
						ServerFunctions.TeleportPlayerCharacter(player, closestSpot.CFrame)
					end
				end
			end
		end
	end
end

local function removeUnwantedOutfielders()
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		local character = player.Character

		if character and character:FindFirstChild("HumanoidRootPart") and ClientFunctions.PlayerIsDefender(player) then
			if (character.HumanoidRootPart.Position - workspace.Plates["Home Base"].Position).Magnitude <= 30 then
				if player ~= GameValues.CurrentPitcher.Value then
					local closestSpot = nil
					local shortestDistance = math.huge

					for _, spot in pairs(OutfieldTeleports:GetChildren()) do
						if spot:IsA("BasePart") then
							local dist = (character.HumanoidRootPart.Position - spot.Position).Magnitude
							if dist < shortestDistance then
								shortestDistance = dist
								closestSpot = spot
							end
						end
					end

					if closestSpot then
						ServerFunctions.TeleportPlayerCharacter(player, closestSpot.CFrame)
					end
				end
			end
		end
	end
end

local function allRunnersOutOrSafe()
	local outOrSafe = true
	
	for _, baseTracker in pairs(OnBase:GetChildren()) do
		local player = PlayerService:FindFirstChild(baseTracker.Name)
		
		if player and not baseTracker.LockedInBase.Value then
			outOrSafe = false
			break
		end
	end
	
	if GameValues.FlyBall.Value and not GameValues.Putout.Value then
		outOrSafe = false
	end
	
	if outOrSafe then
		GameValues.PlayActive.Value = false
		GameValues.BallHit.Value = false
		GameValues.FlyBall.Value = false
		
		for _, baseTracker in pairs(OnBase:GetChildren()) do
			baseTracker.StartingBase.Value = baseTracker.Value
			baseTracker.LockedInBase.Value = false
			baseTracker.LockedInBase.BaseElapseTime.Value = 0
			baseTracker.TaggedUp.Value = false
		end
		
		if SoundService.Effects.RunChime.IsPlaying then
			repeat
				wait()
			until not SoundService.Effects.RunChime.IsPlaying
		end
	end
end

local function returnRunnersToStartingBase()
	for _, baseTracker in pairs(OnBase:GetChildren()) do
		local player = PlayerService:FindFirstChild(baseTracker.Name)
		
		if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			baseTracker.Value = baseTracker.StartingBase.Value
			baseTracker.LockedInBase.Value = false
			baseTracker.LockedInBase.BaseElapseTime.Value = 0
			Remotes.Notification:FireClient(player, "You must return to your starting base to be safe!", "Alert")
		end
	end
end

local function getWinningTeam()
	if HomeScore.Value > AwayScore.Value then
		return GameValues.HomeTeamPicked.Value
	else
		return GameValues.AwayTeamPicked.Value
	end
end

local function decorateStadium()	
	if LoadedBallparkFolder:FindFirstChild("AwaySign") then
		LoadedBallparkFolder.AwaySign.SurfaceGui.Label.Text = TeamsModule[GameValues.AwayTeamPicked.Value].City
		LoadedBallparkFolder.AwaySign.SurfaceGui.Label.UIStroke.Color = TeamsModule[GameValues.AwayTeamPicked.Value].PrimaryColor
		LoadedBallparkFolder.AwaySign.SurfaceGui.CountryIcon.Image = TeamsModule[GameValues.AwayTeamPicked.Value].CountryIcon
	end
	workspace.TeamNameSurfaceGuis.Away.LobbySignAbbrev.SurfaceGui.Label.Text = TeamsModule[GameValues.AwayTeamPicked.Value].Abbreviation
	workspace.TeamNameSurfaceGuis.Away.LobbySignAbbrev.SurfaceGui.Label.UIStroke.Color = TeamsModule[GameValues.AwayTeamPicked.Value].PrimaryColor
	workspace.TeamNameSurfaceGuis.Away.LobbySignDesignation.SurfaceGui.Country.Image = TeamsModule[GameValues.AwayTeamPicked.Value].CountryIcon
	
	if LoadedBallparkFolder:FindFirstChild("HomeSign") then
		LoadedBallparkFolder.HomeSign.SurfaceGui.Label.Text = TeamsModule[GameValues.HomeTeamPicked.Value].City
		LoadedBallparkFolder.HomeSign.SurfaceGui.Label.UIStroke.Color = TeamsModule[GameValues.HomeTeamPicked.Value].PrimaryColor
		LoadedBallparkFolder.HomeSign.SurfaceGui.CountryIcon.Image = TeamsModule[GameValues.HomeTeamPicked.Value].CountryIcon
	end
	workspace.TeamNameSurfaceGuis.Home.LobbySignAbbrev.SurfaceGui.Label.Text = TeamsModule[GameValues.HomeTeamPicked.Value].Abbreviation
	workspace.TeamNameSurfaceGuis.Home.LobbySignAbbrev.SurfaceGui.Label.UIStroke.Color = TeamsModule[GameValues.HomeTeamPicked.Value].PrimaryColor
	workspace.TeamNameSurfaceGuis.Home.LobbySignDesignation.SurfaceGui.Country.Image = TeamsModule[GameValues.HomeTeamPicked.Value].CountryIcon
	
	if LoadedBallparkFolder:FindFirstChild("TeamStadiumColors") then
		for _, part in pairs(LoadedBallparkFolder.TeamStadiumColors:GetChildren()) do
			part.BrickColor = BrickColor.new(TeamsModule[GameValues.HomeTeamPicked.Value].PrimaryColor)
		end
	end
end

local function setupJumbotron(batter)
	if LoadedBallparkFolder:FindFirstChild("StadiumScoreboard") then
		local JumbotronScreen = LoadedBallparkFolder.StadiumScoreboard.Screen.SurfaceGui.Frame
		
		if batter and ServerFunctions.PlayerIsInGame(batter) and _G.sessionData[batter] ~= nil then
			JumbotronScreen.Player.Text = batter.Name
			
			local success, img = pcall(function()
				return PlayerService:GetUserThumbnailAsync(batter.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
			end)
			
			if success and img and batter.UserId > 0 then
				JumbotronScreen.ImageIcon.Image = img
			else
				JumbotronScreen.ImageIcon.Image = "rbxassetid://135927875061357"
			end
			
			if batter.Team then
				local teamName = batter.Team.Name
				
				if TeamsModule[teamName] then
					JumbotronScreen.StatsFrame.AVGFrame.AVGLabel.BackgroundColor3 = TeamsModule[teamName].PrimaryColor
					JumbotronScreen.StatsFrame.HRFrame.HRLabel.BackgroundColor3 = TeamsModule[teamName].PrimaryColor
					JumbotronScreen.StatsFrame.ABFrame.ABLabel.BackgroundColor3 = TeamsModule[teamName].PrimaryColor
					JumbotronScreen.StatsFrame.RFrame.RLabel.BackgroundColor3 = TeamsModule[teamName].PrimaryColor
					JumbotronScreen.StatsFrame.RBIFrame.RBILabel.BackgroundColor3 = TeamsModule[teamName].PrimaryColor
					JumbotronScreen.StatsFrame.OVRFrame.OVRLabel.BackgroundColor3 = TeamsModule[teamName].PrimaryColor
				end
			end
			
			if _G.sessionData[batter] then
				JumbotronScreen.StatsFrame.AVGFrame.AVG.Text = ClientFunctions.CalculateBattingAVG(_G.sessionData[batter].HittingStats.Hits, _G.sessionData[batter].HittingStats["At-Bats"])
				JumbotronScreen.StatsFrame.HRFrame.HR.Text = _G.sessionData[batter].HittingStats.HR
				JumbotronScreen.StatsFrame.ABFrame.AB.Text = _G.sessionData[batter].HittingStats["At-Bats"]
				JumbotronScreen.StatsFrame.RFrame.R.Text = _G.sessionData[batter].HittingStats.Runs
				JumbotronScreen.StatsFrame.RBIFrame.RBI.Text = _G.sessionData[batter].HittingStats.RBI
				JumbotronScreen.StatsFrame.OVRFrame.OVR.Text = _G.sessionData[batter].OVRProgress.OVR
			end
		elseif batter and batter:GetAttribute("IsAI") then
			JumbotronScreen.Player.Text = "Fill-In Hitter (AI)"
			JumbotronScreen.ImageIcon.Image = "rbxassetid://135927875061357"
			
			local teamName = GameValues[ScoreboardValues.AtBat.Value.."TeamPicked"].Value
			
			JumbotronScreen.StatsFrame.AVGFrame.AVGLabel.BackgroundColor3 = TeamsModule[teamName].PrimaryColor
			JumbotronScreen.StatsFrame.HRFrame.HRLabel.BackgroundColor3 = TeamsModule[teamName].PrimaryColor
			JumbotronScreen.StatsFrame.ABFrame.ABLabel.BackgroundColor3 = TeamsModule[teamName].PrimaryColor
			JumbotronScreen.StatsFrame.RFrame.RLabel.BackgroundColor3 = TeamsModule[teamName].PrimaryColor
			JumbotronScreen.StatsFrame.RBIFrame.RBILabel.BackgroundColor3 = TeamsModule[teamName].PrimaryColor
			JumbotronScreen.StatsFrame.OVRFrame.OVRLabel.BackgroundColor3 = TeamsModule[teamName].PrimaryColor
			
			JumbotronScreen.StatsFrame.AVGFrame.AVG.Text = ".000"
			JumbotronScreen.StatsFrame.HRFrame.HR.Text = "0"
			JumbotronScreen.StatsFrame.ABFrame.AB.Text = "0"
			JumbotronScreen.StatsFrame.RFrame.R.Text = "0"
			JumbotronScreen.StatsFrame.RBIFrame.RBI.Text = "0"
			JumbotronScreen.StatsFrame.OVRFrame.OVR.Text = "0"
		end
	end
end

local function getBallWorldPosition()
	-- Prefer a direct reference if you track it
	local ball = GameValues.BaseballObj and GameValues.BaseballObj.Value
	if ball and ball:IsDescendantOf(workspace) then
		local ok, pos = pcall(function() return ball.Position end)
		if ok and typeof(pos) == "Vector3" then return pos end
	end

	-- Fallback: the default holder
	if workspace:FindFirstChild("BallHolder") and BallHolder:FindFirstChild("Baseball") then
		local ok, pos = pcall(function() return BallHolder.Baseball.Position end)
		if ok and typeof(pos) == "Vector3" then return pos end
	end

	-- Last resort: home plate (or wherever you want)
	return BasePlates["Home Base"].Position
end


-- Triggers the player's equipped explosion VFX once at a position
local function triggerEquippedExplosion(player, worldPos)
	if not player or player:GetAttribute("IsAI") then return end
	local session = _G.sessionData[player]
	if not session then return end

	local equipped = session.EquippedExplosion
	if not equipped or equipped == "" then return end
	if typeof(equipped) == "string" and equipped:lower() == "fireworks" then return end

	local template = nil
	if ShopPackItems:FindFirstChild("Explosion") and ShopPackItems.Explosion:FindFirstChild(equipped) then
		template = ShopPackItems.Explosion[equipped]
	elseif ServerObjects:FindFirstChild("Explosions") and ServerObjects.Explosions:FindFirstChild(equipped) then
		template = ServerObjects.Explosions[equipped]
	end
	if not template then return end

	local vfx = template:Clone()
	vfx.Name = "EquippedExplosion_VFX"
	vfx.Parent = workspace

	local anchorCF = CFrame.new(worldPos + Vector3.new(0, 8, 0))
	if vfx:IsA("BasePart") then
		vfx.CFrame = anchorCF
	elseif vfx:IsA("Model") then
		if vfx.PrimaryPart then
			vfx:SetPrimaryPartCFrame(anchorCF)
		else
			local anyPart = vfx:FindFirstChildWhichIsA("BasePart", true)
			if anyPart then
				local offset = vfx:GetPivot():ToObjectSpace(anyPart.CFrame)
				vfx:PivotTo(anchorCF * offset)
			else
				vfx:PivotTo(anchorCF)
			end
		end
	else
		local anchor = Instance.new("Part")
		anchor.Anchored, anchor.CanCollide, anchor.Transparency, anchor.Size = true, false, 1, Vector3.new(1,1,1)
		anchor.CFrame = anchorCF
		anchor.Name = "VFXAnchor"
		anchor.Parent = vfx
	end

	for _, d in ipairs(vfx:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			d:Emit(d.Rate > 0 and math.clamp(math.floor(d.Rate/2), 10, 200) or 50)
		elseif d:IsA("Beam") then
			d.Enabled = true
		elseif d:IsA("Sound") then
			d:Play()
		elseif d:IsA("PointLight") or d:IsA("SpotLight") then
			d.Enabled = true
		end
	end

	task.delay(6, function()
		if vfx and vfx.Parent then vfx:Destroy() end
	end)
end



local function activateFireworks()
	local FireworkEffects = LoadedBallparkFolder:FindFirstChild("FireworkEffects")
	
	if FireworkEffects then
		for _, firework in pairs(FireworkEffects:GetChildren()) do
			firework.FireworksClassicStyle.Trigger.Value = not firework.FireworksClassicStyle.Trigger.Value
		end
	end
end

local function retrieveTitleCard(batter)
	local foundGlobalHitter = GlobalLeaderboards.BestHitters.Board.SurfaceGui.Container:FindFirstChild(batter.Name)
	
	if foundGlobalHitter then
		return "#"..foundGlobalHitter.RankLabelFrame.Label.Text.." Global Hitter"
	end
	
	local foundGlobalPitcher = GlobalLeaderboards.BestPitchers.Board.SurfaceGui.Container:FindFirstChild(batter.Name)

	if foundGlobalPitcher then
		return "#"..foundGlobalPitcher.RankLabelFrame.Label.Text.." Global Pitcher"
	end
	
	local foundGlobalFielder = GlobalLeaderboards.BestFielders.Board.SurfaceGui.Container:FindFirstChild(batter.Name)

	if foundGlobalFielder then
		return "#"..foundGlobalFielder.RankLabelFrame.Label.Text.." Global Fielder"
	end
	
	-- If not global, fallback to OVR title
	local session = _G.sessionData[batter]
	if not session or not session.OVRProgress then
		return "Rookie"
	end

	local playerOVR = session.OVRProgress.OVR

	for titleName, data in pairs(TitleCards.Titles) do
		if playerOVR >= data.MinOVR and playerOVR <= data.MaxOVR then
			return titleName
		end
	end

	return "Rookie"
end

local function displayBatterCard(batter)
	local isAIBatter = batter:GetAttribute("IsAI")
	
	if batter and typeof(batter) == "Instance" and batter:IsA("Player") then
		local batterCardGui = ServerGUIs.BatterCardGui:Clone()
		batterCardGui.Frame.Background.PlayerName.Text = batter.Name

		local success, img = pcall(function()
			return PlayerService:GetUserThumbnailAsync(batter.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)

		if success and img and batter.UserId > 0 then
			batterCardGui.Frame.Background.PlayerIcon.Image = img
		else
			batterCardGui.Frame.Background.PlayerIcon.Image = "rbxassetid://135927875061357"
		end
		
		local titleCardLabel = retrieveTitleCard(batter)
		
		if titleCardLabel then
			batterCardGui.Frame.Background.GlobalPlayer.Text = titleCardLabel
			batterCardGui.Frame.Background.GlobalPlayer.Visible = true
			batterCardGui.Frame.Background.PlayerName.Size = UDim2.new(0.5, 0, 0.25, 0)
			
			if TitleCards.Titles[titleCardLabel] then
				batterCardGui.Frame.Background.GlobalPlayer.TextColor3 = TitleCards.Titles[titleCardLabel].Color
			end
		end

		local teamColor = Color3.fromRGB(255, 255, 255) -- fallback color
		if batter.Team and TeamsModule[batter.Team.Name] then
			teamColor = TeamsModule[batter.Team.Name].PrimaryColor
		end
		batterCardGui.Frame.Background.BackgroundColor3 = teamColor

		local stats = _G.sessionData[batter]
		if stats then
			local H = stats.HittingStats and stats.HittingStats.Hits or 0
			local AB = stats.HittingStats and stats.HittingStats["At-Bats"] or 0
			local HR = stats.HittingStats and stats.HittingStats.HR or 0
			local RBI = stats.HittingStats and stats.HittingStats.RBI or 0
			local OVR = stats.OVRProgress and stats.OVRProgress.OVR or 0
			local GamesPlayed = stats.GameStats and stats.GameStats.GamesPlayed or 0

			batterCardGui.Frame.Background.AVG.Text = ClientFunctions.CalculateBattingAVG(H, AB).." AVG"
			batterCardGui.Frame.Background.HR.Text = HR.." HR"
			batterCardGui.Frame.Background.AB.Text = AB.." AB"
			batterCardGui.Frame.Background.RBI.Text = RBI.." RBI"
			batterCardGui.Frame.Background.OVR.Text = OVR.." OVR"

			if GamesPlayed == 1 then
				batterCardGui.Frame.Background.GamesPlayed.Text = GamesPlayed.." GAME PLAYED"
			else
				batterCardGui.Frame.Background.GamesPlayed.Text = GamesPlayed.." GAMES PLAYED"
			end
		end

		for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
			if player and player:FindFirstChild("PlayerGui") then
				batterCardGui:Clone().Parent = player.PlayerGui
			end
		end
	elseif batter and batter:GetAttribute("IsAI") then
		local batterCardGui = ServerGUIs.BatterCardGui:Clone()
		batterCardGui.Frame.Background.PlayerName.Text = "Fill-In Hitter (AI)"
		batterCardGui.Frame.Background.PlayerIcon.Image = "rbxassetid://135927875061357"
		batterCardGui.Frame.Background.BackgroundColor3 = TeamsModule[batter:GetAttribute("TeamName")].PrimaryColor
		
		for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
			if player and player:FindFirstChild("PlayerGui") then
				batterCardGui:Clone().Parent = player.PlayerGui
			end
		end
	end
end


local function getBestHitterMVP()
	local bestBatter = {Name = "", CBS = 0}
	local maxAVG = 0
	local maxRBI = 0
	local batterPlayers = {}

	for _, statFolder in pairs(CurrentGameStats:GetChildren()) do
		local name = statFolder.Name
		local hits = statFolder.Hitting.Hits.Value
		local atBats = statFolder.Hitting["At-Bats"].Value
		local rbi = statFolder.Hitting.RBI.Value

		local avg = atBats > 0 and (hits / atBats) or 0

		table.insert(batterPlayers, {Name = name, AVG = avg, RBI = rbi})
		
		if avg > maxAVG then maxAVG = avg end
		if rbi > maxRBI then maxRBI = rbi end
	end

	for _, player in ipairs(batterPlayers) do
		local normalizedAVG = maxAVG > 0 and (player.AVG / maxAVG) or 0
		local normalizedRBI = maxRBI > 0 and (player.RBI / maxRBI) or 0
		local cbs = normalizedAVG + normalizedRBI

		if cbs >= bestBatter.CBS then
			bestBatter = {Name = player.Name, CBS = cbs}
		end
	end

	return bestBatter
end

local function getBestPitcherMVP()
	local bestPitcher = {Name = "", PPS = -math.huge}

	for _, statFolder in pairs(CurrentGameStats:GetChildren()) do
		local name = statFolder.Name
		local pitches = statFolder.Pitching.Pitches.Value
		local strikes = statFolder.Pitching.Strikes.Value
		local strikeouts = statFolder.Pitching.Strikeouts.Value
		local walksAllowed = statFolder.Pitching.WalksAllowed.Value
		local hitsAllowed = statFolder.Pitching.HitsAllowed.Value
		local runsAllowed = statFolder.Pitching.RunsAllowed.Value

		local adjustedPitches = pitches + 1  

		local pps = (strikeouts / adjustedPitches) + (strikes / adjustedPitches) 
		- ((walksAllowed + hitsAllowed) / adjustedPitches) 
		- ((runsAllowed * 2) / adjustedPitches)

		if pps >= bestPitcher.PPS then
			bestPitcher = {Name = name, PPS = pps}
		end
	end

	return bestPitcher
end

local function getBestOutfielderMVP()
	local bestOutfielder = {Name = "", DIS = 0}
	local maxPutouts = 0
	local maxAssists = 0
	local players = {}

	for _, statFolder in pairs(CurrentGameStats:GetChildren()) do
		local name = statFolder.Name
		local putouts = statFolder.Outfield.Putouts.Value
		local assists = statFolder.Outfield.Assists.Value

		table.insert(players, {Name = name, Putouts = putouts, Assists = assists})

		if putouts > maxPutouts then maxPutouts = putouts end
		if assists > maxAssists then maxAssists = assists end
	end

	for _, player in ipairs(players) do
		local normalizedPutouts = maxPutouts > 0 and (player.Putouts / maxPutouts) or 0
		local normalizedAssists = maxAssists > 0 and (player.Assists / maxAssists) or 0
		local dis = normalizedPutouts + normalizedAssists

		if dis >= bestOutfielder.DIS then
			bestOutfielder = {Name = player.Name, DIS = dis}
		end
	end

	return bestOutfielder
end

local function setCharacterModelAppearance(playerName, characterModel, userID, teamName)
	local humanoid = characterModel:FindFirstChildOfClass("Humanoid")

	if humanoid then
		pcall(function()
			ServerFunctions.LoadRobloxCharacterOutfit(humanoid, userID)
		end)
		
		if GameValues.AwayTeamPicked.Value == teamName then
			ServerFunctions.GiveNPCUniform(characterModel, teamName, "Away")
		else
			ServerFunctions.GiveNPCUniform(characterModel, teamName, "Home")
		end
		
		if PlayerService:FindFirstChild(playerName) then
			local mvpPlayer = PlayerService[playerName]
			
			if _G.sessionData[mvpPlayer] then
				ServerFunctions.EquipGear(characterModel, "Wristband", _G.sessionData[mvpPlayer].EquippedWristband)
				
				local celebrationAnimation = _G.sessionData[mvpPlayer].EquippedEmote
				
				if celebrationAnimation and ShopPackItems.Emote:FindFirstChild(celebrationAnimation) then
					local animation = Instance.new("Animation")
					animation.AnimationId = ShopPackItems.Emote[celebrationAnimation].AnimationId
					
					pcall(function()
						local animTrack = humanoid:LoadAnimation(animation)
						animTrack.Looped = true
						animTrack:Play()
					end)
				end
			end
		end
	end
end

local function setupMVPPodiums()
	local bestHitter = getBestHitterMVP()
	local bestPitcher = getBestPitcherMVP()
	local bestOutfielder = getBestOutfielderMVP()
	
	local bestBatterPlayer = PlayerService:FindFirstChild(bestHitter.Name)
	if bestBatterPlayer and _G.sessionData[bestBatterPlayer] ~= nil then
		ServerFunctions.AddStat(bestBatterPlayer, "Game", "BestHitter", 1)
		ServerFunctions.AwardSpin(bestBatterPlayer, 2)
	end
	
	local bestPitcherPlayer = PlayerService:FindFirstChild(bestPitcher.Name)
	if bestPitcherPlayer and _G.sessionData[bestPitcherPlayer] ~= nil then
		ServerFunctions.AddStat(bestPitcherPlayer, "Game", "BestPitcher", 1)
		ServerFunctions.AwardSpin(bestPitcherPlayer, 2)
	end
	
	local bestOutfieldPlayer = PlayerService:FindFirstChild(bestOutfielder.Name)
	if bestOutfieldPlayer and _G.sessionData[bestOutfieldPlayer] ~= nil then
		ServerFunctions.AddStat(bestOutfieldPlayer, "Game", "BestOutfielder", 1)
		ServerFunctions.AwardSpin(bestOutfieldPlayer, 2)
	end
	
	local podium = ServerObjects.Podiums:Clone()
	podium.Parent = workspace
	
	podium.BestHitter.BestHitter.SurfaceGui.Frame.PlayerLabel.Text = bestHitter.Name
	podium.BestPitcher.BestPitcher.SurfaceGui.Frame.PlayerLabel.Text = bestPitcher.Name
	podium.BestOutfielder.BestOutfielder.SurfaceGui.Frame.PlayerLabel.Text = bestOutfielder.Name
	
	local bestHitterCharacter = podium.BestHitter.Character
	ServerObjects.AnimeHighlight:Clone().Parent = bestHitterCharacter
	setCharacterModelAppearance(bestHitter.Name, bestHitterCharacter, CurrentGameStats[bestHitter.Name].UserID.Value, CurrentGameStats[bestHitter.Name].PlayerTeam.Value)
	
	local bestPitcherCharacter = podium.BestPitcher.Character
	ServerObjects.AnimeHighlight:Clone().Parent = bestPitcherCharacter
	setCharacterModelAppearance(bestPitcher.Name, bestPitcherCharacter, CurrentGameStats[bestPitcher.Name].UserID.Value, CurrentGameStats[bestPitcher.Name].PlayerTeam.Value)

	local bestOutfielderCharacter = podium.BestOutfielder.Character
	ServerObjects.AnimeHighlight:Clone().Parent = bestOutfielderCharacter
	setCharacterModelAppearance(bestOutfielder.Name, bestOutfielderCharacter, CurrentGameStats[bestOutfielder.Name].UserID.Value, CurrentGameStats[bestOutfielder.Name].PlayerTeam.Value)
end

local function disableUsedFBAbilities()
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		if player ~= nil then
			ServerFunctions.DisableFBAbility(player)
		end
	end
end

local function returnRunnersToBase(ignoreBatter)
	for _, baseTracker in pairs(OnBase:GetChildren()) do
		local runner = PlayerService:FindFirstChild(baseTracker.Name)
		if runner 
			and runner.Character 
			and runner.Character:FindFirstChild("HumanoidRootPart") 
			and BasePlates:FindFirstChild(baseTracker.Value)
			and BasePlates[baseTracker.Value]:FindFirstChild("TouchPart")
		then
			if (not ignoreBatter) or (ignoreBatter and runner ~= GameValues.CurrentBatter.Value) then
				ServerFunctions.TeleportPlayerCharacter(runner, BasePlates[baseTracker.Value].TouchPart.CFrame)
			end
		end
	end
end

local function deleteAnyBallBeingCarried()
	if GameValues.BaseballObj.Value ~= nil then
		local playerCarrier;
		
		if GameValues.BaseballObj.Value.Parent 
			and GameValues.BaseballObj.Value.Parent.Name == "PlayerGlove" 
			and GameValues.BaseballObj.Value.Parent.Parent 
		then
			playerCarrier = PlayerService:GetPlayerFromCharacter(GameValues.BaseballObj.Value.Parent.Parent)
		end
		
		GameValues.BaseballObj.Value:Destroy()
		
		if playerCarrier then
			Remotes.RemoveGreenThrowCircle:FireClient(playerCarrier)
		end
	end
end

local BadgeService = game:GetService("BadgeService")

local HOMERUN_BADGE_ID = 467846172352287
local GRANDSLAM_BADGE_ID = 4395202742144336
local WIN_BADGE_ID = 3418029068723627
local SCORE_RUN_BADGE_ID = 2565085931631491

local function awardBadge(player, badgeId)
	if not player then return end
	if game.PrivateServerOwnerId > 0 or game.PlaceId == 82183144153025 then return end

	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
	end)

	if success and not hasBadge then
		pcall(function()
			BadgeService:AwardBadge(player.UserId, badgeId)
		end)
	end
end


local function processHomerun(nextBatter)
	ServerFunctions.AddStat(nextBatter, "Hitting", "HR", 1)

	SoundService.Effects.CrowdCheer:Play()
	SoundService.Effects.HomerunChime:Play()

	local isGrandSlam = #OnBase:GetChildren() > 3

	if isGrandSlam then
		Remotes.BatResults:FireAllClients("GRAND SLAM!!!")
		SoundService.Narration.GrandSlamNarration:Play()
		awardBadge(nextBatter, GRANDSLAM_BADGE_ID)
	else
		Remotes.BatResults:FireAllClients("HOMERUN!!!")
		SoundService.Narration.HomeRunNarration:Play()
	end

	awardBadge(nextBatter, HOMERUN_BADGE_ID)

	-- NEW: capture ball position immediately (before any cleanup)
	local hrBallPos = getBallWorldPosition()  -- NEW

	wait(1)

	-- You currently delete the ball here — keep that as-is
	if BallHolder:FindFirstChild("Baseball") then
		BallHolder.Baseball:Destroy()
	end

	-- Trigger stadium fireworks as you already do
	activateFireworks()

	-- NEW: also trigger the player's equipped explosion at the ball's last position
	triggerEquippedExplosion(nextBatter, hrBallPos)  -- NEW

	wait(24)

	for _, onbaseTracker in pairs(OnBase:GetChildren()) do
		local batter = PlayerService:FindFirstChild(onbaseTracker.Name)

		ScoreboardValues[AtBat.Value.."Score"].Value = ScoreboardValues[AtBat.Value.."Score"].Value + 1

		if batter then
			ServerFunctions.RemoveBaseTracking(batter)
			BaseballFunctions.ReturnBatterToDugout(batter, AtBat.Value)

			ServerFunctions.AddStat(batter, "Hitting", "Runs", 1)
			awardBadge(batter, SCORE_RUN_BADGE_ID)

			ServerFunctions.AddStat(nextBatter, "Hitting", "RBI", 1)
			ServerFunctions.AddStat(GameValues.CurrentPitcher.Value, "Pitching", "RunsAllowed", 1)
		end
	end

	GameValues.Homerun.Value = false
	GameValues.PlayActive.Value = false
end

local function setupGuessThePitchUI(pitcher, batter)
	local pitchGuessGUI = ServerGUIs.GuessThePitch:Clone()
	
	if pitcher and _G.sessionData[pitcher] then
		local defensiveStyle = Styles.GetEquippedStyleName(pitcher, "Defensive")
		
		if defensiveStyle and StylesModule.DefensiveStyles[defensiveStyle] and StylesModule.DefensiveStyles[defensiveStyle].SubType == "Pitching" then
			local pitchAbilities = StylesModule.DefensiveStyles[defensiveStyle].PitchAbilities
			
			pitchGuessGUI.Frame.Background.GuessFrame.PitchOption1.Label.Text = pitchAbilities[1]
			pitchGuessGUI.Frame.Background.GuessFrame.PitchOption1.Name = pitchAbilities[1]
			
			pitchGuessGUI.Frame.Background.GuessFrame.PitchOption2.Label.Text = pitchAbilities[2]
			pitchGuessGUI.Frame.Background.GuessFrame.PitchOption2.Name = pitchAbilities[2]
			
			pitchGuessGUI.Frame.Background.GuessFrame.PitchOption3.Label.Text = pitchAbilities[3]
			pitchGuessGUI.Frame.Background.GuessFrame.PitchOption3.Name = pitchAbilities[3]
			
			pitchGuessGUI.Frame.Background.GuessFrame.PitchOption4.Label.Text = pitchAbilities[4]
			pitchGuessGUI.Frame.Background.GuessFrame.PitchOption4.Name = pitchAbilities[4]
		else
			pitchGuessGUI.Frame.Background.GuessFrame.PitchOption1.Label.Text = PitchingAnimationsModule.Default.Pitches[1]
			pitchGuessGUI.Frame.Background.GuessFrame.PitchOption1.Name = PitchingAnimationsModule.Default.Pitches[1]

			pitchGuessGUI.Frame.Background.GuessFrame.PitchOption2.Label.Text = PitchingAnimationsModule.Default.Pitches[2]
			pitchGuessGUI.Frame.Background.GuessFrame.PitchOption2.Name = PitchingAnimationsModule.Default.Pitches[2]

			pitchGuessGUI.Frame.Background.GuessFrame.PitchOption3.Label.Text = PitchingAnimationsModule.Default.Pitches[3]
			pitchGuessGUI.Frame.Background.GuessFrame.PitchOption3.Name = PitchingAnimationsModule.Default.Pitches[3]

			pitchGuessGUI.Frame.Background.GuessFrame.PitchOption4.Label.Text = PitchingAnimationsModule.Default.Pitches[4]
			pitchGuessGUI.Frame.Background.GuessFrame.PitchOption4.Name = PitchingAnimationsModule.Default.Pitches[4]
		end
		
		local numOfPlayers = #ClientFunctions.GetPlayersInGame()
		if numOfPlayers >= 12 then
			GameValues.PitchGuessActive.Reward.Value = 10
		elseif numOfPlayers >= 8 then
			GameValues.PitchGuessActive.Reward.Value = 6
		elseif numOfPlayers >= 6 then
			GameValues.PitchGuessActive.Reward.Value = 4
		elseif numOfPlayers >= 2 then
			GameValues.PitchGuessActive.Reward.Value = 2
		end
		
		pitchGuessGUI.Frame.Background.GuessFrame.RewardFrame.Label.Text = "EARN "..tostring(GameValues.PitchGuessActive.Reward.Value).." COINS"
		
		for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
			if not ClientFunctions.PlayerIsDefender(player) 
				and OnBase:FindFirstChild(player.Name) == nil 
				and player ~= batter 
			then
				pitchGuessGUI:Clone().Parent = player.PlayerGui
			end
		end
	end
end

local function awardPitchGuessRewards()
	for _, dugoutPlayer in pairs(ClientFunctions.GetPlayersInGame()) do
		if dugoutPlayer and not ClientFunctions.PlayerIsDefender(dugoutPlayer) and OnBase:FindFirstChild(dugoutPlayer.Name) == nil then
			local playerData = SharedData:FindFirstChild(dugoutPlayer.Name)
			if playerData then
				local pitchGuess = playerData:FindFirstChild("PitchGuess")
				if pitchGuess and pitchGuess.Value ~= "" then
					if pitchGuess.Value == GameValues.PitchGuessActive.PitchSelected.Value then
						ServerFunctions.CashTransaction(dugoutPlayer, GameValues.PitchGuessActive.Reward.Value, true, true)
						Remotes.Notification:FireClient(dugoutPlayer, "You guessed the pitch correctly and earned "..tostring(GameValues.PitchGuessActive.Reward.Value).." Coins!")
					else
						Remotes.Notification:FireClient(dugoutPlayer, "Sorry, you didn't guess the pitch correctly this time!")
					end
					pitchGuess.Value = ""
				end
			end
		end
	end
end

local function loadPriorityQueue(designation)
	local priorityQueueFolder = GameValues[designation.."PriorityBattingQueue"]
	
	priorityQueueFolder:ClearAllChildren()
	
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		if player.Team and player.Team.Name == GameValues[designation.."TeamPicked"].Value then
			local val = Instance.new("BoolValue")
			val.Name = player.Name
			val.Parent = priorityQueueFolder
		end
	end
end

local function homeHasWonGame()
	return Inning.Value >= MAX_INNINGS and HomeScore.Value > AwayScore.Value and ScoreboardValues.AtBat.Value == "Home"
end

Remotes.VoteGameTime.OnServerEvent:Connect(function(player, timeOfDay)
	gameTimeVotes[player] = timeOfDay
end)

Remotes.VoteBallPark.OnServerEvent:Connect(function(player, ballParkName)
	ballParkVotes[player] = ballParkName
end)

while true do
	CameraValues.FieldPan.Value = true
	
	if not SoundService.Music.GameTheme.IsPlaying and not SoundService.Music.VictoryTheme.IsPlaying then
		SoundService.Music.VictoryTheme:Stop()
		SoundService.Music.GameTheme:Play()
	end
	
	if ServerFunctions.GetServerType() == "ReservedServer" then
		repeat wait(1) until RankedSystem.LobbyType
		
		for i = 30, 0, -1 do
			changeGameStatus("Waiting for players to join ("..i..")")
			
			task.wait(1)
			
			if #PlayerService:GetPlayers() >= RankedUtilities.LobbyTypes[RankedSystem.LobbyType].Size * 2 then
				break
			end
		end
	elseif #ClientFunctions.GetPlayersInGame() < 2 then
		changeGameStatus("Waiting for more players...")
	end
	
	repeat
		wait(1)
	until #ClientFunctions.GetPlayersInGame() > 1
	
	if not DEBUG_SKIP_INTRO and ServerFunctions.GetServerType() ~= "ReservedServer" then
		for i = GAME_START_COUNTDOWN, 0, -1 do
			changeGameStatus("Game starts in "..i)
			wait(1)
		end
	end
		
	changeGameStatus("")
	
	task.wait(1)
	
	voteBallPark()
	
	voteTimeOfDay()
	
	GameValues.HomeCaptain.Value, GameValues.AwayCaptain.Value = pickCaptains()
	
	local homeTeam, awayTeam = selectTeams()
	
	local homeTeamObj = Instance.new("Team")
	homeTeamObj.Name = homeTeam
	homeTeamObj.TeamColor = TeamsModule[homeTeam].TeamColor
	homeTeamObj.AutoAssignable = false
	homeTeamObj.Parent = game.Teams
	
	local awayTeamObj = Instance.new("Team")
	awayTeamObj.Name = awayTeam
	awayTeamObj.TeamColor = BrickColor.new("White")
	awayTeamObj.AutoAssignable = false
	awayTeamObj.Parent = game.Teams
	
	if GameValues.HomeCaptain.Value and GameValues.HomeCaptain.Value.Team then
		GameValues.HomeCaptain.Value.TeamColor = homeTeamObj.TeamColor
		ServerFunctions.GiveUniform(GameValues.HomeCaptain.Value, GameValues.HomeCaptain.Value.Team.Name, "Home")
	end
	
	if GameValues.AwayCaptain.Value and GameValues.AwayCaptain.Value.Team then
		GameValues.AwayCaptain.Value.TeamColor = awayTeamObj.TeamColor
		ServerFunctions.GiveUniform(GameValues.AwayCaptain.Value, GameValues.AwayCaptain.Value.Team.Name, "Away")
	end
	
	decorateStadium()
	
	CameraValues.FieldPan.Value = false
	CameraValues.PlayerSelectCam.Value = true
	
	playerSelection()
	
	setupTeamSpawns(homeTeamObj, awayTeamObj)
	
	CameraValues.PlayerSelectCam.Value = false
	
	-- START GAME
	GameValues.GameActive.Value = true
	
	if ServerFunctions.GetServerType() == "ReservedServer" then
		RankedSystem.RemainingOpponentsCheck()
	end
	
	startPlayerIntro(homeTeamObj, awayTeamObj)
	
	initializeBattingOrders(homeTeamObj, awayTeamObj)

	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		ServerFunctions.SetupCurrentGameStatsTracking(player)
	end
	
	Inning.Value = 1
	AtBat.Value = "Away"
	
	GameValues.AwayBattingQueue.Value = 1
	GameValues.HomeBattingQueue.Value = 1
	
	SoundService.Music.GameTheme:Stop()
	SoundService.Music.VictoryTheme:Stop()
	
	while GameValues.GameActive.Value do
		local addedNewBattersIntoPriorityQueue = false
		
		Outs.Value = 0
		
		Remotes.EnableFieldWalls:FireAllClients(false)
		
		returnPlayersToDugout(homeTeamObj, awayTeamObj)
		
		local catcherDesignation;
		if AtBat.Value == "Away" then
			catcherDesignation = "Home"
		else
			catcherDesignation = "Away"
		end
		
		ServerFunctions.GiveNPCUniform(NPCs.Catcher, GameValues[catcherDesignation.."TeamPicked"].Value, catcherDesignation)
		
		setupOutfielders()
		positionOutfielders(false, nil, OutfieldTeleports.Teleport)
		
		if not addedNewBattersIntoPriorityQueue then -- in rollover innings, if players are still skipped, should play
			addedNewBattersIntoPriorityQueue = true
			
			local priorityQueueFolder = GameValues[AtBat.Value.."PriorityBattingQueue"]
			
			for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
				if player.Team 
					and player.Team.Name == GameValues[AtBat.Value.."TeamPicked"].Value 
					and priorityQueueFolder:FindFirstChild(player.Name) == nil
				then
					local val = Instance.new("BoolValue")
					val.Name = player.Name
					val.Parent = priorityQueueFolder
				end
			end
		end
		
		while Outs.Value < 3 and not homeHasWonGame() and RankedSystem.MercyRuleReached() == nil do
			local nextBatter
			local pitcher
			local batterLeftGame = false
			local pitchClockViolation = false
			local flyOutAnnounced = false
			
			ServerFunctions.EnableLeadBlockers(true)
			returnRunnersToBase(false) -- in case they wandered out
			disableUsedFBAbilities()
			
			for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
				if ClientFunctions.PlayerIsDefender(player) then
					ServerFunctions.IncreaseFieldingPower(player, 20)--TEST should be 20
					ServerFunctions.ResetArms(player)
				end
			end
			
			if AtBat.Value == "Away" then
				local batterAvailable = hasEnoughBatters(awayTeamObj)
				
				if batterAvailable then
					repeat
						if GameValues.AwayBattingQueue.Value == 1 then
							loadPriorityQueue("Away")
						end
						
						nextBatter = getNextBatter(awayTeamObj, GameValues.AwayBattingQueue.Value, "Away")
						if GameValues.AwayBattingQueue.Value + 1 > ServerFunctions.GetLastBattingOrderInQueue("Away") then
							GameValues.AwayBattingQueue.Value = 1
						else
							GameValues.AwayBattingQueue.Value = GameValues.AwayBattingQueue.Value + 1
						end
						wait()
					until nextBatter ~= nil
				else
					local AIBatter = ServerStorage.AIs.AI:Clone()
					AIBatter.Name = "AIBatter"
					ServerObjects.AnimeHighlight:Clone().Parent = AIBatter
					AIBatter:SetAttribute("TeamName", GameValues.AwayTeamPicked.Value)
					ServerObjects["Baseball Helmet"]:Clone().Parent = AIBatter
					ServerFunctions.GiveNPCUniform(AIBatter, GameValues[ScoreboardValues.AtBat.Value.."TeamPicked"].Value, ScoreboardValues.AtBat.Value)
					nextBatter = AIBatter
					
					for _, part in pairs(AIBatter:GetDescendants()) do
						if part:IsA("BasePart") or part:IsA("MeshPart") then
							part.CollisionGroup = "AIOffenseGroup"
						end
					end
				end
				
				pitcher = getPitcher(homeTeamObj, "Home")
				
				if GameValues.CurrentPitcher.Value ~= pitcher 
					and GameValues.CurrentPitcher.Value ~= nil 
					and pitcher ~= nil
					and not GameValues.CurrentPitcher.Value:GetAttribute("IsAI")
					and GameValues.CurrentPitcher.Value.TeamColor == pitcher.TeamColor 
				then
					local oldPitcherCharacter = GameValues.CurrentPitcher.Value.Character

					if oldPitcherCharacter and oldPitcherCharacter:FindFirstChild("HumanoidRootPart") then
						ServerFunctions.TeleportPlayerCharacter(GameValues.CurrentPitcher.Value, OutfieldTeleports.Teleport.CFrame)
					end
				end
				
				Remotes.EnableBattingOrderGui:FireAllClients(true, awayTeamObj)
			else
				local batterAvailable = hasEnoughBatters(homeTeamObj)
				
				if batterAvailable then
					repeat
						if GameValues.HomeBattingQueue.Value == 1 then
							loadPriorityQueue("Home")
						end
						
						nextBatter = getNextBatter(homeTeamObj, GameValues.HomeBattingQueue.Value, "Home")
						if GameValues.HomeBattingQueue.Value + 1 > ServerFunctions.GetLastBattingOrderInQueue("Home") then
							GameValues.HomeBattingQueue.Value = 1
						else
							GameValues.HomeBattingQueue.Value = GameValues.HomeBattingQueue.Value + 1
						end
						wait()
					until nextBatter ~= nil
				else
					local AIBatter = ServerStorage.AIs.AI:Clone()
					AIBatter.Name = "AIBatter"
					ServerObjects.AnimeHighlight:Clone().Parent = AIBatter
					AIBatter:SetAttribute("TeamName", GameValues.HomeTeamPicked.Value)
					ServerObjects["Baseball Helmet"]:Clone().Parent = AIBatter
					ServerFunctions.GiveNPCUniform(AIBatter, GameValues[ScoreboardValues.AtBat.Value.."TeamPicked"].Value, ScoreboardValues.AtBat.Value)
					nextBatter = AIBatter
					
					for _, part in pairs(AIBatter:GetDescendants()) do
						if part:IsA("BasePart") or part:IsA("MeshPart") then
							part.CollisionGroup = "AIOffenseGroup"
						end
					end
				end
				
				pitcher = getPitcher(awayTeamObj, "Away")
				
				if GameValues.CurrentPitcher.Value ~= pitcher 
					and GameValues.CurrentPitcher.Value ~= nil 
					and pitcher ~= nil
					and not GameValues.CurrentPitcher.Value:GetAttribute("IsAI")
					and GameValues.CurrentPitcher.Value.TeamColor == pitcher.TeamColor 
				then
					local oldPitcherCharacter = GameValues.CurrentPitcher.Value.Character

					if oldPitcherCharacter and oldPitcherCharacter:FindFirstChild("HumanoidRootPart") then
						ServerFunctions.TeleportPlayerCharacter(GameValues.CurrentPitcher.Value, OutfieldTeleports.Teleport.CFrame)
					end
				end
				
				Remotes.EnableBattingOrderGui:FireAllClients(true, homeTeamObj)
			end
			
			resetCameras(nextBatter, pitcher)
			
			Balls.Value = 0
			Strikes.Value = 0
			Fouls.Value = 0
			
			GameValues.CurrentBatter.Value = nextBatter
			GameValues.CurrentPitcher.Value = pitcher
			
			if RunService:IsStudio() then
				ServerFunctions.IncreasePitchingPower(pitcher, 100)
			else
				ServerFunctions.IncreasePitchingPower(pitcher, 20) -- should be 20
			end			

			if RunService:IsStudio() then
				ServerFunctions.IncreaseHittingPower(nextBatter, 100)
			else
				ServerFunctions.IncreaseHittingPower(nextBatter, 35) -- should be 35
				ServerFunctions.IncreaseBaserunningPower(nextBatter, 35)
			end
			
			if typeof(nextBatter) == "Instance" and nextBatter:IsA("Player") then
				Remotes.EnableBattingOrderGui:FireClient(nextBatter, false)
			end
			
			setupJumbotron(nextBatter)
			
			if not nextBatter:GetAttribute("IsAI") and nextBatter.Character and nextBatter.Character:FindFirstChild("HumanoidRootPart") then
				changeGameStatus("Up Next : "..nextBatter.Name)

				if _G.sessionData[nextBatter] and _G.sessionData[nextBatter].EquippedBattingGlove ~= "" then
					local LGlove = GearItems["BattingGlove"][_G.sessionData[nextBatter].EquippedBattingGlove]:Clone()
					LGlove.Name = "BattingGlove"
					LGlove.Parent = nextBatter.Character
					local weld = Instance.new("Weld", nextBatter.Character.LeftHand)
					weld.Part0 = weld.Parent
					weld.Part1 = LGlove
					weld.C0 = CFrame.new(0, -0.05, 0)

					local RGlove = GearItems["BattingGlove"][_G.sessionData[nextBatter].EquippedBattingGlove]:Clone()
					RGlove.Name = "BattingGlove"
					RGlove.Parent = nextBatter.Character
					local weld = Instance.new("Weld", nextBatter.Character.RightHand)
					weld.Part0 = weld.Parent
					weld.Part1 = RGlove
					weld.C0 = CFrame.new(0, -0.05, 0)
					
					nextBatter.Character.RightHand.Transparency = 1
					nextBatter.Character.LeftHand.Transparency = 1
				end
				
				ServerFunctions.TeleportPlayerCharacter(nextBatter, OnDeckParts[AtBat.Value.."OnDeck"].CFrame)
				
				displayBatterCard(nextBatter)
				
				startOnDeckIntro(nextBatter)
			elseif nextBatter:GetAttribute("IsAI") then
				changeGameStatus("Up Next : Fill-In Hitter (AI)")
				nextBatter.Parent = workspace.AIs
				--nextBatter.HumanoidRootPart.CFrame = OnDeckParts[AtBat.Value.."OnDeck"].CFrame
				nextBatter:PivotTo(OnDeckParts[AtBat.Value.."OnDeck"].CFrame)
				
				displayBatterCard(nextBatter)

				startOnDeckIntro(nextBatter)
			end		
			
			resetCameras(nextBatter)
			
			if nextBatter:GetAttribute("IsAI") then
				BaseballFunctions.SetUpAIBatter(nextBatter)
				changeGameStatus("Now Batting : Fill-In Hitter (AI)")
			else
				BaseballFunctions.SetUpBatter(nextBatter)
				BaseballFunctions.InitializeBaseTracking(nextBatter)
				changeGameStatus("Now Batting : "..nextBatter.Name)
			end
			
			GameValues.PlayActive.Value = true
			
			if not nextBatter:GetAttribute("IsAI") then
				ServerFunctions.AddStat(nextBatter, "Hitting", "At-Bats", 1)
			end
			
			if pitcher and pitcher.Character and pitcher.Character:FindFirstChild("HumanoidRootPart") and ClientFunctions.PlayerIsInGame(pitcher) then
				ServerFunctions.TeleportPlayerCharacter(pitcher, workspace.VotedPitcherSpawn.Teleport.CFrame)
			end
			
			local votedPitcherOnly = true
			GameValues.PitcherAvailable.Value = true
			local pitcherCircle = SharedObjects.PitcherCircle.GradientCylinder:Clone()
			pitcherCircle.Transparency = 1
			pitcherCircle:ClearAllChildren()
			pitcherCircle.Parent = workspace
			
			ServerFunctions.EnablePitcherWalls(false)
			
			local touchedPitcherCircle
			
			touchedPitcherCircle = pitcherCircle.Touched:Connect(function(hit)
				if not GameValues.PitcherAvailable.Value then return end
				
				if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then		
					local potentialPitcher = PlayerService:GetPlayerFromCharacter(hit.Parent)
					
					if potentialPitcher and ClientFunctions.PlayerIsDefender(potentialPitcher) then
						if votedPitcherOnly then
							if potentialPitcher == pitcher then
								GameValues.PitcherAvailable.Value = false
								GameValues.CurrentPitcher.Value = pitcher
								BaseballFunctions.SetUpPitcher(pitcher)
								touchedPitcherCircle:Disconnect()
								touchedPitcherCircle = nil
								pitcherCircle:Destroy()
								ServerFunctions.EnablePitcherWalls(true)
								positionOutfielders(true, true)
								Remotes.ShowPitcherMoundCircle:FireAllClients(false)
							end
						else
							pitcher = potentialPitcher
							GameValues.PitcherAvailable.Value = false
							GameValues.CurrentPitcher.Value = pitcher
							BaseballFunctions.SetUpPitcher(pitcher)
							touchedPitcherCircle:Disconnect()
							touchedPitcherCircle = nil
							pitcherCircle:Destroy()
							ServerFunctions.EnablePitcherWalls(true)
							positionOutfielders(true, true)
							Remotes.ShowPitcherMoundCircle:FireAllClients(false)
						end
					end
				end
			end)
			
			Remotes.ShowPitcherMoundCircle:FireAllClients(true, pitcher)
			
			local start = tick()
			while tick() - start < 9 do
				if not touchedPitcherCircle then
					break
				end
				task.wait(0.1)
			end
			
			votedPitcherOnly = false
			if GameValues.PitcherAvailable.Value then
				Remotes.ShowPitcherMoundCircle:FireAllClients(true, nil, true)
			end
			
			repeat 
				ScoreboardValues.PitchClockEnabled.Value = true
				GameValues.BallHit.Value = false
				GameValues.FlyBall.Value = false
				GameValues.Putout.Value = false
				GameValues.CountedStrike.Value = false
				GameValues.BallFouled.Value = false
				GameValues.BallPitched.Value = false
				GameValues.PendingStarHit.Value = false
				GameValues.PendingStarPitch.Value = false
				GameValues.PitchGuessActive.Value = true
				GameValues.AbilitiesCanBeUsed.Value = false
				GameValues.PitchGuessActive.PitchSelected.Value = ""
				GameValues.PitchGuessActive.Reward.Value = 0
				pitchClockViolation = false
				
				if (pitcher == nil) or (pitcher and PlayerService:FindFirstChild(pitcher.Name) == nil and not pitcher:GetAttribute("IsAI")) then
					if AtBat.Value == "Away" then
						pitcher = getPitcher(homeTeamObj, "Home")
					else
						pitcher = getPitcher(awayTeamObj, "Away")
					end
					GameValues.CurrentPitcher.Value = pitcher
					BaseballFunctions.SetUpPitcher(pitcher)
				end
				
				setupGuessThePitchUI(pitcher, nextBatter)
				
				local randomAIPitchTime = math.random(3,6)

				for i = 10, 0, -1 do
					if ScoreboardValues.PitchClockEnabled.Value then
						if (nextBatter:GetAttribute("IsAI")) or (ServerFunctions.PlayerIsInGame(nextBatter) and nextBatter.Character) then
							if pitcher and pitcher:GetAttribute("IsAI") and i == randomAIPitchTime then
								ScoreboardValues.PitchClockEnabled.Value = false
								Remotes.PitchAIBall:Fire(pitcher)
							end
							
							if touchedPitcherCircle == nil and (pitcher == nil or (not ServerFunctions.PlayerIsInGame(pitcher) and not pitcher:GetAttribute("IsAI"))) then
								pitcher = nil
								break
							end
							
							ScoreboardValues.PitchClockEnabled.Clock.Value = i
							task.wait(1)
							
							removeUnwantedOutfielders()
						else
							batterLeftGame = true
							ScoreboardValues.PitchClockEnabled.Value = false
							break
						end
					else
						break
					end
				end
				
				GameValues.PitchGuessActive.Value = false
				Remotes.DestroyGui:FireAllClients("GuessThePitch")

				if ScoreboardValues.PitchClockEnabled.Value then
					if touchedPitcherCircle == nil and pitcher and ClientFunctions.PlayerIsInGame(pitcher) then
						Remotes.AutoPitchPlayer:FireClient(pitcher)
						--Remotes.ForceServerPitch:Fire(pitcher)
					else
						ScoreboardValues.PitchClockEnabled.Value = false
						
						if touchedPitcherCircle ~= nil then
							Remotes.BatResults:FireAllClients("No player chose to pitch — AI taking over this plate appearance")
							
							if pitcher and pitcher:GetAttribute("IsAI") then
								pitcher:Destroy()
							end
						
							local AIPitcher = ServerStorage.AIs.AI:Clone()
							AIPitcher.Name = "AIPitcher"
							ServerObjects.AnimeHighlight:Clone().Parent = AIPitcher
							AIPitcher:SetAttribute("TeamName", GameValues[catcherDesignation.."TeamPicked"].Value)
							SharedObjects["Baseball Cap"]:Clone().Parent = AIPitcher
							ServerFunctions.GiveNPCUniform(AIPitcher, GameValues[catcherDesignation.."TeamPicked"].Value, catcherDesignation)
							
							pitcher = AIPitcher
							GameValues.PitcherAvailable.Value = false
							GameValues.CurrentPitcher.Value = pitcher
							pitcher.HumanoidRootPart.CFrame = workspace.Pitching.Mound.CFrame
							pitcher.Parent = workspace.AIs
							pitcher.HumanoidRootPart.Anchored = true
							touchedPitcherCircle:Disconnect()
							touchedPitcherCircle = nil
							pitcherCircle:Destroy()
							ServerFunctions.EnablePitcherWalls(true)
							positionOutfielders(true, true)
							Remotes.ShowPitcherMoundCircle:FireAllClients(false)
							BaseballFunctions.SetUpAIPitcher(pitcher, workspace.Pitching.AIMound)
						else
							pitchClockViolation = true
							Balls.Value = Balls.Value + 1
							Remotes.BatResults:FireAllClients("Pitch Clock Violation")
							
							pitcher = nil
							
							if pitcher and pitcher:GetAttribute("IsAI") then
								pitcher:Destroy()
							end
						end
					end
				end
				
				if not batterLeftGame then					
					for i = 4, 0, -1 do
						wait(1)
						if Strikes.Value == 3 or GameValues.BallFouled.Value then
							break
						end
					end
					
					if (GameValues.PendingStarHit.Value or GameValues.PendingStarPitch.Value) then
						for i = 24, 0, -1 do
							wait(0.5)
							if not GameValues.PendingStarHit.Value 
								and not GameValues.PendingStarPitch.Value
							then
								break
							end
						end
					end
					
					if not pitchClockViolation then
						awardPitchGuessRewards()
					end
				end
				
				if GameValues.BallHit.Value and not GameValues.BallFouled.Value then
					if NPCs and workspace:FindFirstChild("NPCs") then
						NPCs.Parent = ServerStorage
					end
					
					if nextBatter and nextBatter:GetAttribute("IsAI") then
						nextBatter:Destroy()
					end
					
					if GameValues.Homerun.Value then -- homerun
						processHomerun(nextBatter)
					else
						local ballMissingStart = nil

						repeat 
							wait()
							
							if GameValues.Putout.Value and not flyOutAnnounced then
								flyOutAnnounced = true
								Remotes.BatResults:FireAllClients("Flyout")
								SoundService.Effects.CrowdDisappointment:Play()
								SoundService.Effects.OutChime:Play()
								returnRunnersToStartingBase()
								wait(2)
							end
							
							allRunnersOutOrSafe()
							
							if GameValues.Homerun.Value then -- late homerun
								processHomerun(nextBatter)
								break
							end
							
							local ballExists = BallHolder:FindFirstChild("Baseball") or (GameValues.BaseballObj.Value and GameValues.BaseballObj.Value:IsDescendantOf(workspace))
							
							if not ballExists and not GameValues.Homerun.Value then
								if not ballMissingStart then
									ballMissingStart = tick()
								elseif tick() - ballMissingStart >= 5 then
									warn("Ball has been missing for 5 seconds. Respawning ball...")
									ballMissingStart = nil
									
									local NewBall = game.ServerStorage.ServerObjects.Baseball:Clone()
									NewBall.Parent = workspace.BallHolder
									NewBall.Position = BasePlates.PitcherPlate.Position + Vector3.new(0, 5, 0)
									NewBall.CollisionGroup = CollisionGroups.BASEBALL_GROUP_THROWING
									NewBall.CatchBall.Enabled = true
									NewBall.Catchable.Value = false
									NewBall:SetAttribute("Hit", true)
									GameValues.FlyBall.Value = false

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
							else
								ballMissingStart = nil -- reset if ball is found again
							end

							
						until not GameValues.BallHit.Value or Outs.Value >= 3
						
						flyOutAnnounced = false
					end
				elseif GameValues.BallFouled.Value then -- check foul
					if BallHolder:FindFirstChild("Baseball") then
						BallHolder["Baseball"].CanCollide = false	
					end
										
					Remotes.BatResults:FireAllClients("Foul Ball")
					SoundService.Narration.FoulBallNarration:Play()
					
					local startTime = tick()
					repeat
						wait()
					until BallHolder:FindFirstChild("Baseball") == nil 
						or GameValues.Putout.Value 
						or tick() - startTime >= 10

					
					if GameValues.Putout.Value then
						Remotes.BatResults:FireAllClients("Flyout")
						SoundService.Effects.CrowdDisappointment:Play()
						SoundService.Effects.OutChime:Play()
						ServerFunctions.RemoveBaseTracking(nextBatter)
						wait(6)
						BaseballFunctions.ReturnBatterToDugout(nextBatter, AtBat.Value)
					else
						Fouls.Value = Fouls.Value + 1
						if Strikes.Value < 2 or Fouls.Value >= MAX_FOULS_BEFORE_OUT then
							Strikes.Value = Strikes.Value + 1
						end
						
						if ServerFunctions.PlayerIsInGame(nextBatter) and nextBatter.Character then
							BaseballFunctions.SetUpBatter(nextBatter)
							TransformationEffects.RemoveAuras(nextBatter)
							if Fouls.Value == MAX_FOULS_BEFORE_OUT - 1 then
								Remotes.Notification:FireClient(nextBatter, "The next foul ball will be an out", "Alert")
							end
						end
						
						setupOutfielders()
						positionOutfielders(true, true)
						returnRunnersToBase(true) 
						
						ServerFunctions.EnablePitcherWalls(true)
						ServerFunctions.EnableLeadBlockers(true)
						
						if ServerFunctions.PlayerIsInGame(pitcher) and pitcher.Character then
							BaseballFunctions.SetUpPitcher(pitcher)
						end
					end
				end
				Remotes.UpdateStatsGui:FireAllClients()
			until Balls.Value == 4 or Strikes.Value == 3 or batterLeftGame or not GameValues.PlayActive.Value or Outs.Value >= 3 or GameValues.Putout.Value
			
			BallHolder:ClearAllChildren()
			LandingIndicators:ClearAllChildren()
			GameValues.AssistsTracker:ClearAllChildren()
			deleteAnyBallBeingCarried()
			
			if nextBatter and nextBatter:GetAttribute("IsAI") then
				nextBatter:Destroy()
			end
			
			if pitcher and pitcher:GetAttribute("IsAI") then
				pitcher:Destroy()
			end
			
			workspace.AIs:ClearAllChildren()
			
			if touchedPitcherCircle then
				touchedPitcherCircle:Disconnect()
				touchedPitcherCircle = nil
			end
			
			GameValues.PitcherAvailable.Value = false
			
			if pitcherCircle then
				pitcherCircle:Destroy()
			end
			
			Remotes.ShowPitcherMoundCircle:FireAllClients(false)
			
			GameValues.PlayActive.Value = false
			GameValues.BallHit.Value = false
			GameValues.Putout.Value = false
			
			if Strikes.Value == 3 or batterLeftGame then
				Outs.Value = Outs.Value + 1
				if batterLeftGame then
					Remotes.BatResults:FireAllClients("Out - Batter Left!")
				else
					Remotes.BatResults:FireAllClients("Out")
				end
				
				SoundService.Narration.OutNarration:Play()
				SoundService.Effects.CrowdDisappointment:Play()
				SoundService.Effects.OutChime:Play()
				ServerFunctions.RemoveBaseTracking(nextBatter)
				ServerFunctions.AddStat(nextBatter, "Hitting", "Strikeouts", 1)
				ServerFunctions.AddStat(pitcher, "Pitching", "Strikeouts", 1)
				wait(6)
				BaseballFunctions.ReturnBatterToDugout(nextBatter, AtBat.Value)
			elseif Balls.Value == 4 then
				local batterName = "Batter"
				
				if nextBatter ~= nil then
					batterName = nextBatter.Name
				end
				
				changeGameStatus(batterName.." is walking!")
				BaseballFunctions.UnSetupPlayer(pitcher)
				BaseballFunctions.UnSetupPlayer(nextBatter)
				ServerFunctions.AddStat(nextBatter, "Hitting", "Walks", 1)
				ServerFunctions.AddStat(pitcher, "Pitching", "WalksAllowed", 1)
				walkBatters(nextBatter)
				wait(3)
			end
			
			BaseballFunctions.UnSetupPlayer(pitcher)
			BaseballFunctions.UnSetupPlayer(nextBatter)
			if nextBatter and not OnBase:FindFirstChild(nextBatter.Name) then
				BaseballFunctions.GiveBattingPracticeGui(nextBatter)
			end
			
			if ServerStorage:FindFirstChild("NPCs") then
				ServerStorage.NPCs.Parent = workspace
			end

			wait()
		end
		
		GameValues.CurrentBatter.Value = nil
		Remotes.LockedInBaseNotification:FireAllClients(false)
		Remotes.SafeStatusNotification:FireAllClients(false)
		Remotes.ShowBaseMarker:FireAllClients(false)
		Remotes.EnableBattingOrderGui:FireAllClients(false)
		Remotes.SetupFieldingPower:FireAllClients(false)
		Remotes.SetupBaserunningPower:FireAllClients(false)
		Remotes.ToggleAbilityButtons:FireAllClients(false)
		GameValues.OnBase:ClearAllChildren()
		disableUsedFBAbilities()
		
		CameraValues.FieldPan.Value = true
		
		-- NEW INNING
		if AtBat.Value == "Home" then
			if (Inning.Value + 1 > MAX_INNINGS and HomeScore.Value == AwayScore.Value) or (Inning.Value < MAX_INNINGS) then -- check for new inning or overtime inning
				AtBat.Value = "Away"
				Inning.Value = Inning.Value + 1
			elseif (Inning.Value >= MAX_INNINGS and HomeScore.Value ~= AwayScore.Value) then -- check if game ended after full innings
				GameValues.GameActive.Value = false
			end
		else
			AtBat.Value = "Home"
		end
		
		if (Inning.Value >= MAX_INNINGS and AtBat.Value == "Home" and HomeScore.Value > AwayScore.Value) then -- check if game ended in overtime or early
			GameValues.GameActive.Value = false
		end
		
		if not GameValues.GameActive.Value then
			local winningTeam = getWinningTeam()
			
			SoundService.Music.VictoryTheme:Play()
			
			Remotes.ToggleMenuButtons:FireAllClients(true)
			Remotes.ToggleScoreboard:FireAllClients(true)
			
			ServerFunctions.EnablePitcherWalls(false)
			ServerFunctions.EnableLeadBlockers(false)
			Remotes.EnableFieldWalls:FireAllClients(false)
			
			Remotes.BatResults:FireAllClients(TeamsModule[winningTeam].City.." has won the game!!")
			activateFireworks()
			for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
				ServerFunctions.AddStat(player, "Game", "GamesPlayed", 1)
				
				if player and player.Team then
					if player.Team.Name == winningTeam then
						ServerFunctions.AddStat(player, "Game", "Wins", 1)
						awardBadge(player, WIN_BADGE_ID)
						
						if ServerFunctions.GetServerType() == "ReservedServer" then
							RankedSystem.GameEndResult(player, true)
						end
					else
						ServerFunctions.AddStat(player, "Game", "Losses", 1)
						
						if ServerFunctions.GetServerType() == "ReservedServer" then
							RankedSystem.GameEndResult(player, false)
						end
					end
				end
			end
			
			wait(6)
			
			returnPlayersToDugout(homeTeamObj, awayTeamObj)
			setupMVPPodiums()

			CameraValues.FieldPan.Value = false
			CameraValues.MVPAwardCam.Value = true
			Remotes.DisableMovement:FireAllClients(true)
			
			for i = 1, 10 do
				if i == 1 then
					activateFireworks()
				elseif i == 4 then
					activateFireworks()
				elseif i == 7 then
					activateFireworks()
				elseif i == 10 then
					activateFireworks()
				end
				wait(1)
			end
			
			wait(5)

			Remotes.ChangeCameraType:FireAllClients(Enum.CameraType.Custom)
			Remotes.DisableMovement:FireAllClients(false)
			if workspace:FindFirstChild("Podiums") then
				workspace.Podiums:Destroy()
			end
			
			--SoundService.Music.VictoryTheme:Stop()
			CameraValues.MVPAwardCam.Value = false
		else
			Remotes.BatResults:FireAllClients("Changing Sides! "..TeamsModule[GameValues[AtBat.Value.."TeamPicked"].Value].City.." will bat next!")
			SoundService.Effects.NewInningChime:Play()
			SoundService.Narration.ChangingSidesNarration:Play()
			wait(6) 
			
			CameraValues.FieldPan.Value = false
		end
		
		wait()
	end
	-- END GAME
	resetGameValues()
	
	if ServerFunctions.GetServerType() == "ReservedServer" then
		for _, player in pairs(PlayerService:GetPlayers()) do
			TeleportService:Teleport(101432174163538, player)
		end
		
		break
	end
	
	local spawnTeleports = {}
	
	for _, spawnTp in pairs(workspace.SpawnLocations:GetChildren()) do
		if spawnTp.Name == "NoTeamSpawn" then
			table.insert(spawnTeleports, spawnTp)
		end
	end
	
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		if player then
			player.TeamColor = Teams["No Team"].TeamColor
			
			ServerFunctions.TeleportPlayerCharacter(player, spawnTeleports[math.random(#spawnTeleports)].CFrame)
		end
	end
	
	awayTeamObj:Destroy()
	homeTeamObj:Destroy()
end