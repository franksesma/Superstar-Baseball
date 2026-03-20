local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local CAS = game:GetService("ContextActionService")

local Remotes = ReplicatedStorage.RemoteEvents
local SharedModules = ReplicatedStorage.SharedModules
local SharedData = ReplicatedStorage.SharedData
local GameValues = ReplicatedStorage.GameValues
local OnBase = GameValues.OnBase

local TeamsModule = require(SharedModules.Teams)
local GuiAnimationModule = require(SharedModules.GuiAnimation)
local ClientFunctions = require(SharedModules.ClientFunctions)

local player = Players.LocalPlayer

local function setVisibleReturnToLobby(enabled)
	script.Parent.ReturnToLobby.Visible = enabled
	script.Parent.ReturnToLobby.Selectable = enabled
	script.Parent.ReturnToLobby.Active = enabled
	script.Parent.ReturnToLobby.Interactable = enabled
end

local function setVisiblePlayButton(enabled)
	script.Parent.PlayButton.Interactable = enabled
	script.Parent.PlayButton.Active = enabled
	script.Parent.PlayButton.Selectable = enabled
	script.Parent.PlayButton.Visible = enabled
end

local function setVisibleDailyRewardsButton(enabled)
	script.Parent.DailyRewardsButton.Interactable = enabled
	script.Parent.DailyRewardsButton.Active = enabled
	script.Parent.DailyRewardsButton.Selectable = enabled
	script.Parent.DailyRewardsButton.Visible = enabled
end

local function setVisibleServerCodeButton(enabled)
	script.Parent.LeagueServerCodeButton.Interactable = enabled
	script.Parent.LeagueServerCodeButton.Active = enabled
	script.Parent.LeagueServerCodeButton.Selectable = enabled
	script.Parent.LeagueServerCodeButton.Visible = enabled
end

local function setSpectateUI(enabled)
	script.Parent.SpectateFrame.Next.Interactable = enabled
	script.Parent.SpectateFrame.Next.Active = enabled
	script.Parent.SpectateFrame.Next.Selectable = enabled
	
	script.Parent.SpectateFrame.Prev.Interactable = enabled
	script.Parent.SpectateFrame.Prev.Active = enabled
	script.Parent.SpectateFrame.Prev.Selectable = enabled
	
	script.Parent.SpectateFrame.Exit.Interactable = enabled
	script.Parent.SpectateFrame.Exit.Active = enabled
	script.Parent.SpectateFrame.Exit.Selectable = enabled
end

Remotes.ShowReturnToLobby.OnClientEvent:Connect(function(enabled)
	if GameValues.ServerType.Value ~= "ReservedServer" then
		setVisibleReturnToLobby(enabled)
	end
end)


local returnToLobbyClicked = false
GuiAnimationModule.SetupShrinkButton(script.Parent.ReturnToLobby)
script.Parent.ReturnToLobby.MouseButton1Click:Connect(function()
	if GameValues.CurrentBatter.Value == player then
		ClientFunctions.Notification(player, "You cannot return to the lobby while you are at bat!", "Alert")
		return
	end

	if OnBase:FindFirstChild(player.Name) then
		ClientFunctions.Notification(player, "You cannot return to the lobby while you are on base!", "Alert")
		return
	end

	if not returnToLobbyClicked then
		returnToLobbyClicked = true
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		CAS:UnbindAction("PracticeSwing")
		CAS:UnbindAction("PracticeThrowPitch")
		Remotes.ReturnToLobby:FireServer()
		wait(1)
		returnToLobbyClicked = false
	end
end)

GuiAnimationModule.SetupShrinkButton(script.Parent.PlayButton)
script.Parent.PlayButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	Remotes.PlayGame:FireServer()
end)

script.Parent.LeagueServerCodeButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	
	if script.Parent.LeagueServerCodeButton.CodeLabel.Visible then
		script.Parent.LeagueServerCodeButton.CodeLabel.Visible = false
		script.Parent.LeagueServerCodeButton.Label.Text = "SHOW SERVER CODE"
	else
		script.Parent.LeagueServerCodeButton.CodeLabel.Text = GameValues.LeagueServerCode.Value
		script.Parent.LeagueServerCodeButton.CodeLabel.Visible = true
		script.Parent.LeagueServerCodeButton.Label.Text = "HIDE SERVER CODE"
	end 
end)

if player.TeamColor == Teams.Lobby.TeamColor then
	setVisiblePlayButton(true)
	setVisibleDailyRewardsButton(true)
	setSpectateUI(true)
	
	if GameValues.LeagueServerCode.Value ~= "" then
		setVisibleServerCodeButton(true)
	end
else
	if GameValues.ServerType.Value ~= "ReservedServer" then
		setVisibleReturnToLobby(true)
	end
	setSpectateUI(false)
end

player:GetPropertyChangedSignal("TeamColor"):Connect(function()
	if player.TeamColor == Teams.Lobby.TeamColor then
		setVisiblePlayButton(true)
		setVisibleDailyRewardsButton(true)
		setVisibleReturnToLobby(false)
		setSpectateUI(true)
		
		if GameValues.LeagueServerCode.Value ~= "" then
			setVisibleServerCodeButton(true)
		end
	else
		setVisiblePlayButton(false)
		setVisibleDailyRewardsButton(false)
		setSpectateUI(false)
		setVisibleServerCodeButton(false)
		if GameValues.ServerType.Value ~= "ReservedServer" then
			setVisibleReturnToLobby(true)
		end
	end
end)

if UserInputService.TouchEnabled then
	script.Parent.IgnoreGuiInset = false
	script.Parent.ReturnToLobby.Position = UDim2.new(.075, 0, .075, 0)
end