local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.RemoteEvents

Remotes.PlayLocalSound.OnClientEvent:connect(function(sound, onOrOff)
	if onOrOff == "On" then
		local originalVolume = script[sound].Volume
		for i = 0, originalVolume, 0.05 do
			script[sound].Volume = i
			if not script[sound].IsPlaying then
				script[sound]:Play()
			end 
			wait(0.4)
		end
		script[sound].Volume = originalVolume
	elseif onOrOff == "Off" then
		local originalVolume = script[sound].Volume
		for i = originalVolume, 0, -0.05 do
			script[sound].Volume = i
			wait(0.4)
		end
		script[sound]:Stop()
		script[sound].Volume = originalVolume
	else
		script[sound]:Play()
	end
end)
