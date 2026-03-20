local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedDataFolder = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local Remotes = ReplicatedStorage.RemoteEvents

local GuiAnimationModule = require(SharedModules.GuiAnimation)
local RankedUtilities = require(SharedModules.RankedUtilities)

local ExitButton = script.Parent.ExitButton
local SubFrame = script.Parent.SubFrame
local TeamFrame = SubFrame.Team
local ProgressFrame = SubFrame.Progress
local QueueButton = SubFrame.QueueButton
local OnButton = SubFrame.OnButton

local player = Players.LocalPlayer

local inQueue = false

local function updateFriendsOnly(enabled)
	if enabled then
		OnButton.BackgroundColor3 = Color3.fromRGB(85, 170, 0)
		OnButton.Label.Text = "ON"
		OnButton.Label.UIStroke.Color = Color3.fromRGB(81, 162, 0)
		OnButton.UIStroke.Color = Color3.fromRGB(113, 226, 0)
	else
		OnButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
		OnButton.Label.Text = "OFF"
		OnButton.Label.UIStroke.Color = Color3.fromRGB(255, 0, 0)
		OnButton.UIStroke.Color = Color3.fromRGB(255, 0, 0)
	end
end

local function updateQueued(enabled)
	if enabled then
		inQueue = true
		QueueButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
		QueueButton.Label.Text = "CANCEL"
		QueueButton.Label.UIStroke.Color = Color3.fromRGB(255, 0, 0)
		QueueButton.UIStroke.Color = Color3.fromRGB(255, 0, 0)
		
		script.Parent.InQueueLabel.Visible = true
		local counter = 0
		while inQueue do
			local minutes = math.floor(counter / 60)
			local seconds = counter % 60
			script.Parent.InQueueLabel.Text = string.format("Searching.. (%02d:%02d)", minutes, seconds)

			task.wait(1)
			counter = counter + 1
		end
	else
		inQueue = false
		QueueButton.BackgroundColor3 = Color3.fromRGB(170, 255, 0)
		QueueButton.Label.Text = "QUEUE"
		QueueButton.Label.UIStroke.Color = Color3.fromRGB(46, 139, 0)
		QueueButton.UIStroke.Color = Color3.fromRGB(85, 255, 0)
		script.Parent.InQueueLabel.Visible = false
	end
end

Remotes.UpdateRankedLobbyPartyUI.OnClientEvent:Connect(function(partyData, lobbyType)
	if partyData then
		script.Parent.LabelFrame.Label.Text = "RANKED QUEUE - "..lobbyType
		SubFrame.TeamLabel.Text = `Your Team ({#partyData.Players}/{RankedUtilities.LobbyTypes[lobbyType].Size})`
		
		updateFriendsOnly(partyData.FriendsOnly)
		updateQueued(partyData.LobbyQueued)
		
		for _, frame in pairs(TeamFrame.ScrollingFrame:GetChildren()) do
			if frame:IsA("Frame") then
				frame:Destroy()
			end
		end
		
		if partyData.Players[1] == player then
			OnButton.Selectable = true
			OnButton.Active = true
			OnButton.Interactable = true
			OnButton.AutoButtonColor = true
			
			QueueButton.Selectable = true
			QueueButton.Active = true
			QueueButton.Interactable = true
			QueueButton.AutoButtonColor = true
		else
			OnButton.Selectable = false
			OnButton.Active = false
			OnButton.Interactable = false
			OnButton.AutoButtonColor = false
			
			QueueButton.Selectable = false
			QueueButton.Active = false
			QueueButton.Interactable = false
			QueueButton.AutoButtonColor = false
		end
		
		for i, teammatePlayer in pairs(partyData.Players) do
			if teammatePlayer then
				local teammmateCard = script.TeammateCard:Clone()
				if i == 1 then
					teammmateCard.HostIcon.Visible = true
				end
				
				teammmateCard.Name = teammatePlayer.Name
				
				if SharedDataFolder:FindFirstChild(teammatePlayer.Name) and SharedDataFolder[teammatePlayer.Name]:FindFirstChild("RankedElo") then
					local rankedRating = RankedUtilities.GetRankByElo(SharedDataFolder[teammatePlayer.Name].RankedElo.Value)
					teammmateCard.RankIcon.Image = RankedUtilities.RankIcons[rankedRating]
				end

				local success, img = pcall(function()
					return Players:GetUserThumbnailAsync(teammatePlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
				end)

				if success and img and teammatePlayer.UserId > 0 then
					teammmateCard.PlayerIcon.Image = img
				else
					teammmateCard.PlayerIcon.Image = "rbxassetid://135927875061357"
				end

				teammmateCard.PlayerName.Text = teammatePlayer.Name
				
				if player == partyData.Players[1] and teammatePlayer ~= player then -- isHost
					teammmateCard.KickButton.Visible = true
					
					GuiAnimationModule.SetupShrinkButton(teammmateCard.KickButton)
					teammmateCard.KickButton.MouseButton1Click:Connect(function()
						GuiAnimationModule.ButtonPress(player, "PositiveClick")
						Remotes.KickFromRankedLobbyParty:FireServer(teammatePlayer)
					end)
				end
				
				teammmateCard.Parent = TeamFrame.ScrollingFrame
 			end
		end
	end
end)

Remotes.ToggleRankedPartyFriendsOnly.OnClientEvent:Connect(function(enabled)
	updateFriendsOnly(enabled)
end)

Remotes.ToggleRankedQueue.OnClientEvent:Connect(function(enabled)
	updateQueued(enabled)
end)

GuiAnimationModule.SetupShrinkButton(QueueButton)
ExitButton.MouseButton1Click:Connect(function()
	local playerGui = player:WaitForChild("PlayerGui")
	local mainGui = playerGui:WaitForChild("MainGui")
	local lobbyRelatedUI = playerGui:WaitForChild("LobbyRelatedUI")
	
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	Remotes.LeaveRankedLobbyParty:FireServer()
	
	mainGui.Enabled = true
	lobbyRelatedUI.Enabled = true
	script.Parent.Parent.Parent:Destroy()
end)

GuiAnimationModule.SetupShrinkButton(QueueButton)
QueueButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	Remotes.ToggleRankedQueue:FireServer()
end)

GuiAnimationModule.SetupShrinkButton(OnButton)
OnButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	Remotes.ToggleRankedPartyFriendsOnly:FireServer()
end)

local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")
local lobbyRelatedUI = playerGui:WaitForChild("LobbyRelatedUI")

lobbyRelatedUI.Enabled = false
mainGui.Enabled = false

local RankedProgress = Remotes.GetRankedProgress:InvokeServer()

local rankedRating = RankedUtilities.GetRankByElo(RankedProgress.ELO)

ProgressFrame.Wins.Text = "Wins: "..RankedProgress.Wins
ProgressFrame.Losses.Text = "Losses: "..RankedProgress.Losses
ProgressFrame.RankLabel.Text = rankedRating
ProgressFrame.EloLabel.Text = RankedProgress.ELO.." Elo"
ProgressFrame.RankIcon.Image = RankedUtilities.RankIcons[rankedRating]

for i, tier in pairs(RankedUtilities.RankedRatings) do
	if tier.Name == rankedRating then
		local tierMin = tier.Min
		local tierMax = tier.Max
		local tierRange = tierMax - tierMin
		local progressInTier = RankedProgress.ELO - tierMin

		local progressRatio = math.clamp(progressInTier / tierRange, 0, 1)

		ProgressFrame.ProgressBar.Bar.Size = UDim2.new(progressRatio, 0, 1, 0)
		
		if tier.Name == "Superstar" then
			ProgressFrame.ProgressBar.ToGo.Text = `{RankedProgress.ELO} Elo`
		else
			ProgressFrame.ProgressBar.ToGo.Text = `{tier.Max - RankedProgress.ELO} Elo until {RankedUtilities.RankedRatings[i + 1].Name}`
		end

		break
	end
end