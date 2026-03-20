local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

mouse.Icon = "115169999060289"

local imageLabel = script.Parent

mouse.Move:Connect(function()
    local offsetX, offsetY = 25, 25
    imageLabel.Position = UDim2.new(0, mouse.X - offsetX, 0, mouse.Y - offsetY)
end)