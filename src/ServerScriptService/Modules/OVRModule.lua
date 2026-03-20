local OVRModule = {}

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SharedData = ReplicatedStorage.SharedData
local ServerGUIs = ServerStorage.ServerGUIs
local SharedModules = ReplicatedStorage.SharedModules

local GamePassModule = require(SharedModules.GamePasses)

OVRModule.StatXPMappings = {
	Hitting = {
		["At-Bats"] = 15, Hits = 60, Runs = 120, RBI = 40, HR = 400
	},
	Pitching = {
		Strikes = 20, Strikeouts = 60
	},
	Outfield = {
		Putouts = 60, Assists = 30
	},
	["Game"] = {
		GamesPlayed = 15, Wins = 30, MVPAwards = 200, BestHitter = 200, BestPitcher = 200, BestOutfielder = 200
	}
}

function OVRModule.BoostXP(player, XPGained)
	if _G.sessionData[player] and _G.sessionData[player].OVRProgress["OVR"] < 99 then
		
		local success, playerHasPass = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GamePassModule.PassIDs["Superstars VIP"])
		end)

		if playerHasPass then
			XPGained = XPGained * 2
		end
		
		if _G.sessionData[player] then
			_G.sessionData[player].OVRProgress["XP"] = _G.sessionData[player].OVRProgress["XP"] + XPGained

			local XPToNextTier = 200 * _G.sessionData[player].OVRProgress["OVR"]

			if XPToNextTier > 99999 then
				XPToNextTier = 99999
			end

			if _G.sessionData[player].OVRProgress["XP"] >= XPToNextTier then
				_G.sessionData[player].OVRProgress["OVR"] = _G.sessionData[player].OVRProgress["OVR"] + 1
				_G.sessionData[player].OVRProgress["XP"] = 0

				local levelUpGUI = ServerGUIs.LevelUp:Clone()
				levelUpGUI.Frame.OVRLabel.Text = _G.sessionData[player].OVRProgress["OVR"]
				if player and player:FindFirstChild("PlayerGui") then
					levelUpGUI.Parent = player.PlayerGui
				end
			end

			if SharedData:FindFirstChild(player.Name) then
				SharedData[player.Name]["OVR"].Value = _G.sessionData[player].OVRProgress["OVR"]
				SharedData[player.Name]["XP"].Value = _G.sessionData[player].OVRProgress["XP"]
			end
		end
	end
end

return OVRModule
