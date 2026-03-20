local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameValues = ReplicatedStorage.GameValues
local SharedModules = ReplicatedStorage.SharedModules
local ScoreboardValues = GameValues.ScoreboardValues

local TeamsModule = require(SharedModules.Teams)

ScoreboardValues.HomeScore.Changed:Connect(function()
	script.Parent.Home.Score.Text = ScoreboardValues.HomeScore.Value
end)

ScoreboardValues.AwayScore.Changed:Connect(function()
	script.Parent.Away.Score.Text = ScoreboardValues.AwayScore.Value
end)

GameValues.HomeTeamPicked.Changed:Connect(function()
	if TeamsModule[GameValues.HomeTeamPicked.Value] ~= nil then
		script.Parent.Home.Label.Text = TeamsModule[GameValues.HomeTeamPicked.Value].Abbreviation
		script.Parent.Home.Label.BackgroundColor3 = TeamsModule[GameValues.HomeTeamPicked.Value].PrimaryColor
	end
end)

GameValues.AwayTeamPicked.Changed:Connect(function()
	if TeamsModule[GameValues.AwayTeamPicked.Value] ~= nil then
		script.Parent.Away.Label.Text = TeamsModule[GameValues.AwayTeamPicked.Value].Abbreviation
		script.Parent.Away.Label.BackgroundColor3 = TeamsModule[GameValues.AwayTeamPicked.Value].PrimaryColor
	end
end)