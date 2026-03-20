local PlayerService = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local ServerScriptService = game:GetService("ServerScriptService")
local TextService = game:GetService("TextService")
local TeleportService = game:GetService("TeleportService")

local SharedGUIs = ReplicatedStorage.SharedGUIs
local ServerGUIs = ServerStorage.ServerGUIs
local SharedData = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local SharedObjects = ReplicatedStorage.SharedObjects
local Modules = ServerScriptService.Modules
local GameValues = ReplicatedStorage.GameValues
local OnBase = GameValues.OnBase
local MessageValues = GameValues.MessageValues
local Remotes = ReplicatedStorage.RemoteEvents
local FieldCameras = workspace.FieldCameras
local ServerObjects = ServerStorage.ServerObjects
local Services = ServerScriptService.Services

local TeamsModule = require(SharedModules.Teams)
local ServerFunctions = require(Modules.ServerFunctions)
local ClientFunctions = require(SharedModules.ClientFunctions)
local RarityProbability = require(SharedModules.RarityProbability)
local ShopPackItemsModule = require(SharedModules.ShopPackItems)
local ShopPackTypesModule = require(SharedModules.ShopPackTypes)
local GearItemModule = require(SharedModules.GearItems)
local GamePassModule = require(SharedModules.GamePasses)
local StylesModule = require(SharedModules.Styles)
local SpinCostsModule = require(SharedModules.SpinCosts)
local RewardCodesModule = require(Services.Rewards.RewardCodes)
local RankedSystem = require(Modules.RankedSystem)
local OffensiveAbilities = require(Modules.OffensiveAbilities)
local DefensiveAbilities = require(Modules.DefensiveAbilities)
local AntiExploit = require(Modules.AntiExploit)
local BaseballFunctions = require(Modules.BaseballFunctions)

Remotes.ResetCharacter.OnServerEvent:Connect(function(player)
	if ClientFunctions.PlayerIsInGame(player) then
		Remotes.Notification:FireClient(player, "Return to the lobby to reset your character", "Alert")
	else
		if RankedSystem.PlayerIsInLobbyParty(player) then return end
		
		player:LoadCharacter()
	end
end)

Remotes.TeamSelect.OnServerEvent:Connect(function(player, teamName)
	if MessageValues.Status.Value == "Captains selecting Teams" then
		local homeCaptain = GameValues.HomeCaptain.Value
		local awayCaptain = GameValues.AwayCaptain.Value
		
		local homeTeamPicked = GameValues.HomeTeamPicked.Value
		local awayTeamPicked = GameValues.AwayTeamPicked.Value
		
		if TeamsModule[teamName] ~= nil and (homeTeamPicked ~= teamName and awayTeamPicked ~= teamName) then
			if player == homeCaptain then
				GameValues.HomeTeamPicked.Value = teamName
			elseif player == awayCaptain then
				GameValues.AwayTeamPicked.Value = teamName
			end
		end
	end
end)

Remotes.PlaySlidingVFX.OnServerEvent:Connect(function(player, enabled)
	if player.Character 
		and (OnBase:FindFirstChild(player.Name) or ClientFunctions.PlayerIsDefender(player))
		and player.Character:FindFirstChild("UpperTorso")
	then
		if player.Character.UpperTorso:FindFirstChild("SlidingEffects") then
			player.Character.UpperTorso.SlidingEffects:Destroy()
		end
		
		if enabled then
			AntiExploit.Ignore(player, 1.5)
			
			local slidingEffects = ReplicatedStorage.VFX.Slide.SlidingEffects:Clone()
			slidingEffects.Parent = player.Character.UpperTorso
			
			local s = Instance.new("Sound")
			s.SoundId = "rbxassetid://9114658159"
			s.Volume  = 0.5
			s.TimePosition = 0
			s.Parent  = player.Character.UpperTorso
			s:Play()
			game.Debris:AddItem(s, 1.5)
			
			wait(1.5)
			if slidingEffects then
				slidingEffects:Destroy()
			end
		end
	end
end)

Remotes.BattingCage.ExitBattingPractice.OnServerEvent:Connect(function(player)
	if player == GameValues.CurrentBatter.Value then return end
	
	BaseballFunctions.UnSetupPlayer(player)
	
	if GameValues.GameActive.Value 
		and ClientFunctions.PlayerIsOffense(player) 
		and GameValues.CurrentBatter.Value ~= player
	then
		BaseballFunctions.GiveBattingPracticeGui(player)
	end
end)

Remotes.BattingCage.SetupBattingCageCharacter.OnServerInvoke = function(player)
	if workspace.BattingCage:FindFirstChild("AIPitcher") == nil then
		local AIPitcher = ServerStorage.AIs.AI:Clone()
		AIPitcher.Name = "AIPitcher"
		AIPitcher.Animate:Destroy()
		AIPitcher.HumanoidRootPart.Anchored = true
		ServerObjects.AnimeHighlight:Clone().Parent = AIPitcher
		SharedObjects["Baseball Cap"]:Clone().Parent = AIPitcher
		ServerFunctions.GiveNPCUniform(AIPitcher, "Los Angeles 2", "Away")
		AIPitcher.Parent = workspace.BattingCage
		BaseballFunctions.SetUpAIPitcher(AIPitcher, workspace.BattingCage.Pitching.AIMound)
	end
	
	local battingCageCharacter = ServerStorage.ServerObjects.StylesLockerCharacter:Clone()
	battingCageCharacter.Name = "BattingCageCharacter"
	battingCageCharacter.Parent = workspace
	local teamName = player.Team.Name
	local teamName = player.Team.Name

	if teamName == "No Team" or teamName == "Lobby" then
		teamName = "Los Angeles 2"
	end
	
	pcall(function()
		local oldHumanoidDescription = PlayerService:GetHumanoidDescriptionFromUserId(player.UserId)

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

		battingCageCharacter.Humanoid:ApplyDescription(newHumanoidDescription)
	end)
	
	if GameValues.AwayTeamPicked.Value == teamName then
		ServerFunctions.GiveNPCUniform(battingCageCharacter, teamName, "Away")
	else
		ServerFunctions.GiveNPCUniform(battingCageCharacter, teamName, "Home")
	end
	
	if PlayerService:FindFirstChild(player.Name) then
		if _G.sessionData[player] then
			ServerFunctions.EquipGear(battingCageCharacter, "Wristband", _G.sessionData[player].EquippedWristband)
		end
	end

	if SharedData:FindFirstChild(player.Name) and SharedData[player.Name]:FindFirstChild("BattingCageCharacter") then
		SharedData[player.Name].BattingCageCharacter:Destroy()
	end
	
	local equippedStyle = StylesModule.GetEquippedStyleName(player, "Offensive")
	local BatName
	local BatHand = "Right" -- Default
	local BatSide = "Right" -- Default
	
	if SharedData:FindFirstChild(player.Name) then
		battingCageCharacter.Parent = SharedData[player.Name]
		
		if _G.sessionData[player] then
			BatName = _G.sessionData[player].EquippedBat or "Wooden Bat"
		else
			BatName = "Wooden Bat"
		end

		if equippedStyle and OffensiveAbilities[equippedStyle] then
			BatHand = OffensiveAbilities[equippedStyle].BatHand or "Right"
			BatSide = OffensiveAbilities[equippedStyle].BatSide or "Right"
		end
		
		if ReplicatedStorage.ShopItems.Bat:FindFirstChild(BatName) then
			local Bat = ReplicatedStorage.ShopItems.Bat:FindFirstChild(BatName):Clone()
			Bat.Name = "PlayerBat"
			Bat.Parent = battingCageCharacter

			-- Determine which hand the bat should be welded to
			local Hand = BatHand == "Left" and "RightHand" or "LeftHand"
			local weld = ServerStorage.ServerObjects.BackupBatWeld:Clone()
			weld.Parent = battingCageCharacter[Hand]
			weld.Part0 = battingCageCharacter[Hand]
			weld.Part1 = Bat.Handle
		end

		Remotes.CancelSlideDive:FireClient(player)
		-- Move the player to correct batting zone
		local HRP = battingCageCharacter.HumanoidRootPart
		if BatSide == "Left" then
			battingCageCharacter:PivotTo(workspace.BattingCage.Batting.LeftBatter.CFrame)
		else
			battingCageCharacter:PivotTo(workspace.BattingCage.Batting.RightBatter.CFrame)
		end

		--Remotes.DisableMovement:FireClient(player, true)

		Remotes.ToggleMenuButtons:FireClient(player, "Hide")
		Remotes.ToggleAbilityButtons:FireClient(player, false)
		
		Remotes.CloneUI:FireClient(player, "HittingScreen")
		Remotes.BattingCage.SetupBattingPractice:FireClient(player, equippedStyle)
	end
	
	
	return equippedStyle
end

Remotes.SetupLockerStylesCharacter.OnServerInvoke = function(player)
	local lockerStylesCharacter = ServerStorage.ServerObjects.StylesLockerCharacter:Clone()
	lockerStylesCharacter.Parent = workspace
	local teamName = player.Team.Name
	
	if teamName == "No Team" or teamName == "Lobby" then
		teamName = "Los Angeles 2"
	end
	
	pcall(function()
		local oldHumanoidDescription = PlayerService:GetHumanoidDescriptionFromUserId(player.UserId)

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

		lockerStylesCharacter.Humanoid:ApplyDescription(newHumanoidDescription)
	end)

	if GameValues.AwayTeamPicked.Value == teamName then
		ServerFunctions.GiveNPCUniform(lockerStylesCharacter, teamName, "Away")
	else
		ServerFunctions.GiveNPCUniform(lockerStylesCharacter, teamName, "Home")
	end

	if PlayerService:FindFirstChild(player.Name) then
		if _G.sessionData[player] then
			ServerFunctions.EquipGear(lockerStylesCharacter, "Wristband", _G.sessionData[player].EquippedWristband)
		end
	end
	
	if SharedData:FindFirstChild(player.Name) and SharedData[player.Name]:FindFirstChild("StylesLockerCharacter") then
		SharedData[player.Name].StylesLockerCharacter:Destroy()
	end
	
	local transformationEffect = ReplicatedStorage.VFXParticlesFB.AbilityTransformationEffects:Clone()
	ClientFunctions.Weld(transformationEffect, lockerStylesCharacter.HumanoidRootPart)
	transformationEffect.Parent = lockerStylesCharacter.HumanoidRootPart
	
	for _, object in pairs(transformationEffect:GetDescendants()) do
		if object:IsA("ParticleEmitter") or object:IsA("PointLight") then
			object.Enabled = false
		elseif object:IsA("Attachment") then
			for _, particle in pairs(object:GetDescendants()) do
				if particle:IsA("ParticleEmitter") then
					particle.Enabled = false
				end
			end
		end
	end
	
	transformationEffect.Sound.Volume = 0.25
	
	if SharedData:FindFirstChild(player.Name) then
		lockerStylesCharacter.Parent = SharedData[player.Name]
		lockerStylesCharacter.HumanoidRootPart.CFrame = ServerStorage.ServerObjects.StylesLockerCharacterReferencePos.HumanoidRootPart.CFrame
	end
	return true
end

Remotes.PlayerSelect.OnServerEvent:Connect(function(player, chosenPlayer)
	local function isEligibleSelector()
		if GameValues.PlayerSelectPhase.Value ~= "" and player == GameValues[GameValues.PlayerSelectPhase.Value.."Captain"].Value then
			return true
		else
			return false
		end
	end
	
	if MessageValues.Status.Value == "Captains are selecting Players" then
		if chosenPlayer and isEligibleSelector() and not GameValues.PlayerPicked.Value then
			GameValues.PlayerPicked.Value = true

			if chosenPlayer.Character and chosenPlayer.Character:FindFirstChild('Humanoid') then
				chosenPlayer.Character.Humanoid:MoveTo(FieldCameras.PlayerSelectedWalkTo.Position)
			end
			
			chosenPlayer.TeamColor = player.TeamColor
			
			if chosenPlayer.Team and chosenPlayer.Team.Name == GameValues.AwayTeamPicked.Value then
				ServerFunctions.GiveUniform(chosenPlayer, chosenPlayer.Team.Name, "Away")
			elseif chosenPlayer.Team and chosenPlayer.Team.Name == GameValues.HomeTeamPicked.Value then
				ServerFunctions.GiveUniform(chosenPlayer, chosenPlayer.Team.Name, "Home")
			end
			
			ServerFunctions.RemovePlayerSelectPositioning(chosenPlayer)
			
			Remotes.DestroyGui:FireClient(player, "PlayerSelectGamepad")
		end
	end
end)

Remotes.VotePitcher.OnServerEvent:Connect(function(player, votedPlayerName)
	local votedPlayer = PlayerService:FindFirstChild(votedPlayerName)
	
	if votedPlayer and votedPlayer.TeamColor == player.TeamColor and SharedData:FindFirstChild(player.Name) then
		local pitcherVotedFor = SharedData[player.Name].PitcherVotes.PitcherVotedFor.Value
		
		if SharedData:FindFirstChild(pitcherVotedFor) and SharedData[pitcherVotedFor].PitcherVotes.Value > 0 then -- subtract any old vote
			SharedData[pitcherVotedFor].PitcherVotes.Value = SharedData[pitcherVotedFor].PitcherVotes.Value - 1
		end
		
		if SharedData:FindFirstChild(votedPlayerName) then -- add new vote
			SharedData[votedPlayerName].PitcherVotes.Value = SharedData[votedPlayerName].PitcherVotes.Value + 1
			SharedData[player.Name].PitcherVotes.PitcherVotedFor.Value = votedPlayerName
		else
			SharedData[player.Name].PitcherVotes.PitcherVotedFor.Value = ""
		end
		
		local mostVotedPitcher = ClientFunctions.GetMostVotedPitcher(player.TeamColor)
		
		for _, otherPlayer in pairs(ClientFunctions.GetPlayersInGame()) do
			if otherPlayer.TeamColor == player.TeamColor then
				Remotes.VotePitcher:FireClient(otherPlayer, mostVotedPitcher)
			end
		end
	end
end)

Remotes.GetStyleData.OnServerInvoke = function(player, styleType)
	local slotNum = _G.sessionData[player]["Equipped"..styleType.."Style"]
	local equippedName = StylesModule.GetEquippedStyleName(player, styleType) -- uses override if any

	local styleInventory = _G.sessionData[player][styleType.."StyleInventory"]
	local spinPreference = _G.sessionData[player][styleType.."SpinPreference"]
	local limitedInventory = _G.sessionData[player]["Limited"..styleType.."StyleInventory"]
	local equippedLimitedStyle = _G.sessionData[player]["Equipped"..styleType.."LimitedStyle"]

	return equippedName, styleInventory, spinPreference, slotNum, limitedInventory, equippedLimitedStyle
end


Remotes.GetRankedProgress.OnServerInvoke = function(player)
	return _G.sessionData[player].RankedSeasonData
end

Remotes.RetrievePackRolls.OnServerInvoke = function(player, packType, packItemType)
	local dataPackItemTypeKey = string.gsub(packItemType, "%s+", "").."PackRolls"

	return _G.sessionData[player][dataPackItemTypeKey][packType] or 0
end


Remotes.BuyShopPack.OnServerEvent:Connect(function(player, packType, packItemType, purchaseModifier)
	local rollPrice = ShopPackTypesModule[packType].Price * purchaseModifier
	
	if rollPrice <= 0 then return end
	
	if _G.sessionData[player].Cash >= rollPrice then
		ServerFunctions.CashTransaction(player, rollPrice)

		local dataPackItemTypeKey = string.gsub(packItemType, "%s+", "").."PackRolls"
		
		if _G.sessionData[player][dataPackItemTypeKey][packType] == nil then
			_G.sessionData[player][dataPackItemTypeKey][packType] = purchaseModifier
		else
			_G.sessionData[player][dataPackItemTypeKey][packType] = _G.sessionData[player][dataPackItemTypeKey][packType] + purchaseModifier
		end

		Remotes.BuyShopPack:FireClient(player, packType, _G.sessionData[player][dataPackItemTypeKey][packType])

		Remotes.Notification:FireClient(player, "Purchased "..packType.." ("..purchaseModifier..")")
	else
		Remotes.Notification:FireClient(player, "You need "..tostring(rollPrice - _G.sessionData[player].Cash).." more to complete the purchase", "Alert")
	end
end)

Remotes.StopPitchClock.OnServerEvent:Connect(function(player)
	if player == GameValues.CurrentPitcher.Value then
		GameValues.ScoreboardValues.PitchClockEnabled.Value = false
	end
end)
        
Remotes.AlertPitch.OnServerEvent:Connect(function(player)
	if player == GameValues.CurrentPitcher.Value then
		spawn(function()
			GameValues.PitchWindup.Value = true
			task.wait(4)
			GameValues.PitchWindup.Value = false
		end)
	end
end)

Remotes.GetInventory.OnServerInvoke = function(player, inventoryType)
	local sessionData = _G.sessionData[player]
	if sessionData then
		local inventoryKey = inventoryType.."Inventory"
		local equippedKey = "Equipped"..inventoryType

		if inventoryKey and equippedKey then
 			local inventoryData = sessionData[inventoryKey]
			local equippedItem = sessionData[equippedKey]
			return inventoryData, equippedItem 
		end
	end
end

Remotes.GetEmoteInventory.OnServerInvoke = function(player)
	if _G.sessionData[player] and _G.sessionData[player].EmoteInventory then
		return _G.sessionData[player].EmoteInventory
	end
end

Remotes.EquipItem.OnServerEvent:Connect(function(player, itemType, itemName, shopType)
	local sessionData = _G.sessionData[player]

	local inventoryKey = itemType.."Inventory"
	local equippedKey = "Equipped"..itemType

	if inventoryKey and equippedKey then
		if shopType == "Pack" and sessionData[inventoryKey][itemName] ~= nil then
			sessionData[equippedKey] = itemName
			
			if itemType == "Bat" then
				ServerFunctions.ShowOffBat(player, true)
			end
		elseif shopType == "Gear" and (itemName == "" or table.find(sessionData[inventoryKey], itemName)) then
			sessionData[equippedKey] = itemName
			ServerFunctions.EquipGear(player.Character, itemType, itemName)
		end
	end
end)

local Default_Items = {
    Bat = "Wooden Bat",
    Trail = "Normal Trail",
    Glove = "Old Glove"
}

Remotes.SellItem.OnServerEvent:Connect(function(player, itemType, itemName)	
    local sessionData = _G.sessionData[player]
    if not sessionData then return end 

	local inventoryKey = itemType.."Inventory"
	local equippedKey = "Equipped"..itemType 
	local inventory = sessionData[inventoryKey]
	local equipped = sessionData[equippedKey]
	local packType;

	local function findRarityByName(itemName)
		for i,v in pairs (ShopPackItemsModule) do
			if type(v) == "table" then
				for name, details in pairs(v) do
					if name == itemName and details.Rarity then
						packType = i
	 					return details.Rarity
					end
				end
			end		
		end	
	end

	for i,v in pairs (Default_Items) do
		if v == itemName then
			return
		end
	end

    if inventory[itemName] and inventory[itemName] > 0 then
		local Rarity = findRarityByName(itemName)
		
		if ShopPackTypesModule[packType] == nil then
			return
		end
		
		local resaleValue = RarityProbability.ResaleValue[Rarity]
		local sellPrice = math.floor(ShopPackTypesModule[packType].Price * resaleValue)

		inventory[itemName] = inventory[itemName] - 1
		
		if inventory[itemName] == 0 then
			inventory[itemName] = nil
		end

		ServerFunctions.CashTransaction(player, sellPrice, true, false)

		if equipped == itemName then
			_G.sessionData[player][equippedKey] = Default_Items[itemType]
		end
		
		Remotes.UpdateInventory:FireClient(player, itemType)
		
		Remotes.Notification:FireClient(player, "You sold 1 "..itemName.." for "..sellPrice.." Coins!", "Alert")
	end
end)


Remotes.OpenShopPack.OnServerEvent:Connect(function(player, packType, packItemType)
	local dataPackItemTypeKey = string.gsub(packItemType, "%s+", "").."PackRolls"
	
	if _G.sessionData[player][dataPackItemTypeKey][packType] > 0 then
		_G.sessionData[player][dataPackItemTypeKey][packType] = _G.sessionData[player][dataPackItemTypeKey][packType] - 1
		
		Remotes.OpenShopPack:FireClient(player, packType, _G.sessionData[player][dataPackItemTypeKey][packType])
		
		local rarities = {"Legendary", "Epic", "Rare", "Uncommon", "Common"}
		
		local cumulativeTable = {}
		local cumulative = 0
		
		if string.match(packType, "Supreme") then
			for _, rarity in pairs(rarities) do
				cumulative = cumulative + RarityProbability.SupremePackProbability[rarity]
				table.insert(cumulativeTable, {name = rarity, cumulative = cumulative})
			end
		else
			for _, rarity in pairs(rarities) do
				cumulative = cumulative + RarityProbability[rarity]
				table.insert(cumulativeTable, {name = rarity, cumulative = cumulative})
			end
		end
		
		local roll = math.random(1, 100)
		local rarityRolled
		
		for _, rarityRoll in ipairs(cumulativeTable) do
			if roll <= rarityRoll.cumulative then
				rarityRolled = rarityRoll.name
				break
			end
		end
		
		local availableShopItems = {}
		
		for item, itemValues in pairs(ShopPackItemsModule[packType]) do
			if itemValues.Available and itemValues.Rarity == rarityRolled then
				table.insert(availableShopItems, item)
			end
		end
		
		local itemRolled = availableShopItems[math.random(1, #availableShopItems)]
		
		if _G.sessionData[player][packItemType.."Inventory"][itemRolled] == nil then
			_G.sessionData[player][packItemType.."Inventory"][itemRolled] = 1
		else
			_G.sessionData[player][packItemType.."Inventory"][itemRolled] = _G.sessionData[player][packItemType.."Inventory"][itemRolled] + 1
		end
		
		--print(itemRolled.." : "..tostring(_G.sessionData[player][packItemType.."Inventory"][itemRolled]))
		
		local packRewardGui = ServerGUIs.PackReward:Clone()
		packRewardGui.Frame.PackItemType.Value = packItemType
		packRewardGui.Frame.ItemName.Value = itemRolled
		packRewardGui.Frame.PackName.Value = packType
		packRewardGui.Frame.ItemNameLabel.Text = itemRolled
		if rarityRolled == "Legendary" or rarityRolled == "Epic" then
			packRewardGui.Frame.BigRoll.Value = true
		end
		packRewardGui.Frame.Rarity.Text = rarityRolled
		packRewardGui.Frame.Rarity.TextColor3 = RarityProbability.Colors[rarityRolled]
		packRewardGui.Frame.Blur.ImageColor3 = RarityProbability.Colors[rarityRolled] 
		packRewardGui.Frame[rarityRolled.."RarityLabel"].Visible = true
		packRewardGui.Parent = player.PlayerGui
		
		Remotes.UpdateInventory:FireClient(player, packItemType)

		if packItemType == "Emote" then
			Remotes.UpdateEmoteInventory:FireClient(player)
		end
	end
end)

Remotes.SelectPreference.OnServerEvent:Connect(function(player, styleType, abilityName)
	if StylesModule[styleType.."Styles"] == nil or StylesModule[styleType.."Styles"][abilityName] == nil then return end

	_G.sessionData[player][styleType.."SpinPreference"] = abilityName

	Remotes.SelectPreference:FireClient(player, styleType, abilityName)
	Remotes.Notification:FireClient(player, "You now have a higher chance to earn "..abilityName)
end)

Remotes.StyleSpin.OnServerEvent:Connect(function(player, styleType, spinType)
	local function getStyleInventorySize()
		local count = 0

		for styleName, styleData in pairs(_G.sessionData[player][styleType.."StyleInventory"]) do
			count += 1
		end

		return count
	end

	local function equippedSlotNotLocked()
		local equippedSlotNum = _G.sessionData[player]["Equipped"..styleType.."Style"]
		if equippedSlotNum then
			return _G.sessionData[player][styleType.."StyleInventory"][equippedSlotNum].Reserved
		end
	end
	
	local function isLegendaryPlus(r)
		return r == "Legendary" or r == "Mythic" or r == "Superstar" or r == "Limited"
	end

	local function isMythicPlus(r)
		return r == "Mythic" or r == "Superstar" or r == "Limited"
	end

	local function bumpAndCheckPity()
		-- returns: forcePity (bool), pityTargetList (table of rarities), pityKeyName (string)
		if spinType == "Lucky" then
			_G.sessionData[player].PityLuckySpinsCount += 1
			local count = _G.sessionData[player].PityLuckySpinsCount
			SharedData[player.Name].PityLuckySpinsCount.Value = count
			
			-- Every 50 lucky spins => Mythic+
			if count >= RarityProbability.PitySpinsRequired.LuckySpin then
				return true, {"Limited", "Superstar", "Mythic"}, "PityLuckySpinsCount"
			end

			return false, nil, "PityLuckySpinsCount"
		else
			_G.sessionData[player].PityStyleSpinsCount += 1
			local count = _G.sessionData[player].PityStyleSpinsCount
			SharedData[player.Name].PityStyleSpinsCount.Value = count

			-- Every 100 regular spins => Legendary+
			if count >= RarityProbability.PitySpinsRequired.StyleSpin then
				return true, {"Limited", "Superstar", "Mythic", "Legendary"}, "PityStyleSpinsCount"
			end

			return false, nil, "PityStyleSpinsCount"
		end
	end

	local function resetPityIfHit(rarityRolled)
		if spinType == "Lucky" then
			if isMythicPlus(rarityRolled) then
				_G.sessionData[player].PityLuckySpinsCount = 0
			end
		else
			if isLegendaryPlus(rarityRolled) then
				_G.sessionData[player].PityStyleSpinsCount = 0
			end
		end
	end

	local spinsDataKey = "StyleSpins"
	local stylesProbabilityKey = "StylesProbability"

	if spinType == "Lucky" then
		spinsDataKey = "LuckySpins"
		stylesProbabilityKey = "StylesLuckyProbability"
	end

	if _G.sessionData[player][spinsDataKey] <= 0 then
		if spinType == "Lucky" then
			Remotes.Notification:FireClient(player, "You don't have enough Lucky Spins!", "Alert")
		else
			Remotes.Notification:FireClient(player, "You don't have enough Spins left!", "Alert")
		end
		return
	end

	if equippedSlotNotLocked() then
		Remotes.Notification:FireClient(player, "Your equipped slot is currenty locked!", "Alert")
		return
	end

	if SharedData[player.Name].ActivatedFBAbility.Value then
		Remotes.Notification:FireClient(player, "You cannot spin while an ability was activated!", "Alert")
		return
	end
	
	local equippedLimited = _G.sessionData[player]["Equipped"..styleType.."LimitedStyle"]
	if equippedLimited ~= nil then
		Remotes.Notification:FireClient(
			player,
			"Limited equipped! Equip a main style to replace in the next spin.",
			"Alert"
		)
		return
	end

	-- consume spin
	_G.sessionData[player][spinsDataKey] -= 1
	SharedData[player.Name][spinsDataKey].Value = _G.sessionData[player][spinsDataKey]
	
	local forcePity, pityRarities, pityKeyName = bumpAndCheckPity()

	-- build rarity cumulative table using RarityProbability.StylesRarityList
	local rarities = RarityProbability.StylesRarityList
	local cumulativeTable = {}
	local cumulative = 0

	local stylesForType = StylesModule[styleType.."Styles"]

	local function rarityHasAvailableStyle(rarity)
		for _, styleInfo in pairs(stylesForType) do
			if styleInfo.Rarity == rarity and (styleInfo.Available ~= false) then
				return true
			end
		end
		return false
	end

	for _, rarity in ipairs(rarities) do
		local chanceTable = RarityProbability[stylesProbabilityKey]
		if chanceTable then
			local chance = chanceTable[rarity]

			-- only include rarities that:
			-- 1) have a configured chance > 0
			-- 2) actually have at least one available style of that rarity
			if chance and chance > 0 and rarityHasAvailableStyle(rarity) then
				cumulative += chance
				table.insert(cumulativeTable, { name = rarity, cumulative = cumulative })
			end
		end
	end

	if cumulative <= 0 then
		Remotes.Notification:FireClient(player, "No styles are currently available for this spin.", "Alert")
		return
	end
	
	local pityCumulativeTable = nil
	local pityCumulative = 0

	if forcePity then
		pityCumulativeTable = {}
		for _, rarity in ipairs(rarities) do
			local chanceTable = RarityProbability[stylesProbabilityKey]
			local chance = chanceTable and chanceTable[rarity]

			if chance and chance > 0
				and rarityHasAvailableStyle(rarity)
				and table.find(pityRarities, rarity)
			then
				pityCumulative += chance
				table.insert(pityCumulativeTable, { name = rarity, cumulative = pityCumulative })
			end
		end

		-- if no pity-eligible rarities are available, fall back to normal roll
		if pityCumulative <= 0 then
			forcePity = false
			pityCumulativeTable = nil
		end
	end


	-- roll using the actual total cumulative (supports Limited on/off dynamically)
	local rollMax = (forcePity and pityCumulative) or cumulative
	local roll = math.random(1, rollMax)

	local rarityRolled

	local tableToUse = (forcePity and pityCumulativeTable) or cumulativeTable

	for _, rarityRoll in ipairs(tableToUse) do
		if roll <= rarityRoll.cumulative then
			rarityRolled = rarityRoll.name
			break
		end
	end

	if not rarityRolled then
		Remotes.Notification:FireClient(player, "Something went wrong while rolling a rarity.", "Alert")
		return
	end
	
	-- If we triggered pity this spin, consume it now that we got a valid pity rarity.
	if forcePity then
		_G.sessionData[player][pityKeyName] = 0
	else
		-- Otherwise reset only if they naturally hit the target tier
		resetPityIfHit(rarityRolled)
	end

	-- pick a style within that rarity (respecting Available and spin preference)
	local availableStyles = {}

	for styleName, styleInfo in pairs(stylesForType) do
		if styleInfo.Rarity == rarityRolled and (styleInfo.Available ~= false) then
			table.insert(availableStyles, styleName)

			-- duplicate preferred style to weight it higher
			if styleName == _G.sessionData[player][styleType.."SpinPreference"] then
				table.insert(availableStyles, styleName)
				table.insert(availableStyles, styleName)
				table.insert(availableStyles, styleName)
			end
		end
	end

	if #availableStyles == 0 then
		Remotes.Notification:FireClient(player, "No styles of rarity "..rarityRolled.." are currently available.", "Alert")
		return
	end

	local styleRolled = availableStyles[math.random(1, #availableStyles)]
	local equippedSlotNum = _G.sessionData[player]["Equipped"..styleType.."Style"]
	local styleInfo = StylesModule[styleType.."Styles"][styleRolled]

	local styleInventory = _G.sessionData[player][styleType.."StyleInventory"]

	if styleInfo and styleInfo.Rarity == "Limited" then
		local limitedKey = "Limited"..styleType.."StyleInventory"
		local limitedInventory = _G.sessionData[player][limitedKey]

		if limitedInventory[styleRolled] == nil then
			limitedInventory[styleRolled] = 1
		else
			limitedInventory[styleRolled] += 1
		end

		ServerFunctions.EquipStyle(player, styleType, styleRolled, nil)
	else
		styleInventory[equippedSlotNum] = {
			StyleName = styleRolled,
			Reserved = false,
		}

		ServerFunctions.EquipStyle(player, styleType, styleRolled, equippedSlotNum)
	end
	
	if forcePity then
		if spinType == "Lucky" then
			Remotes.Notification:FireClient(player, "Pity activated! Guaranteed Mythic+ style!", "PityRoll")
		else
			Remotes.Notification:FireClient(player, "Pity activated! Guaranteed Legendary+ style!", "PityRoll")
		end
		
	end

	Remotes.StyleSpin:FireClient(
		player,
		styleRolled,
		styleType,
		styleInventory,
		styleRolled,
		spinType,
		equippedSlotNum,
		_G.sessionData[player]["Limited"..styleType.."StyleInventory"],
		_G.sessionData[player]["Equipped"..styleType.."LimitedStyle"]
	)

end)

Remotes.BuyStyleSpinsCash.OnServerEvent:Connect(function(player, spinType)
	local spinPrice = SpinCostsModule[spinType].CashPrice
	local spins = SpinCostsModule[spinType].Spins
	
	if _G.sessionData[player].Cash >= spinPrice then
		ServerFunctions.CashTransaction(player, spinPrice)
		_G.sessionData[player].StyleSpins = _G.sessionData[player].StyleSpins + spins
		SharedData[player.Name].StyleSpins.Value = _G.sessionData[player].StyleSpins
		Remotes.Notification:FireClient(player, "Purchased "..spins.." Style Spins")
	else
		Remotes.Notification:FireClient(player, "You need "..tostring(spinPrice - _G.sessionData[player].Cash).." more to complete the purchase", "Alert")
	end
end)

Remotes.EquipStyle.OnServerEvent:Connect(function(player, styleType, slotNum)
	if _G.sessionData[player][styleType.."StyleInventory"][slotNum] ~= nil then
		local styleName = _G.sessionData[player][styleType.."StyleInventory"][slotNum].StyleName
		
		if (ClientFunctions.PlayerIsDefender(player) or ClientFunctions.PlayerIsBaserunner(player) or GameValues.CurrentBatter.Value == player) and GameValues.BallHit.Value then
			Remotes.Notification:FireClient(player, "You cannot equip a different style while the ball is in play", "Alert")
			return
		end
		
		ServerFunctions.EquipStyle(player, styleType, styleName, slotNum)
		Remotes.StyleSlotUpgrade:FireClient(player, styleType, _G.sessionData[player][styleType.."StyleInventory"], styleName, slotNum, _G.sessionData[player]["Equipped"..styleType.."LimitedStyle"], _G.sessionData[player]["Limited"..styleType.."StyleInventory"])
	end
end)

Remotes.EquipLimitedStyle.OnServerEvent:Connect(function(player, styleType, styleName)
	local limitedKey = "Limited"..styleType.."StyleInventory"
	local limitedInv = _G.sessionData[player][limitedKey]

	if not limitedInv or not limitedInv[styleName] then return end
	
	if (ClientFunctions.PlayerIsDefender(player) or ClientFunctions.PlayerIsBaserunner(player) or GameValues.CurrentBatter.Value == player) and GameValues.BallHit.Value then
		Remotes.Notification:FireClient(player, "You cannot equip a different style while the ball is in play", "Alert")
		return
	end

	ServerFunctions.EquipStyle(player, styleType, styleName, nil)
	Remotes.StyleSlotUpgrade:FireClient(player, styleType, _G.sessionData[player][styleType.."StyleInventory"], styleName, slotNum, _G.sessionData[player]["Equipped"..styleType.."LimitedStyle"], _G.sessionData[player]["Limited"..styleType.."StyleInventory"])
end)

Remotes.ReserveStyle.OnServerEvent:Connect(function(player, styleType, styleName, slotNum)
	if _G.sessionData[player][styleType.."StyleInventory"][slotNum] ~= nil then
		_G.sessionData[player][styleType.."StyleInventory"][slotNum].Reserved = not _G.sessionData[player][styleType.."StyleInventory"][slotNum].Reserved
		Remotes.ReserveStyle:FireClient(player, styleType, styleName, _G.sessionData[player][styleType.."StyleInventory"][slotNum].Reserved, slotNum)
	end
end)

Remotes.CheckGroupJoinBonus.OnServerEvent:Connect(function(player)
	if not _G.sessionData[player].ReceivedGroupJoinBonus then
		local success, playerIsInGroup = pcall(function()
			return player:IsInGroup(10302151)
		end)


		if playerIsInGroup then
			_G.sessionData[player].ReceivedGroupJoinBonus = true
			ServerFunctions.CashTransaction(player, 500, true, false)
			Remotes.Notification:FireClient(player, "You earned a 500 coins reward for joining Metavision!", "Coins")
		end
	end
end)

Remotes.ChangeJerseyInfo.OnServerEvent:Connect(function(player, infoType, jerseyInfo)
	local filteredText = ""
	
	if MarketplaceService:UserOwnsGamePassAsync(player.UserId, GamePassModule.PassIDs["Jersey Editor"]) then
		if infoType == "Number" then
			local numberIsValid = false
			
			local success, message = pcall(function()
				if tonumber(jerseyInfo) > 0 and tonumber(jerseyInfo) < 10 and string.len(jerseyInfo) == 1 then
					numberIsValid = true
				elseif tonumber(jerseyInfo) >= 10 and tonumber(jerseyInfo) < 100 and string.len(jerseyInfo) == 2 then
					numberIsValid = true
				end
			end)
			
			if success and numberIsValid then
				local filterSuccess, errorMessage = pcall(function()
					local filteredTextResult = TextService:FilterStringAsync(jerseyInfo, player.UserId)
					filteredText = filteredTextResult:GetNonChatStringForUserAsync(player.UserId)
				end)
				
				if filterSuccess and filteredText:match("#") == nil and player.Character and player.Character:FindFirstChild("JerseyInfo") then
					player.Character.JerseyInfo.Back.Number.Text = filteredText
					player.Character.JerseyInfo.Front.Number.Text = filteredText
					
					_G.sessionData[player]["Jersey"]["Number"] = filteredText
				elseif filterSuccess and filteredText:match("#") == nil then
					_G.sessionData[player]["Jersey"]["Number"] = filteredText
				end
			end
		elseif infoType == "Name" then
			local filterSuccess, errorMessage = pcall(function()
				local filteredTextResult = TextService:FilterStringAsync(jerseyInfo, player.UserId)
				filteredText = filteredTextResult:GetNonChatStringForUserAsync(player.UserId)
			end)
			
			if filterSuccess and player.Character and player.Character:FindFirstChild("JerseyInfo") then
				player.Character.JerseyInfo.Back.PlayerName.Text = filteredText
				
				_G.sessionData[player].Jersey["Name"] = filteredText
			elseif filterSuccess then
				_G.sessionData[player].Jersey["Name"] = filteredText
			end
		end
	else
		MarketplaceService:PromptGamePassPurchase(player, GamePassModule.PassIDs["Jersey Editor"])
	end 
end)

Remotes.ChangeWalkUpSong.OnServerEvent:Connect(function(player, songID)
	if MarketplaceService:UserOwnsGamePassAsync(player.UserId, GamePassModule.PassIDs["Walk Up Song"])  then
		if tonumber(songID) ~= nil then
			_G.sessionData[player].WalkUpSongID = songID
			SharedData[player.Name].WalkUpSongID.Value = songID
			
			-- Create and preload the sound
			pcall(function()
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://" .. songID

				local startTime = os.clock()
				ContentProvider:PreloadAsync({ sound }, function(assetId, assetFetchStatus)
					
				end)
			end)
		else
			Remotes.ChangeWalkUpSong:FireClient(player, "Reset")
			_G.sessionData[player].WalkUpSongID = ""
			SharedData[player.Name].WalkUpSongID.Value = ""
		end
	else
		MarketplaceService:PromptGamePassPurchase(player, GamePassModule.PassIDs["Walk Up Song"])
		Remotes.ChangeWalkUpSong:FireClient(player, "Reset")
		_G.sessionData[player].WalkUpSongID = ""
		SharedData[player.Name].WalkUpSongID.Value = ""
	end
end)

Remotes.GetGearInventory.OnServerInvoke = function(player, gearType)
	if _G.sessionData[player] and _G.sessionData[player][gearType.."Inventory"] then
		return _G.sessionData[player][gearType.."Inventory"], _G.sessionData[player]["Equipped"..gearType]
	end
end

Remotes.BuyGearItem.OnServerEvent:Connect(function(player, gearType, gearItem)
	local itemPrice = GearItemModule[gearType][gearItem].Price
	local gearInventoryDataKey = gearType.."Inventory"
	
	if table.find(_G.sessionData[player][gearInventoryDataKey], gearItem) == nil then
		if _G.sessionData[player].Cash >= itemPrice then
			ServerFunctions.CashTransaction(player, itemPrice)

			table.insert(_G.sessionData[player][gearInventoryDataKey], gearItem)

			Remotes.BuyGearItem:FireClient(player, gearType, gearItem)
			Remotes.UpdateInventory:FireClient(player, gearType)
			Remotes.Notification:FireClient(player, "Purchased "..gearItem.." ("..gearType..")")
		else
			Remotes.Notification:FireClient(player, "You need "..tostring(itemPrice - _G.sessionData[player].Cash).." more to complete the purchase", "Alert")
		end
	end
end)

Remotes.UpdatePlayerSetting.OnServerEvent:Connect(function(player, settingName)
	if _G.sessionData[player].Settings[settingName] ~= nil then
		_G.sessionData[player].Settings[settingName] = not _G.sessionData[player].Settings[settingName]
		
		SharedData[player.Name].Settings[settingName].Value = _G.sessionData[player].Settings[settingName]
		
		Remotes.UpdatePlayerSetting:FireClient(player, settingName)
	end
end)

Remotes.ActivateFBAbility.OnServerEvent:Connect(function(player)
	if not GameValues.PowerUpsEnabled.Value then
		Remotes.Notification:FireClient(player, "Power Ups are currently disabled by the private server owner", "Alert")
		return
	end
	
	if ClientFunctions.PlayerIsDefender(player) then
		local equippedDefensiveStyle = StylesModule.GetEquippedStyleName(player, "Defensive")
		
		if StylesModule.DefensiveStyles[equippedDefensiveStyle] 
			and StylesModule.DefensiveStyles[equippedDefensiveStyle].SubType == "Fielding" 
		then
			if SharedData[player.Name].FieldingPower.Value >= 50 
				and not SharedData[player.Name].ActivatedFBAbility.Value 
				and DefensiveAbilities[equippedDefensiveStyle].AbilityConditionMet(player)
			then	
				if GameValues.BallHit.Value and GameValues.AbilitiesCanBeUsed.Value then
					SharedData[player.Name].ActivatedFBAbility.Value = true
					SharedData[player.Name].ActivatedFBAbility.PowerActivated.Value = StylesModule.DefensiveStyles[equippedDefensiveStyle].Ability
					SharedData[player.Name].FieldingPower.Value = SharedData[player.Name].FieldingPower.Value - 50
					Remotes.UpdateFieldingPower:FireClient(player, equippedDefensiveStyle)
					Remotes.ActivateFBAbility:FireClient(player) 
					
					ServerFunctions.EnableFBAbility(player, equippedDefensiveStyle, StylesModule.DefensiveStyles[equippedDefensiveStyle].Ability)
				else
					Remotes.Notification:FireClient(player, "You cannot use your Ability until the ball is in play", "Alert")
				end
			end
		end
	elseif (ClientFunctions.PlayerIsBaserunner(player) or player == GameValues.CurrentBatter.Value) then
		local equippedOffensiveStyle = StylesModule.GetEquippedStyleName(player, "Offensive")

		if StylesModule.OffensiveStyles[equippedOffensiveStyle] 
			and StylesModule.OffensiveStyles[equippedOffensiveStyle].SubType == "Baserunning" 
		then
			if SharedData[player.Name].BaserunningPower.Value >= 50 
				and not SharedData[player.Name].ActivatedFBAbility.Value 
				and OffensiveAbilities[equippedOffensiveStyle].AbilityConditionMet(player)
			then	
				if GameValues.BallHit.Value and GameValues.AbilitiesCanBeUsed.Value then
					SharedData[player.Name].ActivatedFBAbility.Value = true
					SharedData[player.Name].ActivatedFBAbility.PowerActivated.Value = StylesModule.OffensiveStyles[equippedOffensiveStyle].Ability
					SharedData[player.Name].BaserunningPower.Value = SharedData[player.Name].BaserunningPower.Value - 50
					Remotes.UpdateBaserunningPower:FireClient(player, equippedOffensiveStyle)
					Remotes.ActivateFBAbility:FireClient(player) 

					ServerFunctions.EnableFBAbility(player, equippedOffensiveStyle, StylesModule.OffensiveStyles[equippedOffensiveStyle].Ability)
				else
					Remotes.Notification:FireClient(player, "You cannot use your Ability until the ball is in play", "Alert")
				end
			end
		end
	end
end)

Remotes.ActivateFBUltimate.OnServerEvent:Connect(function(player)
	if not GameValues.PowerUpsEnabled.Value then
		Remotes.Notification:FireClient(player, "Power Ups are currently disabled by the private server owner", "Alert")
		return
	end
	
	if ClientFunctions.PlayerIsDefender(player) then
		local equippedDefensiveStyle = StylesModule.GetEquippedStyleName(player, "Defensive")

		if StylesModule.DefensiveStyles[equippedDefensiveStyle] 
			and StylesModule.DefensiveStyles[equippedDefensiveStyle].SubType == "Fielding" 
		then
			if SharedData[player.Name].FieldingPower.Value == 100 
				and not SharedData[player.Name].ActivatedFBAbility.Value 
				and DefensiveAbilities[equippedDefensiveStyle].UltimateConditionMet(player)
			then	
				if GameValues.BallHit.Value and GameValues.AbilitiesCanBeUsed.Value then
					SharedData[player.Name].ActivatedFBAbility.Value = true
					SharedData[player.Name].ActivatedFBAbility.PowerActivated.Value = StylesModule.DefensiveStyles[equippedDefensiveStyle].Ultimate
					SharedData[player.Name].FieldingPower.Value = SharedData[player.Name].FieldingPower.Value - 100
					Remotes.UpdateFieldingPower:FireClient(player, equippedDefensiveStyle)

					ServerFunctions.EnableFBAbility(player, equippedDefensiveStyle, StylesModule.DefensiveStyles[equippedDefensiveStyle].Ultimate)
				else
					Remotes.Notification:FireClient(player, "You cannot use your Ultimate until the ball is in play", "Alert")
				end
			end
		end
	elseif (ClientFunctions.PlayerIsBaserunner(player) or player == GameValues.CurrentBatter.Value) then
		local equippedOffensiveStyle = StylesModule.GetEquippedStyleName(player, "Offensive")

		if StylesModule.OffensiveStyles[equippedOffensiveStyle] 
			and StylesModule.OffensiveStyles[equippedOffensiveStyle].SubType == "Baserunning" 
		then
			if SharedData[player.Name].BaserunningPower.Value >= 100 
				and not SharedData[player.Name].ActivatedFBAbility.Value 
				and OffensiveAbilities[equippedOffensiveStyle].UltimateConditionMet(player)
			then	
				if GameValues.BallHit.Value and GameValues.AbilitiesCanBeUsed.Value then
					SharedData[player.Name].ActivatedFBAbility.Value = true
					SharedData[player.Name].ActivatedFBAbility.PowerActivated.Value = StylesModule.OffensiveStyles[equippedOffensiveStyle].Ultimate
					SharedData[player.Name].BaserunningPower.Value = SharedData[player.Name].BaserunningPower.Value - 100
					Remotes.UpdateBaserunningPower:FireClient(player, equippedOffensiveStyle)

					ServerFunctions.EnableFBAbility(player, equippedOffensiveStyle, StylesModule.OffensiveStyles[equippedOffensiveStyle].Ultimate)
				else
					Remotes.Notification:FireClient(player, "You cannot use your Ultimate until the ball is in play", "Alert")
				end
			end
		end
	end
end)

Remotes.GuessThePitch.OnServerEvent:Connect(function(player, pitchGuess)
	if not ClientFunctions.PlayerIsDefender(player) 
		and OnBase:FindFirstChild(player.Name) == nil 
		and GameValues.PitchGuessActive.Value
	then
		SharedData[player.Name].PitchGuess.Value = pitchGuess
	end
end)

Remotes.NewPlayerOpenedMenuCheck.OnServerEvent:Connect(function(player, menuType)
	if _G.sessionData[player][menuType] == false then
		_G.sessionData[player][menuType] = true
		SharedData[player.Name][menuType].Value = true
	end
end)



