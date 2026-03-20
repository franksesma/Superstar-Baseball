local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CAS = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local SharedDataFolder = ReplicatedStorage.SharedData
local Shared = ReplicatedStorage.Shared
local SharedServices = Shared.Services
local GameValues = ReplicatedStorage.GameValues

local BattingButton = script.Parent:WaitForChild("BattingButton")
local BattingPracticeFrame = script.Parent:WaitForChild("BattingPracticeFrame")
local ExitBatting = BattingPracticeFrame:WaitForChild("ExitBatting")
local Options = BattingPracticeFrame:WaitForChild("Options")
local MobileOptions = BattingPracticeFrame:WaitForChild("MobileOptions")

local ClientFunctions = require(SharedModules:WaitForChild("ClientFunctions"))
local GuiAnimationModule = require(SharedModules:WaitForChild("GuiAnimation"))

local player = Players.LocalPlayer

local battingPracticeActivated = false

local battingCage = workspace:FindFirstChild("BattingCage")

if battingCage then
	battingCage.Parent = ReplicatedStorage
end

local function setupBattingCageCharacter()
	local battingCage = ReplicatedStorage:FindFirstChild("BattingCage") or workspace:FindFirstChild("BattingCage")

	if battingCage then
		battingCage.Parent = workspace
	else
		return
	end
	
	local equippedOffensiveStyleName = Remotes.BattingCage.SetupBattingCageCharacter:InvokeServer()
	
	if battingCage:FindFirstChild("BattingCageCharacter") then
		battingCage["BattingCageCharacter"]:Destroy()
	end

	SharedDataFolder:WaitForChild(player.Name)

	if SharedDataFolder[player.Name]:FindFirstChild("BattingCageCharacter") and equippedOffensiveStyleName ~= nil then
		local characterModel = SharedDataFolder[player.Name].BattingCageCharacter
		
		if battingCage:FindFirstChild("AIPitcher") then
			local animeHighlightCopy = battingCage.AIPitcher:FindFirstChild("AnimeHighlight")
			
			if animeHighlightCopy then
				animeHighlightCopy:Clone().Parent = characterModel
			end
		end

		characterModel.Parent = battingCage
	else
		battingPracticeActivated = false
	end
end

-- Batting button
GuiAnimationModule.SetupGrowButton(BattingButton)
BattingButton.Activated:Connect(function()
	if battingPracticeActivated then return end
	if not ClientFunctions.PlayerIsOffense(player) then return end
	if ClientFunctions.PlayerIsBaserunner(player) or GameValues.CurrentBatter.Value == player then return end
	if not GameValues.GameActive.Value then return end
	
	battingPracticeActivated = true
	
	BattingButton.Visible = false
	BattingButton.Selectable = false
	BattingButton.Interactable = false
	
	BattingPracticeFrame.Visible = true
	
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	
	setupBattingCageCharacter()
end)

GuiAnimationModule.SetupShrinkButton(ExitBatting)
ExitBatting.Activated:Connect(function()
	if not battingPracticeActivated then return end
	
	CAS:UnbindAction("PracticeSwing")
	CAS:UnbindAction("PracticeThrowPitch")
	
	player.Character.States.InStylesLocker.Value = false
	
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom

	Remotes.BattingCage.ExitBattingPractice:FireServer()
	
	local battingCage = workspace:FindFirstChild("BattingCage")
	
	if battingCage and battingCage:FindFirstChild("BattingCageCharacter") then
		battingCage["BattingCageCharacter"]:Destroy()
	end
	
	if battingCage then
		battingCage.Parent = ReplicatedStorage
	end
	
	battingPracticeActivated = false

	GuiAnimationModule.ButtonPress(player, "PositiveClick")
end)

Remotes.BattingCage.DeactivateBattingPracticeGui.OnClientEvent:Connect(function()
	if battingPracticeActivated then
		player.Character.States.InStylesLocker.Value = false
	end
	
	local battingCage = workspace:FindFirstChild("BattingCage")
	
	if battingCage and battingCage:FindFirstChild("BattingCageCharacter") then
		battingCage["BattingCageCharacter"]:Destroy()
	end
	
	if battingCage then
		battingCage.Parent = ReplicatedStorage
	end
	
	BattingButton.Visible = false
	BattingButton.Selectable = false
	BattingButton.Interactable = false
	BattingPracticeFrame.Visible = false
	
	battingPracticeActivated = true
end)

Remotes.BattingCage.ActivateBattingPracticeGui.OnClientEvent:Connect(function()
	BattingButton.Visible = true
	BattingButton.Selectable = true
	BattingButton.Interactable = true

	BattingPracticeFrame.Visible = false
	
	battingPracticeActivated = false
end)

local function updateOptionsVisibility()
	if UserInputService.TouchEnabled then
		Options.Visible = false
		MobileOptions.Visible = true
	else
		Options.Visible = true
		MobileOptions.Visible = false
	end
	
	if UserInputService.TouchEnabled then
		MobileOptions.Pitch.Visible = true
	elseif UserInputService.GamepadEnabled then
		Options.Pitch.XboxKeybind.Visible = true
		Options.Pitch.PCKeybind.Visible = false
	else
		Options.Pitch.XboxKeybind.Visible = false
		Options.Pitch.PCKeybind.Visible = true
	end
end

updateOptionsVisibility()
UserInputService.LastInputTypeChanged:Connect(updateOptionsVisibility)