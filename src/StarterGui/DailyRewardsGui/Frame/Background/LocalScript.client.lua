local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")

local SharedDataFolder = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local Remotes = ReplicatedStorage.RemoteEvents

local claimButtonRemote = Remotes:WaitForChild("ClaimDailyReward")
local GuiAnimationModule = require(SharedModules.GuiAnimation)

local player = Players.LocalPlayer
local dailyRewardsData = SharedDataFolder:WaitForChild(player.Name):WaitForChild("DailyRewards")

local ExitButton = script.Parent.ExitButton
local RewardItems = script.Parent.ItemFrame.Container

GuiAnimationModule.ExitButtonPressed(player, script.Parent.Parent, ExitButton)

local function updateUI()
	local currentDay = dailyRewardsData.CurrentDay.Value
	local lastClaim = dailyRewardsData.LastClaimed.Value
	local now = os.time()
	local cooldown = player.Name == "Randy_Moss" and 3 or 86400
	local countdown = cooldown - (now - lastClaim)

	for _, button in ipairs(RewardItems:GetChildren()) do
		if button:IsA("TextButton") then
			local dayNumber = tonumber(button.Name:match("%d+"))
			local titleLabel = button.TitleLabel.ItemName

			if dayNumber < currentDay or (dayNumber == 7 and currentDay == 1 and countdown > 0) then
				titleLabel.Text = "Claimed"
				button.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
				button.Icon.ImageColor3 = Color3.new(0.5, 0.5, 0.5)

			elseif dayNumber == currentDay then
				if countdown <= 0 or lastClaim == 0 then
					titleLabel.Text = "Claim!"
					button.BackgroundColor3 = Color3.new(0, 1, 0)
					button.Icon.ImageColor3 = Color3.new(1, 1, 1)
				else
					local hours = math.floor(countdown / 3600)
					local mins = math.floor((countdown % 3600) / 60)
					local secs = countdown % 60
					titleLabel.Text = string.format("%02d:%02d:%02d", hours, mins, secs)
					button.BackgroundColor3 = Color3.new(1, 1, 1)
					button.Icon.ImageColor3 = Color3.new(1, 1, 1)
				end

			else
				titleLabel.Text = "Locked"
				button.BackgroundColor3 = Color3.new(1, 1, 1)
				button.Icon.ImageColor3 = Color3.new(0.5, 0.5, 0.5)
			end
		end
	end
end

-- Reactively update UI when SharedData values change
dailyRewardsData.CurrentDay.Changed:Connect(updateUI)
dailyRewardsData.LastClaimed.Changed:Connect(updateUI)

-- Update countdown every second (still needed for timer countdown)
task.spawn(function()
	while task.wait(1) do
		updateUI()
	end
end)

-- Set up button click handlers
for _, button in ipairs(RewardItems:GetChildren()) do
	if button:IsA("TextButton") then
		GuiAnimationModule.SetupShrinkButton(button)

		button.MouseButton1Click:Connect(function()
			GuiAnimationModule.ButtonPress(player, "PositiveClick")

			local dayNumber = tonumber(button.Name:match("%d+"))
			if dayNumber == dailyRewardsData.CurrentDay.Value then
				local success, rewardOrTimeLeft = claimButtonRemote:InvokeServer()

				if success then
					-- Immediately update after successful claim
					dailyRewardsData.LastClaimed.Value = os.time()
					updateUI()
				end
			end
		end)
	end
end

Remotes.ShowDailyRewardsGui.OnClientEvent:Connect(function()
	script.Parent.Parent.Visible = true
end)

updateUI() -- Initial UI update
