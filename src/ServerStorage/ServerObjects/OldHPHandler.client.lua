local TweenService = game:GetService("TweenService")

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local Remotes = game.ReplicatedStorage.RemoteEvents
local camera = workspace.CurrentCamera
local CameraFolder = workspace.Cameras
local CAS = game:GetService("ContextActionService")
local PitchingScreen = player.PlayerGui:WaitForChild("PitchingScreen")
local PitchBar = PitchingScreen.PitchForce.Bar
local HittingScreen = player.PlayerGui:WaitForChild("HittingScreen")
local SwingData = HittingScreen.SwingData
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage.SharedModules
local PlateDistance = require(SharedModules.PlateDistance)

local isBarMoving = false
local firstClick = true
local pitchForce = 0

local swingDataRange = Vector2.new(
	SwingData.Location.Hit.Size.X.Offset / 2,
	SwingData.Location.Hit.Size.Y.Offset / 2
)

local function startPitchBar()
	isBarMoving = true
	pitchForce = 0
	local increasing = true

	spawn(function()
		while isBarMoving do
			if increasing then
				pitchForce = pitchForce + 0.02
			else
				pitchForce = pitchForce - 0.02
			end
			
			PitchBar.Size = UDim2.fromScale(1, -pitchForce)
			PitchBar.BackgroundColor3 = Color3.fromRGB(255, 33, 33):Lerp(Color3.fromRGB(92, 255, 56), pitchForce)
			
			if pitchForce >= 1 then
				increasing = false
			elseif pitchForce <= 0 then
				increasing = true
			end
			
			wait()
		end
	end)
end


local function stopPitchBar()
	isBarMoving = false
	return 1.5 - pitchForce 
end

local pitchType = nil
local currentButton = nil

local function handleButtonClick(button)
    button.BorderColor3 = Color3.fromRGB(255, 255, 0) 

    if currentButton and currentButton ~= button then
        currentButton.BorderColor3 = Color3.fromRGB(0, 0, 0)  
    end

    currentButton = button
    pitchType = button.Name
end

for i, button in pairs(PitchingScreen.PitchTypes:GetChildren()) do
	if button:IsA("ImageButton") then
		if currentButton == nil then handleButtonClick(button) end
        button.MouseButton1Click:Connect(function()
            handleButtonClick(button)
        end)
    end
end

local function convertTo3D(relativeX, relativeY, part)
    local partSize = part.Size
    local partPosition = part.Position

    local worldX = partPosition.X - (partSize.X / 2) + (relativeX * partSize.X)
    local worldY = partPosition.Y - (partSize.Y / 2) + (relativeY * partSize.Y)
    local worldZ = partPosition.Z 

    local worldPosition = Vector3.new(worldX, worldY, worldZ)
    return worldPosition
end

mouse.TargetFilter = workspace:WaitForChild("Pitching"):WaitForChild("StrikeZone")

local canPitch = true 

Remotes.SetupPitcher.OnClientEvent:Connect(function()
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = CFrame.new(CameraFolder.PitchingCam.Position, CameraFolder.PitchingCamFocal.Position)

    local goal = {}
    local tweenInfo = TweenInfo.new(0, Enum.EasingStyle.Linear)

    goal.CFrame = CFrame.new(CameraFolder.PitchingCam.Position, CameraFolder.PitchingCamFocal.Position)
    local tween = TweenService:Create(camera, tweenInfo, goal)
    tween:Play()

    camera.FieldOfView = 20
    local Animator = player.Character.Humanoid:WaitForChild("Animator")

    local Animation = Instance.new("Animation")
    Animation.Name = "Holding Stance"
    Animation.AnimationId = "rbxassetid://18512502047"
    local PitchingStanceTrack = Animator:LoadAnimation(Animation)
    --PitchingStanceTrack:Play()

    mouse.Icon = "rbxassetid://9896593019"

    PitchingScreen.PitchTypes.Visible = true    
    PitchingScreen.PitchForce.Visible = true
    PitchingScreen.PitchFrame.Visible = true

    local Target = nil
    local firstClick = true

    mouse.Button1Down:Connect(function()
        if canPitch and mouse.Target and mouse.Target.Name == "ThrowSpot" then  
            if firstClick then
                Target = mouse.Hit.p
                startPitchBar()
                firstClick = false
            else
                local pitchPower = stopPitchBar()

                canPitch = false

                local Animation = Instance.new("Animation")
                Animation.Name = "Throwing Animation"
                Animation.AnimationId = "rbxassetid://18404081571"
                local PitchThrowTrack = Animator:LoadAnimation(Animation)
                PitchThrowTrack:Play()

                wait(1)  
                Remotes.PitchBall:FireServer(Target, pitchPower, pitchType)

                firstClick = true
                canPitch = true 
            end
        end
    end)

    --[[local frame = PitchingScreen.PitchFrame
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and canPitch then
            local relativeX = 1 - (input.Position.X - frame.AbsolutePosition.X) / frame.AbsoluteSize.X
            local relativeY = 1 - (input.Position.Y - frame.AbsolutePosition.Y) / frame.AbsoluteSize.Y 

            local worldPosition = convertTo3D(relativeX, relativeY, workspace.Pitching.ThrowSpot)

            if firstClick then
                Target = worldPosition
                startPitchBar()
                firstClick = false
            else
                PitchingStanceTrack:Stop()
                local pitchPower = stopPitchBar()

                -- Prevent further pitching until the current pitch is finished
                canPitch = false

                local Animation = Instance.new("Animation")
                Animation.Name = "Throwing Animation"
                Animation.AnimationId = "rbxassetid://18512485204"
                local PitchThrowTrack = Animator:LoadAnimation(Animation)
                PitchThrowTrack:Play()

                wait(1)  -- Simulate pitch delay
                Remotes.PitchBall:FireServer(Target, pitchPower, pitchType)

                -- Re-enable pitching after the animation and pitch are done
                firstClick = true
                canPitch = true  -- Reset the pitch lock
            end
        end    
    end)]]--
end)

local UserInputService = game:GetService("UserInputService")
local missParams = RaycastParams.new()

local function getRelativePos(pos: Vector3, object): Vector2
	local strikeZone
	if object then
		strikeZone = object
	else
		strikeZone = workspace:WaitForChild("Pitching"):WaitForChild("StrikeZone")
	end
	local size = strikeZone.Size
	local otherPos = strikeZone.CFrame * CFrame.new(-size/2)
	
	local relPos = otherPos:PointToObjectSpace(pos)
	return Vector2.new(
		1 - math.clamp(relPos.X / size.X, 0, 1),
		1 - math.clamp(relPos.Y / size.Y, 0, 1)
	)
end

local function getHitUIPos(offset: Vector2): UDim2
	local udX = UDim2.new(0, swingDataRange.X, 0, 0):Lerp(
		UDim2.new(1, -swingDataRange.X, 0, 0), math.clamp(offset.X, 0, 1)
	)
	local udY = UDim2.new(0, 0, 0, swingDataRange.Y):Lerp(
		UDim2.new(0, 0, 1, -swingDataRange.Y, 0), math.clamp(offset.Y, 0, 1)
	)
	return UDim2.new(udX.X, udY.Y)
end

Remotes.SetupBatter.OnClientEvent:Connect(function()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(CameraFolder.HittingCam.Position, CameraFolder.HittingCamFocal.Position)
	
	SwingData.Visible = false
	SwingData.Location.Hit.Visible = false
	SwingData.Location.Ball.Visible = false
	
	local goal = {}
	local tweenInfo = TweenInfo.new(0, Enum.EasingStyle.Linear)

	goal.CFrame = CFrame.new(CameraFolder.HittingCam.Position, CameraFolder.HittingCamFocal.Position)
	local tween = TweenService:Create(camera, tweenInfo, goal)
	tween:Play()
	
	local Animator = player.Character.Humanoid:WaitForChild("Animator")
	local Animation = Instance.new("Animation")
	Animation.Name = "Holding Stance"
	Animation.AnimationId = "rbxassetid://17582023160"
	local BattingStanceTrack = Animator:LoadAnimation(Animation)
	BattingStanceTrack:Play()

	mouse.Icon = "rbxassetid://9896593019"
	local State = "idle"
	local swingTimeout

	Remotes.PitchBall.OnClientEvent:Connect(function()
		if State == "idle" then
			local Animation = Instance.new("Animation")
			Animation.Name = "Leg Lift"
			Animation.AnimationId = "rbxassetid://17581555841"
		    local LiftLegTrack = Animator:LoadAnimation(Animation)
			LiftLegTrack:Play()
			task.wait(LiftLegTrack.Length * 0.8)
			LiftLegTrack:AdjustSpeed(0)
			State = "leg_lifted"

			swingTimeout = task.delay(3, function()
				if State == "leg_lifted" then
					LiftLegTrack:Stop()
					State = "idle"
				end
			end)
		end
	end)

	mouse.Button1Down:Connect(function()
		local ball = workspace.BallHolder:FindFirstChild("Baseball")
		if not ball or ball:GetAttribute("Hit") or State ~= "leg_lifted" then return end

		if swingTimeout then
			task.cancel(swingTimeout)
			swingTimeout = nil
		end
		
		local Animator = player.Character.Humanoid:WaitForChild("Animator")
		for i,v in pairs(Animator:GetPlayingAnimationTracks()) do
			if v.Name == "Leg Lift" then
				v:Stop()
			end
		end
		local Animation = Instance.new("Animation")
		Animation.Name = "Swing"
		Animation.AnimationId = "rbxassetid://17581581304"
	    local SwingTrack = Animator:LoadAnimation(Animation)
		SwingTrack:Play()
		State = "idle"

		local mousePosition = UserInputService:GetMouseLocation()
		local ray = workspace.CurrentCamera:ViewportPointToRay(mousePosition.X, mousePosition.Y, 1)
		local rayResult = workspace:Raycast(
			ray.Origin,
			ray.Direction * 500,
			missParams
		)
		local ballPosition = ball.Position
		Remotes.SwingBat:FireServer(rayResult.Position, ballPosition, ball:GetAttribute("Direction"))

		SwingData.Visible = true
		local pos = getRelativePos(rayResult.Position)
		local hit = SwingData.Location.Hit
		hit.Visible = true
		hit.Position = getHitUIPos(pos)
		
		local timing = SwingData.Timing
		local dist, margin = PlateDistance:getRelativeDistToPlate(ballPosition)
		if dist <= margin and dist >= -margin then
			timing.Text = "ON TIME"
		elseif dist < -margin then
			timing.Text = "EARLY"
		elseif dist > margin then
			timing.Text = "LATE"
		end
	end)
end)

local function Hit(actionName, inputState, inputObject)
    if inputState ~= Enum.UserInputState.Begin then
        return
    end
	if State == "idle" then
		local Animator = player.Character.Humanoid:WaitForChild("Animator")
		local Animation = Instance.new("Animation")
		Animation.Name = "Leg Lift"
		Animation.AnimationId = "rbxassetid://17581555841"
	    local LiftLegTrack = Animator:LoadAnimation(Animation)
		LiftLegTrack:Play()
		task.wait(LiftLegTrack.Length * 0.8)
		LiftLegTrack:AdjustSpeed(0)
		State = "leg_lifted"
	elseif State == "leg_lifted" then
		local Animator = player.Character.Humanoid:WaitForChild("Animator")
		for i,v in pairs(Animator:GetPlayingAnimationTracks()) do
			if v.Name == "Leg Lift" then
				v:Stop()
			end
		end
		local Animation = Instance.new("Animation")
		Animation.Name = "Swing"
		Animation.AnimationId = "rbxassetid://17581581304"
	    local SwingTrack = Animator:LoadAnimation(Animation)
		SwingTrack:Play()
		State = "idle"
	end
end

Remotes.BallLanded.OnClientEvent:Connect(function(position: Vector3)
	local pos = getRelativePos(position, workspace:WaitForChild("Pitching"):WaitForChild("ThrowSpot"))
	local hit = SwingData.Location.Ball
	hit.Visible = true
	hit.Position = getHitUIPos(pos)
end)

--CAS:BindAction("Swing", Hit, true, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.KeyCode.ButtonL1)