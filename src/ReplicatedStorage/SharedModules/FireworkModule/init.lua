local FireworkModule = {}

local DefaultEffectStorage --= workspace:WaitForChild("Map"):WaitForChild("AlwaysStreamed")
local DefaultSizeScaling = 2.5
local MaxExplosionSizeForParticleScaling = 80
local MaxExplosionSizeForTrailScaling = 50
local MaxExplosionSizeForSoundScaling = 100

type FireworkInfo = {
	EffectStorage : Instance,
	ExplosionColor : Color3,
	ExplosionEmitCount : number,
	ExplosionLifetime : number,
	ExplosionPopVolume : number,
	ExplosionPopMaxDistance : number,
	ExplosionSize : number,				-- 
	Direction : Vector3,		-- Unit vector direction it will travel (Default is up which is Vector3(0, 1, 0))
	Distance : number,			-- Stud distance it will travel
	LaunchSoundVolume : number,
	LaunchSoundMaxDistance : number,
	PlayExplosionPopSound : boolean,
	PlayLaunchSound : boolean,
	Speed : number,				-- Studs per second
	StartPosition : Vector3,	-- Position where the firework will start
	TrailColor : Color3,
	TrailSize : number
}

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local EffectsFolder
local Signal = require(script.Signal)


local function ScaleNumberSequence(seq: NumberSequence, percent: number): NumberSequence
	assert(typeof(seq) == "NumberSequence", "seq must be a NumberSequence")
	assert(typeof(percent) == "number", "percent must be a number")

	local old = seq.Keypoints
	local newKeypoints = table.create(#old)

	for i, kp in ipairs(old) do
		newKeypoints[i] = NumberSequenceKeypoint.new(
			kp.Time,
			kp.Value * percent,
			kp.Envelope * percent
		)
	end

	return NumberSequence.new(newKeypoints)
end


function FireworkModule.NewFirework(Info : FireworkInfo)
	Info = Info or {}
	
	local PropertiesMissing
	for _, RequiredProperty in {"StartPosition"} do
		if not Info[RequiredProperty] then
			if not PropertiesMissing then PropertiesMissing = {} end
			table.insert(PropertiesMissing, `"{RequiredProperty}"`)
		end
	end
	if PropertiesMissing then warn(`Missing required firework config(s): {table.concat(PropertiesMissing, ", ")}`) return end
	
	local self = setmetatable({
		
		EffectStorage = Info.EffectStorage,
		
		ExplosionColor = Info.ExplosionColor or Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255)),
		ExplosionLifetime = Info.ExplosionLifetime or math.random(50, 80) / 10,
		ExplosionPopMaxDistance = Info.ExplosionPopMaxDistance,
		ExplosionPopVolume = Info.ExplosionPopVolume,
		ExplosionSize = Info.ExplosionSize or math.random(100, 200),
		LaunchSoundVolume = Info.LaunchSoundVolume,
		LaunchSoundMaxDistance = Info.LaunchSoundMaxDistance,
		PlayExplosionPopSound = Info.PlayExplosionPopSound or true,
		PlayLaunchSound = Info.PlayLaunchSound or true,
		TrailSize = Info.TrailSize,
		
		Direction = Info.Direction or Vector3.yAxis,
		Distance = Info.Distance or math.random(350, 450),
		Speed = Info.Speed or math.random(70, 100),
		StartPosition = Info.StartPosition,
		
		OnExplosion = Signal.new()
		
	}, {__index = FireworkModule})
	
	self.ExplosionEmitCount = Info.ExplosionEmitCount or self.ExplosionSize * DefaultSizeScaling
	self.TrailColor = Info.TrailColor or self.ExplosionColor
	
	local Part = script.Firework:Clone()
	self.FireworkPart = Part
	
	task.spawn(self.Run, self)
	
	return self	
end

function FireworkModule:Run()
	local Part = self.FireworkPart
	Part.CFrame = CFrame.new(self.StartPosition, self.StartPosition + self.Direction)
	Part.Trail.Color = ColorSequence.new(self.TrailColor)
	Part.Attachment.Shine.Color = Part.Trail.Color
	
	local DefaultTrailSize = Part.Trail.WidthScale.Keypoints[1].Value
	Part.Trail.WidthScale = 
		self.TrailSize and NumberSequence.new(self.TrailSize) 
		or NumberSequence.new(DefaultTrailSize * math.min(1, self.ExplosionSize / MaxExplosionSizeForTrailScaling))
	
	Part.Parent = self.EffectStorage or self.GetEffectsFolder(true)
	
	local Tween = TweenService:Create(
		Part,
		TweenInfo.new(self.Distance / self.Speed, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{CFrame = Part.CFrame * CFrame.new(0, 0, -self.Distance)}
	)
	Tween:Play()
	
	if self.PlayLaunchSound then
		local LaunchSound = Part.Attachment.LaunchSound
		LaunchSound.Volume = self.LaunchSoundVolume or LaunchSound.Volume * math.min(1, self.ExplosionSize / MaxExplosionSizeForSoundScaling)
		LaunchSound.RollOffMaxDistance = self.LaunchSoundMaxDistance or LaunchSound.RollOffMaxDistance * math.min(1, self.ExplosionSize / MaxExplosionSizeForSoundScaling)

		LaunchSound:Play()
		local Con; Con = RunService.Heartbeat:Connect(function()
			if not LaunchSound.IsPlaying then Con:Disconnect() Con = nil return end
			if LaunchSound.TimePosition >= LaunchSound.TimeLength - 0.5 then
				LaunchSound.TimePosition = 1.5
			end
		end)
	end
	
	Tween.Completed:Wait()
	
	self:Explode()
	Debris:AddItem(Part, self.ExplosionLifetime + 10)
end

function FireworkModule:Explode()
	self.OnExplosion:Fire()
	
	local Part = self.FireworkPart
	local Effect = Part.Attachment.SparksRelease
	
	Part.Attachment.Shine.Enabled = false
	
	Effect.Size = ScaleNumberSequence(Effect.Size, math.min(1, self.ExplosionSize / MaxExplosionSizeForParticleScaling))
	Effect.Color = ColorSequence.new(self.ExplosionColor)
	Effect.Lifetime = NumberRange.new(self.ExplosionLifetime)
	Effect.Speed = NumberRange.new(self.ExplosionSize)
	Effect:Emit(self.ExplosionEmitCount)
	
	if self.PlayLaunchSound then
		Part.Attachment.LaunchSound:Stop()
	end
	
	if self.PlayExplosionPopSound then
		local Sound = Part.Attachment.PopSound
		Sound.Volume = self.ExplosionPopVolume or Sound.Volume * math.min(1, self.ExplosionSize / MaxExplosionSizeForSoundScaling)
		Sound.RollOffMaxDistance = self.ExplosionPopMaxDistance or Sound.RollOffMaxDistance * math.min(1, self.ExplosionSize / MaxExplosionSizeForSoundScaling)
		Sound:Play()
	end
	
	Debris:AddItem(Part, self.ExplosionLifetime + 10)
end


function FireworkModule.GetEffectsFolder(CreateIfNonExistant)
	if EffectsFolder or not CreateIfNonExistant then return EffectsFolder end
	EffectsFolder = Instance.new("Folder")
	EffectsFolder.Name = "_FireworkEffects"
	EffectsFolder.Parent = DefaultEffectStorage or workspace
	return EffectsFolder
end

return FireworkModule
