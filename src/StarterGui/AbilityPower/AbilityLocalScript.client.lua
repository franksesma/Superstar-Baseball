local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Remotes = ReplicatedStorage.RemoteEvents
local SharedData = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local GameValues = ReplicatedStorage.GameValues

local FieldingProgressFrame = script.Parent.FieldingProgress
local FieldingBar = FieldingProgressFrame.Bar

local BaserunningProgressFrame = script.Parent.BaserunningProgress
local BaserunningBar = BaserunningProgressFrame.Bar

local KeybindsFrame = script.Parent.Keybinds
local AbilityButtons = script.Parent.AbilityButtons

local GuiAnimationModule = require(SharedModules.GuiAnimation)
local StylesModule = require(SharedModules.Styles)

local player = Players.LocalPlayer

local playerDataFolder = SharedData:WaitForChild(player.Name)

local function updateFieldingPower(equippedFieldingStyle)
	local powerAccrued = playerDataFolder.FieldingPower.Value / 100

	FieldingBar:TweenSize(UDim2.new(powerAccrued, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.5, true)

	FieldingProgressFrame.ProgressLabel.Text = (powerAccrued * 100).."%"
	AbilityButtons.Ability.AbilityLabel.Text = StylesModule.DefensiveStyles[equippedFieldingStyle].Ability
	AbilityButtons.Ultimate.AbilityLabel.Text = StylesModule.DefensiveStyles[equippedFieldingStyle].Ultimate
	
	if powerAccrued == 1 then
		FieldingBar.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
		FieldingProgressFrame.AbilityLabel.Text = StylesModule.DefensiveStyles[equippedFieldingStyle].Ultimate.." is ready (Press V)"
		AbilityButtons.Ultimate.Visible = true
	elseif powerAccrued >= 0.5 then
		FieldingBar.BackgroundColor3 = Color3.fromRGB(170, 255, 255)
		FieldingProgressFrame.AbilityLabel.Text = StylesModule.DefensiveStyles[equippedFieldingStyle].Ability.." is ready (Press F)"
		AbilityButtons.Ultimate.Visible = false
	else
		FieldingBar.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
		FieldingProgressFrame.AbilityLabel.Text = ""
		AbilityButtons.Ultimate.Visible = false
	end
	
	AbilityButtons.Ability.Visible = true
	
	if powerAccrued >= 0.5 then
		AbilityButtons.Ability.Disabled.Visible = false
	else
		AbilityButtons.Ability.Disabled.Visible = true
	end
end

local function updateBaserunningPower(equippedBaserunningStyle)
	local powerAccrued = playerDataFolder.BaserunningPower.Value / 100

	BaserunningBar:TweenSize(UDim2.new(powerAccrued, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.5, true)

	BaserunningProgressFrame.ProgressLabel.Text = (powerAccrued * 100).."%"
	AbilityButtons.Ability.AbilityLabel.Text = StylesModule.OffensiveStyles[equippedBaserunningStyle].Ability
	AbilityButtons.Ultimate.AbilityLabel.Text = StylesModule.OffensiveStyles[equippedBaserunningStyle].Ultimate

	if powerAccrued == 1 then
		BaserunningBar.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
		BaserunningProgressFrame.AbilityLabel.Text = StylesModule.OffensiveStyles[equippedBaserunningStyle].Ultimate.." is ready (Press V)"
		AbilityButtons.Ultimate.Visible = true
	elseif powerAccrued >= 0.5 then
		BaserunningBar.BackgroundColor3 = Color3.fromRGB(170, 255, 255)
		BaserunningProgressFrame.AbilityLabel.Text = StylesModule.OffensiveStyles[equippedBaserunningStyle].Ability.." is ready (Press F)"
		AbilityButtons.Ultimate.Visible = false
	else
		BaserunningBar.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
		BaserunningProgressFrame.AbilityLabel.Text = ""
		AbilityButtons.Ultimate.Visible = false
	end

	AbilityButtons.Ability.Visible = true
	
	if powerAccrued >= 0.5 then
		AbilityButtons.Ability.Disabled.Visible = false
	else
		AbilityButtons.Ability.Disabled.Visible = true
	end
end

Remotes.UpdateFieldingPower.OnClientEvent:Connect(function(equippedFieldingStyle)
	updateFieldingPower(equippedFieldingStyle)
end)

Remotes.SetupFieldingPower.OnClientEvent:Connect(function(enabled, equippedFieldingStyle)
	if enabled then
		FieldingProgressFrame.Visible = true
		FieldingProgressFrame.StyleName.Text = equippedFieldingStyle.." (Fielding)"
		
		updateFieldingPower(equippedFieldingStyle)
	else 
		FieldingProgressFrame.Visible = false
		AbilityButtons.Ability.Visible = false
		AbilityButtons.Ultimate.Visible = false
	end
end)

Remotes.UpdateBaserunningPower.OnClientEvent:Connect(function(equippedBaserunningStyle)
	updateBaserunningPower(equippedBaserunningStyle)
end)

Remotes.SetupBaserunningPower.OnClientEvent:Connect(function(enabled, equippedBaserunningStyle)
	if enabled then
		BaserunningProgressFrame.Visible = true
		BaserunningProgressFrame.StyleName.Text = equippedBaserunningStyle.." (Baserunning)"
		
		updateBaserunningPower(equippedBaserunningStyle)
	else 
		BaserunningProgressFrame.Visible = false
		AbilityButtons.Ability.Visible = false
		AbilityButtons.Ultimate.Visible = false
	end
end)

Remotes.ToggleAbilityButtons.OnClientEvent:Connect(function(enabled)
	if enabled and player.TeamColor == game.Teams.Lobby.TeamColor then
		return
	end
	
	AbilityButtons.Visible = enabled
end)

GameValues.ScoreboardValues.AtBat.Changed:Connect(function()
	if GameValues.ScoreboardValues.AtBat.Value ~= "" and player.Team.name == GameValues[GameValues.ScoreboardValues.AtBat.Value.."TeamPicked"].Value then
		AbilityButtons.Dive.AbilityLabel.Text = "Slide"
	else
		AbilityButtons.Dive.AbilityLabel.Text = "Dive"
	end
end)

local function enableGamepadIcons(enabled)
	for _, keybind in pairs(KeybindsFrame:GetChildren()) do
		if keybind:IsA("Frame") then
			keybind.PCKeybind.Visible = not enabled
			keybind.XboxKeybind.Visible = enabled
		end
	end
	
	AbilityButtons.Dive.PCKeybind.Visible = not enabled
	AbilityButtons.Dive.XboxKeybind.Visible = enabled
	
	AbilityButtons.Ability.PCKeybind.Visible = not enabled
	AbilityButtons.Ability.XboxKeybind.Visible = enabled
	
	AbilityButtons.Ultimate.PCKeybind.Visible = not enabled
	AbilityButtons.Ultimate.XboxKeybind.Visible = enabled
	
	AbilityButtons.Throw.PCKeybind.Visible = not enabled
	AbilityButtons.Throw.XboxKeybind.Visible = enabled
	
	AbilityButtons.BuddyJump.PCKeybind.Visible = not enabled
	AbilityButtons.BuddyJump.XboxKeybind.Visible = enabled
end

if UserInputService.GamepadEnabled then
	enableGamepadIcons(true)
end

UserInputService.GamepadConnected:Connect(function(gamepad)
	enableGamepadIcons(true)
end)

UserInputService.GamepadDisconnected:Connect(function(gamepad)
	enableGamepadIcons(false)
end)

local function ability()
	if not playerDataFolder.ActivatedFBAbility.Value then
		Remotes.ActivateFBAbility:FireServer()
	end
end

local function ultimate()
	if not playerDataFolder.ActivatedFBAbility.Value then
		Remotes.ActivateFBUltimate:FireServer()
	end
end

UserInputService.InputBegan:Connect(function(input, gameprocessed)
	if gameprocessed then return end

	if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonX then
		ability()
	elseif input.KeyCode == Enum.KeyCode.V or input.KeyCode == Enum.KeyCode.ButtonY then
		ultimate()
	end
end)

AbilityButtons.Ability.MouseButton1Click:Connect(function()
	ability()
end)

AbilityButtons.Ultimate.MouseButton1Click:Connect(function()
	ultimate()
end)

Remotes.ActivateFBAbility.OnClientEvent:Connect(function()
	GuiAnimationModule.DisplayAbilityUnusable(player, "Ability")
end)

if UserInputService.TouchEnabled then
	KeybindsFrame.Visible = false
end