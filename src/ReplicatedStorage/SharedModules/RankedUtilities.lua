local RankedUtilities = {}

RankedUtilities.RankedRatings = {
	{ Name = "Iron",     Min = 0,     Max = 899  },
	{ Name = "Bronze",   Min = 900,   Max = 1099 },
	{ Name = "Silver",   Min = 1100,  Max = 1299 },
	{ Name = "Gold",     Min = 1300,  Max = 1499 },
	{ Name = "Platinum", Min = 1500,  Max = 1699 },
	{ Name = "Diamond",  Min = 1700,  Max = 1899 },
	{ Name = "Superstar", Min = 1900,  Max = math.huge },
}

RankedUtilities.RankProgression = {
	["Iron"] = 200,       
	["Bronze"] = 50,      
	["Silver"] = 50,
	["Gold"] = 50,
	["Platinum"] = 50,
	["Diamond"] = 50,
	["Superstar"] = 50   
}


RankedUtilities.RankIcons = {
	["Iron"] = "rbxassetid://126828616894654",       
	["Bronze"] = "rbxassetid://105733362949848",      
	["Silver"] = "rbxassetid://77444989374377",
	["Gold"] = "rbxassetid://116131739221678",
	["Platinum"] = "rbxassetid://137151217369577",
	["Diamond"] = "rbxassetid://83454692244120",
	["Superstar"] = "rbxassetid://124205203773810"  
}

RankedUtilities.LobbyTypes = {
	["2v2"] = {
		Size = 2,
	},
	["3v3"] = {
		Size = 3,
	},
	["4v4"] = {
		Size = 4,
	},
	["5v5"] = {
		Size = 5,
	}
}

function RankedUtilities.GetRankByElo(elo)
	for _, rank in ipairs(RankedUtilities.RankedRatings) do
		if elo >= rank.Min and elo <= rank.Max then
			return rank.Name
		end
	end
	return "Unranked"
end

return RankedUtilities
