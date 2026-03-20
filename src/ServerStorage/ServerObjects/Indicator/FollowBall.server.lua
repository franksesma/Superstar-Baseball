local FIELD_Y_PLANE = 2

local ballHolder = workspace.BallHolder

local ball = ballHolder:WaitForChild("Baseball", 10)

if ball then
	game:GetService("RunService").RenderStepped:Connect(function()
		if ball.Parent then
			if ball.Transparency == 1 then
				script.Parent.Position = Vector3.new(0, math.huge, 0)
			else
				script.Parent.Position = Vector3.new(ball.Position.X, FIELD_Y_PLANE, ball.Position.Z)
			end
		end
	end)
end
