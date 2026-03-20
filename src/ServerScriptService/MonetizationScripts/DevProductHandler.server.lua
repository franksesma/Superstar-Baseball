local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local PurchaseHistory = game:GetService("DataStoreService"):GetDataStore("PurchaseHistory")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = ReplicatedStorage.RemoteEvents
local SharedData = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local PurchaseEvents = ReplicatedStorage.PurchaseEvents
local Modules = ServerScriptService.Modules

local ServerFunctions = require(Modules.ServerFunctions)
local ShopPackTypesModule = require(SharedModules.ShopPackTypes)
local SpinCostsModule = require(SharedModules.SpinCosts)
local StylesModule = require(SharedModules.Styles)

_G.giftTarget = {}

local Products = {
	[2706355469] = function(receipt,player) -- Coins 500
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end

		ServerFunctions.CashTransaction(player, 500, true, false)
		Remotes.Notification:FireClient(player, "Successfully purchased 500 Coins!", "Coins")

		return true
	end,
	[2706355676] = function(receipt,player) -- Coins 2,000
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end

		ServerFunctions.CashTransaction(player, 2000, true, false)
		Remotes.Notification:FireClient(player, "Successfully purchased 1,000 Coins!", "Coins")

		return true
	end,
	[2706355805] = function(receipt,player) -- Coins 4,500
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end

		ServerFunctions.CashTransaction(player, 4500, true, false)
		Remotes.Notification:FireClient(player, "Successfully purchased 4,500 Coins!", "Coins")

		return true
	end,
	[2706356018] = function(receipt,player) -- Cash $8,000
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end

		ServerFunctions.CashTransaction(player, 8000, true, false)
		Remotes.Notification:FireClient(player, "Successfully purchased 8,000 Coins!", "Coins")

		return true
	end,
	[2706356185] = function(receipt,player) -- Coins 30,000
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end

		ServerFunctions.CashTransaction(player, 30000, true, false)
		Remotes.Notification:FireClient(player, "Successfully purchased 30,000 Coins!", "Coins")

		return true
	end,
	[3363308239] = function(receipt,player) -- 2nd Offensive Style Slot
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end
		if _G.sessionData[player].OffensiveStyleSlots > 1 then return end
		
		ServerFunctions.StyleSlotUpgrade(player, "Offensive")
		
		return true
	end,
	[3363309711] = function(receipt,player) -- 3rd Offensive Style Slot
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end
		if _G.sessionData[player].OffensiveStyleSlots > 2 then return end

		ServerFunctions.StyleSlotUpgrade(player, "Offensive")

		return true
	end,
	[3363310021] = function(receipt,player) -- 4th Offensive Style Slot
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end
		if _G.sessionData[player].OffensiveStyleSlots > 3 then return end

		ServerFunctions.StyleSlotUpgrade(player, "Offensive")

		return true
	end,
	[3363310231] = function(receipt,player) -- 5th Offensive Style Slot
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end
		if _G.sessionData[player].OffensiveStyleSlots > 4 then return end

		ServerFunctions.StyleSlotUpgrade(player, "Offensive")

		return true
	end,
	[3541019190] = function(receipt,player) -- 6th Offensive Style Slot
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end
		if _G.sessionData[player].OffensiveStyleSlots > 5 then return end

		ServerFunctions.StyleSlotUpgrade(player, "Offensive")

		return true
	end,
	[3363307381] = function(receipt,player) -- 2nd Defensive Style Slot
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end
		if _G.sessionData[player].DefensiveStyleSlots > 1 then return end

		ServerFunctions.StyleSlotUpgrade(player, "Defensive")

		return true
	end,
	[3363308609] = function(receipt,player) -- 3rd Defensive Style Slot
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end
		if _G.sessionData[player].DefensiveStyleSlots > 2 then return end

		ServerFunctions.StyleSlotUpgrade(player, "Defensive")

		return true
	end,
	[3363308949] = function(receipt,player) -- 4th Defensive Style Slot
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end
		if _G.sessionData[player].DefensiveStyleSlots > 3 then return end

		ServerFunctions.StyleSlotUpgrade(player, "Defensive")

		return true
	end,
	[3363309461] = function(receipt,player) -- 5th Defensive Style Slot
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end
		if _G.sessionData[player].DefensiveStyleSlots > 4 then return end

		ServerFunctions.StyleSlotUpgrade(player, "Defensive")

		return true
	end,
	[3541019016] = function(receipt,player) -- 6th Defensive Style Slot
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end
		if _G.sessionData[player].DefensiveStyleSlots > 5 then return end

		ServerFunctions.StyleSlotUpgrade(player, "Defensive")

		return true
	end,
	-- 🎁 Gifted Defensive Style Slots
	[3440194067] = function(receipt, player) -- Gift Defensive Style Slot 2
		local target = _G.giftTarget and _G.giftTarget[player.UserId]
		if not target or not _G.sessionData[target] then return end
		if _G.sessionData[target].DefensiveStyleSlots > 1 then return end

		ServerFunctions.StyleSlotUpgrade(target, "Defensive")
		Remotes.Notification:FireClient(target, player.DisplayName .. " gifted you a Defensive Style Slot!", "Game")
		_G.giftTarget[player.UserId] = nil
		return true
	end,
	[3440194770] = function(receipt, player) -- Gift Defensive Style Slot 3
		local target = _G.giftTarget and _G.giftTarget[player.UserId]
		if not target or not _G.sessionData[target] then return end
		if _G.sessionData[target].DefensiveStyleSlots > 2 then return end

		ServerFunctions.StyleSlotUpgrade(target, "Defensive")
		Remotes.Notification:FireClient(target, player.DisplayName .. " gifted you a Defensive Style Slot!", "Game")
		_G.giftTarget[player.UserId] = nil
		return true
	end,
	[3440196144] = function(receipt, player) -- Gift Defensive Style Slot 4
		local target = _G.giftTarget and _G.giftTarget[player.UserId]
		if not target or not _G.sessionData[target] then return end
		if _G.sessionData[target].DefensiveStyleSlots > 3 then return end

		ServerFunctions.StyleSlotUpgrade(target, "Defensive")
		Remotes.Notification:FireClient(target, player.DisplayName .. " gifted you a Defensive Style Slot!", "Game")
		_G.giftTarget[player.UserId] = nil
		return true
	end,
	[3440196652] = function(receipt, player) -- Gift Defensive Style Slot 5
		local target = _G.giftTarget and _G.giftTarget[player.UserId]
		if not target or not _G.sessionData[target] then return end
		if _G.sessionData[target].DefensiveStyleSlots > 4 then return end

		ServerFunctions.StyleSlotUpgrade(target, "Defensive")
		Remotes.Notification:FireClient(target, player.DisplayName .. " gifted you a Defensive Style Slot!", "Game")
		_G.giftTarget[player.UserId] = nil
		return true
	end,
	[3541019419] = function(receipt, player) -- Gift Defensive Style Slot 6
		local target = _G.giftTarget and _G.giftTarget[player.UserId]
		if not target or not _G.sessionData[target] then return end
		if _G.sessionData[target].DefensiveStyleSlots > 5 then return end

		ServerFunctions.StyleSlotUpgrade(target, "Defensive")
		Remotes.Notification:FireClient(target, player.DisplayName .. " gifted you a Defensive Style Slot!", "Game")
		_G.giftTarget[player.UserId] = nil
		return true
	end,

	-- 🎁 Gifted Offensive Style Slots
	[3440194394] = function(receipt, player) -- Gift Offensive Style Slot 2
		local target = _G.giftTarget and _G.giftTarget[player.UserId]
		if not target or not _G.sessionData[target] then return end
		if _G.sessionData[target].OffensiveStyleSlots > 1 then return end

		ServerFunctions.StyleSlotUpgrade(target, "Offensive")
		Remotes.Notification:FireClient(target, player.DisplayName .. " gifted you an Offensive Style Slot!", "Game")
		_G.giftTarget[player.UserId] = nil
		return true
	end,
	[3440195819] = function(receipt, player) -- Gift Offensive Style Slot 3
		local target = _G.giftTarget and _G.giftTarget[player.UserId]
		if not target or not _G.sessionData[target] then return end
		if _G.sessionData[target].OffensiveStyleSlots > 2 then return end

		ServerFunctions.StyleSlotUpgrade(target, "Offensive")
		Remotes.Notification:FireClient(target, player.DisplayName .. " gifted you an Offensive Style Slot!", "Game")
		_G.giftTarget[player.UserId] = nil
		return true
	end,
	[3440196355] = function(receipt, player) -- Gift Offensive Style Slot 4
		local target = _G.giftTarget and _G.giftTarget[player.UserId]
		if not target or not _G.sessionData[target] then return end
		if _G.sessionData[target].OffensiveStyleSlots > 3 then return end

		ServerFunctions.StyleSlotUpgrade(target, "Offensive")
		Remotes.Notification:FireClient(target, player.DisplayName .. " gifted you an Offensive Style Slot!", "Game")
		_G.giftTarget[player.UserId] = nil
		return true
	end,
	[3440196853] = function(receipt, player) -- Gift Offensive Style Slot 5
		local target = _G.giftTarget and _G.giftTarget[player.UserId]
		if not target or not _G.sessionData[target] then return end
		if _G.sessionData[target].OffensiveStyleSlots > 4 then return end

		ServerFunctions.StyleSlotUpgrade(target, "Offensive")
		Remotes.Notification:FireClient(target, player.DisplayName .. " gifted you an Offensive Style Slot!", "Game")
		_G.giftTarget[player.UserId] = nil
		return true
	end,
	[3541019618] = function(receipt, player) -- Gift Offensive Style Slot 6
		local target = _G.giftTarget and _G.giftTarget[player.UserId]
		if not target or not _G.sessionData[target] then return end
		if _G.sessionData[target].OffensiveStyleSlots > 5 then return end

		ServerFunctions.StyleSlotUpgrade(target, "Offensive")
		Remotes.Notification:FireClient(target, player.DisplayName .. " gifted you an Offensive Style Slot!", "Game")
		_G.giftTarget[player.UserId] = nil
		return true
	end,
}

local function setupPackProduct(packType, packValues, purchaseModifier)
	Products[packValues["DevProductIDx"..purchaseModifier]] = function(receipt,player)
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end

		local dataPackItemTypeKey = string.gsub(packValues.PackItemType, "%s+", "").."PackRolls"

		if _G.sessionData[player][dataPackItemTypeKey][packType] == nil then
			_G.sessionData[player][dataPackItemTypeKey][packType] = purchaseModifier
		else
			_G.sessionData[player][dataPackItemTypeKey][packType] = _G.sessionData[player][dataPackItemTypeKey][packType] + purchaseModifier
		end

		Remotes.Notification:FireClient(player, "Purchased "..packType.." ("..purchaseModifier..")")
		Remotes.BuyShopPack:FireClient(player, packType, _G.sessionData[player][dataPackItemTypeKey][packType])

		return true
	end
end

local function setupSpinProduct(spinValues)
	Products[spinValues["DevProductID"]] = function(receipt,player)
		local DataLoaded = _G.sessionData[player].DataLoaded
		if not DataLoaded then return end
		
		if spinValues.Type == "Normal" then
			_G.sessionData[player].StyleSpins = _G.sessionData[player].StyleSpins + spinValues.Spins
			SharedData[player.Name].StyleSpins.Value = _G.sessionData[player].StyleSpins
			
			Remotes.Notification:FireClient(player, "Purchased "..spinValues.Spins.." Style Spins")
		elseif spinValues.Type == "Lucky" then
			_G.sessionData[player].LuckySpins = _G.sessionData[player].LuckySpins + spinValues.Spins
			SharedData[player.Name].LuckySpins.Value = _G.sessionData[player].LuckySpins

			Remotes.Notification:FireClient(player, "Purchased "..spinValues.Spins.." Lucky Spins")
		end
		
		return true
	end
	
	Products[spinValues["GiftProductID"]] = function(receipt, player)
		local target = _G.giftTarget and _G.giftTarget[player.UserId]
		if not target or not _G.sessionData[target] then return end

		local targetData = _G.sessionData[target]

		if spinValues.Type == "Normal" then
			targetData.StyleSpins += spinValues.Spins
			SharedData[target.Name].StyleSpins.Value = targetData.StyleSpins
			Remotes.Notification:FireClient(target, player.DisplayName .. " gifted you " .. spinValues.Spins .. " Style Spins!", "Game")

		elseif spinValues.Type == "Lucky" then
			targetData.LuckySpins += spinValues.Spins
			SharedData[target.Name].LuckySpins.Value = targetData.LuckySpins
			Remotes.Notification:FireClient(target, player.DisplayName .. " gifted you " .. spinValues.Spins .. " Lucky Spins!", "Game")
		end

		_G.giftTarget[player.UserId] = nil
		return true
	end
end

for packType, packValues in pairs(ShopPackTypesModule) do
	setupPackProduct(packType, packValues, 1)
	setupPackProduct(packType, packValues, 10)
end

for spin, spinValues in pairs(SpinCostsModule) do
	setupSpinProduct(spinValues)
end

local shuttingDown = false
game:BindToClose(function()
	shuttingDown = true
	task.wait(3)
end)

 
function MarketplaceService.ProcessReceipt(receiptInfo) 
	if shuttingDown then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
    local playerProductKey = receiptInfo.PlayerId .. ":" .. receiptInfo.PurchaseId
    if PurchaseHistory:GetAsync(playerProductKey) then
        return Enum.ProductPurchaseDecision.PurchaseGranted --We already granted it.
    end
    -- find the player based on the PlayerId in receiptInfo
	local player = game:GetService("Players"):GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
	-- player left? don't process it
 
	local handler
	for productId,func in pairs(Products) do
		if productId == receiptInfo.ProductId then
			handler = func break -- found our handler
		end
	end
 
	-- apparently it's not our responsibility to handle this purchase
	-- if this happens, you should probably check your productIds etc
	-- let's just assume this is ment behavior, and let the purchase go through
	if not handler then return Enum.ProductPurchaseDecision.PurchaseGranted end
 
	-- call it safely with pcall, to catch any error
	local suc,err = pcall(handler,receiptInfo,player)
	if not suc then
		warn("An error occured while processing a product purchase")
		print("\t ProductId:",receiptInfo.ProductId)
		print("\t Player:",player)
		print("\t Error message:",err) -- log it to the output
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
 
	-- if the function didn't error, 'err' will be whatever the function returned
	-- if our handler didn't return anything (or it returned false/nil), it means
	-- that the purchase failed for some reason, so we have to cancel it
	if not err then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
 
    -- record the transaction in a Data Store
    suc,err = pcall(function()
        PurchaseHistory:SetAsync(playerProductKey, true)
    end)
    if not suc then
        print("An error occured while saving a product purchase")
		print("\t ProductId:",receiptInfo.ProductId)
		print("\t Player:",player)
		print("\t Error message:",err) -- log it to the output
		print("\t Handler worked fine, purchase granted") -- add a small note that the actual purchase has succeed
    end
    -- tell ROBLOX that we have successfully handled the transaction (required)
    return Enum.ProductPurchaseDecision.PurchaseGranted		
end

PurchaseEvents.DevProductPurchase.OnServerEvent:connect(function(player, productId)
	MarketplaceService:PromptProductPurchase(player, tonumber(productId))
end)

PurchaseEvents.StyleSlotUpgrade.OnServerEvent:Connect(function(player, styleType)
	local styleSlotsOwned = _G.sessionData[player][styleType.."StyleSlots"]
	
	local productID = StylesModule.SlotUpgrades[styleType][styleSlotsOwned]

	MarketplaceService:PromptProductPurchase(player, productID)
end)

PurchaseEvents.GiftPlayer.OnServerEvent:Connect(function(player, targetName, giftType, giftSubTypeOrID, quantity)
	local targetPlayer = game.Players:FindFirstChild(targetName)
	if not targetPlayer then
		Remotes.Notification:FireClient(player, "Target player not found!", "Alert")
		return
	end

	local senderData = _G.sessionData[player]
	local receiverData = _G.sessionData[targetPlayer]
	if not senderData or not receiverData then
		return
	end

	if giftType == "Style Slot" then
		local styleType = giftSubTypeOrID -- "Offensive" or "Defensive"
		local receiverSlots = receiverData[styleType .. "StyleSlots"]

		-- cannot exceed 5 slots total
		if receiverSlots >= 6 then
			Remotes.Notification:FireClient(player, targetPlayer.DisplayName .. " already owns all " .. styleType .. " slots.", "Alert")
			return
		end

		local nextProductId = StylesModule.SlotUpgrades[styleType.."Gift"][receiverSlots]
		if not nextProductId then
			return
		end

		_G.giftTarget[player.UserId] = targetPlayer
		MarketplaceService:PromptProductPurchase(player, nextProductId)
	elseif giftType == "DevProduct" then
		local productId = giftSubTypeOrID 

		_G.giftTarget[player.UserId] = targetPlayer
		MarketplaceService:PromptProductPurchase(player, productId)
	end
end)
