local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local Remotes = ReplicatedStorage.RemoteEvents

local MessageLabel = script.Label
local defaultPosition = MessageLabel.Position
local hiddenPosition = UDim2.new(MessageLabel.Position.X.Scale, 0, 1.2, 0)
local tweenTime = 0.5

local player = Players.LocalPlayer

Remotes.BatResults.OnClientEvent:Connect(function(message)
	if player.TeamColor == Teams.Lobby.TeamColor then
		return
	end
	
	if player.Character and player.Character:FindFirstChild("States") and player.Character.States.InStylesLocker.Value then
		return
	end
	
	if script.Parent:FindFirstChild("Label") then
		script.Parent.Label:Destroy()
	end
	
	local messageLabelNew = MessageLabel:Clone()
	messageLabelNew.Parent = script.Parent
	
	local text = message
	local easingStyleIn = "Back"
	local easingStyleOut = "Back"
	
	if message == "Strike" then
		text = "STRIKE!!"
	elseif message == "Ball" then
		text = "BALL!"
	elseif message == "Out" then
		text = "OUT!!!"
		easingStyleOut = "Bounce"
	elseif message == "Flyout" then
		text = "FLYOUT!"
		easingStyleOut = "Bounce"
	end
	
	--MessageLabel.Position = UDim2.new(MessageLabel.Position.X.Scale, 0, defaultYPosition, 0)
	messageLabelNew.Position = hiddenPosition
	messageLabelNew:TweenPosition(defaultPosition, 'Out', easingStyleOut, tweenTime)
	messageLabelNew.Text = text
	wait(4)
	if messageLabelNew and messageLabelNew.Parent and messageLabelNew.Parent == script.Parent then
		messageLabelNew:TweenPosition(hiddenPosition, 'In', easingStyleIn, tweenTime)
	end
	wait(tweenTime)
	if messageLabelNew then
		messageLabelNew.Text = ""
		messageLabelNew:Destroy()
	end
end)