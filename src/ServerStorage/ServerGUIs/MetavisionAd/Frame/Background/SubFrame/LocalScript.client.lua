local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local PlayerGui = player.PlayerGui
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local ClientFunctions = require(SharedModules:WaitForChild("ClientFunctions"))
local Remotes = ReplicatedStorage.RemoteEvents
local GuiAnimationModule = require(SharedModules.GuiAnimation)

local ButtonDebounce = false

GuiAnimationModule.SetupShrinkButton(script.Parent.AcceptButton)

script.Parent:WaitForChild("AcceptButton").MouseButton1Click:connect(function()
	if not ButtonDebounce then
		ButtonDebounce = true
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		Remotes.CheckGroupJoinBonus:FireServer()
		script.Parent.Parent.Parent.Parent:Destroy()
		ButtonDebounce = false
	end
end)