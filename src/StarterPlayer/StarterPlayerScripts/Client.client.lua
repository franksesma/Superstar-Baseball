local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Shared
local SharedServices = Shared.Services

local PlayerUtilsClient = require(SharedServices.Utilities.PlayerUtilsClient)
local StyleMechanicsClient = require(SharedServices.Mechanics.StyleMechanicsClient)

PlayerUtilsClient.init()
StyleMechanicsClient.init()

--[[
 DO NOT PUT ANY CODE IN HERE OTHER THAN .init() CALLS. THIS SCRIPT SHOULD BE USED FOR INITIALIZATION. ANY NEW CLIENT
 SIDE CODE SHOULD BE PLACED IN ITS OWN MODULE AND INITALIZED HERE. THIS IS A STEP TOWARDS CONVERTING THE GAME INTO
 A MODULAR ARCHITECTURE.
--]]

