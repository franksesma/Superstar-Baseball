local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local PlayerGui = player.PlayerGui
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Remotes = ReplicatedStorage.RemoteEvents

local ClientFunctions = require(SharedModules:WaitForChild("ClientFunctions"))
local GuiAnimationModule = require(SharedModules.GuiAnimation)

local exitButton = script.Parent:WaitForChild("ExitButton")
local buttonsFrame = script.Parent.ButtonsFrame
local createSubFrame = script.Parent.CreateFrame
local joinSubFrame = script.Parent.JoinFrame
local createServerButton = createSubFrame.ConfirmButton
local joinServerButton = joinSubFrame.JoinButton
local serverIDTextBox = joinSubFrame.TextBox
local createServerDebounce = false

local frames = {
	[buttonsFrame.Create] = script.Parent.CreateFrame;
	[buttonsFrame.Join] = script.Parent.JoinFrame;
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

GuiAnimationModule.SetupShrinkButton(exitButton)
exitButton.Activated:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	
	script.Parent.Parent.Parent:Destroy()
end)

GuiAnimationModule.SetupGrowButton(createServerButton)
createServerButton.Activated:Connect(function()
	if createServerDebounce then return end
	
	createServerDebounce = true
	
	createServerButton.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
	createServerButton.Interactable = false
	
	GuiAnimationModule.ButtonPress(player, "PositiveClick")

	Remotes.LeagueServer.CreateLeagueServer:FireServer()
	
	task.wait(5)
	
	createServerButton.BackgroundColor3 = Color3.fromRGB(112, 112, 112)
	createServerButton.Interactable = true
	
	createServerDebounce = false
end)

GuiAnimationModule.SetupGrowButton(joinServerButton)
joinServerButton.Activated:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	Remotes.LeagueServer.JoinLeagueServer:FireServer(serverIDTextBox.Text)
end)

