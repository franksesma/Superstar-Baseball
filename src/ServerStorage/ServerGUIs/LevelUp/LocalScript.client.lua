local player = game.Players.LocalPlayer
local frame = script.Parent:WaitForChild("Frame")
local SharedModules = game.ReplicatedStorage:WaitForChild("SharedModules")
local ClientFunctions = require(SharedModules:WaitForChild("ClientFunctions"))

wait()
ClientFunctions.PlayAudioSound(player, "LevelUp")
frame:TweenSize(UDim2.new(0.4, 0, 0.25, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.5, true)
wait(4)
frame:TweenSize(UDim2.new(0, 0,0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.5, true)
wait(0.5)
frame.Parent:Destroy()