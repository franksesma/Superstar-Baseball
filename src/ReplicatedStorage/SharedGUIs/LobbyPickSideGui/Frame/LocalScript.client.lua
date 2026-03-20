local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local GameValues = ReplicatedStorage.GameValues
local ScoreboardValues = GameValues.ScoreboardValues
local SharedModules = ReplicatedStorage.SharedModules
local Remotes = ReplicatedStorage.RemoteEvents

local GuiAnimationModule = require(SharedModules.GuiAnimation)
local TeamsModule = require(SharedModules.Teams)

local player = Players.LocalPlayer
local homeJoinButton = script.Parent.Home.JoinButton
local awayJoinButton = script.Parent.Away.JoinButton
local returnToLobbyButton = script.Parent.ExitButton

local function updateTeam(designation)
	if TeamsModule[GameValues[designation.."TeamPicked"].Value] == nil then
		return
	end
	
	script.Parent[designation].TeamName.Text = TeamsModule[GameValues[designation.."TeamPicked"].Value].City
	
	if designation == "Away" then
		if TeamsModule[GameValues[designation.."TeamPicked"].Value].PrimaryColor == TeamsModule[GameValues["HomeTeamPicked"].Value].PrimaryColor then
			script.Parent[designation].BackgroundColor3 = TeamsModule[GameValues[designation.."TeamPicked"].Value].SecondaryColor
		else
			script.Parent[designation].BackgroundColor3 = TeamsModule[GameValues[designation.."TeamPicked"].Value].PrimaryColor
		end
	else
		script.Parent[designation].BackgroundColor3 = TeamsModule[GameValues[designation.."TeamPicked"].Value].PrimaryColor
	end
	
	script.Parent[designation].Country.Image = TeamsModule[GameValues[designation.."TeamPicked"].Value].CountryIcon
end

local function updateScore(designation)
	script.Parent[designation].Score.Text = ScoreboardValues[designation.."Score"].Value
end

updateTeam("Away")
updateTeam("Home")
updateScore("Away")
updateScore("Home")

GameValues.AwayTeamPicked.Changed:Connect(function()
	updateTeam("Away")
end)

GameValues.HomeTeamPicked.Changed:Connect(function()
	updateTeam("Home")
end)

ScoreboardValues.AwayScore.Changed:Connect(function()
	updateScore("Away")
end)

ScoreboardValues.HomeScore.Changed:Connect(function()
	updateScore("Home")
end)

GuiAnimationModule.SetupGrowButton(awayJoinButton)
awayJoinButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	Remotes.JoinGame:FireServer("Away")
end)

GuiAnimationModule.SetupGrowButton(homeJoinButton)
homeJoinButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	Remotes.JoinGame:FireServer("Home")
end)

GuiAnimationModule.SetupGrowButton(returnToLobbyButton)
returnToLobbyButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		script.Parent.Parent:Destroy()
	end
end)

local function enableButton(button)
	button.Active = true
	button.Selectable = true
	button.Interactable = true
	button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	button.Label.Text = "JOIN"
end

local function disableButton(button)
	button.Active = false
	button.Selectable = false
	button.Interactable = false
	button.BackgroundColor3 = Color3.fromRGB(109, 109, 109)
	button.Label.Text = "FULL"
end

while true do
	local awayTeamName = GameValues.AwayTeamPicked.Value
	local homeTeamName = GameValues.HomeTeamPicked.Value
	
	if Teams:FindFirstChild(awayTeamName) and Teams:FindFirstChild(homeTeamName) then
		local awayTeam = Teams[awayTeamName]
		local homeTeam = Teams[homeTeamName]

		local awayCount = 0
		local homeCount = 0

		for _, p in ipairs(Players:GetPlayers()) do
			if p.Team == awayTeam then
				awayCount += 1
			elseif p.Team == homeTeam then
				homeCount += 1
			end
		end
		
		script.Parent.Away.PlayerCount.Text = "Player Count: "..tostring(awayCount)
		script.Parent.Home.PlayerCount.Text = "Player Count: "..tostring(homeCount)
		
		if awayCount == homeCount then
			enableButton(homeJoinButton)

			enableButton(awayJoinButton)
		elseif awayCount < homeCount then
			enableButton(awayJoinButton)
			
			disableButton(homeJoinButton)
		else
			enableButton(homeJoinButton)

			disableButton(awayJoinButton)
		end 
		
		if awayCount > 7 then
			disableButton(awayJoinButton)
		end
		
		if homeCount > 7 then
			disableButton(homeJoinButton)
		end
	else
		script.Parent.Parent:Destroy()
	end
	
	wait()
end