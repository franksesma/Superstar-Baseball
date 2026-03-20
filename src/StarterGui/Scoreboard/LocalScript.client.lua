local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local GameValues = ReplicatedStorage.GameValues
local ScoreboardValues = GameValues.ScoreboardValues
local Remotes = ReplicatedStorage.RemoteEvents
local OnBase = GameValues.OnBase
local AtBat = ScoreboardValues.AtBat
local Outs = ScoreboardValues.Outs
local Strikes = ScoreboardValues.Strikes
local Balls = ScoreboardValues.Balls
local Inning = ScoreboardValues.Inning
local PitchClockEnabled = ScoreboardValues.PitchClockEnabled
local PitchClock = PitchClockEnabled.Clock
local AwayScore = ScoreboardValues.AwayScore
local HomeScore = ScoreboardValues.HomeScore
local AwayTeamPicked = GameValues.AwayTeamPicked
local HomeTeamPicked = GameValues.HomeTeamPicked
local SharedModules = ReplicatedStorage.SharedModules
local SharedData = ReplicatedStorage.SharedData

local ScoreboardGui = script.Parent
local AtBatFrame = ScoreboardGui.AtBatFrame

local BasesFrame = ScoreboardGui.BasesFrame
local GameFrame = ScoreboardGui.GameFrame

local TeamsModule = require(SharedModules.Teams)
local GuiAnimationModule = require(SharedModules.GuiAnimation)
local ClientFunctions = require(SharedModules.ClientFunctions)

local player = Players.LocalPlayer

local PlayerGui = player:WaitForChild("PlayerGui")
local MainGui = PlayerGui:WaitForChild("MainGui")
local OVRFrame = MainGui.OVRFrame

local function updateAtBatGui(stat)
	local pluralStatName = stat.."s"
	local statValue = ScoreboardValues[pluralStatName].Value
	
	local StatFrame = AtBatFrame:FindFirstChild(pluralStatName.."Frame")
	
	for i = 1, 4 do
		local StatCounterFrame = StatFrame:FindFirstChild(stat..i)
				
		if StatCounterFrame then
			if i <= statValue then
				StatCounterFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			else
				StatCounterFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
	end
end

local function getInningSuffixes(num)
	if num % 10 == 1 and num % 100 ~= 11 then
		return num .. "st"
	elseif num % 10 == 2 and num % 100 ~= 12 then
		return num .. "nd"
	elseif num % 10 == 3 and num % 100 ~= 13 then
		return num .. "rd"
	else
		return num .. "th"
	end
end

local function resetInningBoxColors(atBatVal)
	for _, inningBox in pairs(MainGui.StatsFrame.Background.ScoreboardFrame.Frame[atBatVal].Innings:GetChildren()) do
		if inningBox:IsA("Frame") then
			inningBox.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		end
	end
end

local function updateInning()
	local inning = getInningSuffixes(Inning.Value)
	local inningType;
	
	if AtBat.Value == "Home" then
		inningType = "BOT"
		GameFrame.CurrentBatter.Position = UDim2.new(0.03, 0, 0.719, 0)
	else
		inningType = "TOP"
		GameFrame.CurrentBatter.Position = UDim2.new(0.72, 0, 0.719, 0)
	end
	
	resetInningBoxColors("Home")
	resetInningBoxColors("Away")
	if AtBat.Value ~= "" then
		if Inning.Value > 5 then
			MainGui.StatsFrame.Background.ScoreboardFrame.Frame[AtBat.Value].Innings["OT"].BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			
			inningType = inningType.." (OT)"
		else
			MainGui.StatsFrame.Background.ScoreboardFrame.Frame[AtBat.Value].Innings[Inning.Value].BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		end
	end
	
	GameFrame.Inning.Text = inning.." INN "..inningType
end

local function updatePitchClock()
	if PitchClock.Value < 10 then
		ScoreboardGui.PitchClock.Label.Text = ":0"..PitchClock.Value
	else
		ScoreboardGui.PitchClock.Label.Text = ":"..PitchClock.Value
	end
	
	if PitchClock.Value < 5 then
		ScoreboardGui.PitchClock.Label.TextColor3 = Color3.fromRGB(255, 0, 0)
	else
		ScoreboardGui.PitchClock.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	
	if workspace:FindFirstChild("PitcherCircle") then
		workspace.PitcherCircle.Display.Label3.Text = "AI will take over in "..tostring(PitchClock.Value)
	end
end

local function enablePitchClock(enabled)
	if enabled then
		updatePitchClock()
		ScoreboardGui.PitchClock.Visible = true
	else
		ScoreboardGui.PitchClock.Visible = false
	end
end

local function updateOnBase()
	for _, baseUI in pairs(BasesFrame:GetChildren()) do -- reset
		if string.match(baseUI.Name, "Locked") then
			baseUI.Visible = false
		else
			baseUI.ImageColor3 = Color3.fromRGB(255,255,255)
		end
	end
	
	for _, baseTracker in pairs(OnBase:GetChildren()) do -- update
		if BasesFrame:FindFirstChild(baseTracker.Value) then
			BasesFrame[baseTracker.Value].ImageColor3 = Color3.fromRGB(0, 255, 0)
		end
		
		if baseTracker:FindFirstChild("LockedInBase") then
			if BasesFrame:FindFirstChild(baseTracker.Value.." Locked") then
				BasesFrame[baseTracker.Value.." Locked"].Visible = baseTracker.LockedInBase.Value
			end
		end
	end
end

local function updateScore()
	GameFrame.HomeScore.Text = HomeScore.Value
	GameFrame.AwayScore.Text = AwayScore.Value
end

local function updateTeamlogos()
	if AwayTeamPicked.Value ~= "" then
		GameFrame.AwayLogo.Image = TeamsModule[AwayTeamPicked.Value].CountryIcon
		GameFrame.AwayLogo.Label.Text = TeamsModule[AwayTeamPicked.Value].Abbreviation
		GameFrame.AwayLogo.BackgroundColor3 = TeamsModule[AwayTeamPicked.Value].PrimaryColor
	end
	
	if HomeTeamPicked.Value ~= "" then
		GameFrame.HomeLogo.Image = TeamsModule[HomeTeamPicked.Value].CountryIcon
		GameFrame.HomeLogo.Label.Text = TeamsModule[HomeTeamPicked.Value].Abbreviation
		GameFrame.HomeLogo.BackgroundColor3 = TeamsModule[HomeTeamPicked.Value].PrimaryColor
	end
end

updateAtBatGui("Ball")
updateAtBatGui("Out")
updateAtBatGui("Strike")
updateInning()
updateOnBase()
enablePitchClock(PitchClockEnabled.Value)
updateScore()
updateTeamlogos()

for _, baseTracker in pairs(OnBase:GetChildren()) do
	if baseTracker then
		baseTracker.Changed:Connect(function()
			updateOnBase()
		end)

		if baseTracker:WaitForChild("LockedInBase", 1) then
			baseTracker.LockedInBase.Changed:Connect(function()
				updateOnBase()
			end)
		end
	end
end

Balls.Changed:Connect(function()
	updateAtBatGui("Ball")
end)

Strikes.Changed:Connect(function()
	updateAtBatGui("Strike")
end)

Outs.Changed:Connect(function()
	updateAtBatGui("Out")
end)

AtBat.Changed:Connect(function()
	updateInning()
end)

Inning.Changed:Connect(function()
	updateInning()
end)

PitchClockEnabled.Changed:Connect(function()
	enablePitchClock(PitchClockEnabled.Value)
end)

PitchClock.Changed:Connect(function()
	updatePitchClock()
end)

OnBase.ChildAdded:Connect(function(baseTracker)
	baseTracker.Changed:Connect(function()
		updateOnBase()
	end)
	
	baseTracker:WaitForChild("LockedInBase", 1).Changed:Connect(function()
		updateOnBase()
	end)
end)

OnBase.ChildRemoved:Connect(function()
	updateOnBase()
end)

HomeScore.Changed:Connect(function()
	updateScore()
end)

AwayScore.Changed:Connect(function()
	updateScore()
end)

AwayTeamPicked.Changed:Connect(function()
	updateTeamlogos()
end)

HomeTeamPicked.Changed:Connect(function()
	updateTeamlogos()
end)

local PlayerData = SharedData:WaitForChild(player.Name)

if PlayerData then
	local function updateOVRProgress()
		script.Parent.OVRButton.OVRLabel.Text = PlayerData.OVR.Value
		OVRFrame.Background.OVRBackground.Overall.OVR.Text = PlayerData.OVR.Value 

		local XPToNextTier = 200 * PlayerData.OVR.Value

		if XPToNextTier > 99999 then
			XPToNextTier = 99999
		end

		script.Parent.OVRButton.Meter:TweenSizeAndPosition(UDim2.new(1, 0, PlayerData.XP.Value/XPToNextTier, 0), UDim2.new(0, 0, 1-(PlayerData.XP.Value/XPToNextTier), 0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.1, true)
		OVRFrame.Background.OVRBackground.Bar.Bar:TweenSize(UDim2.new(PlayerData.XP.Value/XPToNextTier, 0, 1, 0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.1, true)
		
		OVRFrame.Background.OVRBackground.Bar.ProgressLabel.Text = PlayerData.XP.Value.."/"..XPToNextTier.." XP ("..math.floor((PlayerData.XP.Value/XPToNextTier) * 100).."%)"
	end

	PlayerData:WaitForChild("XP").Changed:Connect(function()
		updateOVRProgress()
	end)

	PlayerData:WaitForChild("OVR").Changed:Connect(function()
		updateOVRProgress()
	end)

	updateOVRProgress()
end