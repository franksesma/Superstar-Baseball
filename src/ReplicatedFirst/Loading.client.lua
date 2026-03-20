local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")


local player = Players.LocalPlayer

ReplicatedFirst:RemoveDefaultLoadingScreen()

local loadingGui = script:WaitForChild("LoadingScreen"):Clone()
loadingGui.Parent = player:WaitForChild("PlayerGui")
task.spawn(function()
	local playerLoaded = false
	local minimumWaitCompleted = false
	
	local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
	
	Remotes:WaitForChild("PlayerDataLoaded").OnClientEvent:Connect(function()
		playerLoaded = true
		
		if minimumWaitCompleted then
			loadingGui:Destroy()
		end
	end)
	
	if not RunService:IsStudio() then
		task.wait(3)
	else
		task.wait(1)	
	end
	if playerLoaded and loadingGui then
		loadingGui:Destroy()
	end

	minimumWaitCompleted = true
end)

local assetsToPreload = {}

for _, obj in ipairs(loadingGui:GetDescendants()) do
	if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
		if obj.Image and obj.Image ~= "" then
			table.insert(assetsToPreload, obj.Image)
		end
	end
end

ContentProvider:PreloadAsync(assetsToPreload)

task.wait(20)

if loadingGui then
	loadingGui:Destroy()
end