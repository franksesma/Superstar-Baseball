local SwingData = script.Parent

SwingData:GetPropertyChangedSignal("Visible"):Connect(function()
	if SwingData.Visible then
		task.delay(5, function()
			SwingData.Visible = false
		end)
	end
end)