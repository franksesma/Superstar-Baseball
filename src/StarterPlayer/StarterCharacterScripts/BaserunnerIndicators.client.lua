local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local GameValues = ReplicatedStorage.GameValues
local OnBaseFolder = GameValues.OnBase
local SharedModules = ReplicatedStorage.SharedModules

local ClientFunctions = require(SharedModules.ClientFunctions)

local player = Players.LocalPlayer

local function updateIndicator(baseTracker, baseRunner)
	if baseTracker.IsSafe.Value then
		baseRunner.Character.Head.BaserunnerSafeIndicator.Icon.Image = "http://www.roblox.com/asset/?id=87346547541443"
	else
		baseRunner.Character.Head.BaserunnerSafeIndicator.Icon.Image = "http://www.roblox.com/asset/?id=117818408425498"
	end
end

local function setupBaserunnerIndicator(baseTracker)
	local baseRunner = Players:FindFirstChild(baseTracker.Name)

	if baseRunner 
		and baseRunner.Character 
		and baseRunner.Character:FindFirstChild("Head") 
		and baseRunner.Character.Head:FindFirstChild("BaserunnerSafeIndicator")
	then
		baseRunner.Character.Head.BaserunnerSafeIndicator.Enabled = true
		
		baseTracker:WaitForChild("IsSafe", 3)
		
		updateIndicator(baseTracker, baseRunner)
		
		baseTracker.IsSafe.Changed:Connect(function()
			updateIndicator(baseTracker, baseRunner)
		end)
	end
end

local function disableBaserunerIndicator(baseTracker)
	local baseRunner = Players:FindFirstChild(baseTracker.Name)

	if baseRunner 
		and baseRunner.Character 
		and baseRunner.Character:FindFirstChild("Head") 
		and baseRunner.Character.Head:FindFirstChild("BaserunnerSafeIndicator")
	then
		baseRunner.Character.Head.BaserunnerSafeIndicator.Enabled = false
	end
end

if ClientFunctions.PlayerIsDefender(player) and player.TeamColor ~= Teams.Lobby.TeamColor then
	for _, baseTracker in pairs(OnBaseFolder:GetChildren()) do
		task.spawn(function()
			setupBaserunnerIndicator(baseTracker)
		end)
	end
else
	for _, baseTracker in pairs(OnBaseFolder:GetChildren()) do
		disableBaserunerIndicator(baseTracker)
	end
end

OnBaseFolder.ChildAdded:Connect(function(baseTrackerAdded)
	if ClientFunctions.PlayerIsDefender(player) and player.TeamColor ~= Teams.Lobby.TeamColor then
		setupBaserunnerIndicator(baseTrackerAdded)
	end
end)

OnBaseFolder.ChildRemoved:Connect(function(baseTrackerRemoved)
	local baseRunner = Players:FindFirstChild(baseTrackerRemoved.Name)
	
	if baseTrackerRemoved 
		and baseRunner 
		and baseRunner.Character 
		and baseRunner.Character:FindFirstChild("Head") 
		and baseRunner.Character.Head:FindFirstChild("BaserunnerSafeIndicator")
	then
		baseRunner.Character.Head.BaserunnerSafeIndicator.Enabled = false
	end
end)