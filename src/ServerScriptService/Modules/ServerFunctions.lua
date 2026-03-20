local ServerFunctions = {}

local Players = game:GetService("Players")
local MarketplaceService =  game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local StarterPlayer = game:GetService("StarterPlayer")

local Remotes = ReplicatedStorage.RemoteEvents
local SharedData = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local Modules = ServerScriptService.Modules
local ServerGUIs = ServerStorage.ServerGUIs
local ServerObjects = ServerStorage.ServerObjects
local GameValues = ReplicatedStorage.GameValues
local SharedObjects = ReplicatedStorage.SharedObjects
local ScoreboardValues = GameValues.ScoreboardValues
local SharedModules = ReplicatedStorage.SharedModules
local Uniforms= ServerStorage.Uniforms
local CurrentGameStatsFolder = ReplicatedStorage.CurrentGameStats
local SharedData = ReplicatedStorage.SharedData
local GearItems = ReplicatedStorage.Gear
local VFXParticlesFB = ReplicatedStorage.VFXParticlesFB
local ShopItems = ReplicatedStorage.ShopItems
local GlovesFolder = ShopItems.Glove
local LoadedBallparkFolder = workspace.LoadedBallpark

local OnBaseTracking = GameValues.OnBase
local SelectPlayerFolder = workspace.SelectPlayers
local FieldCamerasFolder = workspace.FieldCameras

local CollisionGroups = require(SharedModules.CollisionGroups)
local TeamsModule = require(SharedModules.Teams)
local OVRModule = require(Modules.OVRModule)
local GamePassModule = require(SharedModules.GamePasses)
local StylesModule = require(SharedModules.Styles)
local ClientFunctions = require(SharedModules.ClientFunctions)
local DefensiveAbilities = require(Modules.DefensiveAbilities)
local OffensiveAbilities = require(Modules.OffensiveAbilities)
local TransformationEffects = require(Modules.TransformationEffects)
local GameSettings = require(Modules.GameSettings)
local AntiExploit = require(Modules.AntiExploit)

function ServerFunctions.SetupPlayerSelectPositioning(player)
	local character = player.Character
	
	Remotes.DisableMovement:FireClient(player, true)
	
	if character and character:FindFirstChild("UpperTorso") then
		for i = 1, 10 do
			local playerStand = SelectPlayerFolder[tostring(i)]

			if playerStand.Player.Value ==  nil then
				playerStand.Player.Value = player
				playerStand.CanQuery = true

				ServerFunctions.TeleportPlayerCharacter(player, CFrame.new(playerStand.Position, FieldCamerasFolder.CamPlayerSelectOrigin.Position))
				break
			end
		end
	end
end

function ServerFunctions.RemovePlayerSelectPositioning(player)
	for i = 1, 10 do
		local playerStand = SelectPlayerFolder[tostring(i)]

		if playerStand.Player.Value ==  player then
			playerStand.Player.Value = nil
			playerStand.CanQuery = false

			break
		end
	end
end

function ServerFunctions.RemoveBaseTracking(player)
	if player and OnBaseTracking:FindFirstChild(player.Name) ~= nil then
		OnBaseTracking[player.Name]:Destroy()
	end
end

function ServerFunctions.EnableLeadBlockers(enabled)
	for _, part in pairs(workspace.LeadBlockerWalls:GetChildren()) do
		part.CanCollide = enabled
	end
end

function ServerFunctions.EnablePitcherWalls(enabled)
	for _, part in pairs(workspace.PitcherWalls:GetChildren()) do
		part.CanCollide = enabled
	end
end

function ServerFunctions.CalculateBattingOrder(player)
	local battingOrder = 1
	local teamBattingOrders = {}

	for _, otherPlayer in pairs(ClientFunctions.GetPlayersInGame()) do
		if otherPlayer.TeamColor == player.TeamColor then
			local otherPlayerData = SharedData:FindFirstChild(otherPlayer.Name)
			if otherPlayerData and otherPlayerData:FindFirstChild("BattingOrder") then
				teamBattingOrders[otherPlayerData.BattingOrder.Value] = true
			end
		end
	end

	while teamBattingOrders[battingOrder] do
		battingOrder = battingOrder + 1
	end

	local playerData = SharedData:FindFirstChild(player.Name)
	if playerData and playerData:FindFirstChild("BattingOrder") then
		playerData.BattingOrder.Value = battingOrder
	end
end

function ServerFunctions.GetPlayerPositionInBattingQueue(player)
	local playerData = SharedData:FindFirstChild(player.Name)

	local designation;
	local currentBattingQueue

	if player.Team then
		if player.Team.Name == GameValues.AwayTeamPicked.Value then
			designation = "Away"
		elseif player.Team.Name == GameValues.HomeTeamPicked.Value then
			designation = "Home"
		end

		currentBattingQueue = GameValues[designation.."BattingQueue"].Value
	end

	if playerData and playerData:FindFirstChild("BattingOrder") and currentBattingQueue then
		local playerOrder = playerData.BattingOrder.Value

		local maxOrder = 0
		for _, otherPlayer in pairs(ClientFunctions.GetPlayersInGame()) do
			if otherPlayer.TeamColor == player.TeamColor 
				and SharedData:FindFirstChild(otherPlayer.Name) 
				and SharedData[otherPlayer.Name]:FindFirstChild("BattingOrder")
			then
				maxOrder = math.max(maxOrder, SharedData[otherPlayer.Name].BattingOrder.Value)
			end
		end

		local relativePosition = (playerOrder - currentBattingQueue + maxOrder) % maxOrder

		return relativePosition + 1 
	end
end

function ServerFunctions.UpdateBattingOrders(teamName)
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		if player.Team and player.Team.Name == teamName then
			if player.Character and player.Character:FindFirstChild("Head") and player.Character.Head:FindFirstChild('BattingOrderBillboard') then
				player.Character.Head.BattingOrderBillboard.Label.Text = ServerFunctions.GetPlayerPositionInBattingQueue(player)
			end
		end
	end
end

function ServerFunctions.ReadjustBattingOrders(poppedBattingOrder, teamName)
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		if player.Team and player.Team.Name == teamName then
			local playerData = SharedData:FindFirstChild(player.Name)
			if playerData and playerData:FindFirstChild("BattingOrder") then
				local currentOrder = playerData.BattingOrder.Value
				if currentOrder > poppedBattingOrder then
					playerData.BattingOrder.Value = currentOrder - 1
					
					--if player.Character and player.Character:FindFirstChild("Head") and player.Character.Head:FindFirstChild('BattingOrderBillboard') then
					--	player.Character.Head.BattingOrderBillboard.Label.Text = playerData.BattingOrder.Value
					--end
				end
			end
		end
	end
	
	local battingQueue
	if GameValues.HomeTeamPicked.Value == teamName then
		battingQueue = GameValues.HomeBattingQueue
	elseif GameValues.AwayTeamPicked.Value == teamName then
		battingQueue = GameValues.AwayBattingQueue
	end
	
	if battingQueue then
		if battingQueue.Value > poppedBattingOrder then
			battingQueue.Value = battingQueue.Value - 1
		end
	end
	
	--ServerFunctions.UpdateBattingOrders(teamName)
end

function ServerFunctions.GetLastBattingOrderInQueue(designation)
	local lastBattingOrder = 1
	
	for _, player in pairs(ClientFunctions.GetPlayersInGame()) do
		if player.Team and player.Team.Name == GameValues[designation.."TeamPicked"].Value then
			local playerData = SharedData:FindFirstChild(player.Name)
			if playerData and playerData:FindFirstChild("BattingOrder") then
				if playerData.BattingOrder.Value > lastBattingOrder then
					lastBattingOrder = playerData.BattingOrder.Value
				end
			end 
		end
	end

	return lastBattingOrder
end

function ServerFunctions.PlayerIsInGame(player)
	if player ~= nil 
		and Players:FindFirstChild(player.Name) 
		and player.Team ~= nil
		and player.Team.Name ~= "Lobby"
	then
		return true
	else
		return false
	end
end

function ServerFunctions.GiveUniform(player, teamName, designation)
	local shirt = Uniforms[teamName].Shirts[designation]:Clone()
	local pants = Uniforms[teamName].Pants[designation]:Clone()
	
	if player.Character then
		local foundShirt = player.Character:FindFirstChildOfClass("Shirt")
		local foundPants = player.Character:FindFirstChildOfClass("Pants")
		local foundJerseyInfo = player.Character:FindFirstChild("JerseyInfo")
		
		if foundShirt then
			foundShirt:Destroy()
		end
		
		if foundPants then
			foundPants:Destroy()
		end
		
		shirt.Parent = player.Character
		pants.Parent = player.Character
		
		if foundJerseyInfo then
			foundJerseyInfo:Destroy()
		end
		
		local JerseyInfo = ServerObjects.JerseyInfo:Clone()
		JerseyInfo.Parent = player.Character
		
		local weld = Instance.new("Weld", player.Character.UpperTorso)
		weld.Part0 = weld.Parent
		weld.Part1 = JerseyInfo
		weld.C0 = CFrame.new(0, 0, 0)
		
		if _G.sessionData[player] then
			if _G.sessionData[player].Jersey["Number"] == "" then
				local randomNumber = tostring(math.random(1, 99))
				JerseyInfo.Back.Number.Text = randomNumber
				JerseyInfo.Front.Number.Text = randomNumber
			else
				JerseyInfo.Back.Number.Text = _G.sessionData[player].Jersey["Number"]
				JerseyInfo.Front.Number.Text = _G.sessionData[player].Jersey["Number"]
			end
		else
			JerseyInfo.Back.Number.Text = "0"
			JerseyInfo.Front.Number.Text = "0"
		end
		
		if _G.sessionData[player] then
			if _G.sessionData[player].Jersey["Name"] == "" then
				JerseyInfo.Back.PlayerName.Text = player.Name
			else
				JerseyInfo.Back.PlayerName.Text = _G.sessionData[player].Jersey["Name"]
			end
		else
			JerseyInfo.Back.PlayerName.Text = player.Name
		end
		
		if designation == "Away" then
			JerseyInfo.Back.Number.TextColor3 = TeamsModule[teamName].PrimaryColor
			JerseyInfo.Front.Number.TextColor3 = TeamsModule[teamName].PrimaryColor	
			JerseyInfo.Back.PlayerName.TextColor3 = TeamsModule[teamName].PrimaryColor
			JerseyInfo.Front.City.TextColor3 = TeamsModule[teamName].PrimaryColor
		end
		
		JerseyInfo.Back.Number.UIStroke.Color = TeamsModule[teamName].SecondaryColor
		
		JerseyInfo.Front.Number.UIStroke.Color = TeamsModule[teamName].SecondaryColor
		
		JerseyInfo.Back.PlayerName.UIStroke.Color = TeamsModule[teamName].SecondaryColor
		
		JerseyInfo.Front.City.UIStroke.Color = TeamsModule[teamName].SecondaryColor
		JerseyInfo.Front.City.Text = TeamsModule[teamName].City
	end
end

function ServerFunctions.GiveNPCUniform(npcCharacter, teamName, designation)
	local shirt = Uniforms[teamName].Shirts[designation]:Clone()
	local pants = Uniforms[teamName].Pants[designation]:Clone()

	local foundShirt = npcCharacter:FindFirstChildOfClass("Shirt")
	local foundPants = npcCharacter:FindFirstChildOfClass("Pants")

	if foundShirt then
		foundShirt:Destroy()
	end

	if foundPants then
		foundPants:Destroy()
	end

	shirt.Parent = npcCharacter
	pants.Parent = npcCharacter
end

function ServerFunctions.EquipGear(character, gearType, gearName)
	if character then
		if gearType ~= "BattingGlove" then
			for _, part in pairs(character:GetChildren()) do
				if part.Name == gearType then
					part:Destroy()
				end
			end
		end
		
		if gearName ~= "" then
			if gearType == "Wristband" then
				local LWristband = GearItems[gearType][gearName]:Clone()
				LWristband.Name = gearType
				LWristband.Parent = character
				local weld = Instance.new("Weld", character.LeftLowerArm)
				weld.Part0 = weld.Parent
				weld.Part1 = LWristband
				weld.C0 = CFrame.new(0, -0.2, 0)
				
				local RWristband = GearItems[gearType][gearName]:Clone()
				RWristband.Name = gearType
				RWristband.Parent = character
				local weld = Instance.new("Weld", character.RightLowerArm)
				weld.Part0 = weld.Parent
				weld.Part1 = RWristband
				weld.C0 = CFrame.new(0, -0.2, 0)
			end
		end
	end
end

function ServerFunctions.SetupCurrentGameStatsTracking(player)
	if player and CurrentGameStatsFolder:FindFirstChild(player.Name) == nil and _G.sessionData[player] ~= nil then
		local playerCurrentGameStatsFolder = Instance.new("Folder")
		playerCurrentGameStatsFolder.Name = player.Name

		local hittingStatsFolder = Instance.new("Folder", playerCurrentGameStatsFolder)
		hittingStatsFolder.Name = "Hitting"

		for statName, statValue in pairs(_G.sessionData[player].HittingStats) do
			local statVal = Instance.new("NumberValue")
			statVal.Name = statName
			statVal.Parent = hittingStatsFolder
		end

		local pitchingStatsFolder = Instance.new("Folder", playerCurrentGameStatsFolder)
		pitchingStatsFolder.Name = "Pitching"

		for statName, statValue in pairs(_G.sessionData[player].PitchingStats) do
			local statVal = Instance.new("NumberValue")
			statVal.Name = statName
			statVal.Parent = pitchingStatsFolder
		end

		local outfieldStatsFolder = Instance.new("Folder", playerCurrentGameStatsFolder)
		outfieldStatsFolder.Name = "Outfield"

		for statName, statValue in pairs(_G.sessionData[player].OutfieldStats) do
			local statVal = Instance.new("NumberValue")
			statVal.Name = statName
			statVal.Parent = outfieldStatsFolder
		end

		local gameStatsFolder = Instance.new("Folder", playerCurrentGameStatsFolder)
		gameStatsFolder.Name = "Game"

		for statName, statValue in pairs(_G.sessionData[player].GameStats) do
			local statVal = Instance.new("NumberValue")
			statVal.Name = statName
			statVal.Parent = gameStatsFolder
		end
		
		local teamVal = Instance.new("StringValue")
		teamVal.Name = "PlayerTeam"
		teamVal.Value = player.Team.Name
		teamVal.Parent = playerCurrentGameStatsFolder
		
		local userID = Instance.new("IntValue")
		userID.Name = "UserID"
		userID.Value = player.UserId
		userID.Parent = playerCurrentGameStatsFolder

		playerCurrentGameStatsFolder.Parent = CurrentGameStatsFolder
	end
end

function ServerFunctions.DeleteCurrentGameStatsTracking(player)
	CurrentGameStatsFolder:ClearAllChildren()
end

function ServerFunctions.AddStat(player, statType, statVal, increment)	
	if player and _G.sessionData[player] then
		if game.PrivateServerOwnerId <= 0 and game.PlaceId ~= 82183144153025 and #ClientFunctions.GetPlayersInGame() >= 4 then
			_G.sessionData[player][statType.."Stats"][statVal] = _G.sessionData[player][statType.."Stats"][statVal] + increment
			
			if SharedData:FindFirstChild(player.Name) then
				SharedData[player.Name].Stats[statType][statVal].Value = _G.sessionData[player][statType.."Stats"][statVal]
			end

			if OVRModule.StatXPMappings[statType] ~= nil and OVRModule.StatXPMappings[statType][statVal] ~= nil then
				OVRModule.BoostXP(player, OVRModule.StatXPMappings[statType][statVal])

				local coinsEarned = math.ceil(OVRModule.StatXPMappings[statType][statVal] / 4)

				ServerFunctions.CashTransaction(player, coinsEarned, true, true)
			end	
		end
		
		if CurrentGameStatsFolder:FindFirstChild(player.Name) then
			CurrentGameStatsFolder[player.Name][statType][statVal].Value = CurrentGameStatsFolder[player.Name][statType][statVal].Value + increment
		end
	end
end

function ServerFunctions.SubtractStat(player, statType, statVal, decrement)	
	if player and _G.sessionData[player] then
		if game.PrivateServerOwnerId <= 0 and game.PlaceId ~= 82183144153025 then
			_G.sessionData[player][statType.."Stats"][statVal] = _G.sessionData[player][statType.."Stats"][statVal] - decrement

			if SharedData:FindFirstChild(player.Name) then
				SharedData[player.Name].Stats[statType][statVal].Value = _G.sessionData[player][statType.."Stats"][statVal]
			end
		end

		if CurrentGameStatsFolder:FindFirstChild(player.Name) then
			CurrentGameStatsFolder[player.Name][statType][statVal].Value = CurrentGameStatsFolder[player.Name][statType][statVal].Value - decrement
		end
	end
end

function ServerFunctions.AddFieldingAssistStats(putoutCatcher)
	for _, assistTracker in pairs(GameValues.AssistsTracker:GetChildren()) do
		if assistTracker.Value ~= nil and assistTracker.Value ~= putoutCatcher then
			ServerFunctions.AddStat(assistTracker.Value, "Outfield", "Assists", 1)
		end
	end
end

function ServerFunctions.CashTransaction(player, amount, isPayment, isEarned)
	if isPayment then
		if isEarned then
			local success, playerHasPass = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GamePassModule.PassIDs["2X Coins"])
			end)
			
			if game.PrivateServerOwnerId > 0 or game.PlaceId == 82183144153025 then
				amount = amount / 2
			end
			
			if playerHasPass then
				amount = amount * 2
			end
		end
		
		if _G.sessionData[player] then
			_G.sessionData[player].Cash = _G.sessionData[player].Cash + amount
		end
	else
		if _G.sessionData[player] then
			_G.sessionData[player].Cash = _G.sessionData[player].Cash - amount
		end
	end
	
	if SharedData:FindFirstChild(player.Name) then
		SharedData[player.Name].Cash.Value = _G.sessionData[player].Cash
	end
end

function ServerFunctions.AwardSpin(player, amount)
	if game.PrivateServerOwnerId > 0 or game.PlaceId == 82183144153025 then return end
	
	_G.sessionData[player].StyleSpins = _G.sessionData[player].StyleSpins + amount
	SharedData[player.Name].StyleSpins.Value = _G.sessionData[player].StyleSpins
	Remotes.Notification:FireClient(player, "You were awarded "..amount.." Style Spins!")
end

function ServerFunctions.IncreaseFieldingPower(player, amount)
	if player and _G.sessionData[player] then
		local equippedDefensiveStyle = StylesModule.GetEquippedStyleName(player, "Defensive")
		
		if equippedDefensiveStyle and StylesModule.DefensiveStyles[equippedDefensiveStyle] and SharedData:FindFirstChild(player.Name) then
			if StylesModule.DefensiveStyles[equippedDefensiveStyle].SubType == "Fielding" then
				if SharedData[player.Name].FieldingPower.Value + amount > 100 then
					SharedData[player.Name].FieldingPower.Value = 100
				else
					SharedData[player.Name].FieldingPower.Value = SharedData[player.Name].FieldingPower.Value + amount
				end

				Remotes.UpdateFieldingPower:FireClient(player, equippedDefensiveStyle)
				SharedData[player.Name].ActivatedFBAbility.Value = false
				SharedData[player.Name].ActivatedFBAbility.PowerActivated.Value = ""
			end
		end
	end
end

function ServerFunctions.IncreaseBaserunningPower(player, amount)
	if player and _G.sessionData[player] then
		local equippedOffensiveStyle = StylesModule.GetEquippedStyleName(player, "Offensive")

		if equippedOffensiveStyle and StylesModule.OffensiveStyles[equippedOffensiveStyle] and SharedData:FindFirstChild(player.Name) then
			if StylesModule.OffensiveStyles[equippedOffensiveStyle].SubType == "Baserunning" then
				if SharedData[player.Name].BaserunningPower.Value + amount > 100 then
					SharedData[player.Name].BaserunningPower.Value = 100
				else
					SharedData[player.Name].BaserunningPower.Value = SharedData[player.Name].BaserunningPower.Value + amount
				end

				Remotes.UpdateBaserunningPower:FireClient(player, equippedOffensiveStyle)
				SharedData[player.Name].ActivatedFBAbility.Value = false
				SharedData[player.Name].ActivatedFBAbility.PowerActivated.Value = ""
			end
		end
	end
end

function ServerFunctions.IncreasePitchingPower(player, amount)
	if player and _G.sessionData[player] then
		local equippedDefensiveStyle = StylesModule.GetEquippedStyleName(player, "Defensive")
		
		if equippedDefensiveStyle and StylesModule.DefensiveStyles[equippedDefensiveStyle] and SharedData:FindFirstChild(player.Name) then
			if StylesModule.DefensiveStyles[equippedDefensiveStyle].SubType == "Pitching" and GameValues.CurrentPitcher.Value == player then
				if SharedData[player.Name].PitchingPower.Value + amount > 100 then
					SharedData[player.Name].PitchingPower.Value = 100
				else
					SharedData[player.Name].PitchingPower.Value = SharedData[player.Name].PitchingPower.Value + amount
				end
			end
		end
	end
end

function ServerFunctions.IncreaseHittingPower(player, amount)
	if player and _G.sessionData[player] then
		local equippedOffensiveStyle = StylesModule.GetEquippedStyleName(player, "Offensive")

		if equippedOffensiveStyle and StylesModule.OffensiveStyles[equippedOffensiveStyle] and SharedData:FindFirstChild(player.Name) then
			if StylesModule.OffensiveStyles[equippedOffensiveStyle].SubType == "Hitting" and GameValues.CurrentBatter.Value == player then
				if SharedData[player.Name].HittingPower.Value + amount > 100 then
					SharedData[player.Name].HittingPower.Value = 100
				else
					SharedData[player.Name].HittingPower.Value = SharedData[player.Name].HittingPower.Value + amount
				end
			end
		end
	end
end

function ServerFunctions.SetupFieldingPower(player) 
	if _G.sessionData[player] then
		local equippedDefensiveStyle = StylesModule.GetEquippedStyleName(player, "Defensive")
		
		if equippedDefensiveStyle and StylesModule.DefensiveStyles[equippedDefensiveStyle] 
			and StylesModule.DefensiveStyles[equippedDefensiveStyle].SubType == "Fielding" 
		then
			Remotes.SetupFieldingPower:FireClient(player, true, equippedDefensiveStyle)
		else
			Remotes.SetupFieldingPower:FireClient(player, false)
		end
	end
end

function ServerFunctions.SetupBaserunningPower(player) 
	if _G.sessionData[player] then
		local equippedOffensiveStyle = StylesModule.GetEquippedStyleName(player, "Offensive")

		if equippedOffensiveStyle and StylesModule.OffensiveStyles[equippedOffensiveStyle] 
			and StylesModule.OffensiveStyles[equippedOffensiveStyle].SubType == "Baserunning" 
		then
			Remotes.SetupBaserunningPower:FireClient(player, true, equippedOffensiveStyle)
		else
			Remotes.SetupBaserunningPower:FireClient(player, false)
		end
	end
end

function ServerFunctions.EquipStyle(player, styleType, styleName, slotNum)
	-- If slotNum is provided, this is a normal equip from inventory
	if slotNum ~= nil then
		_G.sessionData[player]["Equipped"..styleType.."Style"] = slotNum
		_G.sessionData[player]["Equipped"..styleType.."LimitedStyle"] = nil
	else
		_G.sessionData[player]["Equipped"..styleType.."LimitedStyle"] = styleName
	end
	
	if styleType == "Defensive" and ClientFunctions.PlayerIsDefender(player) then
		ServerFunctions.SetupFieldingPower(player) 
	elseif styleType == "Offensive" and ClientFunctions.PlayerIsOffense(player) then
		ServerFunctions.SetupBaserunningPower(player)
	end
end

function ServerFunctions.DisableFBAbility(player)
	if _G.sessionData[player] and SharedData:FindFirstChild(player.Name) and SharedData[player.Name].ActivatedFBAbility.Value then
		if ClientFunctions.PlayerIsDefender(player) then
			local equippedDefensiveStyle = StylesModule.GetEquippedStyleName(player, "Defensive")
			
			if DefensiveAbilities[equippedDefensiveStyle] and DefensiveAbilities[equippedDefensiveStyle]["Clear"] then
				DefensiveAbilities[equippedDefensiveStyle].Clear(player)
			end
		elseif ClientFunctions.PlayerIsOffense(player) then
			local equippedOffensiveStyle = StylesModule.GetEquippedStyleName(player, "Offensive")

			if OffensiveAbilities[equippedOffensiveStyle] and OffensiveAbilities[equippedOffensiveStyle]["Clear"] then
				OffensiveAbilities[equippedOffensiveStyle].Clear(player)
			end
		end
	end
end

function ServerFunctions.EnableFBAbility(player, styleType, abilityName)
	if _G.sessionData[player] then
		if ClientFunctions.PlayerIsDefender(player) then
			if abilityName == StylesModule.DefensiveStyles[styleType].Ability then
				TransformationEffects.AbilityActivateEffect(player)
				
				if DefensiveAbilities[styleType] and DefensiveAbilities[styleType].Ability then
					DefensiveAbilities[styleType].Ability(player)
				end
				
			elseif abilityName == StylesModule.DefensiveStyles[styleType].Ultimate then
				TransformationEffects.UltimateActivateEffect(player)
				
				if DefensiveAbilities[styleType] and DefensiveAbilities[styleType].Ultimate then
					DefensiveAbilities[styleType].Ultimate(player)
				end
			end
		elseif (ClientFunctions.PlayerIsBaserunner(player) or player == GameValues.CurrentBatter.Value) then
			if abilityName == StylesModule.OffensiveStyles[styleType].Ability then
				TransformationEffects.AbilityActivateEffect(player)

				if OffensiveAbilities[styleType] and OffensiveAbilities[styleType].Ability then
					OffensiveAbilities[styleType].Ability(player)
				end

			elseif abilityName == StylesModule.OffensiveStyles[styleType].Ultimate then
				TransformationEffects.UltimateActivateEffect(player)

				if OffensiveAbilities[styleType] and OffensiveAbilities[styleType].Ultimate then
					OffensiveAbilities[styleType].Ultimate(player)
				end
			end
		end
	end
end

function ServerFunctions.GiveGlove(player)
	if player and player.Character then
		local Character = player.Character

		-- clear old glove
		if Character:FindFirstChild("PlayerGlove") then
			Character.PlayerGlove:Destroy()
		end

		-- find which glove to equip
		local EquippedGlove
		if _G.sessionData[player] then
			EquippedGlove = _G.sessionData[player].EquippedGlove
		else
			EquippedGlove = "Old Glove"
		end

		local Gloves = ReplicatedStorage.ShopItems.Glove
		local GloveModel = Gloves:FindFirstChild(EquippedGlove)
		local Glove

		if GloveModel then
			Glove = GloveModel:Clone()
			Glove.Name = "PlayerGlove"
			Glove.Parent = Character

			local MeshPart = Glove:FindFirstChild("MeshPart")
			local LeftHand = Character:FindFirstChild("LeftHand")

			if MeshPart and LeftHand then
				local gloveWeld

				-- use the glove’s own weld if it exists
				local customWeld = Glove:FindFirstChild("GloveWeld")
				if customWeld then
					gloveWeld = customWeld
				else
					-- otherwise fall back to default
					gloveWeld = ServerStorage.ServerObjects.GloveWeld:Clone()
					gloveWeld.Parent = MeshPart
				end

				-- set weld attachments
				gloveWeld.Part0 = MeshPart
				gloveWeld.Part1 = LeftHand
			end
		end
	end
end


function ServerFunctions.ResetArms(player)
	if player.Character then
		local leftUpperArm = player.Character:FindFirstChild("LeftUpperArm")
		local upperTorso = player.Character:FindFirstChild("UpperTorso")

		local lShoulder

		if leftUpperArm and leftUpperArm:FindFirstChild("LeftShoulder") then
			lShoulder = leftUpperArm["LeftShoulder"]
		end

		if lShoulder and upperTorso then
			lShoulder.C0 = StarterPlayer.StarterCharacter.LeftUpperArm.LeftShoulder.C0
			lShoulder.C1 = StarterPlayer.StarterCharacter.LeftUpperArm.LeftShoulder.C1

			if upperTorso:FindFirstChild("LAWeld") then
				upperTorso["LAWeld"]:Destroy()
			end
		end
	end
end

function ServerFunctions.TeleportPlayerCharacter(player, cframePos)
	if player then
		local character = player.Character
		
		if character and character:FindFirstChild("HumanoidRootPart") then
			AntiExploit.Ignore(player, 2)
			Remotes.CancelSlideDive:FireClient(player)
			
			character.HumanoidRootPart.Anchored = true

			character:PivotTo(cframePos)
			Remotes.CFramePlayerCharacter:FireClient(player, cframePos)

			character.HumanoidRootPart.Anchored = false
		end
	end
end

function ServerFunctions.ShowOffBat(player, enabled)
	if enabled then
		if ClientFunctions.PlayerIsDefender(player) or OnBaseTracking:FindFirstChild(player.Name) then
			return
		end
		
		if player.Character and player.Character:FindFirstChild("RightHand") then
			if player.Character:FindFirstChild("PlayerBatDisplay") then
				player.Character.PlayerBatDisplay:Destroy()
			end
			
			local batName

			if _G.sessionData[player] then
				batName = _G.sessionData[player].EquippedBat or "Wooden Bat"
			else
				batName = "Wooden Bat"
			end

			if ReplicatedStorage.ShopItems.Bat:FindFirstChild(batName) then
				local bat = ReplicatedStorage.ShopItems.Bat:FindFirstChild(batName):Clone()

				bat.Name = "PlayerBatDisplay"
				bat.Parent = player.Character

				local weld = ServerStorage.ServerObjects.BackupBatWeld:Clone()
				weld.Parent = player.Character.RightHand
				weld.Part0 = player.Character.RightHand
				weld.Part1 = bat.Handle
				
				Remotes.ShowOffBat:FireClient(player, true)
			end
		end
	else
		if player.Character and player.Character:FindFirstChild("PlayerBatDisplay") then
			player.Character.PlayerBatDisplay:Destroy()
		end
		
		Remotes.ShowOffBat:FireClient(player, false)
	end
end

function ServerFunctions.LoadRobloxCharacterOutfit(humanoid, userID)
	local oldHumanoidDescription = Players:GetHumanoidDescriptionFromUserId(userID)

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
end

function ServerFunctions.StyleSlotUpgrade(player, styleType)
	local key = styleType.."StyleSlots"
	local inventoryKey = styleType.."StyleInventory"
	local equippedStyleKey = `Equipped{styleType}Style`
	
	if _G.sessionData[player][key] >= 6 then return end
	
	local starterStyle;
	
	if styleType == "Offensive" then
		starterStyle = "Heat"
	elseif styleType == "Defensive" then
		starterStyle = "Acrobat"
	end
	
	_G.sessionData[player][key] = _G.sessionData[player][key] + 1
	SharedData[player.Name][key].Value = _G.sessionData[player][key]

	local newSlotNum = _G.sessionData[player][key]

	_G.sessionData[player][inventoryKey][newSlotNum] = {["StyleName"] = starterStyle, ["Reserved"] = false}

	Remotes.StyleSlotUpgrade:FireClient(player, styleType, _G.sessionData[player][inventoryKey], starterStyle, _G.sessionData[player][equippedStyleKey])
	Remotes.Notification:FireClient(player, `Purchased an additional {styleType} Style Slot!`)
end

function ServerFunctions.GetServerType()
	if game.PrivateServerId ~= "" then
		if game.PrivateServerOwnerId ~= 0 or game.PlaceId == 82183144153025 then
			return "PrivateServer"
		else
			return "ReservedServer"
		end
	else
		return "PublicServer"
	end
end

return ServerFunctions
