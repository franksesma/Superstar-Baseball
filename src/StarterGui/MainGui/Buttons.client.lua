local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local MainGui = player.PlayerGui:WaitForChild("MainGui")
local StylesGui = player.PlayerGui:WaitForChild("StylesGui")
local ScoreboardGui = player.PlayerGui:WaitForChild("Scoreboard")
local CoinsDisplayGui = player.PlayerGui:WaitForChild("CoinsDisplay")
local DailyRewardsGui = player.PlayerGui:WaitForChild("DailyRewardsGui")
local LobbyRelatedUI = player.PlayerGui:WaitForChild("LobbyRelatedUI")

local MenuButtons = script.Parent:WaitForChild("MenuButtons")
local CoinsDisplayFrame = CoinsDisplayGui.CoinsDisplayFrame

local Remotes = ReplicatedStorage.RemoteEvents
local SharedDataFolder = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local GearItems = ReplicatedStorage.Gear
local GameValues = ReplicatedStorage.GameValues
local CameraValues = GameValues.CameraValues
local SharedObjects = ReplicatedStorage.SharedObjects
local StylesLocker = workspace.StylesLocker

local GuiAnimationModule = require(SharedModules.GuiAnimation)
local ClientFunctions = require(SharedModules.ClientFunctions)
local TeamsModule = require(SharedModules.Teams)

local frames = {
	[MenuButtons:WaitForChild("VoteButton")] = MainGui:WaitForChild("VotingFrame");
	[MenuButtons:WaitForChild("StatsButton")] = MainGui:WaitForChild("StatsFrame");
	[MenuButtons:WaitForChild("ShopButton")] = MainGui:WaitForChild("StoreFrame");
	[MenuButtons:WaitForChild("InventoryButton")] = MainGui:WaitForChild("InventoryFrame");
	[MenuButtons:WaitForChild("SettingsButton")] = MainGui:WaitForChild("SettingsFrame");
	[MenuButtons.StylesButton] = StylesGui.StylesFrame;
	[CoinsDisplayFrame.CoinsButton] = MainGui.StoreFrame;
	[ScoreboardGui.OVRButton] = MainGui.OVRFrame;
	[ScoreboardGui.TutorialButton] = MainGui.TutorialFrame;
	[LobbyRelatedUI.DailyRewardsButton] = DailyRewardsGui.Frame;
}

local buttonClicked = false
local defaultMenuButtonPosition = MenuButtons.Position
local PlayerData;

local function setupLockerCharacter()
	local characterSetup = Remotes.SetupLockerStylesCharacter:InvokeServer()
	
	if StylesLocker:FindFirstChild("StylesLockerCharacter") then
		StylesLocker["StylesLockerCharacter"]:Destroy()
	end
	
	SharedDataFolder:WaitForChild(player.Name)
	
	if SharedDataFolder[player.Name]:FindFirstChild("StylesLockerCharacter") then
		local characterModel = SharedDataFolder[player.Name].StylesLockerCharacter
		
		characterModel.Parent = StylesLocker
		
		local anim = characterModel.Humanoid:LoadAnimation(characterModel.Animations.Idle)

		anim.Looped = true
		anim:Play()
	end
end


local function frameButtonClicked(frame, button)
	if not buttonClicked then
		buttonClicked = true
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		
		if (GameValues.CurrentBatter.Value == player or (GameValues.CurrentPitcher.Value == player and workspace:FindFirstChild("PitcherCircle") == nil)) and not GameValues.BallHit.Value then
			buttonClicked = false
			return
		end
		
		if button.Name == "CoinsButton" then
			if (frame.Visible and not frame.Background.CashFrame.Visible) or (not frame.Visible) then
				frame.Visible = true
				frame.Background.PacksFrame.Visible = false
				frame.Background.GamePassFrame.Visible = false
				frame.Background.CashFrame.Visible = true
				frame.Background.GearFrame.Visible = false
				
				for _, button in pairs(frame.Background.ButtonsFrame:GetChildren()) do
					if button:IsA("TextButton") then
						if button.Name == "Cash" then
							button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
							button.UIStroke.Color = Color3.fromRGB(0, 255, 255)
						else
							button.BackgroundColor3 = Color3.fromRGB(170, 255, 255)
							button.UIStroke.Color = Color3.fromRGB(255, 255, 255)
						end
					end
				end
			else
				frame.Visible = false
			end
		elseif button.Name == "StylesButton" then
			if not player.Character.States.StylesLockerDisabled.Value then
				if not frame.Visible then
					setupLockerCharacter()
				end
				
				frame.Visible = not frame.Visible

				if frame.Visible then
					if PlayerData and not PlayerData.OpenedStylesMenu.Value then
						Remotes.NewPlayerOpenedMenuCheck:FireServer("OpenedStylesMenu")
					end 
					ClientFunctions.ToggleStylesGuiView(false)
					player.Character.States.InStylesLocker.Value = true		
					workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
					workspace.CurrentCamera.CFrame = CFrame.new(StylesLocker.Cameras.CamFocalA.Position, StylesLocker.Cameras.CamFocalB.Position)
					if playerGui:FindFirstChild("GuessThePitch") then
						playerGui.GuessThePitch:Destroy()
					end
				else
					ClientFunctions.ToggleStylesGuiView(true)
					player.Character.States.InStylesLocker.Value = false
					frame.StyleSubFrame.Visible = true
					frame.SpinsPurchaseFrame.Visible = false
					
					ClientFunctions.HandleStyleCameraToggle(player)
				end
			end
		else
			frame.Visible = not frame.Visible
			
			if PlayerData and not PlayerData.OpenedTutorial.Value then
				Remotes.NewPlayerOpenedMenuCheck:FireServer("OpenedTutorial")
				
				ScoreboardGui.TutorialArrowIcon.Visible = false
			end 
		end
		
		for k,v in pairs(frames) do
			if v ~= frame then
				v.Visible = false
			end
		end

		if frame then
			buttonClicked = false
		end	
		
		if not StylesGui.StylesFrame.Visible then
			ClientFunctions.ToggleStylesGuiView(true)
			player.Character.States.InStylesLocker.Value = false
			StylesGui.StylesFrame.StyleSubFrame.Visible = true
			StylesGui.StylesFrame.SpinsPurchaseFrame.Visible = false
			
			ClientFunctions.HandleStyleCameraToggle(player)
		end
	end
end

for button, frame in pairs(frames) do
	GuiAnimationModule.SetupGrowButton(button)

	button.MouseButton1Click:connect(function()
		frameButtonClicked(frame, button)
	end)
end

Remotes.ViewPack.OnClientEvent:Connect(function()
	if MainGui.StoreFrame.Visible then
		return
	end
	
	frameButtonClicked(MainGui.StoreFrame, MenuButtons.ShopButton)
end)

Remotes.InitialStyleRoll.OnClientEvent:Connect(function()
	local frame = StylesGui.StylesFrame
		
	if not frame.Visible then
		setupLockerCharacter()
	end

	frame.Visible = not frame.Visible

	if frame.Visible then
		ClientFunctions.ToggleStylesGuiView(false)
		player.Character.States.InStylesLocker.Value = true		
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		workspace.CurrentCamera.CFrame = CFrame.new(StylesLocker.Cameras.CamFocalA.Position, StylesLocker.Cameras.CamFocalB.Position)
	else
		ClientFunctions.ToggleStylesGuiView(true)
		player.Character.States.InStylesLocker.Value = false
		frame.StyleSubFrame.Visible = true
		frame.SpinsPurchaseFrame.Visible = false

		ClientFunctions.HandleStyleCameraToggle(player)
	end
	
	frame.IsInitialRoll.Value = true
	
	if player:FindFirstChild("PlayerGui") then
		if player.PlayerGui:FindFirstChild("DailyRewardsGui") then
			player.PlayerGui.DailyRewardsGui.Enabled = false
		end
		
		if player.PlayerGui:FindFirstChild("MetavisionAd") then
			player.PlayerGui.MetavisionAd.Enabled = false
		end
		
		if player.PlayerGui:FindFirstChild("UpdateNotice") then
			player.PlayerGui.UpdateNotice.Enabled = false
		end
	end
	
	local arrow = frame.StyleSubFrame.SpinFrame.ArrowIcon
	local exitArrowIcon = frame.StyleSubFrame.ExitArrowIcon
	
	local exitArrowBasePosition = exitArrowIcon.Position
	local basePosition = arrow.Position

	local bounceOffset = 0.03
	local bounceTime = 0.5

	local tweenUp = TweenService:Create(arrow, TweenInfo.new(bounceTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = basePosition - UDim2.new(bounceOffset, 0, 0, 0)
	})

	local tweenDown = TweenService:Create(arrow, TweenInfo.new(bounceTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
		Position = basePosition
	})
	
	local exitTweenUp = TweenService:Create(exitArrowIcon, TweenInfo.new(bounceTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
		Position = exitArrowBasePosition + UDim2.new(0.02, 0, 0, 0)
	})

	local exitTweenDown = TweenService:Create(exitArrowIcon, TweenInfo.new(bounceTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = exitArrowBasePosition
	})

	arrow.Visible = true
	
	spawn(function()
		while frame.IsInitialRoll.Value do
			tweenUp:Play()
			tweenUp.Completed:Wait()
			tweenDown:Play()
			tweenDown.Completed:Wait()
		end 

		arrow.Visible = false
	end)

	spawn(function()
		while frame.Visible do
			exitTweenUp:Play()
			exitTweenUp.Completed:Wait()
			exitTweenDown:Play()
			exitTweenDown.Completed:Wait()
		end
		
		exitArrowIcon.Visible = false
		exitArrowIcon:Destroy()
	end)
end)

Remotes.ToggleMenuButtons.OnClientEvent:Connect(function(action)
	if action == "Hide" then
		local tweenPos = UDim2.new(-0.1, 0, defaultMenuButtonPosition.Y.Scale, 0)
		MenuButtons:TweenPosition(tweenPos, 'Out', "Back", 0.5, true)
		task.delay(0.5, function()
			if MenuButtons.Position ~= tweenPos then
				MenuButtons.Position = tweenPos
			end
		end)
		for k,v in pairs(frames) do
			v.Visible = false
		end
		
		player.Character.States.InStylesLocker.Value = false
		
		ClientFunctions.ToggleStylesGuiView(true)
		
		player.PlayerGui.AbilityPower.Enabled = false
	elseif action == "Show" then
		MenuButtons:TweenPosition(defaultMenuButtonPosition, 'Out', "Back", 0.5, true)
		task.delay(0.5, function()
			if MenuButtons.Position ~= defaultMenuButtonPosition then
				MenuButtons.Position = defaultMenuButtonPosition
			end
		end)
		
		player.PlayerGui.AbilityPower.Enabled = true
	end
end)

Remotes.ToggleScoreboard.OnClientEvent:Connect(function(action)
	if action == "Hide" then
		for _,v in pairs (ScoreboardGui:GetChildren()) do
			if v:IsA("Frame") or v:IsA("TextButton") or v:IsA("ImageLabel") then
				v.Visible = false
			end
		end
		
	elseif action == "Show" then
		for _,v in pairs (ScoreboardGui:GetChildren()) do
			if (v:IsA("Frame") and v.Name ~= "PitchClock") or v:IsA("TextButton") or v:IsA("ImageLabel")  then
				if (v.Name ~= "TutorialArrowIcon") or (v.Name == "TutorialArrowIcon" and PlayerData:FindFirstChild("OpenedTutorial") and not PlayerData.OpenedTutorial.Value) then
					v.Visible = true
				end
			end
		end
		
	end
end)

PlayerData = SharedDataFolder:WaitForChild(player.Name)

local currentCash = PlayerData:WaitForChild("Cash").Value

CoinsDisplayFrame.CoinsLabel.Text = ClientFunctions.ConvertShort(PlayerData.Cash.Value)

PlayerData.Cash.Changed:Connect(function()
	CoinsDisplayFrame.CoinsLabel.Text = ClientFunctions.ConvertShort(PlayerData.Cash.Value)
	
	local cashDifference = math.abs(currentCash - PlayerData.Cash.Value)

	if PlayerData.Cash.Value > currentCash then -- increase
		currentCash = PlayerData.Cash.Value

		local Increase = script.Increase:Clone()
		Increase.Text = "+"..ClientFunctions.ConvertShort(cashDifference)
		Increase.Parent = CoinsDisplayFrame

		Increase:TweenPosition(UDim2.new(0.5,0,-1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 1, true)

		wait(1)

		for i = 1, 20 do
			Increase.TextTransparency = Increase.TextTransparency + 0.05
			Increase.UIStroke.Transparency = Increase.UIStroke.Transparency + 0.05
			if i == 20 then
				Increase:Destroy()
			end
			wait()
		end 
	elseif PlayerData.Cash.Value < currentCash then -- decrease 
		currentCash = PlayerData.Cash.Value

		local Decrease = script.Decrease:Clone()
		Decrease.Text = "-"..ClientFunctions.ConvertShort(cashDifference)
		Decrease.Parent = CoinsDisplayFrame

		Decrease:TweenPosition(UDim2.new(0.5,0,-1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 1, true)

		ClientFunctions.PlayAudioSound(player, "BuySound")

		wait(1)
		for i = 1, 20 do
			Decrease.TextTransparency = Decrease.TextTransparency + 0.05
			Decrease.UIStroke.Transparency = Decrease.UIStroke.Transparency + 0.05
			if i == 20 then
				Decrease:Destroy()
			end
			wait()
		end 
	end
end)

if not PlayerData:WaitForChild("OpenedStylesMenu").Value then
	MenuButtons.StylesButton.Exclamation.Visible = true
end

PlayerData.OpenedStylesMenu.Changed:Connect(function()
	if not PlayerData.OpenedStylesMenu.Value then
		MenuButtons.StylesButton.Exclamation.Visible = true
	else
		MenuButtons.StylesButton.Exclamation.Visible = false
	end
end)

if not PlayerData:WaitForChild("OpenedTutorial").Value then
	local arrow = ScoreboardGui.TutorialArrowIcon
	local basePosition = arrow.Position
	
	local bounceOffset = 0.01
	local bounceTime = 0.5

	local tweenUp = TweenService:Create(arrow, TweenInfo.new(bounceTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = basePosition - UDim2.new(0, 0, bounceOffset, 0)
	})

	local tweenDown = TweenService:Create(arrow, TweenInfo.new(bounceTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
		Position = basePosition
	})
	
	arrow.Visible = true

	while PlayerData:FindFirstChild("OpenedTutorial") and not PlayerData.OpenedTutorial.Value do
		tweenUp:Play()
		tweenUp.Completed:Wait()
		tweenDown:Play()
		tweenDown.Completed:Wait()
	end
	
	arrow.Visible = false
end