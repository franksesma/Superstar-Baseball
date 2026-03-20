local animPlayer = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local SharedObjects = ReplicatedStorage.SharedObjects
local SharedModules = ReplicatedStorage.SharedModules
local AbilityFolder = ReplicatedStorage.Abilities

local CinematicUtils = require(SharedModules.AbilityCinematics.CinematicUtils)
local ClientVFXHandler = require(SharedModules.ClientVFXHandler)
local ClientFunctions = require(SharedModules.ClientFunctions)

local humAnim = script:WaitForChild("Hum")
local camAnim = script:WaitForChild("Cam")

animPlayer.camRig = SharedObjects:WaitForChild("CameraRig4")
animPlayer.customCamPivot = animPlayer.camRig.PrimaryPart.CFrame
animPlayer.requiresCinematicFrame = true
animPlayer.faceHomePlate = true
animPlayer.CustomFixedPos = Vector3.new(-127.807, 5.9, 87.285)
animPlayer.CustomFixedRotation = CFrame.Angles(0, math.rad(25), 0)
animPlayer.fieldOfView = 70
animPlayer.adjustSpeed = 1.6667

-- Half all waits/delays/timings
local TIME_SCALE = 0.6

local function waitScaled(t)
	if t == nil then
		return task.wait()
	end
	return task.wait(t * TIME_SCALE)
end

local function delayScaled(t, fn)
	return task.delay((t or 0) * TIME_SCALE, fn)
end

pcall(function()
	ContentProvider:PreloadAsync({camAnim, humAnim})
end)

function animPlayer.Execute(char, camPart, camTrack, humTrack)
	-- Play VFX (SINGLE THREAD VERSION)

	task.spawn(function()

		-- Clone
		local head1 = script.VFX.CharacterVFX.Head:Clone()
		local head2 = script.VFX.CharacterVFX.Head2:Clone()
		local rightHand = script.VFX.CharacterVFX.RightHand:Clone()
		local rightLowerArm = script.VFX.CharacterVFX.RightLowerArm:Clone()
		local upperTorso = script.VFX.CharacterVFX.UpperTorso:Clone()

		local dust1 = script.VFX.Dust1:Clone()
		local intenseF = script.VFX.IntenseF:Clone()
		local lighting = script.VFX.Lighting:Clone()
		local explosion = script.VFX.Explosion:Clone()

		-- Parent to character
		if char:FindFirstChild("Head") then
			head1.Parent = char.Head
			head2.Parent = char.Head
		end
		if char:FindFirstChild("RightHand") then
			rightHand.Parent = char.RightHand
		end
		if char:FindFirstChild("RightLowerArm") then
			rightLowerArm.Parent = char.RightLowerArm
		end
		if char:FindFirstChild("UpperTorso") then
			upperTorso.Parent = char.UpperTorso
		end

		-- Parent to workspace
		intenseF.Parent = workspace.VFXFolder
		dust1.Parent = workspace.VFXFolder
		lighting.Parent = workspace.VFXFolder
		explosion.Parent = workspace.VFXFolder

		-------------------------------------------------
		-- Timeline Driven Execution
		-------------------------------------------------

		local totalTime = 0
		local function advanceTo(targetTime)
			local delta = targetTime - totalTime
			if delta > 0 then
				waitScaled(delta)
				totalTime = targetTime
			end
		end

		-- 0.09
		advanceTo(0.09)
		CinematicUtils.Emit(intenseF)

		-- 0.17
		advanceTo(0.17)
		CinematicUtils.PlayAudioSound("ElectricSpin")

		-- 0.25
		advanceTo(0.25)
		CinematicUtils.Emit(lighting)

		-- 0.29
		advanceTo(0.29)
		CinematicUtils.Emit(intenseF)

		-- 0.38
		advanceTo(0.38)
		CinematicUtils.Emit(lighting)

		-- 0.50
		advanceTo(0.50)
		CinematicUtils.Emit(intenseF)

		-- 0.54
		advanceTo(0.54)
		CinematicUtils.Emit(intenseF)

		-- 1.28
		advanceTo(1.28)
		CinematicUtils.Emit(intenseF)

		-- 1.32
		advanceTo(1.32)
		CinematicUtils.Emit(intenseF)

		-- 3.26 HEAD ON
		advanceTo(3.26)
		if head1:FindFirstChild("65764") then head1["65764"].Enabled = true end
		if head2:FindFirstChild("67") then head2["67"].Enabled = true end

		-- 8.24 RIGHT HAND ON
		advanceTo(8.24)
		if rightHand then
			if rightHand:FindFirstChild("67") then rightHand["67"].Enabled = true end
			if rightHand:FindFirstChild("Stars1") then rightHand.Stars1.Enabled = true end
			if rightHand:FindFirstChild("impact") then rightHand.impact.Enabled = true end
			if rightHand:FindFirstChild("slicers2") then rightHand.slicers2.Enabled = true end
		end

		-- 15.59 SCRAMBLE ON
		advanceTo(15.59)
		if rightLowerArm:FindFirstChild("Scramble") then
			rightLowerArm.Scramble.Enabled = true
		end

		-- 17.27 HEAD OFF
		advanceTo(17.27)
		if head1:FindFirstChild("65764") then head1["65764"].Enabled = false end
		if head2:FindFirstChild("67") then head2["67"].Enabled = false end

		-- 19.24 TORSO BURST
		advanceTo(19.24)

		local function emitTorso()
			if upperTorso:FindFirstChild("others") then CinematicUtils.EmitSpecificParticle(upperTorso.others) end
			if upperTorso:FindFirstChild("ToonLightning") then CinematicUtils.EmitSpecificParticle(upperTorso.ToonLightning) end
			if upperTorso:FindFirstChild("Stylized winds") then CinematicUtils.EmitSpecificParticle(upperTorso["Stylized winds"]) end
			if upperTorso:FindFirstChild("Shockwave3") then CinematicUtils.EmitSpecificParticle(upperTorso.Shockwave3) end
			if upperTorso:FindFirstChild("Flash") then CinematicUtils.EmitSpecificParticle(upperTorso.Flash) end
		end

		emitTorso()
		waitScaled(0.04)
		emitTorso()

		-- 19.31 Dust ON
		advanceTo(19.31)
		CinematicUtils.EnableParticles(dust1, true)

		-- 20.27 Explosion
		advanceTo(20.27)
		CinematicUtils.Emit(explosion)
		CinematicUtils.PlayAudioSound("Explosion")
		CinematicUtils.PlayAudioSound("Electric")

		-- 20.42 Dust OFF
		advanceTo(20.42)
		CinematicUtils.EnableParticles(dust1, false)

		-- 21.01 Cleanup
		advanceTo(21.01)

		head1:Destroy()
		head2:Destroy()
		rightHand:Destroy()
		rightLowerArm:Destroy()
		upperTorso:Destroy()
		dust1:Destroy()
		intenseF:Destroy()
		lighting:Destroy()
		explosion:Destroy()

	end)
end

return animPlayer
