local TitleCards = {}

TitleCards.Titles = {
	["Rookie"] = {
		MinOVR = 1,
		MaxOVR = 19,
		GamePassRequired = 0,
		Color = Color3.fromRGB(255, 255, 255),
	},
	["Professional"] = {
		MinOVR = 20,
		MaxOVR = 39,
		GamePassRequired = 0,
		Color = Color3.fromRGB(0, 255, 0),
	},
	["Veteran"] = {
		MinOVR = 40,
		MaxOVR = 59,
		GamePassRequired = 0,
		Color = Color3.fromRGB(0, 255, 255),
	},
	["Elite"] = {
		MinOVR = 60,
		MaxOVR = 79,
		GamePassRequired = 0,
		Color = Color3.fromRGB(85, 85, 255),
	},
	["All-Star"] = {
		MinOVR = 80,
		MaxOVR = 98,
		GamePassRequired = 0,
		Color = Color3.fromRGB(255, 0, 0),
	},
	["Superstar"] = {
		MinOVR = 99,
		MaxOVR = 99,
		GamePassRequired = 0,
		Color = Color3.fromRGB(255, 170, 255),
	},
}

return TitleCards
