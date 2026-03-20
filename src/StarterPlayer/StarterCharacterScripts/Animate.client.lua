local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Remotes = ReplicatedStorage.RemoteEvents
local SharedData = ReplicatedStorage.SharedData

local PLAYER = Players.LocalPlayer
local CHARACTER = script.Parent

local HUMANOID = CHARACTER:WaitForChild("Humanoid")
local STANCE = ""
local ROOT_PART = CHARACTER:WaitForChild("HumanoidRootPart")
local TORSO = CHARACTER:WaitForChild("UpperTorso")
local ANIMATIONS = script:WaitForChild("Animations")

local sprinting	= false
local Ragdolled = false
local canJump = true

local speeds = {
	Walk	= 1.8;
	Crouch	= 1.7;
	Sprint	= 1;
}

local animations = {
	Movement	= {};
	Actions		= {};
}

HUMANOID.WalkSpeed = 0

local function UpdateMovement(localVelocity)
	local speed = 0
	if localVelocity ~= 0 then
		speed = localVelocity.Magnitude
	end
	
	if speed > 1 then
		local unit	= localVelocity.Unit
		for name, animation in pairs(animations.Movement) do
			local state	= string.match(name, "^" .. STANCE .. "_(.+)")
			if state then
				if state == "Idle" then
					if animation.IsPlaying then
						animation:Stop(0.4)
					end
				else
					if speeds[STANCE] then
						if sprinting then
							animation:AdjustSpeed(math.max(speeds[STANCE] * (speed / 6), 0.1))
						else
							animation:AdjustSpeed(math.max(speeds[STANCE] * (speed / 9), 0.1))	
						end
					end
					if not animation.IsPlaying then
						animation:Play()
					end
				end
				if state == "Forward" then
					local weight = math.abs(math.clamp(unit.Z, -1, 0.1))^2
					if weight < 0.1 then
						weight = 0.1
					end
					animation:AdjustWeight(weight)
				elseif state == "Backward" then
					local weight = math.abs(math.clamp(unit.Z, 0.1, 1))^2
					if weight < 0.1 then
						weight = 0.1
					end
					animation:AdjustWeight(weight)
				elseif state == "Right" then
					local weight = math.abs(math.clamp(unit.X, 0.1, 1))^2
					if weight < 0.1 then
						weight = 0.1
					end
					animation:AdjustWeight(weight)
				elseif state == "Left" then
					local weight = math.abs(math.clamp(unit.X, -1, 0.1))^2
					if weight < 0.1 then
						weight = 0.1
					end
					animation:AdjustWeight(weight)
				end
			else
				if animation.IsPlaying then
					animation:Stop()
				end
			end
		end
	else
		for name, animation in pairs(animations.Movement) do
			local state	= string.match(name, "^" .. STANCE .. "_(.+)")
			if state then
				if state == "Idle" then
					if not animation.IsPlaying then
						animation:Play()
					end
				else
					if animation.IsPlaying then
						animation:Stop()
					end
				end
			else
				if animation.IsPlaying then
					animation:Stop()
				end
			end
		end
	end
end

local function SetStance(newStance)
	if STANCE ~= newStance then
		STANCE = newStance
		
		for _, animation in pairs(animations.Movement) do
			animation:Stop()
		end
	end
end

local function ragDoll(setEnabled)
	HUMANOID:ChangeState(setEnabled and Enum.HumanoidStateType.Physics or Enum.HumanoidStateType.GettingUp)
end

ANIMATIONS:WaitForChild("Movement").ChildAdded:connect(function(animation)
	HUMANOID:WaitForChild("Animator")
	animations.Movement[animation.Name]	= HUMANOID.Animator:LoadAnimation(animation)
end)

ANIMATIONS:WaitForChild("Actions").ChildAdded:connect(function(animation)
	HUMANOID:WaitForChild("Animator")
	animations.Actions[animation.Name]	= HUMANOID.Animator:LoadAnimation(animation)
end)


for _, animation in pairs(ANIMATIONS.Movement:GetChildren()) do
	HUMANOID:WaitForChild("Animator")
	animations.Movement[animation.Name]	= HUMANOID.Animator:LoadAnimation(animation)
end

for _, animation in pairs(ANIMATIONS.Actions:GetChildren()) do
	HUMANOID:WaitForChild("Animator")
	animations.Actions[animation.Name]	= HUMANOID.Animator:LoadAnimation(animation)
end

Remotes.ShowOffBat.OnClientEvent:Connect(function(enabled)
	if enabled then
		animations.Actions["BatHolding"]:Play()
	else
		animations.Actions["BatHolding"]:Stop()
	end
end)

if PLAYER.TeamColor == Teams.Lobby.TeamColor then
	HUMANOID.WalkSpeed = 30
else
	HUMANOID.WalkSpeed = 18
end

SetStance("Sprint")

RunService:BindToRenderStep("Animate", 5, function(deltaTime)
	local ragdollEnabled = HUMANOID:GetState() ~= Enum.HumanoidStateType.Physics
	if not Ragdolled then
		if not ragdollEnabled then
			ragDoll(false)
		end
		
		local velocity = Vector3.new(ROOT_PART.Velocity.X, 0, ROOT_PART.Velocity.Z)
		local localVelocity	= ROOT_PART.CFrame:vectorToObjectSpace(velocity)
		local speed	= velocity.Magnitude
		
		if HUMANOID.FloorMaterial == Enum.Material.Air then
			SetStance("Falling")
			if not animations.Movement.Fall.IsPlaying then
				animations.Movement.Fall:Play()
			end
		else
			SetStance("Sprint")
			UpdateMovement(localVelocity)
		end
	else
		if ragdollEnabled then
			ragDoll(true)
		end
		for _, animation in pairs(animations.Movement) do
			animation:Stop()
		end
		UpdateMovement(0)
	end
end)

HUMANOID.StateChanged:connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Jumping then
		if HUMANOID.FloorMaterial ~= Enum.Material.Air then
			animations.Actions.Jump:Play(0.05, 1, 2)
		end
	elseif newState == Enum.HumanoidStateType.Landed then
		animations.Actions.Land:Play(0.05, 1, 1)
	end
end)

HUMANOID.Changed:connect(function()
	if (not canJump and HUMANOID.Jump) then
		HUMANOID.Jump = false
	elseif canJump and HUMANOID.Jump then
		HUMANOID.Jump = true
		spawn(function()
			canJump = false
			wait(1)
			canJump = true
		end)
	end
end)