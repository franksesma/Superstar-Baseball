local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local PurchaseEvents = ReplicatedStorage:WaitForChild("PurchaseEvents")
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local GuiAnimationModule = require(SharedModules.GuiAnimation)

local player = Players.LocalPlayer
local gui = script.Parent.Parent -- PlayerSelectGifting ScreenGui
local frame = script.Parent:WaitForChild("Background")
local container = frame:WaitForChild("Container")
local exitButton = frame:WaitForChild("ExitButton")

-- Template reference
local playerTemplate = script:WaitForChild("PlayerSelectGift")

-- Attribute on ScreenGui: e.g. "Style Slot" or "Spin"
local giftType = gui:GetAttribute("GiftType") or "Unknown"
local giftSubTypeOrID = gui:GetAttribute("GiftSubTypeOrID") or "Unknown" -- "Offensive" / "Defensive" / "Lucky" / "Normal"

local function ClearPlayers()
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function CreatePlayerButton(targetPlayer)
	if targetPlayer == player then return end

	local button = playerTemplate:Clone()
	button.Name = targetPlayer.Name
	button.Visible = true
	button.Parent = container

	button.PlayerName.Text = targetPlayer.DisplayName
	button.PlayerIcon.Image = Players:GetUserThumbnailAsync(
		targetPlayer.UserId,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size100x100
	)

	GuiAnimationModule.SetupShrinkButton(button)

	button.MouseButton1Click:Connect(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		
		PurchaseEvents.GiftPlayer:FireServer(
			targetPlayer.Name,
			giftType,
			giftSubTypeOrID)

		gui:Destroy()
	end)
end

local function LoadPlayers()
	ClearPlayers()
	for _, p in ipairs(Players:GetPlayers()) do
		CreatePlayerButton(p)
	end
end

Players.PlayerAdded:Connect(function(p)
	CreatePlayerButton(p)
end)

Players.PlayerRemoving:Connect(function(p)
	local existing = container:FindFirstChild(p.Name)
	if existing then
		existing:Destroy()
	end
end)

GuiAnimationModule.SetupShrinkButton(exitButton)
exitButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	gui:Destroy()
end)

LoadPlayers()
