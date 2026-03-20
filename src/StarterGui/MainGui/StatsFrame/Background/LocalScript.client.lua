local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")

local SharedDataFolder = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local Remotes = ReplicatedStorage.RemoteEvents
local GameValues = ReplicatedStorage.GameValues
local CurrentGameStatsFolder = ReplicatedStorage.CurrentGameStats
local ScoreboardValues = GameValues.ScoreboardValues
local AwayScores = ScoreboardValues.Away
local HomeScores = ScoreboardValues.Home

local GuiAnimationModule = require(SharedModules.GuiAnimation)
local ClientFunctions = require(SharedModules.ClientFunctions)
local TeamsModule = require(SharedModules.Teams)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local ButtonsFrame = script.Parent.ButtonsFrame
local ExitButton = script.Parent.ExitButton
local PlayerStatsFrame = script.Parent.PlayerStatsFrame
local ScoreboardFrame = script.Parent.ScoreboardFrame
local StatsContainer = PlayerStatsFrame.Container
local PositionButtons = PlayerStatsFrame.Positions
local SortButtons = PlayerStatsFrame.Sort

local currentSortSelected = "CurrentMatch"
local currentPositionSelected = "Hitting"

-- BUTTON FRAME

local frames = {
	[ButtonsFrame.Score] = script.Parent.ScoreboardFrame;
	[ButtonsFrame.PlayerStats] = script.Parent.PlayerStatsFrame;
}

local buttonClicked = false

local function frameButtonClicked(frame, button)
	if not buttonClicked then
		buttonClicked = true
		GuiAnimationModule.ButtonPress(player, "PositiveClick")

		frame.Visible = true
		button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		button.UIStroke.Color = Color3.fromRGB(0, 255, 255)

		for k,v in pairs(frames) do
			if v ~= frame then
				k.BackgroundColor3 = Color3.fromRGB(170, 255, 255)
				k.UIStroke.Color = Color3.fromRGB(255, 255, 255)
				v.Visible = false
			end
		end

		if frame then
			buttonClicked = false
		end	
	end
end

for button, frame in pairs(frames) do
	GuiAnimationModule.SetupShrinkButton(button)

	button.MouseButton1Click:connect(function()
		frameButtonClicked(frame, button)
	end)
end


-- INITIAL LOAD

script.HittingTitleFrame:Clone().Parent = StatsContainer

local function addStats(playerDataFolder, templateColor)
	if currentSortSelected == "Server" or currentSortSelected == "CurrentMatch" then
		if currentPositionSelected == "Hitting" then
			local playerHittingStatsTemplate = script.PlayerHittingStatsTemplate:Clone()
			playerHittingStatsTemplate.Name = playerDataFolder.Name

			if templateColor then
				for _, frame in pairs(playerHittingStatsTemplate:GetChildren()) do
					if frame:IsA("Frame") then
						frame.BackgroundColor3 = templateColor
					end
				end
			end
			
			local statsFolder = playerDataFolder:FindFirstChild("Stats") or playerDataFolder
			
			if statsFolder:WaitForChild("Hitting", 3) then
				playerHittingStatsTemplate.ABLabelFrame.Label.Text = statsFolder.Hitting["At-Bats"].Value
				playerHittingStatsTemplate.AVGLabelFrame.Label.Text = ClientFunctions.CalculateBattingAVG(statsFolder.Hitting.Hits.Value, statsFolder.Hitting["At-Bats"].Value)
				playerHittingStatsTemplate.HLabelFrame.Label.Text = statsFolder.Hitting.Hits.Value
				playerHittingStatsTemplate.HRLabelFrame.Label.Text = statsFolder.Hitting.HR.Value
				playerHittingStatsTemplate.PlayerLabelFrame.Label.Text = playerDataFolder.Name
				playerHittingStatsTemplate.RBILabelFrame.Label.Text = statsFolder.Hitting.RBI.Value
				playerHittingStatsTemplate.RLabelFrame.Label.Text = statsFolder.Hitting.Runs.Value
				playerHittingStatsTemplate.SOLabelFrame.Label.Text = statsFolder.Hitting.Strikeouts.Value
				playerHittingStatsTemplate.Parent = StatsContainer
			end
		elseif currentPositionSelected == "Pitching" then
			local playerPitchingStatsTemplate = script.PlayerPitchingStatsTemplate:Clone()
			playerPitchingStatsTemplate.Name = playerDataFolder.Name
			
			if templateColor then
				for _, frame in pairs(playerPitchingStatsTemplate:GetChildren()) do
					if frame:IsA("Frame") then
						frame.BackgroundColor3 = templateColor
					end
				end
			end
			
			local statsFolder = playerDataFolder:FindFirstChild("Stats") or playerDataFolder

			if statsFolder then
				playerPitchingStatsTemplate.PlayerLabelFrame.Label.Text = playerDataFolder.Name
				playerPitchingStatsTemplate.BBLabelFrame.Label.Text = statsFolder.Pitching.WalksAllowed.Value
				playerPitchingStatsTemplate.HLabelFrame.Label.Text = statsFolder.Pitching.HitsAllowed.Value
				playerPitchingStatsTemplate.KLabelFrame.Label.Text = statsFolder.Pitching.Strikeouts.Value
				playerPitchingStatsTemplate.RLabelFrame.Label.Text = statsFolder.Pitching.RunsAllowed.Value
				playerPitchingStatsTemplate.StrikePercentageLabelFrame.Label.Text = ClientFunctions.CalculateStrikePercentage(statsFolder.Pitching.Strikes.Value,statsFolder.Pitching.Pitches.Value)
				playerPitchingStatsTemplate.Parent = StatsContainer	
			end
		elseif currentPositionSelected == "Outfield" then	
			local playerOutfieldStatsTemplate = script.PlayerOutfieldStatsTemplate:Clone()
			playerOutfieldStatsTemplate.Name = playerDataFolder.Name
			
			if templateColor then
				for _, frame in pairs(playerOutfieldStatsTemplate:GetChildren()) do
					if frame:IsA("Frame") then
						frame.BackgroundColor3 = templateColor
					end
				end
			end
			
			local statsFolder = playerDataFolder:FindFirstChild("Stats") or playerDataFolder
				
			if statsFolder then
				playerOutfieldStatsTemplate.PlayerLabelFrame.Label.Text = playerDataFolder.Name
				playerOutfieldStatsTemplate.ALabelFrame.Label.Text = statsFolder.Outfield.Assists.Value
				playerOutfieldStatsTemplate.POLabelFrame.Label.Text = statsFolder.Outfield.Putouts.Value
				playerOutfieldStatsTemplate.RFLabelFrame.Label.Text = ClientFunctions.CalculateRangeFactor(statsFolder.Outfield.Putouts.Value,statsFolder.Outfield.Assists.Value,statsFolder.Game.GamesPlayed.Value)
				playerOutfieldStatsTemplate.Parent = StatsContainer	
			end
		end
	end
end

-- BUTTON INTERACTIONS
local function updateStatsContainer()
	wait()
	for _, frame in pairs(StatsContainer:GetChildren()) do
		if frame:IsA("Frame") or frame:IsA("TextLabel") then
			frame:Destroy()
		end
	end
	
	if currentSortSelected == "Server" then
		script[currentPositionSelected.."TitleFrame"]:Clone().Parent = StatsContainer
		
		for _, playerDataFolder in pairs(SharedDataFolder:GetChildren()) do
			addStats(playerDataFolder)
		end
	elseif currentSortSelected == "CurrentMatch" then
		script[currentPositionSelected.."TitleFrame"]:Clone().Parent = StatsContainer
		
		local HomeTeamPicked = GameValues.HomeTeamPicked.Value
		local AwayTeamPicked = GameValues.AwayTeamPicked.Value
		 
		if Teams:FindFirstChild(HomeTeamPicked) then
			local homeTeam = Teams[HomeTeamPicked]
			
			local homeTitleFrame = script.TeamTitleFrame:Clone()
			homeTitleFrame.LabelFrame.BackgroundColor3 = homeTeam.TeamColor.Color
			homeTitleFrame.LabelFrame.Label.Text = TeamsModule[HomeTeamPicked].City
			homeTitleFrame.Parent = StatsContainer
			
			for _, playerDataFolder in pairs(CurrentGameStatsFolder:GetChildren()) do
				if playerDataFolder:FindFirstChild("PlayerTeam") and Teams:FindFirstChild(playerDataFolder.PlayerTeam.Value) and playerDataFolder.PlayerTeam.Value == HomeTeamPicked then
					addStats(playerDataFolder, homeTeam.TeamColor.Color)
				end
			end
		end
		
		if Teams:FindFirstChild(AwayTeamPicked) then
			local awayTeam = Teams[AwayTeamPicked]
			
			local awayTitleFrame = script.TeamTitleFrame:Clone()
			awayTitleFrame.LabelFrame.BackgroundColor3 = awayTeam.TeamColor.Color
			awayTitleFrame.LabelFrame.Label.Text = TeamsModule[AwayTeamPicked].City
			awayTitleFrame.Parent = StatsContainer

			for _, playerDataFolder in pairs(CurrentGameStatsFolder:GetChildren()) do
				if playerDataFolder:FindFirstChild("PlayerTeam") and Teams:FindFirstChild(playerDataFolder.PlayerTeam.Value) and playerDataFolder.PlayerTeam.Value == AwayTeamPicked then
					addStats(playerDataFolder, awayTeam.TeamColor.Color)
				end
			end
		end
	elseif currentSortSelected == "Global" then
		local titleFrame = script.GlobalTitleFrame:Clone()
		
		if currentPositionSelected == "Pitching" then
			titleFrame.StatLabelFrame.Label.Text = "Strikeouts"
		elseif currentPositionSelected == "Hitting" then
			titleFrame.StatLabelFrame.Label.Text = "RBI"
		elseif currentPositionSelected == "Outfield" then
			titleFrame.StatLabelFrame.Label.Text = "Putouts"
		end
		
		titleFrame.Parent = StatsContainer

		local topPlayerData = Remotes.RetrieveGlobalStats:InvokeServer(currentPositionSelected)
		
		local loadedData = false

		for rank, data in pairs(topPlayerData) do
			loadedData = true
			local playerStatsTemplate = script.PlayerGlobalStatsTemplate:Clone()
			playerStatsTemplate.Name = data[1]
			playerStatsTemplate.PlayerLabelFrame.Label.Text = data[1]
			playerStatsTemplate.StatLabelFrame.Label.Text = data[2]
			playerStatsTemplate.RankLabelFrame.Label.Text = rank
			
			if rank == 1 then
				playerStatsTemplate.RankLabelFrame.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
			elseif rank == 2 then
				playerStatsTemplate.RankLabelFrame.BackgroundColor3 = Color3.fromRGB(170, 170, 255)
			elseif rank == 3 then
				playerStatsTemplate.RankLabelFrame.BackgroundColor3 = Color3.fromRGB(170, 85, 0)
			end
			
			playerStatsTemplate.Parent = StatsContainer	
		end
		
		if not loadedData then
			local loadingLabel = script.LoadingLabel:Clone()
			loadingLabel.Parent = StatsContainer
		end
	end
end

SharedDataFolder.ChildAdded:Connect(function(folder)
	if currentSortSelected == "Server" then
		updateStatsContainer()
	end
end)

SharedDataFolder.ChildRemoved:Connect(function(folder)
	if currentSortSelected == "Server" then
		updateStatsContainer()
	end
end)

CurrentGameStatsFolder.ChildAdded:Connect(function(folder)
	if currentSortSelected == "CurrentMatch" then
		updateStatsContainer()
	end
end)

CurrentGameStatsFolder.ChildRemoved:Connect(function(folder)
	if currentSortSelected == "CurrentMatch" then
		updateStatsContainer()
	end
end)

updateStatsContainer()

local buttonPressed = false

for _, button in pairs(SortButtons:GetChildren()) do
	if button:IsA("TextButton") then
		GuiAnimationModule.SetupShrinkButton(button)
		button.MouseButton1Click:Connect(function()
			if button.Name ~= currentSortSelected and not buttonPressed then
				buttonPressed = true
				GuiAnimationModule.ButtonPress(player, "PositiveClick")
				
				SortButtons[currentSortSelected].BackgroundColor3 = Color3.fromRGB(170, 255, 255)
				SortButtons[currentSortSelected].UIStroke.Color = Color3.fromRGB(255, 255, 255)
				currentSortSelected = button.Name
				SortButtons[currentSortSelected].BackgroundColor3 = Color3.fromRGB(0, 170, 255)
				SortButtons[currentSortSelected].UIStroke.Color = Color3.fromRGB(0, 255, 255)
				pcall(function()
					updateStatsContainer()
				end)
				buttonPressed = false
			end
		end)
	end
end

for _, button in pairs(PositionButtons:GetChildren()) do
	if button:IsA("TextButton") then
		GuiAnimationModule.SetupShrinkButton(button)
		button.MouseButton1Click:Connect(function()
			if button.Name ~= currentPositionSelected and not buttonPressed then
				buttonPressed = true
				GuiAnimationModule.ButtonPress(player, "PositiveClick")

				PositionButtons[currentPositionSelected].BackgroundColor3 = Color3.fromRGB(170, 255, 255)
				PositionButtons[currentPositionSelected].UIStroke.Color = Color3.fromRGB(255, 255, 255)
				currentPositionSelected = button.Name
				PositionButtons[currentPositionSelected].BackgroundColor3 = Color3.fromRGB(0, 170, 255)
				PositionButtons[currentPositionSelected].UIStroke.Color = Color3.fromRGB(0, 255, 255)
				pcall(function()
					updateStatsContainer()
				end)
				buttonPressed = false
			end
		end)
	end
end

Remotes.UpdateStatsGui.OnClientEvent:Connect(function()
	updateStatsContainer()
end)

GuiAnimationModule.ExitButtonPressed(player, script.Parent.Parent, ExitButton)

for _, inningScore in pairs(AwayScores:GetChildren()) do
	inningScore.Changed:Connect(function()
		ScoreboardFrame.Frame.Away.Innings[inningScore.Name].Score.Text = inningScore.Value
	end)
	
	ScoreboardFrame.Frame.Away.Innings[inningScore.Name].Score.Text = inningScore.Value
end

for _, inningScore in pairs(HomeScores:GetChildren()) do
	inningScore.Changed:Connect(function()
		ScoreboardFrame.Frame.Home.Innings[inningScore.Name].Score.Text = inningScore.Value
	end)
	
	ScoreboardFrame.Frame.Home.Innings[inningScore.Name].Score.Text = inningScore.Value
end

ScoreboardValues.AwayScore.Changed:Connect(function()
	ScoreboardFrame.Frame.Away.Runs.RunLabelFrame.Score.Text = ScoreboardValues.AwayScore.Value
end)
ScoreboardFrame.Frame.Away.Runs.RunLabelFrame.Score.Text = ScoreboardValues.AwayScore.Value

ScoreboardValues.HomeScore.Changed:Connect(function()
	ScoreboardFrame.Frame.Home.Runs.RunLabelFrame.Score.Text = ScoreboardValues.HomeScore.Value
end)
ScoreboardFrame.Frame.Home.Runs.RunLabelFrame.Score.Text = ScoreboardValues.HomeScore.Value

GameValues.AwayTeamPicked.Changed:Connect(function()
	if TeamsModule[GameValues.AwayTeamPicked.Value] ~= nil then
		ScoreboardFrame.Frame.Away.TeamLabel.Text = TeamsModule[GameValues.AwayTeamPicked.Value].Abbreviation
	end
end)

if TeamsModule[GameValues.AwayTeamPicked.Value] ~= nil then
	ScoreboardFrame.Frame.Away.TeamLabel.Text = TeamsModule[GameValues.AwayTeamPicked.Value].Abbreviation
end

GameValues.HomeTeamPicked.Changed:Connect(function()
	if TeamsModule[GameValues.HomeTeamPicked.Value] ~= nil then
		ScoreboardFrame.Frame.Home.TeamLabel.Text = TeamsModule[GameValues.HomeTeamPicked.Value].Abbreviation
	end
end)

if TeamsModule[GameValues.HomeTeamPicked.Value] ~= nil then
	ScoreboardFrame.Frame.Home.TeamLabel.Text = TeamsModule[GameValues.HomeTeamPicked.Value].Abbreviation
end