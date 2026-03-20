local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local Remotes = ReplicatedStorage.RemoteEvents
local AdminEvents = ReplicatedStorage.AdminEvents
local BallHolder = workspace.BallHolder
local SharedModules = ReplicatedStorage.SharedModules
local GameValues = ReplicatedStorage.GameValues
local ScoreboardValues = GameValues.ScoreboardValues
local SharedData = ReplicatedStorage.SharedData
local Modules = ServerScriptService.Modules

local StylesModule = require(SharedModules.Styles) 
local ServerFunctions = require(Modules.ServerFunctions)
local BaseballFunctions = require(Modules.BaseballFunctions)
	
local function isAuthorized(player)
	if player.Name == "VRYLLION" or player.Name == "Randy_Moss" or player.Name == "SafetyEdReed" or player.UserId < 0 then
		return true
	else
		return false
	end
end

local function isPrivateServerOwner(player)
	if player.UserId == game.PrivateServerOwnerId or player.UserId == GameValues.LeagueServerOwnerID.Value then
		return true
	else
		return false
	end
end

AdminEvents.KickPlayer.OnServerEvent:Connect(function(player, otherPlayerName)
	if isPrivateServerOwner(player) or isAuthorized(player) then
		local playerFound = Players:FindFirstChild(otherPlayerName)

		if playerFound and playerFound ~= player then
			playerFound:Kick("You have been kicked by the private server owner")
			Remotes.Notification:FireAllClients(playerFound.name.." was kicked by the private server owner")
		end
	end
end)

AdminEvents.PowerUps.OnServerEvent:Connect(function(player)
	if isPrivateServerOwner(player) or isAuthorized(player) then
		GameValues.PowerUpsEnabled.Value = not GameValues.PowerUpsEnabled.Value
		
		if GameValues.PowerUpsEnabled.Value then
			Remotes.Notification:FireAllClients("Power Ups were enabled by the private server owner")
		else
			Remotes.Notification:FireAllClients("Power Ups were disabled by the private server owner")
		end
	end
end)

AdminEvents.SetPlayerTeam.OnServerEvent:Connect(function(player, otherPlayerName, teamDesignation)
	if isPrivateServerOwner(player) or isAuthorized(player) then
		local playerFound = Players:FindFirstChild(otherPlayerName)
		
		if playerFound then
			local teamName = GameValues[teamDesignation.."TeamPicked"].Value
			
			local returningPlayerTeam = playerFound.Team.Name
			
			local playerLeavingBattingOrder
			local sharedData = SharedData:FindFirstChild(playerFound.Name)
			
			if sharedData and sharedData:FindFirstChild("BattingOrder") then
				playerLeavingBattingOrder = sharedData.BattingOrder.Value
				sharedData.BattingOrder.Value = 0
			end
			
			if sharedData and sharedData:FindFirstChild("PitcherVotes") then
				local pitcherVotedFor = sharedData.PitcherVotes.PitcherVotedFor.Value

				if SharedData:FindFirstChild(pitcherVotedFor) and SharedData[pitcherVotedFor].PitcherVotes.Value > 0 then 
					SharedData[pitcherVotedFor].PitcherVotes.Value = SharedData[pitcherVotedFor].PitcherVotes.Value - 1
				end

				sharedData.PitcherVotes.PitcherVotedFor.Value = ""
				sharedData.PitcherVotes.Value = 0
			end
			
			ServerFunctions.ReadjustBattingOrders(playerLeavingBattingOrder, returningPlayerTeam)

			ServerFunctions.RemovePlayerSelectPositioning(playerFound)
			ServerFunctions.RemoveBaseTracking(playerFound)

			if GameValues.CurrentBatter.Value == playerFound then
				GameValues.CurrentBatter.Value = nil
			end

			if GameValues.CurrentPitcher.Value == playerFound then
				GameValues.CurrentPitcher.Value = nil
			end
			
			if Teams:FindFirstChild(teamName) then
				playerFound.TeamColor = Teams[teamName].TeamColor
				
				if Teams[GameValues.AwayTeamPicked.Value].TeamColor == playerFound.TeamColor then
					ServerFunctions.CalculateBattingOrder(playerFound)
				elseif Teams[GameValues.HomeTeamPicked.Value].TeamColor == playerFound.TeamColor then
					ServerFunctions.CalculateBattingOrder(playerFound)
				end

				if ScoreboardValues.AtBat.Value ~= "" 
					and GameValues[ScoreboardValues.AtBat.Value.."TeamPicked"].Value == playerFound.Team.Name 
					and GameValues.GameActive.Value
				then
					Remotes.EnableBattingOrderGui:FireAllClients(true, playerFound.Team)
				end
				
				playerFound:LoadCharacter()
				Remotes.Notification:FireClient(player, "Admin: "..otherPlayerName.."'s team changed to "..teamName.." ("..teamDesignation..")")
			end
		end
	end
end) 

AdminEvents.CurrentBatterOut.OnServerEvent:Connect(function(player)
	if isAuthorized(player) then
		BaseballFunctions.PlayerOut(GameValues.CurrentBatter.Value)
		ScoreboardValues.Outs.Value = ScoreboardValues.Outs.Value - 1
	end
end)

AdminEvents.SetWalkSpeed.OnServerEvent:Connect(function(player, walkspeed)
	if isAuthorized(player) then
		if typeof(walkspeed) == "number" and walkspeed <= 100 and walkspeed >= 16 then
			player.Character.Humanoid.WalkSpeed = walkspeed

			Remotes.Notification:FireClient(player, "Admin: Walkspeed changed to "..walkspeed)
		end
	end
end)

AdminEvents.BallTeleport.OnServerEvent:Connect(function(player)
	if isAuthorized(player) then
		if BallHolder:FindFirstChild("Baseball") then
			player.Character.HumanoidRootPart.CFrame = BallHolder["Baseball"].CFrame
			
			Remotes.Notification:FireClient(player, "Admin: Teleported to the ball")
		end
	end
end)

AdminEvents.SetDefensiveStyle.OnServerEvent:Connect(function(player, styleName)
	if isAuthorized(player) then
		if StylesModule.DefensiveStyles[styleName] ~= nil then
			_G.sessionData[player].DefensiveStyleInventory[1] = {["StyleName"] = styleName, ["Reserved"] = false}
			ServerFunctions.EquipStyle(player, "Defensive", styleName, 1)
			Remotes.Notification:FireClient(player, "Admin: Defensive style set to "..styleName)
		else
			Remotes.Notification:FireClient(player, "Admin: Invalid defensive style entered")
		end
	end
end)

AdminEvents.SetOffensiveStyle.OnServerEvent:Connect(function(player, styleName)
	if isAuthorized(player) then
		if StylesModule.OffensiveStyles[styleName] ~= nil then
			_G.sessionData[player].OffensiveStyleInventory[1] = {["StyleName"] = styleName, ["Reserved"] = false}
			ServerFunctions.EquipStyle(player, "Offensive", styleName, 1)
			Remotes.Notification:FireClient(player, "Admin: Offensive style set to "..styleName)
		else
			Remotes.Notification:FireClient(player, "Admin: Invalid offensive style entered")
		end
	end
end)

AdminEvents.ChangeOuts.OnServerEvent:Connect(function(player, action)
	if isAuthorized(player) or isPrivateServerOwner(player) then
		if action == "Add" then
			if ScoreboardValues.Outs.Value < 3 then
				ScoreboardValues.Outs.Value = ScoreboardValues.Outs.Value + 1
				Remotes.Notification:FireAllClients("Server: Outs increased by 1")
			end
		elseif action == "Subtract" then
			if ScoreboardValues.Outs.Value > 0 then
				ScoreboardValues.Outs.Value = ScoreboardValues.Outs.Value - 1
				Remotes.Notification:FireAllClients("Server: Outs decreased by 1")
			end
		end
	end
end)

AdminEvents.ChangeBalls.OnServerEvent:Connect(function(player, action)
	if isAuthorized(player) or isPrivateServerOwner(player) then
		if action == "Add" then
			if ScoreboardValues.Balls.Value < 4 then
				ScoreboardValues.Balls.Value = ScoreboardValues.Balls.Value + 1
				Remotes.Notification:FireAllClients("Server: Balls increased by 1")
			end
		elseif action == "Subtract" then
			if ScoreboardValues.Balls.Value > 0 then
				ScoreboardValues.Balls.Value = ScoreboardValues.Balls.Value - 1
				Remotes.Notification:FireAllClients("Server: Balls decreased by 1")
			end
		end
	end
end)

AdminEvents.ChangeStrikes.OnServerEvent:Connect(function(player, action)
	if isAuthorized(player) or isPrivateServerOwner(player) then
		if action == "Add" then
			if ScoreboardValues.Strikes.Value < 3 then
				ScoreboardValues.Strikes.Value = ScoreboardValues.Strikes.Value + 1
				Remotes.Notification:FireAllClients("Server: Strikes increased by 1")
			end
		elseif action == "Subtract" then
			if ScoreboardValues.Strikes.Value > 0 then
				ScoreboardValues.Strikes.Value = ScoreboardValues.Strikes.Value - 1
				Remotes.Notification:FireAllClients("Server: Strikes decreased by 1")
			end
		end
	end
end)

AdminEvents.ChangeInning.OnServerEvent:Connect(function(player, action)
	if isAuthorized(player) or isPrivateServerOwner(player) then
		if action == "Add" then
			if ScoreboardValues.Inning.Value < 7 then
				ScoreboardValues.Inning.Value = ScoreboardValues.Inning.Value + 1
				Remotes.Notification:FireAllClients("Server: Inning increased by 1")
			end
		elseif action == "Subtract" then
			if ScoreboardValues.Inning.Value > 1 then
				ScoreboardValues.Inning.Value = ScoreboardValues.Inning.Value - 1
				Remotes.Notification:FireAllClients("Server: Inning decreased by 1")
			end
		end
	end
end)

AdminEvents.HomeScore.OnServerEvent:Connect(function(player, action)
	if isAuthorized(player) or isPrivateServerOwner(player) then
		if action == "Add" then
			if ScoreboardValues.HomeScore.Value < 100 then
				ScoreboardValues.HomeScore.Value = ScoreboardValues.HomeScore.Value + 1
				Remotes.Notification:FireAllClients("Server: Home Score increased by 1")
			end
		elseif action == "Subtract" then
			if ScoreboardValues.HomeScore.Value > 0 then
				ScoreboardValues.HomeScore.Value = ScoreboardValues.HomeScore.Value - 1
				Remotes.Notification:FireAllClients("Server: Home Score decreased by 1")
			end
		end
	end
end)

AdminEvents.AwayScore.OnServerEvent:Connect(function(player, action)
	if isAuthorized(player) or isPrivateServerOwner(player) then
		if action == "Add" then
			if ScoreboardValues.AwayScore.Value < 100 then
				ScoreboardValues.AwayScore.Value = ScoreboardValues.AwayScore.Value + 1
				Remotes.Notification:FireAllClients("Server: Away Score increased by 1")
			end
		elseif action == "Subtract" then
			if ScoreboardValues.AwayScore.Value > 0 then
				ScoreboardValues.AwayScore.Value = ScoreboardValues.AwayScore.Value - 1
				Remotes.Notification:FireAllClients("Server: Away Score decreased by 1")
			end
		end
	end
end)

AdminEvents.IncreaseFieldingPower.OnServerEvent:Connect(function(player)
	if isAuthorized(player) then
		ServerFunctions.IncreaseFieldingPower(player, 10)
		Remotes.Notification:FireClient(player, "Admin: Fielding power increased by 10% (Current: "..SharedData[player.Name].FieldingPower.Value.."%)")
	end
end)

AdminEvents.IncreaseBaserunningPower.OnServerEvent:Connect(function(player)
	if isAuthorized(player) then
		ServerFunctions.IncreaseBaserunningPower(player, 10)
		Remotes.Notification:FireClient(player, "Admin: Baserunning power increased by 10% (Current: "..SharedData[player.Name].BaserunningPower.Value.."%)")
	end
end)

AdminEvents.IncreasePitchingPower.OnServerEvent:Connect(function(player)
	if isAuthorized(player) then
		ServerFunctions.IncreasePitchingPower(player, 10)
		Remotes.Notification:FireClient(player, "Admin: Pitching power increased by 10% (Current: "..SharedData[player.Name].PitchingPower.Value.."%)")
	end
end)

AdminEvents.IncreaseHittingPower.OnServerEvent:Connect(function(player)
	if isAuthorized(player) then
		ServerFunctions.IncreaseHittingPower(player, 10)
		Remotes.Notification:FireClient(player, "Admin: Hitting power increased by 10% (Current: "..SharedData[player.Name].HittingPower.Value.."%)")
	end
end)

AdminEvents.IsPrivateServerOwner.OnServerInvoke = function(player)
	if game.PrivateServerOwnerId == player.UserId or GameValues.LeagueServerOwnerID.Value == player.UserId then
		return true
	else
		return false
	end
end