local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateLikes = Remotes:WaitForChild("UpdateLikes")

local gui = workspace:WaitForChild("LikeSign"):WaitForChild("LikeSign").SurfaceGui
local progressText = gui:WaitForChild("ProgressText")
local unlockText = gui:WaitForChild("UnlockText")
local freeCode = gui:WaitForChild("FreeCode")
local fill = gui:WaitForChild("ProgressBar"):WaitForChild("Fill")

local function formatNumber(n)
	local s = tostring(n)
	while true do
		local newS, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		s = newS
		if k == 0 then
			break
		end
	end
	return s
end

UpdateLikes.OnClientEvent:Connect(function(progressData)
	progressText.Text = string.format("%d/%d", progressData.progress, progressData.progressMax)

	unlockText.Text = string.format(
		"NEW CODE AT\n%s LIKES!",
		formatNumber(progressData.nextGoal)
	)

	freeCode.Text = "Code: " .. progressData.currentCode
	fill.Size = UDim2.new(progressData.percent, 0, 1, 0)
end)