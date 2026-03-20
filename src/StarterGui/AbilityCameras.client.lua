--------------------------------------------------------------------------------
--// Services & Variables
--------------------------------------------------------------------------------
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local ClientFunctions = require(SharedModules.ClientFunctions)
local ClientVFXHandler = require(SharedModules.ClientVFXHandler)

local CameraFolder = workspace:WaitForChild("Cameras")
local LocalPlayer = Players.LocalPlayer
local CurrentPlayer = LocalPlayer
local camera = workspace.CurrentCamera

-- Cinematic GUI Frame (for certain pitch abilities)
local CinematicFrame = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Cinematic"):WaitForChild("Frame")

--------------------------------------------------------------------------------
--// Helper Functions
--------------------------------------------------------------------------------

local function playAnimation(character: Model, animationId: string)
	if not character then return nil end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return nil end

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId

	local track = animator:LoadAnimation(animation)
	track:Play()
	return track
end

local function tweenCamera(targetCFrame: CFrame, duration: number, easingStyle: Enum.EasingStyle?, easingDirection: Enum.EasingDirection?)
	-- Moves the camera to a target CFrame over 'duration' seconds
	local info = TweenInfo.new(
		duration,
		easingStyle or Enum.EasingStyle.Quad,
		easingDirection or Enum.EasingDirection.Out
	)
	local tween = TweenService:Create(camera, info, { CFrame = targetCFrame })
	tween:Play()
	return tween
end

local function playStarPowerSound()
	ClientFunctions.PlayAudioSound(LocalPlayer, "StarPowerSound")
end

local function removeCatcherFromWorkspace()
	-- If the NPCs folder has a Catcher, move it to ReplicatedStorage
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs and npcs:FindFirstChild("Catcher") then
		npcs.Catcher.Parent = ReplicatedStorage
	end
end

local function restoreCatcherToWorkspace()
	-- Move the Catcher back into the NPCs folder if it exists in ReplicatedStorage
	if ReplicatedStorage:FindFirstChild("Catcher") and workspace:FindFirstChild("NPCs") then
		ReplicatedStorage.Catcher.Parent = workspace.NPCs
	end
end

local function resetLocalCameraIfNotBatterOrPitcher(pitcher, hitter)
	-- If we are neither the pitcher nor the hitter, restore our default camera
	if LocalPlayer.Name ~= pitcher.Name and LocalPlayer.Name ~= hitter.Name then
		camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		camera.CameraType = Enum.CameraType.Custom
	end
end


Remotes.WhiteFlashEffect.OnClientEvent:Connect(function(player)
	if player ~= LocalPlayer then return end
	local flash = Instance.new("ScreenGui")
	flash.IgnoreGuiInset = true
	flash.ResetOnSpawn = false
	flash.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 1
	frame.Parent = flash

	local tween = TweenService:Create(frame, TweenInfo.new(0.15), {BackgroundTransparency = 0})
	tween:Play()
	tween.Completed:Wait()

	local outTween = TweenService:Create(frame, TweenInfo.new(0.25), {BackgroundTransparency = 1})
	outTween:Play()
	outTween.Completed:Wait()

	flash:Destroy()
end)

--------------------------------------------------------------------------------
--// Swing Ability Handlers
--------------------------------------------------------------------------------

local function handleFireSwing(pitcher, hitter)
	if not hitter or not hitter.Character then return end
	local rootPart = hitter.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	playAnimation(hitter.Character, "rbxassetid://77363237544590")
	playStarPowerSound()

	local lookDirection = rootPart.CFrame.LookVector
	local rightVector = rootPart.CFrame.RightVector
	local initialOffset = (lookDirection * 7) - (rightVector * 7) + Vector3.new(0, 5, 0)
	local cameraPosition = rootPart.Position + initialOffset

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(cameraPosition, rootPart.Position)

	removeCatcherFromWorkspace()

	task.wait(0.5)
	ClientFunctions.PlayAudioSound(LocalPlayer, "Fire")

	local hittingCam = CameraFolder:FindFirstChild("HittingCam")
	local hittingCamFocal = CameraFolder:FindFirstChild("HittingCamFocal")
	if hittingCam and hittingCamFocal then
		local target = CFrame.new(hittingCam.Position, hittingCamFocal.Position)
		tweenCamera(target, 2.5)
		task.wait(2.5)
	end

	restoreCatcherToWorkspace()
	camera.CameraType = Enum.CameraType.Custom
end

local function handlePortalSwing(pitcher, hitter, bat)
	if not hitter or not hitter.Character then return end
	local rootPart = hitter.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	playAnimation(hitter.Character, "rbxassetid://98250279200759")
	playStarPowerSound()

	camera.CameraType = Enum.CameraType.Scriptable
	local cameraPosition = (rootPart.CFrame * CFrame.new(-3.5, 0, -2)).Position

	-- Focus on the bat's barrel or handle
	local camFocus = bat:FindFirstChild("Barrel") or bat:FindFirstChild("Bat") or bat:FindFirstChild("Handle") or bat:FindFirstChildOfClass("BasePart")
	if camFocus then
		camera.CFrame = CFrame.new(cameraPosition, camFocus.Position)
	end

	-- Continuously lerp the camera to track the bat
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not camFocus then return end
		camera.CFrame = camera.CFrame:Lerp(CFrame.new(cameraPosition, camFocus.Position), 0.35)
	end)

	task.wait(1.9)

	-- Create a special Portal baseball & portal
	local BALL_OFFSET = CFrame.new(-4, 2, -2.5)
	local PORTAL_OFFSET = CFrame.new(-8, 2, -2.5)
	local ball = ReplicatedStorage.VFX.PortalBaseball:Clone()
	ball.CFrame = rootPart.CFrame * BALL_OFFSET
	ball.Parent = workspace.CurrentCamera

	local portal = ReplicatedStorage.VFX.Portal:Clone()
	portal:PivotTo(rootPart.CFrame * PORTAL_OFFSET * CFrame.Angles(0, 0, math.rad(90)))
	portal.Parent = workspace.CurrentCamera

	-- Focus the camera on the ball now
	camFocus = ball
	cameraPosition = (rootPart.CFrame * CFrame.new(1.5, 1.5, -4)).Position

	local tween = TweenService:Create(
		ball,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = rootPart.CFrame * PORTAL_OFFSET }
	)
	tween:Play()

	removeCatcherFromWorkspace()

	task.wait(0.25)
	conn:Disconnect()
	ball:Destroy()

	portal.Fade.Enabled = true
	task.delay(0.4, function()
		portal:Destroy()
	end)

	local hittingCam = CameraFolder:FindFirstChild("HittingCam")
	local hittingCamFocal = CameraFolder:FindFirstChild("HittingCamFocal")
	if hittingCam and hittingCamFocal then
		local target = CFrame.new(hittingCam.Position, hittingCamFocal.Position)
		tweenCamera(target, 0.25)
		task.wait(0.25)
	end

	restoreCatcherToWorkspace()
	resetLocalCameraIfNotBatterOrPitcher(pitcher, hitter)
end

local function handleBoomerangSwing(pitcher, hitter)
	if not hitter or not hitter.Character then return end
	local rootPart = hitter.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	playAnimation(hitter.Character, "rbxassetid://70404182388627")
	playStarPowerSound()

	local cameraPosition = (rootPart.CFrame * CFrame.new(0, 0, -4)).Position
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(cameraPosition, rootPart.Position)

	task.wait(0.35)

	local target = CFrame.new((rootPart.CFrame * CFrame.new(0, 0, -7)).Position, rootPart.Position)
	tweenCamera(target, 0.25)

	removeCatcherFromWorkspace()
	task.wait(2.35)  -- total 2.7 minus 0.35

	local hittingCam = CameraFolder:FindFirstChild("HittingCam")
	local hittingCamFocal = CameraFolder:FindFirstChild("HittingCamFocal")
	if hittingCam and hittingCamFocal then
		local targetCFrame = CFrame.new(hittingCam.Position, hittingCamFocal.Position)
		tweenCamera(targetCFrame, 0.25)
		task.wait(0.25)
	end

	restoreCatcherToWorkspace()
	resetLocalCameraIfNotBatterOrPitcher(pitcher, hitter)
end

local function handleBouncyBallSwing(pitcher, hitter)
	if not hitter or not hitter.Character then return end
	local rootPart = hitter.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	playAnimation(hitter.Character, "rbxassetid://104977458612349")
	playStarPowerSound()

	camera.CameraType = Enum.CameraType.Scriptable
	local closeUpOffset = CFrame.new(0, 2, -4)
	camera.CFrame = CFrame.new(
		(rootPart.CFrame * closeUpOffset).Position,
		rootPart.Position
	)

	task.wait(0.5)

	local panInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local panUpOffset = CFrame.new(0, 4, -4)
	local targetPan = CFrame.new(
		(rootPart.CFrame * panUpOffset).Position,
		rootPart.Position
	)

	local tweenPan = TweenService:Create(camera, panInfo, { CFrame = targetPan })
	tweenPan:Play()

	-- Create the ball overhead
	local baseball = ReplicatedStorage.VFX:FindFirstChild("FakeBaseball"):Clone()
	baseball.Parent = workspace
	baseball.Anchored = true
	baseball.CFrame = rootPart.CFrame:ToWorldSpace(CFrame.new(0, 2, 3))

	tweenPan.Completed:Connect(function()
		baseball.Anchored = false  -- drop the ball

		local zoomOutOffset = CFrame.new(0, 3, -8)
		local zoomOutCFrame = CFrame.new(
			(rootPart.CFrame * zoomOutOffset).Position,
			rootPart.Position
		)
		local tweenZoom = TweenService:Create(camera, panInfo, { CFrame = zoomOutCFrame })
		tweenZoom:Play()

		tweenZoom.Completed:Connect(function()
			task.wait(0.5)
			resetLocalCameraIfNotBatterOrPitcher(pitcher, hitter)
		end)
	end)
end

local function handleWhirlwindSwing(pitcher, hitter)
	-- Variation that does an up-close pan, etc.
	-- (from your "Whirlwind Swing" block that had the overhead baseball logic)
	if not hitter or not hitter.Character then return end
	local rootPart = hitter.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	playAnimation(hitter.Character, "rbxassetid://83303577336793")
	playStarPowerSound()

	camera.CameraType = Enum.CameraType.Scriptable
	local closeUpOffset = CFrame.new(0, 2, -4)
	camera.CFrame = CFrame.new(
		(rootPart.CFrame * closeUpOffset).Position,
		rootPart.Position
	)

	task.wait(0.5)

	local panInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local panUpOffset = CFrame.new(0, 4, -4)
	local targetPan = CFrame.new(
		(rootPart.CFrame * panUpOffset).Position,
		rootPart.Position
	)
	local tweenPan = TweenService:Create(camera, panInfo, { CFrame = targetPan })
	tweenPan:Play()

	-- Overhead baseball
	local baseball = ReplicatedStorage.VFX:FindFirstChild("FakeBaseball"):Clone()
	baseball.Parent = workspace
	baseball.Anchored = true
	baseball.CFrame = rootPart.CFrame:ToWorldSpace(CFrame.new(0, 2, 3))

	tweenPan.Completed:Connect(function()
		baseball.Anchored = false

		local zoomOutOffset = CFrame.new(0, 3, -8)
		local zoomOutCFrame = CFrame.new(
			(rootPart.CFrame * zoomOutOffset).Position,
			rootPart.Position
		)
		local tweenZoom = TweenService:Create(camera, panInfo, { CFrame = zoomOutCFrame })
		tweenZoom:Play()

		tweenZoom.Completed:Connect(function()
			task.wait(0.5)
			resetLocalCameraIfNotBatterOrPitcher(pitcher, hitter)
		end)
	end)
end

local function handleSeismicSwing(pitcher, hitter)
	if not hitter or not hitter.Character then return end
	local rootPart = hitter.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	playAnimation(hitter.Character, "rbxassetid://127074785063600")
	playStarPowerSound()

	local HomePlate = workspace.Plates:WaitForChild("Home Base")

	camera.CameraType = Enum.CameraType.Scriptable
	-- 🎥 Start: Camera facing hitter from left-front of HomePlate
	local startOffset = HomePlate.CFrame:ToWorldSpace(CFrame.new(-4, 2, -6))
	camera.CFrame = CFrame.new(startOffset.Position, rootPart.Position)

	task.wait(0.3)

	-- ⚡ Impact VFX (flash + shockwave + debris)
	local flashGui = Instance.new("ScreenGui")
	flashGui.IgnoreGuiInset = true
	flashGui.ResetOnSpawn = false
	flashGui.Name = "ImpactFrame"
	flashGui.Parent = game.Players.LocalPlayer.PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 1
	frame.ZIndex = 100
	frame.Parent = flashGui
	local flashTween = TweenService:Create(frame, TweenInfo.new(0.1), {BackgroundTransparency = 0.5})
	flashTween:Play()
	flashTween.Completed:Wait()

	local fadeTween = TweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency = 1})
	fadeTween:Play()
	fadeTween.Completed:Wait()

	flashGui:Destroy()

	--ClientVFXHandler.CameraShake(0.25, 5)

	-- Shockwave from Home Plate
	local shockwave = ReplicatedStorage.VFX:WaitForChild("ShockwaveRing"):Clone()

	ClientVFXHandler.PlaceModel(shockwave, HomePlate.Position)

	shockwave.Parent = workspace

	ClientVFXHandler.GrowModel(shockwave, 0.5)
	ClientVFXHandler.FadeModel(shockwave, false, 0.5)

	game:GetService("Debris"):AddItem(shockwave, 0.6)
	-- Debris
	for _ = 1, 8 do
		local debrisPart = Instance.new("Part")
		debrisPart.Size = Vector3.new(0.2, 0.2, 0.2)
		debrisPart.Shape = Enum.PartType.Ball
		debrisPart.Material = Enum.Material.Neon
		debrisPart.Color = Color3.fromRGB(200, 200, 255)
		debrisPart.CanCollide = false
		debrisPart.Anchored = false
		debrisPart.Position = HomePlate.Position + Vector3.new(math.random(-2,2), math.random(1,3), math.random(-2,2))
		debrisPart.Parent = workspace

		local force = Instance.new("BodyVelocity")
		force.Velocity = Vector3.new(math.random(-5,5), math.random(5,10), math.random(-5,5))
		force.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		force.Parent = debrisPart

		game:GetService("Debris"):AddItem(debrisPart, 1)
	end

	-- 🎥 Dynamic Camera MOVES using tweenCamera properly now!

	task.wait(0.1)

	-- Snap to right side quickly
	local rightOffset = HomePlate.CFrame:ToWorldSpace(CFrame.new(4, 2, -6))
	tweenCamera(CFrame.new(rightOffset.Position, rootPart.Position), 0.3)
	task.wait(0.3)
	-- Move above hitter
	local aboveOffset = HomePlate.CFrame:ToWorldSpace(CFrame.new(0, 8, -5))
	tweenCamera(CFrame.new(aboveOffset.Position, rootPart.Position), 0.3)
	task.wait(0.3)

	-- Zoom out backward
	local zoomOutOffset = HomePlate.CFrame:ToWorldSpace(CFrame.new(0, 5, -12))
	tweenCamera(CFrame.new(zoomOutOffset.Position, rootPart.Position), 0.4)
	task.wait(0.4)

	-- 🏏 Baseball Spawn
	local baseball = ReplicatedStorage.VFX:FindFirstChild("FakeBaseball"):Clone()
	baseball.Parent = workspace
	baseball.Anchored = true
	baseball.CFrame = rootPart.CFrame:ToWorldSpace(CFrame.new(0, 2, 3))

	task.wait(0.2)
	baseball.Anchored = false

	-- 🎥 Final camera hold, then reset
	task.wait(0.5)
	resetLocalCameraIfNotBatterOrPitcher(pitcher, hitter)
end



local function handleSerenitySwing(pitcher, hitter)
	if not hitter or not hitter.Character then return end
	local rootPart = hitter.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	playAnimation(hitter.Character, "rbxassetid://129844896760252")
	playStarPowerSound()

	local cameraPosition = (rootPart.CFrame * CFrame.new(-4, 0, 0)).Position
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(cameraPosition, rootPart.Position)

	task.wait(0.35)
	local targetCFrame = CFrame.new((rootPart.CFrame * CFrame.new(-7, 0, 0)).Position, rootPart.Position)
	tweenCamera(targetCFrame, 0.25)

	removeCatcherFromWorkspace()
	task.wait(2.35)

	local hittingCam = CameraFolder:FindFirstChild("HittingCam")
	local hittingCamFocal = CameraFolder:FindFirstChild("HittingCamFocal")
	if hittingCam and hittingCamFocal then
		local finalCF = CFrame.new(hittingCam.Position, hittingCamFocal.Position)
		tweenCamera(finalCF, 0.25)
		task.wait(0.25)
	end

	restoreCatcherToWorkspace()
	resetLocalCameraIfNotBatterOrPitcher(pitcher, hitter)
end

local function handleBombSwing(pitcher, hitter)
	if not hitter or not hitter.Character then return end
	local rootPart = hitter.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local track = playAnimation(hitter.Character, "rbxassetid://95752640747401")
	if track then track.Looped = false end
	playStarPowerSound()

	local lookDirection = rootPart.CFrame.LookVector
	local rightVector = rootPart.CFrame.RightVector
	local initialOffset = (lookDirection * 7) - (rightVector * 7) + Vector3.new(0, 5, 0)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(rootPart.Position + initialOffset, rootPart.Position)

	removeCatcherFromWorkspace()

	-- Create bomb
	local bomb = ReplicatedStorage.VFX.Bomb:Clone()
	local vfx = ReplicatedStorage.VFXParticlesFB.BombSmoke:Clone()
	vfx.Enabled = false
	vfx.Parent = bomb

	local weld = Instance.new("Weld")
	weld.Part0 = hitter.Character.RightHand
	weld.Part1 = bomb
	weld.C0 = CFrame.new(0, 0, 0.25)
	weld.Parent = bomb

	bomb.Parent = hitter.Character

	task.wait(3)
	bomb:Destroy()

	local hittingCam = CameraFolder:FindFirstChild("HittingCam")
	local hittingCamFocal = CameraFolder:FindFirstChild("HittingCamFocal")
	if hittingCam and hittingCamFocal then
		local target = CFrame.new(hittingCam.Position, hittingCamFocal.Position)
		tweenCamera(target, 2.5)
		task.wait(2.5)
	end

	restoreCatcherToWorkspace()
	resetLocalCameraIfNotBatterOrPitcher(pitcher, hitter)
end

--------------------------------------------------------------------------------
--// Pitch Ability Handlers
--------------------------------------------------------------------------------

local function handleFirePitch(pitcher, hitter)
	-- If we are the current batter, do nothing special
	local gameValues = ReplicatedStorage:FindFirstChild("GameValues")
	if gameValues and gameValues:FindFirstChild("CurrentBatter") then
		if CurrentPlayer == gameValues.CurrentBatter.Value then
			return
		end
	end

	if not pitcher or not pitcher.Character then return end
	local rootPart = pitcher.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	playAnimation(pitcher.Character, "rbxassetid://113018770655567")
	playStarPowerSound()

	-- Basic camera behind the pitcher
	local lookDirection = rootPart.CFrame.LookVector
	local rightVector = rootPart.CFrame.RightVector
	local initialOffset = (lookDirection * 7) - (rightVector * 7) + Vector3.new(0, 5, 0)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(rootPart.Position + initialOffset, rootPart.Position)

	task.wait(0.5)
	ClientFunctions.PlayAudioSound(LocalPlayer, "Fire")

	local starPitchCam = CameraFolder:FindFirstChild("StarPitchingCam")
	local starPitchCamFocal = CameraFolder:FindFirstChild("StarPitchingCamFocal")
	if starPitchCam and starPitchCamFocal then
		local target = CFrame.new(starPitchCam.Position, starPitchCamFocal.Position)
		tweenCamera(target, 2.5)
		task.wait(2.5)
	end

	camera.CameraType = Enum.CameraType.Custom
end

local function handleTornadoPitch(pitcher, hitter)
	-- If we are the current batter, do nothing
	local gameValues = ReplicatedStorage:FindFirstChild("GameValues")
	if gameValues and gameValues:FindFirstChild("CurrentBatter") then
		if CurrentPlayer == gameValues.CurrentBatter.Value then
			return
		end
	end

	if not pitcher or not pitcher.Character then return end
	local rootPart = pitcher.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local track = playAnimation(pitcher.Character, "rbxassetid://105692201703866")
	playStarPowerSound()

	-- Adjust the animation speed in steps (based on your original code)
	spawn(function()
		if track then
			task.wait()
			track:AdjustSpeed(0)
			task.wait(0.5)
			track:AdjustSpeed(1)
			task.wait(1.8)
			track:AdjustSpeed(0)
			task.wait(0.2)
			track:AdjustSpeed(1)
		end
	end)

	CinematicFrame.Visible = true
	camera.CameraType = Enum.CameraType.Scriptable

	local leftVector = -rootPart.CFrame.RightVector
	local initialOffset = (leftVector * 12)
	local cameraPosition = rootPart.Position + initialOffset
	local lookAtTarget = rootPart.Position + Vector3.new(0, 1, 0)
	camera.CFrame = CFrame.new(cameraPosition, lookAtTarget)

	task.wait(0.5)
	-- Zoom in
	local zoomInCF = camera.CFrame:lerp(CFrame.new(cameraPosition + (-leftVector * 4), lookAtTarget), 0.5)
	tweenCamera(zoomInCF, 0.7)  -- do a short tween
	task.wait(2)

	local zoomOutTween = tweenCamera(CFrame.new(cameraPosition, lookAtTarget), 1)
	task.wait(1)

	CinematicFrame.Visible = false
	resetLocalCameraIfNotBatterOrPitcher(pitcher, hitter)
end

local function handleSeismicPitch(pitcher, hitter)
	-- If we are the current batter, do nothing
	local gameValues = ReplicatedStorage:FindFirstChild("GameValues")
	if gameValues and gameValues:FindFirstChild("CurrentBatter") then
		if CurrentPlayer == gameValues.CurrentBatter.Value then
			-- Wait a bit then cause camera shake
			task.wait(3)
			ClientVFXHandler.CameraShake(0.5, 2)
			return
		end
	end

	if not pitcher or not pitcher.Character then return end
	local rootPart = pitcher.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local track = playAnimation(pitcher.Character, "rbxassetid://127234307873934")
	playStarPowerSound()

	-- Freeze/unfreeze the animation in steps
	spawn(function()
		if track then
			task.wait()
			track:AdjustSpeed(0)
			task.wait(0.5)
			track:AdjustSpeed(1)
			task.wait(1.8)
			track:AdjustSpeed(0)
			task.wait(0.2)
			track:AdjustSpeed(1)
		end
	end)

	CinematicFrame.Visible = true
	camera.CameraType = Enum.CameraType.Scriptable

	local leftVector = -rootPart.CFrame.RightVector
	local initialOffset = (leftVector * 12)
	local cameraPosition = rootPart.Position + initialOffset
	local lookAtTarget = rootPart.Position + Vector3.new(0, 1, 0)
	camera.CFrame = CFrame.new(cameraPosition, lookAtTarget)

	task.wait(0.5)
	-- Zoom in
	local zoomInCF = camera.CFrame:lerp(CFrame.new(cameraPosition + (-leftVector * 4), lookAtTarget), 0.5)
	tweenCamera(zoomInCF, 0.7)
	task.wait(2)

	local zoomOutCF = CFrame.new(cameraPosition, lookAtTarget)
	tweenCamera(zoomOutCF, 1)
	task.wait(1)

	CinematicFrame.Visible = false
	resetLocalCameraIfNotBatterOrPitcher(pitcher, hitter)
end

local function handleBoomerangPitch(pitcher, hitter)
	-- If we are the current batter, do nothing
	local gameValues = ReplicatedStorage:FindFirstChild("GameValues")
	if gameValues and gameValues:FindFirstChild("CurrentBatter") then
		if CurrentPlayer == gameValues.CurrentBatter.Value then
			return
		end
	end

	if not pitcher or not pitcher.Character then return end
	local rootPart = pitcher.Character:FindFirstChild("HumanoidRootPart")
	local rightHand = pitcher.Character:FindFirstChild("RightHand")
	if not rootPart or not rightHand then return end

	local track = playAnimation(pitcher.Character, "rbxassetid://111129214918649")
	playStarPowerSound()

	spawn(function()
		if track then
			task.wait()
			track:AdjustSpeed(0) -- Freeze
			task.wait(0.9)
			track:AdjustSpeed(1)
			task.wait(1.9)
			track:AdjustSpeed(0)
			task.wait(1)
			track:AdjustSpeed(1)
		end
	end)

	CinematicFrame.Visible = true
	camera.CameraType = Enum.CameraType.Scriptable

	local leftVector = -rootPart.CFrame.RightVector
	local initialOffset = (leftVector * 12)
	local cameraPosition = rootPart.Position + initialOffset
	local lookAtTarget = rootPart.Position + Vector3.new(0, 1, 0)

	camera.CFrame = CFrame.new(cameraPosition, lookAtTarget)
	task.wait(0.2)

	-- Zoom in on the Right Hand
	local handZoomPosition = rightHand.Position + (rightHand.CFrame.LookVector * -3) + Vector3.new(0, 0.5, 0)
	local zoomInCFrame = CFrame.new(handZoomPosition, rightHand.Position + Vector3.new(0, 0.2, 0))
	tweenCamera(zoomInCFrame, 0.7)
	task.wait(0.7)

	-- Pop out
	tweenCamera(CFrame.new(cameraPosition, lookAtTarget), 0.3)
	task.wait(0.3)

	task.wait(2)
	CinematicFrame.Visible = false

	resetLocalCameraIfNotBatterOrPitcher(pitcher, hitter)
end

local function handleGrowthPitch(pitcher, hitter)
	-- If we are the current batter, do nothing
	local gameValues = ReplicatedStorage:FindFirstChild("GameValues")
	if gameValues and gameValues:FindFirstChild("CurrentBatter") then
		if CurrentPlayer == gameValues.CurrentBatter.Value then
			return
		end
	end

	if not pitcher or not pitcher.Character then return end
	local rootPart = pitcher.Character:FindFirstChild("HumanoidRootPart")
	local rightHand = pitcher.Character:FindFirstChild("RightHand")
	if not rootPart or not rightHand then return end

	local track = playAnimation(pitcher.Character, "rbxassetid://111111584508129")
	playStarPowerSound()

	spawn(function()
		if track then
			task.wait()
			track:AdjustSpeed(0)
			task.wait(0.9)
			track:AdjustSpeed(1)
			task.wait(1.9)
			track:AdjustSpeed(0)
			task.wait(1)
			track:AdjustSpeed(1)
		end
	end)

	CinematicFrame.Visible = true
	camera.CameraType = Enum.CameraType.Scriptable

	local leftVector = -rootPart.CFrame.RightVector
	local initialOffset = (leftVector * 12)
	local cameraPosition = rootPart.Position + initialOffset
	local lookAtTarget = rootPart.Position + Vector3.new(0, 1, 0)

	camera.CFrame = CFrame.new(cameraPosition, lookAtTarget)
	task.wait(0.2)

	-- Zoom in on Right Hand
	local handZoomPosition = rightHand.Position + (rightHand.CFrame.LookVector * -3)
	local zoomInCF = CFrame.new(handZoomPosition, rightHand.Position + Vector3.new(0, 0.2, 0))
	tweenCamera(zoomInCF, 0.7)
	task.wait(0.7)

	-- Pop out
	tweenCamera(CFrame.new(cameraPosition, lookAtTarget), 0.3)
	task.wait(0.3)

	task.wait(2)
	CinematicFrame.Visible = false

	resetLocalCameraIfNotBatterOrPitcher(pitcher, hitter)
end

local function playImpactFrame()
	local flashGui = Instance.new("ScreenGui")
	flashGui.IgnoreGuiInset = true
	flashGui.ResetOnSpawn = false
	flashGui.Name = "ImpactFrame"
	flashGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(240, 240, 240) -- slightly off-white
	frame.BackgroundTransparency = 0.35 -- not fully opaque
	frame.ZIndex = 100
	frame.Parent = flashGui

	-- Slight fade-in and out for a smooth pop
	local inTween = TweenService:Create(frame, TweenInfo.new(0.05), {BackgroundTransparency = 0.35})
	inTween:Play()
	inTween.Completed:Wait()

	local outTween = TweenService:Create(frame, TweenInfo.new(0.05), {BackgroundTransparency = 1})
	outTween:Play()
	outTween.Completed:Wait()

	flashGui:Destroy()
end

local function addEyeGlowAndFlare(character)
	local head = character:FindFirstChild("Head")
	if not head then return end

	-- 🌌 Eye Glow
	local glow = Instance.new("ParticleEmitter")
	glow.Name = "GhostEyeGlow"
	glow.Texture = "rbxassetid://259248902" -- soft glow
	glow.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
	glow.LightEmission = 1
	glow.Rate = 25
	glow.Lifetime = NumberRange.new(0.6)
	glow.Speed = NumberRange.new(0)
	glow.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0)})
	glow.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
	glow.Parent = head

	-- ☀️ Lens Flare
	local flare = Instance.new("BillboardGui")
	flare.Size = UDim2.new(4, 0, 4, 0)
	flare.LightInfluence = 0
	flare.AlwaysOnTop = true
	flare.Name = "LensFlare"
	flare.Adornee = head
	flare.Parent = head

	local flareImage = Instance.new("ImageLabel")
	flareImage.Size = UDim2.new(1, 0, 1, 0)
	flareImage.BackgroundTransparency = 1
	flareImage.Image = "rbxassetid://138036401143666" -- blue flare ring
	flareImage.ImageColor3 = Color3.fromRGB(160, 200, 255)
	flareImage.ImageTransparency = 0.3
	flareImage.Parent = flare

	-- 🌀 Ghost Trail Particles
	local trail = Instance.new("ParticleEmitter")
	trail.Name = "GhostDrift"
	trail.Texture = "rbxassetid://82104870020794 " -- wavy ghost trail
	trail.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
	trail.LightEmission = 0.5
	trail.Lifetime = NumberRange.new(0.8, 1.1)
	trail.Rate = 12
	trail.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)})
	trail.Speed = NumberRange.new(0.5, 1)
	trail.VelocitySpread = 40
	trail.VelocityInheritance = 0.2
	trail.Rotation = NumberRange.new(-60, 60)
	trail.RotSpeed = NumberRange.new(-40, 40)
	trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
	trail.EmissionDirection = Enum.NormalId.Top
	trail.Parent = head

	-- ⚡ Anime Flash Line
	local flashLineGui = Instance.new("ScreenGui")
	flashLineGui.IgnoreGuiInset = true
	flashLineGui.Name = "AnimeFlashLine"
	flashLineGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local flash = Instance.new("ImageLabel")
	flash.Size = UDim2.new(1.5, 0, 0, 14)
	flash.Position = UDim2.new(-0.1, 0, 0.5, 0)
	flash.BackgroundTransparency = 1
	flash.Image = "rbxassetid://132235126977079" -- anime slash line
	flash.ImageColor3 = Color3.fromRGB(180, 220, 255)
	flash.ImageTransparency = 0.15
	flash.Parent = flashLineGui
	
	local tweenIn = TweenService:Create(flash, TweenInfo.new(0.05), {ImageTransparency = 0.15})
	local tweenOut = TweenService:Create(flash, TweenInfo.new(0.4), {ImageTransparency = 1})
	tweenIn:Play()
	tweenIn.Completed:Wait()
	tweenOut:Play()

	game:GetService("Debris"):AddItem(glow, 1.5)
	game:GetService("Debris"):AddItem(trail, 1.5)
	game:GetService("Debris"):AddItem(flare, 1.5)
	game:GetService("Debris"):AddItem(flashLineGui, 1.5)
end

local function handleGhostPitch(pitcher, hitter)
	if CurrentPlayer == ReplicatedStorage.GameValues.CurrentBatter.Value then return end
	if not pitcher or not pitcher.Character then return end

	local mound = workspace.Plates:WaitForChild("PitcherPlate")
	local moundCFrame = mound.CFrame
	local moundPos = moundCFrame.Position
	local moundLook = moundCFrame.LookVector
	local moundRight = moundCFrame.RightVector

	local rightHand = pitcher.Character:FindFirstChild("RightHand")
	local head = pitcher.Character:FindFirstChild("Head")
	if not rightHand or not head then return end

	local track = playAnimation(pitcher.Character, "rbxassetid://116705192995918")
	playStarPowerSound()

	spawn(function()
		if track then
			task.wait()
			track:AdjustSpeed(0) -- character standing still
			task.wait(0.9)
			track:AdjustSpeed(1) -- character starts moving
			task.wait(1.1)
			track:AdjustSpeed(0) -- characters arms are both out after moving
			task.wait(1)
			track:AdjustSpeed(1) -- character throws ball
		end
	end)

	CinematicFrame.Visible = true
	camera.CameraType = Enum.CameraType.Scriptable

	-- 🎥 Side angle
	local sideShot = moundPos - moundRight * 14 + Vector3.new(0, 3, 0)
	camera.CFrame = CFrame.new(sideShot, moundPos + Vector3.new(0, 2, 0))
	playImpactFrame()
	task.wait(0.4)

	-- 🛰 Overhead
	local topView = moundPos + Vector3.new(0, 18, 0)
	camera.CFrame = CFrame.new(topView, moundPos)
	playImpactFrame()
	task.wait(0.4)

	-- 🎯 Front full-body shot with zoom out
	local frontStart = moundPos + moundLook * -5 + Vector3.new(0, 3, 0)
	local frontEnd = moundPos + moundLook * -9 + Vector3.new(0, 3.5, 0)
	camera.CFrame = CFrame.new(frontStart, moundPos + Vector3.new(0, 2.5, 0))
	playImpactFrame()
	task.wait(0.2)

	tweenCamera(CFrame.new(frontEnd, moundPos + Vector3.new(0, 2.5, 0)), 0.8)
	task.wait(0.8)

	-- 💢 Snap to face with glow and flare
	addEyeGlowAndFlare(pitcher.Character)

	-- 👁️ Set up front-facing face shot camera (backed up more)
	local faceOffset = moundLook * -3.2
	local faceCamPos = head.Position + faceOffset + Vector3.new(0, 0.2, 0)
	local faceCamFocus = head.Position + Vector3.new(0, 0.2, 0)
	camera.CFrame = CFrame.new(faceCamPos, faceCamFocus)

	-- 👁️ Smooth zoom in (not too close)
	local zoomCloser = CFrame.new(head.Position + moundLook * -2.6 + Vector3.new(0, 0.2, 0), faceCamFocus)
	tweenCamera(zoomCloser, 0.3)
	task.wait(0.3)

	-- 💥 Flash + Shake
	playImpactFrame()
	--ClientVFXHandler.CameraShake(0.5, 2)

	-- 👁️ Zoom back out to base face cam
	tweenCamera(CFrame.new(faceCamPos, faceCamFocus), 0.3)
	task.wait(0.3)
	
	-- 🌀 Ghost aura ring from below
	local aura = Instance.new("Part")
	aura.Anchored = true
	aura.CanCollide = false
	aura.Shape = Enum.PartType.Cylinder
	aura.Size = Vector3.new(1, 0.2, 1)
	aura.Material = Enum.Material.Neon
	aura.Color = Color3.fromRGB(160, 220, 255)
	aura.CFrame = CFrame.new(head.Position - Vector3.new(0, 2, 0)) * CFrame.Angles(math.rad(90), 0, 0)
	aura.Transparency = 0.2
	aura.Parent = workspace

	TweenService:Create(aura, TweenInfo.new(1), {
		Size = Vector3.new(10, 0.2, 10),
		Transparency = 1,
	}):Play()

	game:GetService("Debris"):AddItem(aura, 1.2)

	task.wait(0.4)

	-- 🧿 Slowly pan left (stare-down angle, farther out)
	local leftOffset = moundPos - moundLook * 3.5 - moundRight * 5 + Vector3.new(0, 2.2, 0)
	tweenCamera(CFrame.new(leftOffset, moundPos + Vector3.new(0, 2.2, 0)), 1.2)
	task.wait(1.2)

	-- 💥 Final back-facing shot (silhouette)
	--[[local behindPitcher = moundPos + moundLook * 6 + Vector3.new(0, 3, 0)
	camera.CFrame = CFrame.new(behindPitcher, moundPos + Vector3.new(0, 2, 0))
	playImpactFrame()
	task.wait(0.6)]]--
	
	CinematicFrame.Visible = false
	resetLocalCameraIfNotBatterOrPitcher(pitcher, hitter)
end


local function handleSerenityPitch(pitcher, hitter)
	-- If we are the current batter, do nothing
	local gameValues = ReplicatedStorage:FindFirstChild("GameValues")
	if gameValues and gameValues:FindFirstChild("CurrentBatter") then
		if CurrentPlayer == gameValues.CurrentBatter.Value then
			return
		end
	end

	if not pitcher or not pitcher.Character then return end
	local rootPart = pitcher.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local track = playAnimation(pitcher.Character, "rbxassetid://124164608114214")
	playStarPowerSound()

	if track then track.Looped = false end

	CinematicFrame.Visible = true
	camera.CameraType = Enum.CameraType.Scriptable

	local leftVector = -rootPart.CFrame.RightVector
	local initialOffset = (leftVector * 12)
	local cameraPosition = rootPart.Position + initialOffset
	local lookAtTarget = rootPart.Position + Vector3.new(0, 1, 0)

	camera.CFrame = CFrame.new(cameraPosition, lookAtTarget)

	local zoomInCF = camera.CFrame:lerp(CFrame.new(cameraPosition + (-leftVector * 4), lookAtTarget), 0.5)
	tweenCamera(zoomInCF, 0.3)
	task.wait(0.3)

	-- Overhead angle
	camera.CFrame = rootPart.CFrame * CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0) * CFrame.Angles(0, 0, math.rad(-90))
	task.wait(1.3)

	camera.CFrame = CFrame.new(cameraPosition, lookAtTarget)
	task.wait(0.4)

	CinematicFrame.Visible = false
	resetLocalCameraIfNotBatterOrPitcher(pitcher, hitter)
end

local function handleDeceiverPitch(pitcher, hitter)
	-- If we are the current batter, do nothing
	local gameValues = ReplicatedStorage:FindFirstChild("GameValues")
	if gameValues and gameValues:FindFirstChild("CurrentBatter") then
		if CurrentPlayer == gameValues.CurrentBatter.Value then
			return
		end
	end

	if not pitcher or not pitcher.Character then return end
	local rootPart = pitcher.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local track = playAnimation(pitcher.Character, "rbxassetid://116951082473287")
	playStarPowerSound()

	CinematicFrame.Visible = true
	camera.CameraType = Enum.CameraType.Scriptable

	-- Create two fake balls to look like illusions
	local ballTemplate = ReplicatedStorage.VFX:FindFirstChild("FakeBall")
	if ballTemplate and LocalPlayer.Character then
		local ball1 = ballTemplate:Clone()
		local ball2 = ballTemplate:Clone()

		local w1 = Instance.new("Weld")
		w1.Part0 = LocalPlayer.Character.RightHand
		w1.Part1 = ball1
		w1.C0 = CFrame.new(0, -0.25, 0.35)

		local w2 = Instance.new("Weld")
		w2.Part0 = LocalPlayer.Character.RightHand
		w2.Part1 = ball2
		w2.C0 = CFrame.new(0, -0.25, -0.35)

		ball1.Parent = LocalPlayer.Character
		ball2.Parent = LocalPlayer.Character
	end

	local leftVector = -(rootPart.CFrame.RightVector)
	local initialOffset = (leftVector * 12)
	local cameraPosition = rootPart.Position + initialOffset
	local lookAtTarget = rootPart.Position + Vector3.new(0, 1, 0)

	camera.CFrame = CFrame.new(cameraPosition, lookAtTarget)

	task.wait(0.5)

	local zoomInCF = camera.CFrame:lerp(CFrame.new(cameraPosition + (-leftVector * 4), lookAtTarget), 0.5)
	tweenCamera(zoomInCF, 0.7)
	task.wait(2)

	tweenCamera(CFrame.new(cameraPosition, lookAtTarget), 1)
	task.wait(1)

	-- Destroy the fake balls
	if LocalPlayer.Character then
		local b1 = LocalPlayer.Character:FindFirstChild("FakeBall")
		local b2 = LocalPlayer.Character:FindFirstChild("FakeBall")
		if b1 then b1:Destroy() end
		if b2 then b2:Destroy() end
	end

	CinematicFrame.Visible = false
	resetLocalCameraIfNotBatterOrPitcher(pitcher, hitter)
end

--------------------------------------------------------------------------------
--// Main OnClientEvent
--------------------------------------------------------------------------------

Remotes.AbilityCamera.OnClientEvent:Connect(function(pitcher, hitter, ability, bat)
	if not ability then return end	
	if Players.LocalPlayer.TeamColor == game.Teams.Lobby.TeamColor then return end
	if Players.LocalPlayer.PlayerGui.StylesGui.StylesFrame.Visible then
		Players.LocalPlayer.PlayerGui.StylesGui.StylesFrame.Visible = false
		Players.LocalPlayer.Character.States.InStylesLocker.Value = false
		
		ClientFunctions.ToggleStylesGuiView(true)
	end
	
	Players.LocalPlayer.Character.States.StylesLockerDisabled.Value = true
	
	pcall(function()
		----------------------------------------------------------------
		-- SWING ABILITIES
		----------------------------------------------------------------
		if ability == "Fire Swing" then
			handleFireSwing(pitcher, hitter)

		elseif ability == "Portal Swing" then
			handlePortalSwing(pitcher, hitter, bat)

		elseif ability == "Boomerang Swing" then
			handleBoomerangSwing(pitcher, hitter)

		elseif ability == "BouncyBall Swing" then
			handleBouncyBallSwing(pitcher, hitter)

		elseif ability == "Whirlwind Swing" then
			handleWhirlwindSwing(pitcher, hitter)

		elseif ability == "Seismic Swing" then
			handleSeismicSwing(pitcher, hitter)

		elseif ability == "Serenity Swing" then
			handleSerenitySwing(pitcher, hitter)

		elseif ability == "Bomb Swing" then
			handleBombSwing(pitcher, hitter)

		----------------------------------------------------------------
		-- PITCH ABILITIES
		----------------------------------------------------------------
		elseif ability == "Fire Pitch" then
			handleFirePitch(pitcher, hitter)

		elseif ability == "Tornado Pitch" then
			handleTornadoPitch(pitcher, hitter)

		elseif ability == "Seismic Pitch" then
			handleSeismicPitch(pitcher, hitter)

		elseif ability == "Boomerang Pitch" then
			handleBoomerangPitch(pitcher, hitter)

		elseif ability == "Growth Pitch" then
			handleGrowthPitch(pitcher, hitter)

		elseif ability == "Ghost Pitch" then
			handleGhostPitch(pitcher, hitter)

		elseif ability == "Serenity Pitch" then
			handleSerenityPitch(pitcher, hitter)

		elseif ability == "Deceiver Pitch" then
			handleDeceiverPitch(pitcher, hitter)

		----------------------------------------------------------------
		-- UNKNOWN
		----------------------------------------------------------------
		else
			warn("No camera handler for ability:", ability)
		end
	end)
	
	Players.LocalPlayer.Character.States.StylesLockerDisabled.Value = false
end)
