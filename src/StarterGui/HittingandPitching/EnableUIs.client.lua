local Player = game.Players.LocalPlayer
local ReplicatedStorage = game.ReplicatedStorage
local remote = ReplicatedStorage.RemoteEvents:WaitForChild("CloneUI")

local sharedGUIs = ReplicatedStorage:WaitForChild("SharedGUIs")
local playerGui = Player:WaitForChild("PlayerGui")

remote.OnClientEvent:Connect(function(uiName)
	-- Special handling for HittingScreen
	if uiName == "HittingScreen" then
		local template = sharedGUIs:FindFirstChild("HittingScreen")
		if template then
			-- remove old one if it exists
			local existing = playerGui:FindFirstChild("HittingScreen")
			if existing then
				existing:Destroy()
			end

			-- clone new one
			local clone = template:Clone()
			clone.Parent = playerGui
			clone.Enabled = true

			-- controller support
			local controllerScript = clone:FindFirstChild("ControllerSupport")
			if controllerScript and not controllerScript.Enabled then
				controllerScript.Enabled = true
			end
		end

	else
		-- original behavior for other UIs
		local ui = script.Parent.Parent:FindFirstChild(uiName)
		if ui then
			ui.Enabled = true

			if uiName == "PitchingScreen" then
				local controllerScript = ui:FindFirstChild("ControllerSupport")
				if controllerScript and not controllerScript.Enabled then
					controllerScript.Enabled = true
				end
			end
		end
	end
end)
