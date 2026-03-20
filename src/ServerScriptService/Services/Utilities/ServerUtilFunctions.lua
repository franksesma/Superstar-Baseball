local Service = {}

local Players = game:GetService("Players")
local MarketplaceService =  game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local StarterPlayer = game:GetService("StarterPlayer")

local Remotes = ReplicatedStorage.RemoteEvents
local SharedData = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local Assets = ServerStorage.Assets

local GamePassModule = require(SharedModules.GamePasses)

function Service.CashTransaction(player, amount, isPayment, isEarned)
	if isPayment then
		if isEarned then
			local success, playerHasPass = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GamePassModule.PassIDs["2X Coins"])
			end)

			if game.PrivateServerOwnerId > 0 or game.PlaceId == 82183144153025 then
				amount = amount / 2
			end

			if playerHasPass then
				amount = amount * 2
			end
		end

		if _G.sessionData[player] then
			_G.sessionData[player].Cash = _G.sessionData[player].Cash + amount
		end
	else
		if _G.sessionData[player] then
			_G.sessionData[player].Cash = _G.sessionData[player].Cash - amount
		end
	end

	if SharedData:FindFirstChild(player.Name) then
		SharedData[player.Name].Cash.Value = _G.sessionData[player].Cash
	end
end

function Service.SetupFootsteps(character)
	local footstepScripts = Assets.Scripts.Footsteps:GetChildren()
	local footstepObjects = Assets.Objects.Footsteps:GetChildren()

	if character:FindFirstChild('Sound') then
		character.Sound:Destroy()
	end

	for i = 1, #footstepScripts do
		if footstepScripts[i]:IsA('Script') then
			local footstepScript = footstepScripts[i]:Clone()
			footstepScript.Disabled = true
			footstepScript.Parent = character.HumanoidRootPart
			footstepScript.Disabled = false
		end
	end

	for _, object in pairs(footstepObjects) do 
		object:Clone().Parent = character.HumanoidRootPart
	end

	local r = character.Head:GetChildren()
	for i = 1,#r do
		if r[i]:IsA('Sound') then
			r[i]:Destroy()
		end
	end
end

return Service
