local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local SharedModules = ReplicatedStorage.SharedModules
local SharedGUIs = ReplicatedStorage.SharedGUIs
local Remotes = ReplicatedStorage.RemoteEvents
local SharedData = ReplicatedStorage.SharedData

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local mouse = player:GetMouse()  

local SelectPlayersFolder = workspace.SelectPlayers
local GameValues = ReplicatedStorage.GameValues
local MessageValues = GameValues.MessageValues
local PlayerSelectStatusObj = MessageValues.PlayerSelectStatus
local GameStatusGui = playerGui:WaitForChild("GameStatus", 3)
local GameStatusFrame = GameStatusGui.Frame
local Frame = script.Parent.Frame

local TeamsModule = require(SharedModules.Teams)

local hiddenYPos = GameStatusFrame.Position.Y.Scale + (Frame.Size.Y.Scale / 3)
local visibleYPos = 0.135--0.11

Frame.Position = UDim2.new(Frame.Position.X.Scale, 0, hiddenYPos, 0)

local function removeAllBillboards()
	for _, part in pairs(SelectPlayersFolder:GetChildren()) do
		local billboardGui = part:FindFirstChildOfClass("BillboardGui")
		if billboardGui then
			billboardGui:Destroy()
		end
	end
end

local function isEligibleSelector()
	if GameValues.PlayerSelectPhase.Value ~= "" and player == GameValues[GameValues.PlayerSelectPhase.Value.."Captain"].Value then
		return true
	else
		return false
	end
end

local function addClickDetector(playerStand)
	if playerStand.Player.Value ~= nil and isEligibleSelector() then
		if playerStand:FindFirstChild("ClickDetector") == nil then
			local clickDetector = Instance.new("ClickDetector")
			clickDetector.MaxActivationDistance = 500
			clickDetector.Parent = playerStand

			clickDetector.MouseClick:Connect(function()
				if isEligibleSelector() then
					Remotes.PlayerSelect:FireServer(playerStand.Player.Value)
				end
			end)
		end
	else
		if playerStand:FindFirstChild("ClickDetector") then
			playerStand.ClickDetector:Destroy()
		end
	end
end

local function showStatus()
	Frame.Label.Text = PlayerSelectStatusObj.Value
	
	local teamDesignation = GameValues.PlayerSelectPhase.Value
	Frame.BackgroundColor3 = TeamsModule[GameValues[teamDesignation.."TeamPicked"].Value].PrimaryColor

	if PlayerSelectStatusObj.Value == "" then 
		if Frame.Position.Y.Scale ~= hiddenYPos then
			--Frame:TweenPosition(UDim2.new(Frame.Position.X.Scale, 0, hiddenYPos, 0), 'Out', 'Quint', 0.5)
			Frame:TweenSizeAndPosition(UDim2.new(0.25,0,0,0), UDim2.new(Frame.Position.X.Scale, 0, visibleYPos, 0), 'Out', 'Linear', 0.1)
			Frame.UIStroke.Thickness = 0
			Frame.Label.UIStroke.Thickness = 0
		end
		
		if playerGui:FindFirstChild("PlayerSelectGamepad") then
			playerGui.PlayerSelectGamepad:Destroy()
		end
	else
		if Frame.Position.Y.Scale ~= visibleYPos then
			--Frame:TweenPosition(UDim2.new(Frame.Position.X.Scale, 0, visibleYPos, 0), 'In', 'Quint', 0.5)
			Frame:TweenSizeAndPosition(UDim2.new(0.25,0,0.05,0), UDim2.new(Frame.Position.X.Scale, 0, visibleYPos, 0), 'In', 'Linear', 0.1)
			Frame.UIStroke.Thickness = 2
			Frame.Label.UIStroke.Thickness = 2
		end
		removeAllBillboards()
		
		local playerGamepadSelectGui = SharedGUIs.PlayerSelectGamepad:Clone()
		
		for _, playerStand in pairs(SelectPlayersFolder:GetChildren()) do	
			if isEligibleSelector() then
				if playerStand.Player.Value ~= nil then
					local playerSelectButton = SharedGUIs.PlayerSelect:Clone()
					playerSelectButton.Name = playerStand.Player.Value.Name
					
					if SharedData:FindFirstChild(playerStand.Player.Value.Name) then
						playerSelectButton.OVR.Text = SharedData[playerStand.Player.Value.Name].OVR.Value.." OVR"
					end
					
					playerSelectButton.Parent = playerGamepadSelectGui.Frame.Background.Container
					
					addClickDetector(playerStand)
				end
			else
				if playerStand:FindFirstChild("ClickDetector") then
					playerStand.ClickDetector:Destroy()
				end
			end
		end
		
		if UIS.GamepadEnabled and isEligibleSelector() and playerGui:FindFirstChild("PlayerSelectGamepad") == nil then
			playerGamepadSelectGui.Parent = playerGui
		else
			playerGamepadSelectGui = nil
		end
	end
end

if GameValues.PlayerSelectPhase.Value ~= "" then
	showStatus()
end

PlayerSelectStatusObj.Changed:connect(function()
	showStatus()
end)

for _, playerStand in pairs(SelectPlayersFolder:GetChildren()) do	
	playerStand.Player.Changed:Connect(function()
		addClickDetector(playerStand)
	end)
end

local previousTarget = nil

local function removeBillboard(target)
	local billboardGui = target:FindFirstChildOfClass("BillboardGui")
	if billboardGui then
		billboardGui:Destroy()
	end
end

local function addBillboard(target)
	local billboardGui = SharedGUIs.PlayerSelectBillboard:Clone()
	billboardGui.Label.Text = target.Player.Value.Name
	
	if SharedData:FindFirstChild(target.Player.Value.Name) then
		billboardGui.OVR.Text = SharedData[target.Player.Value.Name].OVR.Value.." OVR"
	else
		billboardGui.OVR.Visible = false
	end
	
	billboardGui.Parent = target
	billboardGui.Adornee = target
end

RunService.RenderStepped:Connect(function()
	if mouse.Target and mouse.Target.Parent and mouse.Target.Parent.Name == "SelectPlayers" and isEligibleSelector() then
		if previousTarget ~= nil then
			removeBillboard(previousTarget)
		end

		if mouse.Target.Player.Value ~= nil then
			addBillboard(mouse.Target)
			previousTarget = mouse.Target
		end
	elseif previousTarget ~= nil then
		removeBillboard(previousTarget)
		previousTarget = nil
	end
	
	if isEligibleSelector() then
		script.Parent.TooltipLabel.Visible = true
		script.Parent.TooltipTitle.Visible = true
	else
		script.Parent.TooltipLabel.Visible = false
		script.Parent.TooltipTitle.Visible = false
	end
end)