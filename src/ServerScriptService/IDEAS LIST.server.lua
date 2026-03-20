--[[


UPDATE LOGS:
- Add Pity

NEW UPDATES EVERY WEEK!

ADJUST DATA:
local DataStoreService = game:GetService("DataStoreService")
local PlayerData = DataStoreService:GetDataStore("GameData_Version_"..38)
local playerSaveKey = "ID: "..63574433
	
local success, playerSaveData = pcall(function()
	return PlayerData:GetAsync(playerSaveKey)
end)
print(playerSaveData)

playerSaveData.RankedSeasonData.ELO = 0

PlayerData:SetAsync(playerSaveKey, playerSaveData)
print(playerSaveData)


playerSaveData.OffensiveStyleInventory[3] = {["StyleName"] = "Heat", ["Reserved"] = false}
playerSaveData.DefensiveStyleInventory[2] = {["StyleName"] = "Acrobat", ["Reserved"] = false}
playerSaveData.DefensiveStyleInventory[3] = {["StyleName"] = "Acrobat", ["Reserved"] = false}
playerSaveData.LuckySpins = playerSaveData.LuckySpins + 50
playerSaveData.DefensiveStyleSlots = playerSaveData.DefensiveStyleSlots + 1
playerSaveData.OffensiveStyleSlots = playerSaveData.OffensiveStyleSlots + 1
playerSaveData.BatPackRolls["Elite Bat Pack"] = 1 

// RESET STATS:
local DataStoreService = game:GetService("DataStoreService")
local PlayerData = DataStoreService:GetDataStore("GameData_Version_"..38)
local playerSaveKey = "ID: "..649979687
	
local success, playerSaveData = pcall(function()
	return PlayerData:GetAsync(playerSaveKey)
end)
print(playerSaveData)

playerSaveData.HittingStats = {["At-Bats"] = 0, Hits = 0, Runs = 0, RBI = 0, HR = 0, Doubles = 0, Triples = 0, Walks = 0, Strikeouts = 0}
PlayerData:SetAsync(playerSaveKey, playerSaveData)
print(playerSaveData)


--]]