local ClientFunctions = {}

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedData = ReplicatedStorage.SharedData
local SharedGUIs = ReplicatedStorage.SharedGUIs
local GameValues = ReplicatedStorage.GameValues
local CameraValues = GameValues.CameraValues
local ScoreboardValues = GameValues.ScoreboardValues
local OnBaseTracking = GameValues.OnBase
local FieldCameras = workspace.FieldCameras
local BasePlates = workspace.Plates

function ClientFunctions.Weld(partToWeld, targetPart)
	partToWeld.CFrame = targetPart.CFrame
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = targetPart
	weld.Part1 = partToWeld
	weld.Parent = partToWeld
	partToWeld.Anchored = false
end

function ClientFunctions.SendLocalNotification(player, title, message)
	local StarterGui = game:GetService("StarterGui")
	StarterGui:SetCore("SendNotification", {
		Title = title,
		Text = message,
		Duration = 3
	})
	ClientFunctions.PlayAudioSound(player, "Notification")
end

function ClientFunctions.GetFoulWallPos(posType)
	if workspace.LoadedBallpark:FindFirstChild("FoulWalls") then
		if posType == "FairZ" then
			local pos = workspace.LoadedBallpark.FoulWalls[posType].Position.Z

			return pos
		elseif posType == "FairX" then
			local pos = workspace.LoadedBallpark.FoulWalls[posType].Position.X

			return pos
		end
	end
end

function ClientFunctions.ToggleStylesGuiView(enabled)
	local player = Players.LocalPlayer
	
	if player:FindFirstChild("PlayerGui") 
		and player.PlayerGui:FindFirstChild("Scoreboard") 
	then
		player.PlayerGui.Scoreboard.Enabled = enabled
	end
	
	if player:FindFirstChild("PlayerGui") 
		and player.PlayerGui:FindFirstChild("MainGui") 
	then
		player.PlayerGui.MainGui.Enabled = enabled
	end
	
	if player:FindFirstChild("PlayerGui") 
		and player.PlayerGui:FindFirstChild("LobbyRelatedUI") 
		and not SharedData[player.Name].FreecamMode.Value
	then
		player.PlayerGui.LobbyRelatedUI.Enabled = enabled
	end
	
	if player:FindFirstChild("PlayerGui") 
		and player.PlayerGui:FindFirstChild("GameStatus") 
	then
		player.PlayerGui.GameStatus.Enabled = enabled
	end
	
	if player:FindFirstChild("PlayerGui") 
		and player.PlayerGui:FindFirstChild("AbilityPower")
		and not SharedData[player.Name].FreecamMode.Value
	then
		player.PlayerGui.AbilityPower.Enabled = enabled
	end
	
	if player:FindFirstChild("PlayerGui") 
		and player.PlayerGui:FindFirstChild("BattingPracticeGui")
	then
		player.PlayerGui.BattingPracticeGui.Enabled = enabled
	end
	
	if not enabled then
		if player.Character 
			and player.Character:FindFirstChild("CameraAnimations") 
			and player.Character.CameraAnimations:FindFirstChild("ExitedStylesMenu") 
		then
			player.Character.CameraAnimations.ExitedStylesMenu:Fire()
		end
	end
end

function ClientFunctions.RoundNumber(num)
	return math.floor(num * 10) / 10;
end

function ClientFunctions.PlayerIsInGame(player)
	if player ~= nil 
		and Players:FindFirstChild(player.Name) 
		and player.Team ~= nil
		and player.Team.Name ~= "Lobby"
	then
		return true
	else
		return false
	end
end

function ClientFunctions.GetPlayersInGame()
	local playersInGame = {}

	for _, player in pairs(Players:GetPlayers()) do
		if ClientFunctions.PlayerIsInGame(player) then
			table.insert(playersInGame, player)
		end
	end

	return playersInGame
end

function ClientFunctions.PlayAudioSound(player, sound)
	if player 
		and player:FindFirstChild("PlayerScripts") 
		and player.PlayerScripts:FindFirstChild("SoundScript") 
		and player.PlayerScripts.SoundScript:FindFirstChild(sound)
	then
		local newSound = player.PlayerScripts.SoundScript[sound]:Clone()
		newSound.Parent = SoundService
		newSound:Play()
		Debris:AddItem(newSound, newSound.TimeLength)
	end
end

function ClientFunctions.NoOtherCameraActive(player)
	if not player.Character.States.InStylesLocker.Value 
		and not CameraValues.MVPAwardCam.Value 
		and not CameraValues.PlayerSelectCam.Value
		and not CameraValues.FieldPan.Value
		and not CameraValues.PlayerIntro.Value
	then
		return true
	else
		return false
	end
end

function ClientFunctions.LoadGifting(giftType, subType)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local existingGui = playerGui:FindFirstChild("PlayerSelectGifting")
	if existingGui then
		existingGui:Destroy()
	end

	local giftingGuiTemplate = SharedGUIs:WaitForChild("PlayerSelectGifting")
	local giftingGui = giftingGuiTemplate:Clone()
	giftingGui.Name = "PlayerSelectGifting"

	giftingGui:SetAttribute("GiftType", giftType)
	giftingGui:SetAttribute("GiftSubTypeOrID", subType)

	giftingGui.Parent = playerGui
end

function ClientFunctions.GetMostVotedPitcher(teamColor)
	local mostVotedPitcher = {Votes = 0, PitcherName = ""}

	for _, otherPlayer in pairs(ClientFunctions.GetPlayersInGame()) do
		if otherPlayer.TeamColor == teamColor and SharedData:FindFirstChild(otherPlayer.Name) then
			if mostVotedPitcher.PitcherName == "" then
				mostVotedPitcher.PitcherName = otherPlayer.Name
				mostVotedPitcher.Votes = SharedData[otherPlayer.Name].PitcherVotes.Value
			else
				if SharedData[otherPlayer.Name].PitcherVotes.Value > mostVotedPitcher.Votes then
					mostVotedPitcher.PitcherName = otherPlayer.Name
					mostVotedPitcher.Votes = SharedData[otherPlayer.Name].PitcherVotes.Value
				end
			end
		end
	end
	
	return mostVotedPitcher.PitcherName
end

ClientFunctions.ConvertShort = function(Filter_Num)
	local x = tostring(Filter_Num)
	if #x >= 10 then
		local important = (#x-9)
		return x:sub(0,(important)).."."..(x:sub(#x-7,(#x-7))).."B+"
	elseif #x >= 7 then
		local important = (#x-6)
		return x:sub(0,(important)).."."..(x:sub(#x-5,(#x-5))).."M+"
	elseif #x >= 4 then
		return x:sub(0,(#x-3)).."."..(x:sub(#x-2,(#x-2))).."K+"
	else
		return Filter_Num
	end
end

function ClientFunctions.PlayerIsDefender(player)
	if player 
		and GameValues.GameActive.Value 
		and player.Team 
		and ScoreboardValues.AtBat.Value ~= ""
		and player.Team.Name ~= GameValues[ScoreboardValues.AtBat.Value.."TeamPicked"].Value 
		and player.Team.Name ~= "Lobby" 
	then
		return true
	else
		return false
	end
end

function ClientFunctions.PlayerIsOffense(player)
	if player 
		and GameValues.GameActive.Value 
		and player.Team 
		and ScoreboardValues.AtBat.Value ~= ""
		and player.Team.Name == GameValues[ScoreboardValues.AtBat.Value.."TeamPicked"].Value 
		and player.Team.Name ~= "Lobby" 
	then
		return true
	else
		return false
	end
end

function ClientFunctions.PlayerIsBaserunner(player)
	if player and OnBaseTracking:FindFirstChild(player.Name) and player ~= GameValues.CurrentBatter.Value then
		return true
	else
		return false
	end
end

function ClientFunctions.CalculateBattingAVG(H, AB)
	if AB > 0 then
		local battingAverage = H / AB
		local formatted_average = string.format("%.3f", battingAverage)
		return tostring(formatted_average)
	else
		return ".000"
	end
end

function ClientFunctions.CalculateStrikePercentage(Strikes, Pitches)
	if Pitches > 0 then
		local percentage = (Strikes / Pitches) * 100
		local formatted_percentage = string.format("%.2f", percentage).."%"
		return tostring(formatted_percentage)
	else
		return "0%"
	end
end

function ClientFunctions.CalculateRangeFactor(PO, A, GamesPlayed)
	if GamesPlayed > 0 then
		local RF = (PO + A) / GamesPlayed
		local formatted_rf = string.format("%.2f", RF)
		return tostring(formatted_rf)
	else
		return "0.0"
	end
end

function ClientFunctions.HandleStyleCameraToggle(player)
	if CameraValues.PlayerSelectCam.Value then
		workspace.CurrentCamera.CFrame = CFrame.new(FieldCameras.CamPlayerSelectOrigin.Position, FieldCameras.CamPlayerSelectFocal.Position)
	elseif CameraValues.MVPAwardCam.Value then
		workspace.CurrentCamera.CFrame = CFrame.new(FieldCameras.CamMVPSceneOrigin.Position, FieldCameras.CamPlayerSelectFocal.Position)
	else
		if workspace.CurrentCamera.CameraType ~= Enum.CameraType.Custom then
			local focalPart = BasePlates:FindFirstChild("Home Base")
			if focalPart then
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					workspace.CurrentCamera.CFrame = CFrame.new(player.Character.HumanoidRootPart.Position, focalPart.Position)
				end
			end
			
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		end
	end
end

function ClientFunctions.ResetUltimateCameras(player)
	local focalPart = BasePlates:FindFirstChild("Home Base")
	if focalPart then
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and GameValues.CurrentBatter.Value ~= player then
			workspace.CurrentCamera.CFrame = CFrame.new(player.Character.HumanoidRootPart.Position + Vector3.new(0, 5, 0), focalPart.Position)
		end
	end

	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	workspace.CurrentCamera.FieldOfView = 70
end

function ClientFunctions.Notification(player, message, notificationType)
	local playerGui = player.PlayerGui
	if playerGui:FindFirstChild("NotificationGui") then
		local notificationContainer = playerGui.NotificationGui.NotificationContainer

		for _, object in pairs(notificationContainer:GetChildren()) do
			if object:IsA("TextLabel") then
				object.LayoutOrder = object.LayoutOrder + 1
			end
		end

		local notificationLabel = SharedGUIs.NotificationLabel:Clone()
		notificationLabel.Text = message
		if notificationType == "Alert" then
			notificationLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		elseif notificationType == "Coins" then
			notificationLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
		elseif notificationType == "Game" then
			notificationLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
		elseif notificationType == "PityRoll" then
			notificationLabel.TextColor3 = Color3.fromRGB(255, 85, 255)
		end

		notificationLabel.Parent = notificationContainer

		ClientFunctions.PlayAudioSound(player, "Notification")
		
		spawn(function()
			task.wait(1)
			for i = 0, 1, 0.025 do
				if notificationLabel and notificationLabel:FindFirstChild("UIStroke") then
					notificationLabel.TextTransparency = i
					notificationLabel.UIStroke.Transparency = i
					notificationLabel.BackgroundTransparency = i
				else
					break
				end
				task.wait(0.05)
			end
			if notificationLabel then
				notificationLabel:Destroy()
			end

		end)
	end
end

return ClientFunctions
