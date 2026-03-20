local ball = script.Parent
local rolling = false

local rollingDampFactor = 0.92
local dampInterval = 0.05
local minSpeedToStop = 0.1

ball.Touched:Connect(function(hit)
	if hit:IsDescendantOf(ball) then return end
	if rolling then return end

	-- Only apply anti-roll if the material is Grass
	if hit.Material ~= Enum.Material.Grass then
		return
	end

	rolling = true

	task.spawn(function()
		while rolling and ball.AssemblyLinearVelocity.Magnitude > minSpeedToStop do
			local currentVel = ball.AssemblyLinearVelocity

			local horizontalVel = Vector3.new(currentVel.X, 0, currentVel.Z) * rollingDampFactor
			local newVel = Vector3.new(horizontalVel.X, currentVel.Y, horizontalVel.Z)

			ball.AssemblyLinearVelocity = newVel
			task.wait(dampInterval)
		end

		rolling = false
	end)
end)