local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameValues = ReplicatedStorage.GameValues
local MessageValues = GameValues.MessageValues
local Remotes = ReplicatedStorage.RemoteEvents
local StatusObj = MessageValues.Status

local Frame = script.Parent.Frame
local LockedInBaseFrame = script.Parent.LockedInBase
local SafeLabel = script.Parent.SafeLabel

local inPosition = UDim2.new(0.35, 0, 0.021, 0)
local outPosition = UDim2.new(0.35, 0, -0.1, 0)

local function showStatus()
	Frame.SubFrame.Label.Text = StatusObj.Value
	
	if StatusObj.Value == "" then 
		if Frame.Position ~= outPosition then
			Frame:TweenPosition(UDim2.new(0.35, 0, -0.1, 0), 'In', 'Quint', 1)
		end
	else
		if Frame.Position ~= inPosition then
			Frame:TweenPosition(UDim2.new(0.35, 0, 0.021, 0), 'Out', 'Quint', 1)
		end
	end
end

showStatus()

StatusObj.Changed:connect(function()
	showStatus()
end)

Remotes.LockedInBaseNotification.OnClientEvent:Connect(function(visible, base)
	if visible then
		LockedInBaseFrame:TweenPosition(UDim2.new(0.25, 0, 0.78, 0), 'Out', 'Quint', 1)
		LockedInBaseFrame.Label.Text = "YOU CANNOT STEAL "..string.upper(base).." UNTIL THE NEXT HIT"
	else
		LockedInBaseFrame:TweenPosition(UDim2.new(0.25, 0, 1.05, 0), 'In', 'Quint', 1)
		LockedInBaseFrame.Label.Text = ""
	end
end)

Remotes.SafeStatusNotification.OnClientEvent:Connect(function(visible, safe)
	if visible then
		SafeLabel.Text = string.upper(safe)
		
		if safe == "Safe" then
			SafeLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
		else
			SafeLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		end
		
		SafeLabel.Visible = true
	else
		SafeLabel.Visible = false
	end
end)