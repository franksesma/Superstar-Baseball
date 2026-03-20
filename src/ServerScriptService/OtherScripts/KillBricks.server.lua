local Players = game:GetService("Players")

local KillBricks = workspace.KillBricks

for _, part in pairs(KillBricks:GetChildren()) do
	if part:IsA("BasePart") then
		part.Touched:Connect(function(hit)
			if hit.Parent then
				local foundPlayer = Players:FindFirstChild(hit.Parent.Name)
				
				if foundPlayer then
					foundPlayer:LoadCharacter()
				end
			end
		end)
	end
end