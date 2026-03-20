local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local AdminEvents = ReplicatedStorage.AdminEvents
local SharedDataFolder = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules

local GuiAnimationModule = require(SharedModules.GuiAnimation)

local AdminButton = script.Parent.AdminButton
local AdminFrame = script.Parent.AdminFrame
local ContainerFrame = AdminFrame.Background.SubFrame.Container
local WalkSpeed = ContainerFrame.WalkSpeed
local SetOffensiveStyle = ContainerFrame.SetOffensiveStyle
local SetDefensiveStyle = ContainerFrame.SetDefensiveStyle
local BallTeleport = ContainerFrame.BallTeleport
local ChangeBalls = ContainerFrame.ChangeBalls
local ChangeOuts = ContainerFrame.ChangeOuts
local ChangeStrikes = ContainerFrame.ChangeStrikes
local ChangeInning = ContainerFrame.ChangeInning
local IncreaseFieldingPower = ContainerFrame.IncreaseFieldingPower
local IncreaseBaserunningPower = ContainerFrame.IncreaseBaserunningPower
local IncreasePitchingPower = ContainerFrame.IncreasePitchingPower
local IncreaseHittingPower = ContainerFrame.IncreaseHittingPower
local AwayScore = ContainerFrame.AwayScore
local CurrentbatterOut = ContainerFrame.CurrentBatterOut
local HomeScore = ContainerFrame.HomeScore
local RemoveGui = ContainerFrame.DestroyGui
local ExitButton = AdminFrame.Background.ExitButton

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

if playerGui:FindFirstChild("ActiveAdminGui") then
	script.Parent:Destroy()
else
	script.Parent.Name = "ActiveAdminGui"
end

repeat wait() until player.Character

local character = player.Character
local humanoid = character:WaitForChild("Humanoid")

-- COMMANDS
WalkSpeed.TextBox.Text = player.Character.Humanoid.WalkSpeed
WalkSpeed.TextBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local number = tonumber(WalkSpeed.TextBox.Text)

		if number and number == math.floor(number) and number <= 100 and number >= 16 then
			AdminEvents.SetWalkSpeed:FireServer(number)
		else
			WalkSpeed.TextBox.Text = player.Character.Humanoid.WalkSpeed
		end
	end
end)

SetOffensiveStyle.TextBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		AdminEvents.SetOffensiveStyle:FireServer(SetOffensiveStyle.TextBox.Text)
	end
end)

SetDefensiveStyle.TextBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		AdminEvents.SetDefensiveStyle:FireServer(SetDefensiveStyle.TextBox.Text)
	end
end)

GuiAnimationModule.SetupShrinkButton(IncreaseBaserunningPower.Button)
IncreaseBaserunningPower.Button.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.IncreaseBaserunningPower:FireServer()
end)

GuiAnimationModule.SetupShrinkButton(IncreaseFieldingPower.Button)
IncreaseFieldingPower.Button.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.IncreaseFieldingPower:FireServer()
end)

GuiAnimationModule.SetupShrinkButton(CurrentbatterOut.Button)
CurrentbatterOut.Button.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.CurrentBatterOut:FireServer()
end)


GuiAnimationModule.SetupShrinkButton(IncreasePitchingPower.Button)
IncreasePitchingPower.Button.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.IncreasePitchingPower:FireServer()
end)

GuiAnimationModule.SetupShrinkButton(IncreaseHittingPower.Button)
IncreaseHittingPower.Button.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.IncreaseHittingPower:FireServer()
end)


GuiAnimationModule.SetupShrinkButton(BallTeleport.Button)
BallTeleport.Button.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.BallTeleport:FireServer()
end)

GuiAnimationModule.SetupShrinkButton(ChangeOuts.AddButton)
ChangeOuts.AddButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.ChangeOuts:FireServer("Add")
end)

GuiAnimationModule.SetupShrinkButton(ChangeOuts.SubtractButton)
ChangeOuts.SubtractButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.ChangeOuts:FireServer("Subtract")
end)

GuiAnimationModule.SetupShrinkButton(ChangeBalls.AddButton)
ChangeBalls.AddButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.ChangeBalls:FireServer("Add")
end)

GuiAnimationModule.SetupShrinkButton(ChangeBalls.SubtractButton)
ChangeBalls.SubtractButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.ChangeBalls:FireServer("Subtract")
end)

GuiAnimationModule.SetupShrinkButton(ChangeStrikes.AddButton)
ChangeStrikes.AddButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.ChangeStrikes:FireServer("Add")
end)

GuiAnimationModule.SetupShrinkButton(ChangeStrikes.SubtractButton)
ChangeStrikes.SubtractButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.ChangeStrikes:FireServer("Subtract")
end)

GuiAnimationModule.SetupShrinkButton(ChangeInning.AddButton)
ChangeInning.AddButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.ChangeInning:FireServer("Add")
end)

GuiAnimationModule.SetupShrinkButton(ChangeInning.SubtractButton)
ChangeInning.SubtractButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.ChangeInning:FireServer("Subtract")
end)

GuiAnimationModule.SetupShrinkButton(HomeScore.AddButton)
HomeScore.AddButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.HomeScore:FireServer("Add")
end)

GuiAnimationModule.SetupShrinkButton(HomeScore.SubtractButton)
HomeScore.SubtractButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.HomeScore:FireServer("Subtract")
end)

GuiAnimationModule.SetupShrinkButton(AwayScore.AddButton)
AwayScore.AddButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.AwayScore:FireServer("Add")
end)

GuiAnimationModule.SetupShrinkButton(AwayScore.SubtractButton)
AwayScore.SubtractButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminEvents.AwayScore:FireServer("Subtract")
end)
-- SETUP

GuiAnimationModule.SetupShrinkButton(AdminButton)
AdminButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	AdminFrame.Visible = not AdminFrame.Visible
end)

GuiAnimationModule.SetupShrinkButton(AdminButton)
RemoveGui.Button.Activated:Connect(function()
	script.Parent:Destroy()
end)

GuiAnimationModule.ExitButtonPressed(player, script.Parent.AdminFrame, ExitButton)