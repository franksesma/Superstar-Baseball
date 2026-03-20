local StyleMechanicsClient = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Remotes = ReplicatedStorage.RemoteEvents
local Shared = ReplicatedStorage.Shared
local SharedServices = Shared.Services

local PlayerUtilsClient = require(SharedServices.Utilities.PlayerUtilsClient)

local player = Players.LocalPlayer
local _zapLock = false
local warping = false

local function quadBezier(a,b,c,t)
	local u = 1 - t
	return (u*u)*a + 2*u*t*b + (t*t)*c
end

local function playZapAnimAndSound()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum  = char:FindFirstChildOfClass("Humanoid")
	local hrp  = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end

	-- Animation
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://121894478302723"
	local track = hum:LoadAnimation(anim)
	track:Play(0)
	game:GetService("Debris"):AddItem(anim, 3)

	-- Sound
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://129853966749911"
	s.Volume = 1
	s.RollOffMaxDistance = 70
	s.Parent = hrp
	s:Play()
	game:GetService("Debris"):AddItem(s, 6)
end

local function playAnim(animID)
	local char = player.Character
	if not char then return end

	local hum  = char:FindFirstChildOfClass("Humanoid")
	local hrp  = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end

	-- Animation
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://"..animID
	local track = hum:LoadAnimation(anim)
	track:Play(0)
	game:GetService("Debris"):AddItem(anim, 3)
end

function StyleMechanicsClient.init()
	Remotes.StartCannonFlight.OnClientEvent:Connect(function(p0, p1, p2, flightTime)
		local char = player.Character or player.CharacterAdded:Wait()
		local root = char:WaitForChild("HumanoidRootPart")
		local hum  = char:FindFirstChildOfClass("Humanoid")

		-- Local prep mirrors server (for visuals)
		if hum then
			hum.PlatformStand = true
			hum:ChangeState(Enum.HumanoidStateType.Freefall)
		end
		for _, bp in ipairs(char:GetDescendants()) do
			if bp:IsA("BasePart") then
				--bp.CanCollide = false
				bp.AssemblyLinearVelocity = Vector3.zero
				bp.AssemblyAngularVelocity = Vector3.zero
			end
		end

		-- Smooth client‑side arc
		local t0 = tick()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			if not char or not char.Parent then
				if conn then conn:Disconnect() end
				return
			end

			local t = (tick() - t0) / flightTime
			if t >= 1 then t = 1 end

			local pos     = quadBezier(p0, p1, p2, t)
			local nextPos = quadBezier(p0, p1, p2, math.clamp(t + 0.02, 0, 1))
			local look    = nextPos - pos
			local lookCF  = (look.Magnitude > 0.001) and CFrame.lookAt(pos, pos + look) or root.CFrame

			char:PivotTo(lookCF)

			if t >= 1 then
				if conn then conn:Disconnect() end
				-- Restore locally (server watchdog also restores)
				if hum then hum.PlatformStand = false end
			end
		end)
	end)
	
	Remotes.OverdriveZap.OnClientEvent:Connect(function()
		if _zapLock then return end
		_zapLock = true

		-- disable movement, play fx, restore shortly after
		PlayerUtilsClient.disableMovement(true)
		playZapAnimAndSound()

		task.delay(1.25, function()
			PlayerUtilsClient.disableMovement(false)
			_zapLock = false
		end)
	end)

	Remotes.QuantumTeleportEffect.OnClientEvent:Connect(function(nextBasePos)
		if warping then return end
		warping = true

		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = CFrame.new(player.Character.HumanoidRootPart.Position, nextBasePos)
		end

		PlayerUtilsClient.disableMovement(true)
		playAnim("74582043903175")

		task.delay(1.1, function()
			playAnim("90051200202996")
			task.wait(0.2)
			PlayerUtilsClient.disableMovement(false)
			warping = false
		end)
	end)
end

return StyleMechanicsClient
