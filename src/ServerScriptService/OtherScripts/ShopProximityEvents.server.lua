local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")

local Interactables = workspace.Interactables
local Remotes = ReplicatedStorage.RemoteEvents
local SharedModules = ReplicatedStorage.SharedModules

local PackInteracts = Interactables.Packs
local PassInteracts = Interactables.Passes
local TeleportInteracts = Interactables.Teleports

local ShopPackTypes = require(SharedModules.ShopPackTypes)
local GamePasses = require(SharedModules.GamePasses)

for _, pack in pairs(PackInteracts:GetChildren()) do
	pack.Interact.ViewPrompt.Triggered:Connect(function(player)
		Remotes.ViewPack:FireClient(player, pack.Name, ShopPackTypes[pack.Name].PackItemType)
	end)
end

for _, pass in pairs(PassInteracts:GetChildren()) do
	pass.Interact.ViewPrompt.Triggered:Connect(function(player)
		MarketplaceService:PromptGamePassPurchase(player, GamePasses.PassIDs[pass.Name])
	end)
end

for _, teleport in pairs(TeleportInteracts:GetChildren()) do
	if game.PlaceId == 92200951444783 then
		teleport.Name = "Normal Servers"
		teleport.Interact.ViewPrompt.ActionText = "Join Normal Servers"
		teleport.PlaceID.Value = 101432174163538
		workspace.ProServersTeleportDisplay.Attachment.Primary.Frame.TextLabel.Text = "NORMAL SERVERS"
		workspace.ProServersTeleportDisplay.Attachment.Secondary.Enabled = false
		workspace.ProServersTeleportDisplay.Attachment.Primary.Frame.TextLabel.UIGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 170, 255)) 
		}
		workspace.ProServersTeleportDisplay.MeshPart.Particle.Top.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)), 
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 170, 255)) 
		}
	end
	
	teleport.Interact.ViewPrompt.Triggered:Connect(function(player)
		if teleport.Name == "Pro Servers" 
			and _G.sessionData[player]
			and _G.sessionData[player].OVRProgress.OVR < 10
		then
			Remotes.Notification:FireClient(player, "You need 10 OVR to join Pro Servers!", "Alert")
			return
		end

		if teleport.Name == "AFK World" then
			local success, accessCodeOrErr = pcall(function()
				return TeleportService:ReserveServer(teleport.PlaceID.Value)
			end)

			if success and accessCodeOrErr then
				local accessCode = accessCodeOrErr
				TeleportService:TeleportToPrivateServer(teleport.PlaceID.Value, accessCode, { player })
			else
				warn("Failed to reserve AFK server:", accessCodeOrErr)
				Remotes.Notification:FireClient(player, "Failed to teleport to AFK World. Try again.", "Alert")
			end
		else
			TeleportService:Teleport(teleport.PlaceID.Value, player)
		end
	end)
end

