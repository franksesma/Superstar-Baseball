local BaseballFunctions = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")

local GameValues = ReplicatedStorage.GameValues
local OnBaseFolder = GameValues.OnBase
local ServerObjects =ServerStorage.ServerObjects
local HittingCam = workspace.Cameras.HittingCam
local Remotes = ReplicatedStorage.RemoteEvents
local Modules = ServerScriptService.Modules
local BattingZones = workspace.Batting
local Pitching = workspace.Pitching
local LoadedBallparkFolder = workspace.LoadedBallpark
local ScoreboardValues = GameValues.ScoreboardValues

local SharedGUIs = game.ReplicatedStorage.SharedGUIs
local SharedModules = ReplicatedStorage.SharedModules
local ServerModules = ServerScriptService.Modules

local DefensiveAbilities = require(ServerModules.DefensiveAbilities)
local OffensiveAbilities = require(ServerModules.OffensiveAbilities)
local CollisionGroups = require(SharedModules.CollisionGroups)
local TransformationEffects = require(Modules.TransformationEffects)
local TeamsModule = require(SharedModules.Teams)
local Styles = require(SharedModules.Styles)
local ServerFunctions = require(Modules.ServerFunctions)
local ClientFunctions = require(SharedModules.ClientFunctions)
local GameSettings = require(Modules.GameSettings)

function BaseballFunctions.ReturnBatterToDugout(player, atBat)
	local PlayerSpawns = LoadedBallparkFolder:FindFirstChild("PlayerSpawns")
	local homeSpawns = PlayerSpawns.Home:GetChildren()
	local awaySpawns = PlayerSpawns.Away:GetChildren()

	if ServerFunctions.PlayerIsInGame(player) then
		local character = player.Character

		if character and character:FindFirstChild("HumanoidRootPart") then
			if atBat == "Home" then
				ServerFunctions.TeleportPlayerCharacter(player, homeSpawns[math.random(1, #homeSpawns)].CFrame)
			elseif atBat == "Away" then
				ServerFunctions.TeleportPlayerCharacter(player, awaySpawns[math.random(1, #awaySpawns)].CFrame)
			end

			for _, part in pairs(character:GetChildren()) do
				if part:IsA("BasePart") or part:IsA("MeshPart") then
					part.CollisionGroup = CollisionGroups.DEFENSE_GROUP
				end

				if part ~= nil and part.Name == "BattingGlove" then
					part:Destroy()
				end

				if part ~= nil and part:IsA("BasePart") and part.Name == "LeftHand" or part.Name == "RightHand" then
					part.Transparency = 0
				end
			end

			TransformationEffects.RemoveAuras(player)
		end

		Remotes.LockedInBaseNotification:FireClient(player, false)
		Remotes.SafeStatusNotification:FireClient(player, false)
		Remotes.ShowBaseMarker:FireClient(player, false)
		Remotes.EnableBattingOrderGui:FireClient(player, true, player.Team)
		ServerFunctions.ShowOffBat(player, true)

		if GameValues.GameActive.Value and ClientFunctions.PlayerIsOffense(player) then
			BaseballFunctions.GiveBattingPracticeGui(player)
		end
	end
end

function BaseballFunctions.PlayerScored(player)
	local currentAtBat = ScoreboardValues.AtBat.Value

	ServerFunctions.RemoveBaseTracking(player)

	ScoreboardValues[currentAtBat.."Score"].Value = ScoreboardValues[currentAtBat.."Score"].Value + 1

	if ScoreboardValues.Inning.Value > GameSettings.MAX_INNINGS then
		ScoreboardValues[currentAtBat]["OT"].Value = ScoreboardValues[currentAtBat]["OT"].Value + 1
	else
		ScoreboardValues[currentAtBat][ScoreboardValues.Inning.Value].Value = ScoreboardValues[currentAtBat][ScoreboardValues.Inning.Value].Value + 1
	end

	BaseballFunctions.ReturnBatterToDugout(player, currentAtBat)

	Remotes.BatResults:FireAllClients("+1 Run for "..TeamsModule[GameValues[currentAtBat.."TeamPicked"].Value].City.."!")

	Remotes.ShowBaseMarker:FireClient(player, false)

	if not SoundService.Effects.CrowdCheer.IsPlaying then
		SoundService.Effects.CrowdCheer:Play()
	end

	if not SoundService.Effects.RunChime.IsPlaying then
		SoundService.Effects.RunChime:Play()
	end

	ServerFunctions.AddStat(player, "Hitting", "Runs", 1)

	ServerFunctions.AddStat(GameValues.CurrentBatter.Value, "Hitting", "RBI", 1)

	ServerFunctions.AddStat(GameValues.CurrentPitcher.Value, "Pitching", "RunsAllowed", 1)
end

function BaseballFunctions.PlayerOut(player)
	local currentAtBat = ScoreboardValues.AtBat.Value

	ServerFunctions.RemoveBaseTracking(player)

	BaseballFunctions.ReturnBatterToDugout(player, currentAtBat)

	Remotes.ShowBaseMarker:FireClient(player, false)

	ScoreboardValues.Outs.Value = ScoreboardValues.Outs.Value + 1
end

function BaseballFunctions.SetUpBatter(player)
	if player and ServerFunctions.PlayerIsInGame(player) then
		local Character = player.Character
		local BatName
		local EquippedStyle
		local BatHand = "Right" -- Default
		local BatSide = "Right" -- Default
		
		ServerFunctions.ShowOffBat(player, false)

		if _G.sessionData[player] then
			BatName = _G.sessionData[player].EquippedBat or "Wooden Bat"
			EquippedStyle = Styles.GetEquippedStyleName(player, "Offensive")
		else
			BatName = "Wooden Bat"
		end

		if EquippedStyle and OffensiveAbilities[EquippedStyle] then
			BatHand = OffensiveAbilities[EquippedStyle].BatHand or "Right"
			BatSide = OffensiveAbilities[EquippedStyle].BatSide or "Right"
		end

		if Character 
			and Character:FindFirstChild("HumanoidRootPart") 
			and Character:FindFirstChild("LeftHand")
			and Character:FindFirstChild("RightHand")
		then
			if ReplicatedStorage.ShopItems.Bat:FindFirstChild(BatName) then
				local Bat = ReplicatedStorage.ShopItems.Bat:FindFirstChild(BatName):Clone()
				Bat.Name = "PlayerBat"
				Bat.Parent = Character

				-- Determine which hand the bat should be welded to
				local Hand = BatHand == "Left" and "RightHand" or "LeftHand"
				local weld = ServerStorage.ServerObjects.BackupBatWeld:Clone()
				weld.Parent = Character[Hand]
				weld.Part0 = Character[Hand]
				weld.Part1 = Bat.Handle
			end
			
			Remotes.CancelSlideDive:FireClient(player)
			-- Move the player to correct batting zone
			local HRP = Character.HumanoidRootPart
			if BatSide == "Left" then
				--HRP.CFrame = BattingZones.LeftBatter.CFrame
				ServerFunctions.TeleportPlayerCharacter(player, BattingZones.LeftBatter.CFrame)
				--HRP.CFrame = CFrame.new(HRP.Position) * CFrame.Angles(0, math.rad(180), 0)
			else
				--HRP.CFrame = BattingZones.RightBatter.CFrame
				ServerFunctions.TeleportPlayerCharacter(player, BattingZones.RightBatter.CFrame)
			end

			local Humanoid = Character:FindFirstChild("Humanoid")
			Remotes.DisableMovement:FireClient(player, true)

			Remotes.CloneUI:FireClient(player, "HittingScreen")
			Remotes.SetupBatter:FireClient(player, EquippedStyle)
			Remotes.EnableFieldWalls:FireClient(player, true)
			Remotes.EnableBattingOrderGui:FireClient(player, false)
			Remotes.DisableEmotes:FireClient(player)

			for _, part in pairs(Character:GetDescendants()) do
				if part:IsA("BasePart") or part:IsA("MeshPart") then
					part.CollisionGroup = "OffenseGroup"
				end
			end

			Remotes.ToggleMenuButtons:FireClient(player, "Hide")
			Remotes.ToggleAbilityButtons:FireClient(player, false)
		end
	end
end

function BaseballFunctions.PlayBallLaunchEffects()
	for _, particle in pairs(workspace.Batting.StrikeZone.LaunchEffects:GetChildren()) do
		if particle:IsA("ParticleEmitter") then
			particle:Emit(5)
		end
	end
end

function BaseballFunctions.PlayPitchWooshSound(ball)
	if ball then
		local s = Instance.new("Sound")
		s.SoundId = "rbxassetid://75754607063587"
		s.Volume  = 1
		s.TimePosition = 0.15
		s.Parent  = ball
		s:Play()
		game.Debris:AddItem(s, 2)
	end
end

function BaseballFunctions.PlayHitWooshSound(ball)
	if ball then
		local s = Instance.new("Sound")
		s.SoundId = "rbxassetid://107152149795145"
		s.Volume  = 1
		s.Parent  = ball
		s:Play()
		game.Debris:AddItem(s, 2)
	end
end

function BaseballFunctions.SetUpPitcher(player)
	if player and player.Character and ServerFunctions.PlayerIsInGame(player) then
		local Character = player.Character
		local EquippedGlove
		local EquippedStyle 
		
		if _G.sessionData[player] then
			EquippedGlove = _G.sessionData[player].EquippedGlove
			
			EquippedStyle = Styles.GetEquippedStyleName(player, "Defensive")
		else
			EquippedGlove = "Old Glove"
		end
		
		local Gloves = ReplicatedStorage.ShopItems.Glove

		local StyleData = DefensiveAbilities[EquippedStyle]
		local GloveHand = StyleData and StyleData.GloveHand or "Left"
		local Hand = GloveHand == "Right" and "RightHand" or "LeftHand"

		for _, child in ipairs(Character:GetChildren()) do
			if child:IsA("Model") and child:FindFirstChild("MeshPart") then
				child:Destroy()
			end
		end

		local GloveModel = Gloves:FindFirstChild(EquippedGlove)
		if GloveModel then
			local Glove = GloveModel:Clone()
			Glove.Name = "PlayerGlove"
			Glove.Parent = Character
			
			local MeshPart = Glove:FindFirstChild("MeshPart")
			if MeshPart and Character:FindFirstChild(Hand) then
				local gloveWeld = game.ServerStorage.ServerObjects.GloveWeld:Clone()
				gloveWeld.Parent = MeshPart
				gloveWeld.Part0 = MeshPart
				gloveWeld.Part1 = Character[Hand]
			end
		end

		if Character:FindFirstChild("HumanoidRootPart") then
			local HRP = Character.HumanoidRootPart
			Remotes.CancelSlideDive:FireClient(player)
			
			Remotes.DisableMovement:FireClient(player, true)
			ServerFunctions.TeleportPlayerCharacter(player, Pitching.Mound.CFrame)
			
			local Humanoid = Character:FindFirstChild("Humanoid")

			Remotes.CloneUI:FireClient(player, "PitchingScreen")
			Remotes.SetupPitcher:FireClient(player, EquippedStyle)
			
			Remotes.EnableFieldWalls:FireClient(player, false)
			Remotes.ToggleMenuButtons:FireClient(player, "Hide")
			Remotes.ToggleAbilityButtons:FireClient(player, false)
			Remotes.DisableEmotes:FireClient(player)
		end
		
		ServerFunctions.ResetArms(player)
	end
end

function BaseballFunctions.SetUpNPC(player)
	local Character = player
	local Gloves = ReplicatedStorage.ShopItems.Glove
	local GloveModel = Gloves:FindFirstChild("Old Glove")
	local Glove
	
	if GloveModel then
		Glove = GloveModel:Clone()
		Glove.Parent = Character
		local MeshPart = Glove:FindFirstChild("MeshPart")
		if MeshPart then
			local gloveWeld = ServerStorage.ServerObjects.GloveWeld:Clone()
			gloveWeld.Parent = MeshPart
			gloveWeld.Part0 = MeshPart
			gloveWeld.Part1 = Character["LeftHand"]
		end
	end

end

function BaseballFunctions.SetUpTrail(player, ball)
	-- Remove all existing trail-related instances
	for _, obj in pairs(ball:GetChildren()) do
		if obj:IsA("Attachment") or obj:IsA("Trail") or obj:IsA("ParticleEmitter") then
			obj:Destroy()
		end
	end

	local equippedTrailName = "Normal Trail"
	if _G.sessionData[player] and _G.sessionData[player].EquippedTrail then
		equippedTrailName = _G.sessionData[player].EquippedTrail
	end

	local trailTemplate = game.ReplicatedStorage:WaitForChild("ShopItems"):WaitForChild("Trail"):FindFirstChild(equippedTrailName)
	if not trailTemplate then return end

	local effectFolder = trailTemplate:FindFirstChild("PersonalTrailEffect") or trailTemplate

	local attachment0 = nil
	local attachment1 = nil

	for _, item in pairs(effectFolder:GetChildren()) do
		if item:IsA("Attachment") then
			local newAttachment = item:Clone()
			newAttachment.Parent = ball
			if not attachment0 then
				attachment0 = newAttachment
			elseif not attachment1 then
				attachment1 = newAttachment
			end
		end
	end

	for _, item in pairs(effectFolder:GetChildren()) do
		if item:IsA("Trail") then
			local trail = item:Clone()
			trail.Attachment0 = attachment0
			trail.Attachment1 = attachment1
			trail.Enabled = true
			trail.Parent = ball
		elseif item:IsA("ParticleEmitter") then
			local emitter = item:Clone()
			if attachment0 then
				emitter.Parent = attachment0
			else
				emitter.Parent = ball
			end
			emitter.Enabled = true
		elseif item:IsA("Beam") then
			item:Clone().Parent = ball
		end
	end
end

function BaseballFunctions.GiveBattingPracticeGui(player)
	if player and not player:GetAttribute("IsAI") then
		Remotes.BattingCage.ActivateBattingPracticeGui:FireClient(player)
	end
end

function BaseballFunctions.UnSetupPlayer(player)
	if player and not player:GetAttribute("IsAI") then
		print("UNBINDING PLAYER CAM")
		Remotes.RemoveGui:FireClient(player, "PitchingScreen")
		Remotes.RemoveGui:FireClient(player, "HittingScreen", true)
		Remotes.BattingCage.DeactivateBattingPracticeGui:FireClient(player)
		Remotes.ResetFOV:FireClient(player)

		local Character = player.Character
		
	    if Character then
			if Character:FindFirstChild("PlayerBat") then
				Character["PlayerBat"]:Destroy()
			end
		end

		Remotes.StopAnimations:FireClient(player)
		Remotes.ToggleMenuButtons:FireClient(player, "Show")
		Remotes.ToggleAbilityButtons:FireClient(player, true)
		Remotes.UnbindHitting:FireClient(player)
	end
end

function BaseballFunctions.RemoveGUIs(player)
	if player and player.Character then
		Remotes.RemoveGui:FireClient(player, "PitchingScreen")
		Remotes.RemoveGui:FireClient(player, "HittingScreen", false)
		Remotes.ResetFOV:FireClient(player)
		Remotes.UnbindHitting:FireClient(player)
	end
end

function BaseballFunctions.DeleteBat(player)
	if player and player.Character then

		local Character = player.Character
		
	    if Character then
			if Character:FindFirstChild("PlayerBat") then
				Character["PlayerBat"]:Destroy()
			end
		end
	end
end

function BaseballFunctions.DeleteGlove(player)
	if player and player.Character then

		local Character = player.Character

		if Character then
			if Character:FindFirstChild("PlayerGlove") then
				Character["PlayerGlove"]:Destroy()
			end
		end
	end
end


function BaseballFunctions.StepOffMound(player)
	if player and player.Character then
		Remotes.RemoveGui:FireClient(player, "PitchingScreen")
		Remotes.RemoveGui:FireClient(player, "HittingScreen")
		Remotes.ResetFOV:FireClient(player)

		local Character = player.Character

		Remotes.StopAnimations:FireClient(player)
		Remotes.DisableMovement:FireClient(player, false)
		Remotes.ChangeCameraType:FireClient(player, Enum.CameraType.Custom)
	end
end

function BaseballFunctions.InitializeBaseTracking(player)
	if OnBaseFolder:FindFirstChild(player.Name) == nil then
		if GameValues.CurrentBatter.Value == player then -- player just hit
			local currentBaseObj = Instance.new("StringValue")
			currentBaseObj.Value = "Home Base"
			currentBaseObj.Name = player.Name
			currentBaseObj.Parent = OnBaseFolder

			local startingBaseObj = Instance.new("StringValue")
			startingBaseObj.Name = "StartingBase"
			startingBaseObj.Value = "Home Base"
			startingBaseObj.Parent = currentBaseObj

			local lockedInBaseObj = Instance.new("BoolValue")
			lockedInBaseObj.Name = "LockedInBase"
			lockedInBaseObj.Parent = currentBaseObj

			local baseElapseTime = Instance.new("NumberValue")
			baseElapseTime.Name = "BaseElapseTime"
			baseElapseTime.Parent = lockedInBaseObj
			
			local isSafeBool = Instance.new("BoolValue")
			isSafeBool.Name = "IsSafe"
			isSafeBool.Parent = currentBaseObj
			
			local taggedUp = Instance.new("BoolValue")
			taggedUp.Name = "TaggedUp"
			taggedUp.Parent = currentBaseObj
		end
	end
end


function BaseballFunctions.SetUpAIBatter(aiModel)
	if aiModel then
		local Character = aiModel
		local BatName = "Wooden Bat" -- For now, you can expand this later
		local BatHand = "Right"
		local BatSide = "Right"

		local Bat = ReplicatedStorage.ShopItems.Bat:FindFirstChild(BatName):Clone()
		Bat.Name = "PlayerBat"
		Bat.Parent = Character

		local Hand = BatHand == "Left" and "RightHand" or "LeftHand"
		local weld = ServerStorage.ServerObjects.BackupBatWeld:Clone()
		weld.Parent = Character[Hand]
		weld.Part0 = Character[Hand]
		weld.Part1 = Bat.Handle

		-- Move to correct batter box
		if BatSide == "Left" then
			Character:PivotTo(BattingZones.LeftBatter.CFrame)
		else
			Character:PivotTo(BattingZones.RightBatter.CFrame)
		end

		-- Play batting stance idle animation
		local humanoid = Character:FindFirstChild("Humanoid")
		if humanoid then
			local battingStanceAnimation = Instance.new("Animation")
			battingStanceAnimation.AnimationId = "rbxassetid://93937867770996"
			local animationTrack = humanoid:LoadAnimation(battingStanceAnimation)
			animationTrack:Play()
		end

		-- Optional: put in OffenseGroup collision group
		for _, part in pairs(Character:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("MeshPart") then
				part.CollisionGroup = "AIOffenseGroup"
			end
		end
	end
end


function BaseballFunctions.SetUpAIPitcher(aiModel, aiMound)
	if aiModel then
		local Character = aiModel

		-- Use default glove for AI
		local GloveName = "Old Glove"
		local Gloves = ReplicatedStorage.ShopItems.Glove

		-- Pick default defensive style for AI (or expand later)
		local EquippedStyle = "Default" -- your AI defensive style name
		local StyleData = DefensiveAbilities[EquippedStyle]
		local GloveHand = StyleData and StyleData.GloveHand or "Left"
		local Hand = GloveHand == "Right" and "RightHand" or "LeftHand"

		-- Clear existing gloves
		for _, child in ipairs(Character:GetChildren()) do
			if child:IsA("Model") and child:FindFirstChild("MeshPart") then
				child:Destroy()
			end
		end

		-- Attach glove
		local GloveModel = Gloves:FindFirstChild(GloveName)
		if GloveModel then
			local Glove = GloveModel:Clone()
			Glove.Name = "PlayerGlove"
			Glove.Parent = Character

			local MeshPart = Glove:FindFirstChild("MeshPart")
			if MeshPart and Character:FindFirstChild(Hand) then
				local gloveWeld = game.ServerStorage.ServerObjects.GloveWeld:Clone()
				gloveWeld.Parent = MeshPart
				gloveWeld.Part0 = MeshPart
				gloveWeld.Part1 = Character[Hand]
			end
		end

		-- Teleport AI pitcher to mound
		if Character:FindFirstChild("HumanoidRootPart") then
			Character:PivotTo(aiMound.CFrame)

			-- Play pitching stance idle animation
			local humanoid = Character:FindFirstChild("Humanoid")
			if humanoid then
				local pitchStanceAnim = Instance.new("Animation")
				pitchStanceAnim.AnimationId = "rbxassetid://18512502047" 
				local animTrack = humanoid:LoadAnimation(pitchStanceAnim)
				animTrack:Play()
			end
		end

		-- Optional: put in DefenseGroup collision group
		for _, part in ipairs(Character:GetChildren()) do
			if part:IsA("BasePart") or part:IsA("MeshPart") then
				part.CollisionGroup = "DefenseGroup"
			end
		end
	end
end


return BaseballFunctions