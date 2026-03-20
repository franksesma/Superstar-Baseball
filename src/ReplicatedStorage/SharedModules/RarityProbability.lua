local RarityProbability = {
	Legendary = 1,
	Epic = 5,
	Rare = 10,
	Uncommon = 30,
	Common = 54,
}

RarityProbability.SupremePackProbability = {
	Legendary = 3,
	Epic = 12,
	Rare = 20,
	Uncommon = 30,
	Common = 35,
}

RarityProbability.RarityList = {
	"Legendary", "Epic", "Rare", "Uncommon", "Common"
}

RarityProbability.StylesRarityList = {
	"Limited", "Superstar", "Mythic", "Legendary", "Epic", "Rare", "Uncommon"
}

RarityProbability.StylesProbability = {
	Limited = 0.25,
	Superstar = 0.25,
	Mythic = 1,
	Legendary = 3,
	Epic = 8,
	Rare = 25,
	Uncommon = 62.75,
}

RarityProbability.StylesLuckyProbability = {
	Limited = 1,
	Superstar = 1,
	Mythic = 3,
	Legendary = 10,
	Epic = 86,
}

RarityProbability.Colors = {
	Limited = Color3.fromRGB(170, 170, 0),
	Superstar = Color3.fromRGB(255, 170, 255),
	Mythic = Color3.fromRGB(255, 0, 0),
	Legendary = Color3.fromRGB(255, 170, 0),
	Epic = Color3.fromRGB(170, 85, 255),
	Rare = Color3.fromRGB(0, 255, 255),
	Uncommon = Color3.fromRGB(85, 255, 0),
	Common = Color3.fromRGB(229, 229, 229)
}

RarityProbability.ResaleValue = {
	Legendary = 0.5,
	Epic = 0.4,
	Rare = 0.3, 
	Uncommon = 0.2, 
	Common = 0.1
}

RarityProbability.PitySpinsRequired = {
	LuckySpin = 90,
	StyleSpin = 100,
}


return RarityProbability
