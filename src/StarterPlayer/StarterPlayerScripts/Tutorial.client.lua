-- Client-side script to handle tutorial UI
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local GuiAnimationModule = require(SharedModules:WaitForChild("GuiAnimation"))
local ButtonDebounce = false

-- Wait for tutorial GUI
local tutorialGui = playerGui:WaitForChild("Tutorial", 10)
if not tutorialGui then
	return
end

-- Find the buttons (supports Frame -> Background -> SubFrame)
local background = tutorialGui:FindFirstChild("Background")
if not background then
	local frame = tutorialGui:FindFirstChild("Frame")
	if frame then
		background = frame:FindFirstChild("Background")
	end
end
if not background then
	for _, child in pairs(tutorialGui:GetDescendants()) do
		if child.Name == "Background" and child:IsA("Frame") then
			background = child
			break
		end
	end
end
if not background then
	return
end

local subFrame = background:FindFirstChild("SubFrame")
if not subFrame then
end

local function findButton(container, names)
	if not container then return nil end
	for _, child in pairs(container:GetDescendants()) do
		if (child:IsA("TextButton") or child:IsA("ImageButton")) then
			local lowerName = string.lower(child.Name)
			for _, name in ipairs(names) do
				if lowerName == string.lower(name) then
					return child
				end
			end
		end
	end
	return nil
end

local acceptButton = (subFrame and (subFrame:FindFirstChild("AcceptButton") or subFrame:FindFirstChild("Accept") or subFrame:FindFirstChild("Teleport")))
local declineButton = (subFrame and (subFrame:FindFirstChild("DeclineButton") or subFrame:FindFirstChild("Decline")))

if not acceptButton then
	acceptButton = findButton(subFrame or background, {"AcceptButton", "Accept", "Teleport", "TeleportButton"})
end
if not declineButton then
	declineButton = findButton(subFrame or background, {"DeclineButton", "Decline", "Skip", "SkipButton"})
end

if not acceptButton then
	warn("[TutorialClient] Accept/Teleport button not found")
	return
end
if not declineButton then
	warn("[TutorialClient] Decline button not found")
	return
end

-- Make sure tutorial is disabled by default
tutorialGui.Enabled = false

GuiAnimationModule.SetupShrinkButton(acceptButton)
GuiAnimationModule.SetupShrinkButton(declineButton)

-- Listen for server to show tutorial
local showTutorialRemote = Remotes:WaitForChild("ShowTutorial", 10)
if showTutorialRemote then
	showTutorialRemote.OnClientEvent:Connect(function()
		tutorialGui.Enabled = true
	end)
end

-- Handle Accept/Teleport button
acceptButton.MouseButton1Click:Connect(function()
	if ButtonDebounce then return end
	ButtonDebounce = true

	-- Hide GUI immediately
	tutorialGui.Enabled = false

	-- Play animation
	pcall(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
	end)

	-- Fire remote to server to teleport
	local tutorialAcceptRemote = Remotes:FindFirstChild("TutorialAccept")
	if not tutorialAcceptRemote then
		tutorialAcceptRemote = Remotes:WaitForChild("TutorialAccept", 5)
	end
	if tutorialAcceptRemote then
		tutorialAcceptRemote:FireServer()
	end

	-- Don't reset debounce - player is teleporting anyway
end)

-- Handle Decline button
declineButton.MouseButton1Click:Connect(function()
	if ButtonDebounce then return end
	ButtonDebounce = true
	GuiAnimationModule.ButtonPress(player, "NegativeClick")
	local tutorialDeclineRemote = Remotes:WaitForChild("TutorialDecline", 10)
	if tutorialDeclineRemote then
		tutorialDeclineRemote:FireServer()
	end
	tutorialGui.Enabled = false
	task.delay(0.1, function()
		ButtonDebounce = false
	end)
end)



