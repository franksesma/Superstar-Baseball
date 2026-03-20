local TweenService = game:GetService("TweenService")
local SwingData = script.Parent

SwingData:GetPropertyChangedSignal("Visible"):Connect(function()
	if SwingData.Visible then
		-- Reset position to offscreen left when made visible
		SwingData.Position = UDim2.new(-0.5, 0, 0.1, 0)

		-- Tween in
		local swooshIn = TweenService:Create(
			SwingData,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0.25, 0, 0.1, 0) }
		)

		-- Tween out
		local swooshOut = TweenService:Create(
			SwingData,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(1.5, 0, 0.1, 0) }
		)

		-- Play swoosh in
		swooshIn:Play()
		swooshIn.Completed:Wait()

		-- Sit for 1 second
		task.wait(2)

		-- Play swoosh out
		swooshOut:Play()
		swooshOut.Completed:Wait()

		-- Hide when done
		SwingData.Visible = false
	end
end)