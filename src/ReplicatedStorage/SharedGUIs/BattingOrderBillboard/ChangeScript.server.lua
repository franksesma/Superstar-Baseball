local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedData = ReplicatedStorage.SharedData

local playerData = SharedData:WaitForChild(script.Parent.PlayerName.Value)

script.Parent.Label.Text = playerData.BattingOrder.Value

playerData.BattingOrder.Changed:Connect(function()
	script.Parent.Label.Text = playerData.BattingOrder.Value
end)
