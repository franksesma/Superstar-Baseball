local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage:WaitForChild("SharedModules")
local Folder = Modules:WaitForChild("AbilityCinematics")

local AbilityCinematics = {}
local loadedModules = {}

local CinematicUtils = require(Modules.AbilityCinematics.CinematicUtils)
local ClientFunctions = require(Modules.ClientFunctions)


function AbilityCinematics:PlayCinematic(pitcher, hitter, category, bat, module, styleName)
	local cinematicPlayer = nil
	
	local player = Players.LocalPlayer

	if category == "Defensive" then
		cinematicPlayer = pitcher
		
		local gameValues = ReplicatedStorage:FindFirstChild("GameValues")
		if gameValues and gameValues:FindFirstChild("CurrentBatter") and player == gameValues.CurrentBatter.Value then
			return
		end
	elseif category == "Offensive" then
		cinematicPlayer = hitter
	end

	if not cinematicPlayer then return end

	local char = cinematicPlayer.Character

	if not char then return end
	
	local playerGui = player:WaitForChild("PlayerGui")
	local cinematic = playerGui:WaitForChild("Cinematic")
	
	if module.requiresCinematicFrame then
		cinematic.Frame.Visible = true
	end
	
	CinematicUtils.ShowUIVisibility(false)
	
	-- Play hype music 

	local music = CinematicUtils.PlayHypeMusic("rbxassetid://72982404278746", 0.5)

	-- Get animator and humanoidrootpart

	local hum = char:FindFirstChildOfClass("Humanoid")
	local animator = hum:FindFirstChildOfClass("Animator")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	
	if module.faceHomePlate then
		if module.CustomFixedPos then
			local lookCFrame = CFrame.new(module.CustomFixedPos, workspace.Plates["Home Base"].Position)
			
			hrp.CFrame = lookCFrame
			
			if module.CustomFixedRotation then
				hrp.CFrame = lookCFrame * module.CustomFixedRotation
			end
		else
			hrp.CFrame = CFrame.new(hrp.Position, workspace.Plates["Home Base"].Position)
		end
	elseif module.facePitcherMound then
		hrp.CFrame = CFrame.new(hrp.Position, workspace.Plates.PitcherPlate.Position)
	end
	
	-- Gets the camera rig
	
	local camRig = module.camRig:Clone()
	camRig.Parent = workspace
	
	local camPart = CinematicUtils.GetCamRigPart(camRig)
	local camHRP = camRig:FindFirstChild("RootPart")
	local animationController = camRig:FindFirstChildOfClass("AnimationController")
	local camAnimator = animationController:FindFirstChildOfClass("Animator")
	camAnimator.PreferLodEnabled = false

	-- Load the tracks

	local humTrack = animator:LoadAnimation(script[category][styleName].Hum)
	local camTrack = camAnimator:LoadAnimation(script[category][styleName].Cam)
	
	-- Positions the camera rig
	
	if module.customCamPivot then
		camRig:PivotTo(module.customCamPivot)
	else
		camRig:PivotTo(hrp.CFrame)
	end
	
	hrp.Anchored = true
	
	-- Make player's camera follow the rig's camera

	local cam = workspace.CurrentCamera

	cam.FieldOfView = module.fieldOfView

	CinematicUtils.RemoveCatcher()
	
	-- Play the tracks

	camTrack:Play()
	humTrack:Play(0)
	
	if module.adjustSpeed then
		camTrack:AdjustSpeed(module.adjustSpeed)
		humTrack:AdjustSpeed(module.adjustSpeed)
	end

	task.wait()
	
	local connection: RBXScriptConnection = RunService.RenderStepped:Connect(function()
		cam.CFrame = camPart.CFrame
	end)
	
	task.delay(0.1, function()
		if camTrack.Length == 0 then
			warn("CamRig animation failed to load V8: "..styleName)
		end
		
		if humTrack.Length == 0 then
			warn("Hum animation failed to load: "..styleName)
		end
	end)

	ClientFunctions.PlayAudioSound(player, "StarPowerSound")
	
	-- Play VFX
	module.Execute(char, camPart, camTrack, humTrack)
	
	-- Wait for the animation to end
	local timeout = 15
	local start = tick()
	
	repeat
		task.wait()
	until not camTrack.IsPlaying or tick() - start > timeout
	
	-- Return everything to normal

	camRig:Destroy()
	connection:Disconnect()
	cinematic.Frame.Visible = false
	humTrack:Destroy()

	workspace.VFXFolder:ClearAllChildren()
	CinematicUtils.RestoreCatcher()
	CinematicUtils.FadeHypeMusic(music)
	ClientFunctions.ResetUltimateCameras(player)
	CinematicUtils.ShowUIVisibility(true)
	
	if category == "Defensive" then
		ReplicatedStorage.RemoteEvents.CinematicFinished:FireServer()
	end

	if hrp then
		hrp.Anchored = false
	end
end

function AbilityCinematics.HandleAbilityCamera(pitcher, hitter, abilityName, category, bat)
	local cleanName = abilityName:gsub(" Swing", ""):gsub(" Pitch", "")
	local key = category .. "_" .. cleanName

	if not loadedModules[key] then
		local categoryFolder = Folder:FindFirstChild(category)
		if categoryFolder then
			local modScript = categoryFolder:FindFirstChild(cleanName)
			if modScript and modScript:IsA("ModuleScript") then
				loadedModules[key] = require(modScript)
			end
		end
	end

	local module = loadedModules[key]
	if module and module.Execute then
		local player = Players.LocalPlayer
		if player 
			and player.Character 
			and player.Character:FindFirstChild("States")
			and player.Character.States:FindFirstChild("InStylesLocker")
			and player.Character.States.InStylesLocker.Value 
		then -- do not interrupt players in styles locker
			return
		end
		
		AbilityCinematics:PlayCinematic(pitcher, hitter, category, bat, module, cleanName)
	else
		warn("[AbilityCinematics] No handler for:", category, cleanName)
	end
end

return AbilityCinematics
