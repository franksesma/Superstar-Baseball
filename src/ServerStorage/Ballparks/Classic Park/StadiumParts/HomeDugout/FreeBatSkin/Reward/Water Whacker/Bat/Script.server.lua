local GROUP_ID = 10302151
local BAT_NAME = "Water Whacker"

local ProximityPrompt = script.Parent:WaitForChild("ProximityPrompt")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

ProximityPrompt.Triggered:Connect(function(player)
	local inGroup = false
	pcall(function()
		inGroup = player:IsInGroup(GROUP_ID)
	end)

	if inGroup then
		local session = _G.sessionData[player]
		if session then
			if not session.BatInventory[BAT_NAME] then
				session.BatInventory[BAT_NAME] = 1
				Remotes.Notification:FireClient(player, "You unlocked the Water Whacker bat!", "Bat")
			else
				Remotes.Notification:FireClient(player, "You already have the Water Whacker.", "Info")
			end
		end
	else
		local adGui = ServerStorage.ServerGUIs:FindFirstChild("MetavisionAd2")
		if adGui then
			adGui:Clone().Parent = player:WaitForChild("PlayerGui")
		end
	end
end)