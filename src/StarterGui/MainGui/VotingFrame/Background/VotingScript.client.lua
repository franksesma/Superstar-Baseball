local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")

local SharedDataFolder = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local Remotes = ReplicatedStorage.RemoteEvents

local GuiAnimationModule = require(SharedModules.GuiAnimation)
local ClientFunctions = require(SharedModules.ClientFunctions)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local ExitButton = script.Parent.ExitButton
local Container = script.Parent.Container

local buttonSelected = nil

local debounce = false

local function loadTeamMembers()
	if player.TeamColor ~= Teams["No Team"].TeamColor and player.TeamColor ~= Teams.Lobby.TeamColor then
		local mostVotedPitcher = ClientFunctions.GetMostVotedPitcher(player.TeamColor)
		
		for _, otherPlayer in pairs(ClientFunctions.GetPlayersInGame()) do
			--print(otherPlayer.Name.." | "..otherPlayer.Team.Name)
			if otherPlayer.TeamColor == player.TeamColor then
				local button = script.PlayerVote:Clone()
				button.Name = otherPlayer.Name
				button.PlayerName.Text = otherPlayer.Name
				
				if mostVotedPitcher == otherPlayer.Name then
					button.MostVoted.Visible = true
				end
				
				button.Parent = Container
				
				button.MouseButton1Click:Connect(function()
					if not debounce then
						debounce = true
						GuiAnimationModule.ButtonPress(player, "PositiveClick")
						
						if buttonSelected ~= nil and buttonSelected:FindFirstChild("UIStroke") then
							buttonSelected.BackgroundColor3 = Color3.fromRGB(170, 255, 255)
							buttonSelected.UIStroke.Color = Color3.fromRGB(255, 255, 255)
						end
						
						buttonSelected = button
						button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
						button.UIStroke.Color = Color3.fromRGB(0, 255, 255)
						
						Remotes.VotePitcher:FireServer(button.Name)
						wait()
						debounce = false
					end
				end)
			end
		end
	end
end

local function addTeamMember(newPlayer)
	if player.TeamColor ~= Teams["No Team"].TeamColor and player.TeamColor ~= Teams.Lobby.TeamColor then
		local button = script.PlayerVote:Clone()
		button.Name = newPlayer.Name
		button.PlayerName.Text = newPlayer.Name

		button.Parent = Container

		button.MouseButton1Click:Connect(function()
			if not debounce then
				debounce = true
				GuiAnimationModule.ButtonPress(player, "PositiveClick")

				if buttonSelected ~= nil and buttonSelected:FindFirstChild("UIStroke") then
					buttonSelected.BackgroundColor3 = Color3.fromRGB(170, 255, 255)
					buttonSelected.UIStroke.Color = Color3.fromRGB(255, 255, 255)
				end

				buttonSelected = button
				button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
				button.UIStroke.Color = Color3.fromRGB(0, 255, 255)

				Remotes.VotePitcher:FireServer(button.Name)
				wait()
				debounce = false
			end
		end)
	end
end

local function updateMostVoted(mostVotedPlayerName)
	for _, button in pairs(Container:GetChildren()) do
		if button:IsA("TextButton") then
			if button.Name == mostVotedPlayerName then
				button.MostVoted.Visible = true
			else
				button.MostVoted.Visible = false
			end
		end
	end
end

local function onTeamChanged()
	for _, button in pairs(Container:GetChildren()) do
		if button:IsA("TextButton") then
			button:Destroy()
		end
	end
	
	loadTeamMembers()
end

loadTeamMembers()

local function trackTeamChangeExistingPlayers()
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			otherPlayer:GetPropertyChangedSignal("Team"):Connect(function()
				if otherPlayer.Team == player.Team then
					addTeamMember(otherPlayer)
				elseif Container:FindFirstChild(otherPlayer.Name) then
					Container[otherPlayer.Name]:Destroy()
				end
			end)
		end
	end
end

trackTeamChangeExistingPlayers()

Players.PlayerAdded:Connect(function(newPlayer)
	newPlayer:GetPropertyChangedSignal("Team"):Connect(function()
		if newPlayer.Team == player.Team then
			addTeamMember(newPlayer)
		elseif Container:FindFirstChild(newPlayer.Name) then
			Container[newPlayer.Name]:Destroy()
		end
	end)
	
	if newPlayer.Team == player.Team then
		addTeamMember(newPlayer)
	end
end)

Players.PlayerRemoving:Connect(function(removedPlayer)
	if Container:FindFirstChild(removedPlayer.Name) then
		Container[removedPlayer.Name]:Destroy()

		updateMostVoted(ClientFunctions.GetMostVotedPitcher(player.TeamColor))
	end
end)

player:GetPropertyChangedSignal("Team"):Connect(onTeamChanged)

Remotes.VotePitcher.OnClientEvent:Connect(function(mostVotedPlayerName) -- updated pitcher
	updateMostVoted(mostVotedPlayerName)
end)

GuiAnimationModule.ExitButtonPressed(player, script.Parent.Parent, ExitButton)