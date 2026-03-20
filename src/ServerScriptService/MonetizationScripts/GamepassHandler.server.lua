local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PurchaseEvents = ReplicatedStorage.PurchaseEvents
local ModuleFolder = ServerScriptService.Modules
local SharedModules = ReplicatedStorage.SharedModules

local ServerFunctions = require(ModuleFolder.ServerFunctions)
local GamePassModule = require(SharedModules.GamePasses)
	
MarketplaceService.PromptGamePassPurchaseFinished:connect(function(player, assetId, isPurchased)
	if isPurchased then
		if assetId == GamePassModule.PassIDs["Superstars VIP"] then 
			_G.sessionData[player].ReceivedVIPBonus = true

			ServerFunctions.CashTransaction(player, 3000, true, false)
		end
		
		PurchaseEvents.GamePassPurchase:FireClient(player, assetId)
	end
end)

PurchaseEvents.GamePassPurchase.OnServerEvent:connect(function(player, productId)
	MarketplaceService:PromptGamePassPurchase(player, productId)
end)
