local PlayerUtilsClient = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local TextChatService = game:GetService("TextChatService")

local Remotes = ReplicatedStorage.RemoteEvents
local SharedObjects = ReplicatedStorage.SharedObjects
local FieldWalls = workspace.FieldWalls
local GameValues = ReplicatedStorage.GameValues
local OnBase = GameValues.OnBase
local ScoreboardValues = GameValues.ScoreboardValues
local SharedModules = ReplicatedStorage.SharedModules
local SharedGUIs = ReplicatedStorage.SharedGUIs

local Player = Players.LocalPlayer

local PlayerScripts = Player:WaitForChild("PlayerScripts")
local PlayerModuleEvents = PlayerScripts:WaitForChild("PlayerModuleEvents")
local ControlModule = require(PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
local CameraModule = require(PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("CameraModule"))
local ClientFunctions = require(SharedModules.ClientFunctions)
local FireworkModule = require(SharedModules.FireworkModule) -- unused, kept for compatibility

-- Jump power: save/restore when movement is disabled so jump is disabled with other controls
local savedJumpPower = nil
local savedJumpHeight = nil

function PlayerUtilsClient.disableMovement(disabled)
	local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
	if not disabled then
		ControlModule:Enable()
		if humanoid and savedJumpPower ~= nil then
			humanoid.JumpPower = savedJumpPower
			if humanoid.JumpHeight ~= nil then
				humanoid.JumpHeight = savedJumpHeight or 7.2
			end
			savedJumpPower = nil
			savedJumpHeight = nil
		end
	elseif disabled then
		ControlModule:Disable()
		if humanoid then
			if savedJumpPower == nil then
				savedJumpPower = humanoid.JumpPower
				local jh = humanoid.JumpHeight
				savedJumpHeight = (type(jh) == "number") and jh or 7.2
			end
			humanoid.JumpPower = 0
			if humanoid.JumpHeight ~= nil then
				humanoid.JumpHeight = 0
			end
		end
	end
end

function PlayerUtilsClient.enableMouselock(enabled)
	CameraModule:EnableMouselock(enabled)
end

function PlayerUtilsClient.init()
	Remotes.DisableMovement.OnClientEvent:connect(function(disabled)
		if disabled and Player.Team.Name == "Lobby" then
			return
		end

		PlayerUtilsClient.disableMovement(disabled)
	end)

	-- Clear saved jump when character changes so we don't restore onto a new humanoid
	Player.CharacterAdded:Connect(function()
		savedJumpPower = nil
		savedJumpHeight = nil
	end)

	Remotes.ChangeCameraType.OnClientEvent:Connect(function(cameraType, override)
		if override then
			workspace.Camera.CameraType = cameraType
			return
		end

		if not Player.Character.States.InStylesLocker.Value then
			if Player.Team and Player.Team.Name == "Lobby" and cameraType ~= Enum.CameraType.Custom then
				return
			end

			workspace.Camera.CameraType = cameraType
		end
	end)

	Remotes.EnableMouselock.OnClientEvent:Connect(function(enabled)
		PlayerUtilsClient.enableMouselock(enabled)
	end)

	PlayerModuleEvents:WaitForChild("DisableMovement").Event:Connect(function(disabled)
		PlayerUtilsClient.disableMovement(disabled)
	end)

	Remotes.StopAnimations.OnClientEvent:connect(function()
		local Character = Player.Character

		if Character and Character.Humanoid then
			for _, track in pairs(Character.Humanoid:GetPlayingAnimationTracks()) do
				if track.Name ~= "BatHolding" then
					track:Stop()
				end
			end
		end
	end)

	Remotes.CFramePlayerCharacter.OnClientEvent:Connect(function(cframePos)
		local character = Player.Character

		if character and character:FindFirstChild("HumanoidRootPart") then
			character:PivotTo(cframePos)
		end
	end)

	Remotes.RemoveGui.OnClientEvent:Connect(function(guiName, bool)
		local playerGui = Player.PlayerGui

		if playerGui:FindFirstChild(guiName) then
			playerGui[guiName].Enabled = false

			local controllerScript = playerGui[guiName]:FindFirstChild("ControllerSupport")
			if controllerScript and controllerScript:IsA("LocalScript") then
				controllerScript.Disabled = true
			end

			if guiName == "HittingScreen" then
				
				local coinsDisplay = playerGui:FindFirstChild("CoinsDisplay")
				if coinsDisplay then
					coinsDisplay.Enabled = true
					local frame = coinsDisplay:FindFirstChild("CoinsDisplayFrame")
					if frame and frame:IsA("GuiObject") then
						frame.Visible = true
					end
				end
				
				playerGui[guiName]:Destroy()
			end
		end

		if guiName == "HittingScreen" and bool then
			if game.ReplicatedStorage:FindFirstChild("NPCs") then
				local NPCs = game.ReplicatedStorage.NPCs
				NPCs.Parent = workspace
			end
		end

		if guiName == "PitchingScreen" then
			if playerGui:FindFirstChild("MobileScreen") then
				playerGui.MobileScreen:Destroy()
			end
		end

		CAS:UnbindAction("Swing")
		CAS:UnbindAction("Pitch")
	end)


	Remotes.DestroyGui.OnClientEvent:Connect(function(guiName)
		local playerGui = Player.PlayerGui

		if playerGui:FindFirstChild(guiName) then
			playerGui[guiName]:Destroy()
		end
	end)

	Remotes.EnableFieldWalls.OnClientEvent:Connect(function(enabled)
		for _, basePart in pairs(FieldWalls:GetChildren()) do
			basePart.CanCollide = enabled
		end
	end)

	Remotes.ShowBaseMarker.OnClientEvent:Connect(function(enabled, base)
		for _, base in pairs(workspace.Plates:GetChildren()) do
			if base:FindFirstChild("BaseMarker") then
				base.BaseMarker:Destroy()
			end
		end

		if enabled and OnBase:FindFirstChild(Player.Name) then
			local baseMarker = SharedObjects.BaseMarkerPart.BaseMarker:Clone()
			baseMarker.Marker.Frame.Label.Text = base
			baseMarker.Parent = workspace.Plates[base]
		end
	end)

	Remotes.EnableBattingOrderGui.OnClientEvent:Connect(function(enabled, battingTeamObj)
		if enabled then
			if ClientFunctions.PlayerIsDefender(Player) then
				return
			end

			if Player.TeamColor == battingTeamObj.TeamColor and GameValues.OnBase:FindFirstChild(Player.Name) == nil then
				for _, otherPlayer in pairs(Players:GetPlayers()) do
					if otherPlayer.TeamColor == battingTeamObj.TeamColor
						and otherPlayer.Character
						and otherPlayer.Character:FindFirstChild("Head")
						and otherPlayer.Character.Head:FindFirstChild("BattingOrderBillboard")
						and otherPlayer.Character.Head:FindFirstChild("SkippedBillboard")
					then
						otherPlayer.Character.Head.BattingOrderBillboard.Enabled = true

						if GameValues[ScoreboardValues.AtBat.Value.."PriorityBattingQueue"]:FindFirstChild(otherPlayer.Name) == nil then
							otherPlayer.Character.Head.SkippedBillboard.Enabled = true
						else
							otherPlayer.Character.Head.SkippedBillboard.Enabled = false
						end
					end
				end
			end
		else
			for _, otherPlayer in pairs(Players:GetPlayers()) do
				if otherPlayer.Character
					and otherPlayer.Character:FindFirstChild("Head")
					and otherPlayer.Character.Head:FindFirstChild("BattingOrderBillboard")
					and otherPlayer.Character.Head:FindFirstChild("SkippedBillboard")
				then
					otherPlayer.Character.Head.BattingOrderBillboard.Enabled = false
					otherPlayer.Character.Head.SkippedBillboard.Enabled = false
				end
			end
		end
	end)

	Remotes.Notification.OnClientEvent:connect(function(message, notificationType)
		ClientFunctions.Notification(Player, message, notificationType)
	end)

	Remotes.ShowPitcherMoundCircle.OnClientEvent:Connect(function(visible, chosenPitcher, skipPitcherWait)
		if workspace:FindFirstChild("PitcherCircle") then
			workspace.PitcherCircle:Destroy()
		end

		if visible and ClientFunctions.PlayerIsDefender(Players.LocalPlayer) then
			local pitcherCircle = SharedObjects.PitcherCircle:Clone()
			pitcherCircle.Parent = workspace

			if Players.LocalPlayer == chosenPitcher then
				pitcherCircle.Display.Label2.Visible = true
			end

			for i = 7, 0, -1 do
				if skipPitcherWait then
					break
				end

				wait(1)
				if pitcherCircle ~= nil and pitcherCircle:FindFirstChild("Display") then
					pitcherCircle.Display.Label1.Text = "Waiting for Starting Pitcher ("..tostring(i)..")"
				else
					break
				end
			end

			if pitcherCircle ~= nil and pitcherCircle:FindFirstChild("Display") then
				pitcherCircle.Display.Label1.Text = "Backup Pitcher Needed"
				pitcherCircle.Display.Label2.Visible = true
				pitcherCircle.Display.Label3.Visible = true
			end
		end
	end)


	Remotes.JoinGame.OnClientEvent:Connect(function()
		if Player.PlayerGui:FindFirstChild("LobbyPickSideGui") then
			return
		end

		local lobbyPickSideGui = SharedGUIs.LobbyPickSideGui:Clone()
		lobbyPickSideGui.Parent = Player.PlayerGui
	end)

	Remotes.DisplayHitDistance.OnClientEvent:Connect(function(player, distance)
		local systemChannel = TextChatService:WaitForChild("System", 3)

		if systemChannel then
			systemChannel:DisplaySystemMessage(
				string.format("🔥 %s just smashed a homerun over %d feet! 🔥", player.Name, distance)
			)
		end
	end)

	Remotes.StartMovingCrowds.OnClientEvent:Connect(function()
		if workspace.LoadedBallpark:FindFirstChild("StadiumParts") then
			workspace.LoadedBallpark.StadiumParts.MovingCrowds.CrowdJumpAndSway.Enabled = false
			workspace.LoadedBallpark.StadiumParts.MovingCrowds.CrowdJumpAndSway.Enabled = true
		end
	end)

	RunService.RenderStepped:connect(function()
		if GameValues.BaseballObj.Value ~= nil then
			local ball = GameValues.BaseballObj.Value

			if ball and ball:FindFirstChild("Circle") and ball.Circle:FindFirstChild("CircleGui") and ball.Circle.CircleGui:FindFirstChild("Circle") then
				ball.Circle.CircleGui.Circle.Rotation = ball.Circle.CircleGui.Circle.Rotation + 3

				if ball.Parent and ball.Parent.Parent and ball.Parent.Parent:FindFirstChild("UpperTorso") then
					local characterTorso = ball.Parent.Parent["UpperTorso"]
					ball.Circle.CFrame = CFrame.new(characterTorso.Position.X, 2, characterTorso.Position.Z)
					ball.Circle.CircleGui.Enabled = true
					--ball.Circle.Light.Enabled = true
				else
					ball.Circle.CFrame = CFrame.new(ball.Position.X, 2, ball.Position.Z)
					ball.Circle.CircleGui.Enabled = false
					--ball.Circle.Light.Enabled = false
				end
			end
		end
	end)
end


return PlayerUtilsClient
