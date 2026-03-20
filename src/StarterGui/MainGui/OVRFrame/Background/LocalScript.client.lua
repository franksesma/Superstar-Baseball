local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedModules = ReplicatedStorage.SharedModules

local GuiAnimationModule = require(SharedModules.GuiAnimation)

local player = Players.LocalPlayer

local ExitButton = script.Parent.ExitButton

GuiAnimationModule.ExitButtonPressed(player, script.Parent.Parent, ExitButton)