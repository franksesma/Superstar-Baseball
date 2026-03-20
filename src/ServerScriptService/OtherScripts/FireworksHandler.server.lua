local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedModules = ReplicatedStorage.SharedModules
local GameValues = ReplicatedStorage.GameValues

local FireworkModule = require(SharedModules.FireworkModule)

local running = false

GameValues.Homerun.Changed:Connect(function()
	if GameValues.Homerun.Value and not running then
		running = true

		while GameValues.Homerun.Value do
			FireworkModule.NewFirework {
				StartPosition = Vector3.new(
					math.random(-600, 0),
					-10,
					math.random(-600, 0)
				),
				LaunchSoundVolume = 0.5,
				LaunchSoundMaxDistance = 50,
				ExplosionPopVolume = 0.2,
			}

			task.wait(math.random(5, 10) / 10)
		end

		running = false
	end
end)
