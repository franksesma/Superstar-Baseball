local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")
local PolicyService = game:GetService("PolicyService")

local SharedDataFolder = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local SharedUI = ReplicatedStorage.SharedGUIs
local Remotes = ReplicatedStorage.RemoteEvents
local PurchaseEvents = ReplicatedStorage.PurchaseEvents
local GameValues = ReplicatedStorage.GameValues
local ShopItems = ReplicatedStorage.ShopItems
local GearItems = ReplicatedStorage.Gear

local GuiAnimationModule = require(SharedModules.GuiAnimation)
local ClientFunctions = require(SharedModules.ClientFunctions)
local ShopPackItemsModule = require(SharedModules.ShopPackItems)
local ShopPackTypesModule = require(SharedModules.ShopPackTypes)
local RarityModule = require(SharedModules.RarityProbability)
local ViewportModelModule = require(SharedModules.ViewportModel)
local GearItemsModule = require(SharedModules.GearItems)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local PacksFrame = script.Parent.PacksFrame
local ViewPacksFrame = PacksFrame.ViewPacksFrame
local PacksDisplayFrame = PacksFrame.Packs
local ButtonsFrame = script.Parent.ButtonsFrame
local CashFrame = script.Parent.CashFrame
local GamePassFrame = script.Parent.GamePassFrame
local GearFrame = script.Parent.GearFrame
local ExitButton = script.Parent.ExitButton
local PackActionButtons = ViewPacksFrame.ActionButtons
local GearButtons = GearFrame.Background.Buttons

local frames = {
	[ButtonsFrame.Packs] = PacksFrame;
	[ButtonsFrame.Cash] = CashFrame;
	[ButtonsFrame.GamePasses] = GamePassFrame;
	[ButtonsFrame.Gear] = GearFrame;
}

local buttonClicked = false
local packSelected = "Bat"
local currentPackPurchaseModifier = 1
local viewportModelRenderStepped = nil
local gearViewportModelRenderStepped = nil
local viewportModels = {}
local gearViewportModels = {}

local paidRandomItemsBanned = false

local playerData = SharedDataFolder:WaitForChild(player.Name, 3)
if playerData then
	local foundCharacter = playerData:WaitForChild("EmoteShopDisplayCharacter", 3)

	if foundCharacter then 
		displayCharacter = foundCharacter:Clone()
	end
end
	
local success, result = pcall(function()
	return PolicyService:GetPolicyInfoForPlayerAsync(player)
end)

if success and result.ArePaidRandomItemsRestricted then
	paidRandomItemsBanned = true
end

local function viewPack(pack, packItemType)
	PacksDisplayFrame.Visible = false
	
	ViewPacksFrame.PackType.Value = pack.Name
	
	currentPackPurchaseModifier = 1
	PackActionButtons["10x"].Checkmark.Visible = false

	local success, productInfo = pcall(function()
		if currentPackPurchaseModifier == 1 then
			return MarketplaceService:GetProductInfo(ShopPackTypesModule[ViewPacksFrame.PackType.Value].DevProductIDx1, Enum.InfoType.Product)
		else
			return MarketplaceService:GetProductInfo(ShopPackTypesModule[ViewPacksFrame.PackType.Value].DevProductIDx10, Enum.InfoType.Product)
		end
	end)

	if success and productInfo then
		PackActionButtons.BuyRobux.Label.Text = productInfo.PriceInRobux
	end
	
	PackActionButtons.BuyCash.Label.Text = ClientFunctions.ConvertShort(ShopPackTypesModule[pack.Name].Price)
	ViewPacksFrame.PackLogo.PackIcon.Image = pack:WaitForChild("PackIcon", 3).Image
	ViewPacksFrame.Label.Text = pack.Label.Text

	local sortedPackItems = {}

	for _, rarity in pairs(RarityModule.RarityList) do
		for itemName, itemValues in pairs(ShopPackItemsModule[pack.Name]) do
			if itemValues.Rarity == rarity then
				sortedPackItems[itemName] = itemValues
			end
		end
	end

	local keys = {}

	for itemName, itemValues in pairs(sortedPackItems) do
		local packViewport = script.PackViewport:Clone()
		packViewport.Name = itemName
		packViewport.ItemName.Text = itemName
		packViewport.Rarity.Text = itemValues.Rarity
		packViewport.Rarity.TextColor3 = RarityModule.Colors[itemValues.Rarity]
		packViewport.BackgroundColor3 = RarityModule.Colors[itemValues.Rarity]
		
		local rarityLabel = ViewPacksFrame.RarityPercentages[itemValues.Rarity].Label:Clone()
		rarityLabel.Parent = packViewport
		rarityLabel.Size = packViewport.Rarity.Size
		rarityLabel.Position = packViewport.Rarity.Position
		rarityLabel.TextXAlignment = Enum.TextXAlignment.Center
		rarityLabel.ZIndex = 2

		local uiGradient = SharedUI.StylesUI["UIGradient"..itemValues.Rarity]:Clone()
		uiGradient.Rotation = 90
		uiGradient.Parent = packViewport.UIStroke

		local packItemType = ShopPackTypesModule[pack.Name].PackItemType

		packViewport.Parent = ViewPacksFrame.ScrollingFrameBackground.ScrollingFrame
		
		if packItemType == "Trail" or packItemType == "Explosion" then
			packViewport.TrailIcon.Image = ShopPackItemsModule[pack.Name][itemName].Icon
			packViewport.TrailIcon.Visible = true
			packViewport.ViewportFrame.Visible = false
		elseif packItemType == "Emote" then
			if displayCharacter then
				local worldModel = Instance.new("WorldModel")
				worldModel.Name = "ViewModel"
				local dummy = displayCharacter:Clone()
				dummy.Name = "ViewModel"

				local animateScript = dummy:FindFirstChild("Animate")
				if animateScript then
					animateScript:Destroy() -- Remove default animations
				end

				local animation = Instance.new("Animation")
				animation.AnimationId = ShopItems[packItemType][itemName].AnimationId

				local camera = Instance.new("Camera")
				camera.FieldOfView = 70
				camera.Parent = packViewport.ViewportFrame

				worldModel.Parent = packViewport.ViewportFrame
				dummy.Parent = worldModel
				
				packViewport.ViewportFrame.CurrentCamera = camera
				
				local humanoid = dummy:FindFirstChildOfClass("Humanoid")
				if humanoid then
					local animator = humanoid:FindFirstChildOfClass("Animator")
					if animator then
						animator = Instance.new("Animator")
						animator.Parent = humanoid
					end

					local animTrack = animator:LoadAnimation(animation)
					animTrack.Looped = true
					animTrack:Play()
				end

				viewportModels[itemName] = {ViewportSetup = ViewportModelModule.new(packViewport.ViewportFrame, camera), Theta = math.pi}
				viewportModels[itemName].ViewportSetup:SetModel(worldModel)
			end
		else
			local viewModel = Instance.new("Model")
			viewModel.Name = "ViewModel"
			local referenceModel = ShopItems[packItemType][itemName]

			for _, part in pairs(referenceModel:GetChildren()) do
				if part:IsA("MeshPart") or part:IsA("BasePart") then
					part:Clone().Parent = viewModel
				end
			end

			local camera = Instance.new("Camera")
			camera.FieldOfView = 70
			camera.Parent = packViewport.ViewportFrame

			viewModel.Parent = packViewport.ViewportFrame
			packViewport.ViewportFrame.CurrentCamera = camera

			viewportModels[itemName] = {ViewportSetup = ViewportModelModule.new(packViewport.ViewportFrame, camera), Theta = 0}

			viewportModels[itemName].ViewportSetup:SetModel(viewModel)
		end

		table.insert(keys, itemName)
	end

	local rarityOrder = {
		Legendary = 1,
		Epic = 2,
		Rare = 3,
		Uncommon = 4,
		Common = 5
	}

	table.sort(keys, function(a, b)
		local rarityA = rarityOrder[sortedPackItems[a].Rarity]
		local rarityB = rarityOrder[sortedPackItems[b].Rarity]

		if rarityA == rarityB then
			return a < b 
		else
			return rarityA < rarityB
		end
	end)

	for i, key in ipairs(keys) do
		ViewPacksFrame.ScrollingFrameBackground.ScrollingFrame[key].LayoutOrder = i
	end

	local packRollsOwned = Remotes.RetrievePackRolls:InvokeServer(pack.Name, packItemType)

	if packRollsOwned > 0 then
		PackActionButtons.OpenButton.Label.Text = "Open ("..packRollsOwned..")"
		PackActionButtons.OpenButton.Visible = true
	else
		PackActionButtons.OpenButton.Visible = false
	end
	
	for _, labelFrame in pairs(ViewPacksFrame.RarityPercentages:GetChildren()) do
		if labelFrame:IsA("Frame") then
			if string.match(ViewPacksFrame.PackType.Value, "Supreme")  then
				labelFrame.Percentage.Text = RarityModule.SupremePackProbability[labelFrame.Name].."%"
			else
				labelFrame.Percentage.Text = RarityModule[labelFrame.Name].."%"
			end
		end
	end

	ViewPacksFrame.Visible = true
	
	if packItemType == "Emote" then
		local orientation = CFrame.new()

		viewportModelRenderStepped = game:GetService("RunService").RenderStepped:Connect(function(dt)
			for _, packDisplay in pairs(ViewPacksFrame.ScrollingFrameBackground.ScrollingFrame:GetChildren()) do
				if packDisplay:IsA("Frame") and packDisplay.ViewportFrame:FindFirstChild("ViewModel") then
					local cf, size = packDisplay.ViewportFrame.ViewModel:GetBoundingBox()
					local distance = viewportModels[packDisplay.Name].ViewportSetup:GetFitDistance(cf.Position) * 0.6

					viewportModels[packDisplay.Name].Theta = viewportModels[packDisplay.Name].Theta + math.rad(20 * dt)
					orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), viewportModels[packDisplay.Name].Theta, 0)
					packDisplay.ViewportFrame.Camera.CFrame = CFrame.new(cf.Position) * orientation * CFrame.new(0, 0, distance)
				end
			end
		end)
	elseif packItemType ~= "Trail" or packItemType ~= "Explosion" then
		local orientation = CFrame.new()

		viewportModelRenderStepped = game:GetService("RunService").RenderStepped:Connect(function(dt)
			for _, packDisplay in pairs(ViewPacksFrame.ScrollingFrameBackground.ScrollingFrame:GetChildren()) do
				if packDisplay:IsA("Frame") and packDisplay.ViewportFrame:FindFirstChild("ViewModel") then
					local cf, size = packDisplay.ViewportFrame.ViewModel:GetBoundingBox()
					local distance = viewportModels[packDisplay.Name].ViewportSetup:GetFitDistance(cf.Position)

					viewportModels[packDisplay.Name].Theta = viewportModels[packDisplay.Name].Theta + math.rad(20 * dt)
					orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), viewportModels[packDisplay.Name].Theta, 0)
					packDisplay.ViewportFrame.Camera.CFrame = CFrame.new(cf.Position) * orientation * CFrame.new(0, 0, distance)
				end
			end
		end)
	end
end

local function handlePacksFrameVisibility(packItemType)
	ViewPacksFrame.Visible = false
	PacksDisplayFrame.Visible = true

	if viewportModelRenderStepped ~= nil then
		viewportModelRenderStepped:Disconnect()
		viewportModelRenderStepped = nil
	end

	viewportModels = {}

	for _, frame in pairs(ViewPacksFrame.ScrollingFrameBackground.ScrollingFrame:GetChildren()) do
		if frame:IsA("Frame") then
			frame:Destroy()
		end
	end
	

	for _, frame in pairs(PacksDisplayFrame.PacksScrollingFrame:GetChildren()) do
		if frame:IsA("Frame") then
			frame:Destroy()
		end
	end
	
	for packName, packValues in pairs(ShopPackTypesModule) do
		if packValues.PackItemType == packItemType and packValues.IsActive then
			local packDisplayButton = script.TemplateDisplayPack:Clone()
			packDisplayButton.Name = packName
			packDisplayButton.PackIcon.Image = "http://www.roblox.com/asset/?id="..packValues.PackIcon
			packDisplayButton.Label.Text = packName
			packDisplayButton.LayoutOrder = packValues.LayoutOrder
			packDisplayButton.Parent = PacksDisplayFrame.PacksScrollingFrame
			if packValues.Limited then
				packDisplayButton.LimitedLabel.Visible = true
			end
		end
	end
	
	for _, pack in pairs(PacksDisplayFrame.PacksScrollingFrame:GetChildren()) do
		if pack:IsA("Frame") then
			GuiAnimationModule.SetupShrinkButton(pack.ViewButton)

			pack.ViewButton.MouseButton1Click:Connect(function()
				GuiAnimationModule.ButtonPress(player, "PositiveClick")
				viewPack(pack, packItemType)
			end)
		end
	end
end

local function frameButtonClicked(frame, button)
	if not buttonClicked then
		buttonClicked = true
		GuiAnimationModule.ButtonPress(player, "PositiveClick")

		frame.Visible = true

		if frame == PacksFrame then
			handlePacksFrameVisibility(packSelected)
		end

		button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		button.UIStroke.Color = Color3.fromRGB(0, 255, 255)

		for k,v in pairs(frames) do
			if k ~= button then
				if v ~= frame then
					v.Visible = false
				end
				k.BackgroundColor3 = Color3.fromRGB(170, 255, 255)
				k.UIStroke.Color = Color3.fromRGB(255, 255, 255)
			end
		end

		if frame then
			buttonClicked = false
		end	
	end
end

for button, frame in pairs(frames) do
	GuiAnimationModule.SetupGrowButton(button)

	button.MouseButton1Click:connect(function()
		frameButtonClicked(frame, button)
	end)
end

Remotes.ViewPack.OnClientEvent:Connect(function(packName, packItemType)
	PacksFrame.Packs.PackButtonsFrame[packSelected].BackgroundColor3 = Color3.fromRGB(170, 255, 255)
	PacksFrame.Packs.PackButtonsFrame[packSelected].UIStroke.Color = Color3.fromRGB(255, 255, 255)
	
	packSelected = packItemType
	handlePacksFrameVisibility(packSelected)
	viewPack(PacksDisplayFrame.PacksScrollingFrame[packName], packItemType)
	
	PacksFrame.Packs.PackButtonsFrame[packSelected].BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	PacksFrame.Packs.PackButtonsFrame[packSelected].UIStroke.Color = Color3.fromRGB(0, 255, 255)
end)

GuiAnimationModule.ExitButtonPressed(player, script.Parent.Parent, ExitButton)

handlePacksFrameVisibility(packSelected)

GuiAnimationModule.SetupGrowButton(PackActionButtons.BackButton)

PackActionButtons.BackButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	packSelected = ShopPackTypesModule[ViewPacksFrame.PackType.Value].PackItemType
	handlePacksFrameVisibility(packSelected)
end)

for _, packButton in pairs(PacksFrame.Packs.PackButtonsFrame:GetChildren()) do
	if packButton:IsA("TextButton") then
		GuiAnimationModule.SetupGrowButton(packButton)
		
		packButton.MouseButton1Click:connect(function()
			GuiAnimationModule.ButtonPress(player, "PositiveClick")
			
			PacksFrame.Packs.PackButtonsFrame[packSelected].BackgroundColor3 = Color3.fromRGB(170, 255, 255)
			PacksFrame.Packs.PackButtonsFrame[packSelected].UIStroke.Color = Color3.fromRGB(255, 255, 255)
			
			packSelected = packButton.Name
			handlePacksFrameVisibility(packSelected)
			
			PacksFrame.Packs.PackButtonsFrame[packSelected].BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			PacksFrame.Packs.PackButtonsFrame[packSelected].UIStroke.Color = Color3.fromRGB(0, 255, 255)
		end)
	end
end

GuiAnimationModule.SetupGrowButton(PackActionButtons.BuyCash)
GuiAnimationModule.SetupGrowButton(PackActionButtons.OpenButton)
GuiAnimationModule.SetupGrowButton(PackActionButtons["10x"])
GuiAnimationModule.SetupGrowButton(PackActionButtons.BuyRobux)

local buyDebounce = false
local openDebounce = false

PackActionButtons.BuyRobux.MouseButton1Click:Connect(function()
	if not buyDebounce then
		buyDebounce = true
		GuiAnimationModule.ButtonPress(player, "PositiveClick")

		if not paidRandomItemsBanned then
			if currentPackPurchaseModifier == 10 then
				PurchaseEvents.DevProductPurchase:FireServer(ShopPackTypesModule[ViewPacksFrame.PackType.Value].DevProductIDx10)
			else
				PurchaseEvents.DevProductPurchase:FireServer(ShopPackTypesModule[ViewPacksFrame.PackType.Value].DevProductIDx1)
			end
			wait(0.5)
		else
			ClientFunctions.Notification(player, "Sorry, this action is currently disabled in your region!", "Alert")
		end
		buyDebounce = false
	end
end)

PackActionButtons.BuyCash.MouseButton1Click:Connect(function()
	if not buyDebounce then
		buyDebounce = true
		GuiAnimationModule.ButtonPress(player, "PositiveClick")

		if not paidRandomItemsBanned then
			Remotes.BuyShopPack:FireServer(ViewPacksFrame.PackType.Value, ShopPackTypesModule[ViewPacksFrame.PackType.Value].PackItemType, currentPackPurchaseModifier)
			wait(0.5)
		else
			ClientFunctions.Notification(player, "Sorry, this action is currently disabled in your region!", "Alert")
		end
		buyDebounce = false
	end
end)

PackActionButtons.OpenButton.MouseButton1Click:Connect(function()
	if not openDebounce then
		openDebounce = true
		GuiAnimationModule.ButtonPress(player, "PositiveClick")

		Remotes.OpenShopPack:FireServer(ViewPacksFrame.PackType.Value, ShopPackTypesModule[ViewPacksFrame.PackType.Value].PackItemType)

		wait(1)
		openDebounce = false
	end
end)

PackActionButtons["10x"].MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")

	if currentPackPurchaseModifier == 1 then
		currentPackPurchaseModifier = 10
		PackActionButtons["10x"].Checkmark.Visible = true
		PackActionButtons.BuyCash.Label.Text = ClientFunctions.ConvertShort(ShopPackTypesModule[ViewPacksFrame.PackType.Value].Price * 10)
		
		local success, productInfo = pcall(function()
			return MarketplaceService:GetProductInfo(ShopPackTypesModule[ViewPacksFrame.PackType.Value].DevProductIDx10, Enum.InfoType.Product)
		end)

		if success and productInfo then
			PackActionButtons.BuyRobux.Label.Text = productInfo.PriceInRobux
		end
	else
		currentPackPurchaseModifier = 1
		PackActionButtons["10x"].Checkmark.Visible = false
		PackActionButtons.BuyCash.Label.Text = ClientFunctions.ConvertShort(ShopPackTypesModule[ViewPacksFrame.PackType.Value].Price)
		
		local success, productInfo = pcall(function()
			return MarketplaceService:GetProductInfo(ShopPackTypesModule[ViewPacksFrame.PackType.Value].DevProductIDx1, Enum.InfoType.Product)
		end)

		if success and productInfo then
			PackActionButtons.BuyRobux.Label.Text = productInfo.PriceInRobux
		end
	end
end)

Remotes.BuyShopPack.OnClientEvent:Connect(function(packType, amount)
	if ViewPacksFrame.PackType.Value == packType then
		PackActionButtons.OpenButton.Label.Text = "Open ("..amount..")"
		PackActionButtons.OpenButton.Visible = true
	end
end)

Remotes.OpenShopPack.OnClientEvent:Connect(function(packType, amount)
	if ViewPacksFrame.PackType.Value == packType then
		PackActionButtons.OpenButton.Label.Text = "Open ("..amount..")"

		if amount < 1 then
			PackActionButtons.OpenButton.Visible = false
		end
	end
end)

for _, coinsButton in pairs(CashFrame.Frame:GetChildren()) do
	if coinsButton:IsA("ImageButton") then
		GuiAnimationModule.SetupGrowButton(coinsButton)
		
		local success, productInfo = pcall(function()
			return MarketplaceService:GetProductInfo(coinsButton.ProductID.Value, Enum.InfoType.Product)
		end)
		
		if success and productInfo then
			coinsButton.RobuxLabel.Text = productInfo.PriceInRobux
		end
		
		coinsButton.MouseButton1Click:Connect(function()
			GuiAnimationModule.ButtonPress(player, "PositiveClick")
			PurchaseEvents.DevProductPurchase:FireServer(coinsButton.ProductID.Value)
		end)
	end
end

for _, gamepassButton in pairs(GamePassFrame.Frame:GetChildren()) do
	if gamepassButton:IsA("ImageButton") then
		local success, productInfo = pcall(function()
			return MarketplaceService:GetProductInfo(gamepassButton.ProductID.Value, Enum.InfoType.GamePass)
		end)
		
		if success and productInfo then
			local success, ownsPass = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassButton.ProductID.Value)
			end)
			
			if success and ownsPass then
				gamepassButton.OwnedIcon.Visible = true
			end

			gamepassButton.RobuxLabel.Text = productInfo.PriceInRobux
		end
		
		GuiAnimationModule.SetupGrowButton(gamepassButton)
		
		gamepassButton.MouseButton1Click:Connect(function()
			GuiAnimationModule.ButtonPress(player, "PositiveClick")
			PurchaseEvents.GamePassPurchase:FireServer(gamepassButton.ProductID.Value)
		end)
	end
end

PurchaseEvents.GamePassPurchase.OnClientEvent:Connect(function(assetId)
	for _, gamepassButton in pairs(GamePassFrame.Frame:GetChildren()) do
		if gamepassButton:IsA("ImageButton") and gamepassButton.ProductID.Value == assetId then
			gamepassButton.OwnedIcon.Visible = true
			break
		end
	end
end)

-- Gear Shop
local currentlySelectedGearButton = GearButtons.Wristband

local function clearGearContainer()
	for _, button in pairs(GearFrame.GearContainer:GetChildren()) do
		if button:IsA("Frame") then
			button:Destroy()
		end
	end
	
	if gearViewportModelRenderStepped ~= nil then
		gearViewportModelRenderStepped:Disconnect()
		gearViewportModelRenderStepped = nil
	end

	gearViewportModels = {}
end

local function setGearButtonToOwned(gearViewport)
	gearViewport.BuyCash.Label.Text = "OWNED"
	gearViewport.BuyCash.Logo:Destroy()
	gearViewport.BuyCash.Label.Size = UDim2.new(0.8, 0, 0.8, 0)
	gearViewport.BuyCash.Label.Position = UDim2.new(0.5, 0, 0.5, 0)
	gearViewport.BuyCash.BackgroundColor3 = Color3.fromRGB(0, 136, 204)
	gearViewport.BuyCash.Active = false
	gearViewport.BuyCash.AutoButtonColor = false
	gearViewport.BuyCash.Interactable = false
end

local function sortGearItems(gearItems)
	local sortedGearList = {}

	for itemName, itemInfo in pairs(gearItems) do
		table.insert(sortedGearList, {
			Name = itemName,
			Price = itemInfo.Price,
			Data = itemInfo -- Optionally keep original info
		})
	end

	table.sort(sortedGearList, function(a, b)
		return a.Price > b.Price
	end)

	return sortedGearList
end

local function setupGearFrame(gearType)
	local inventory = Remotes.GetGearInventory:InvokeServer(gearType)
	
	if inventory == nil then
		repeat
			wait(1)
			inventory = Remotes.GetGearInventory:InvokeServer(gearType)
		until inventory ~= nil
	end
	
	local sortedGearList = sortGearItems(GearItemsModule[gearType])
	
	for _, itemInfo in pairs(sortedGearList) do
		if itemInfo.Data.Available then
			local itemName = itemInfo.Name
			
			local gearViewport = script.GearViewport:Clone()
			gearViewport.Name = itemName
			gearViewport.ItemName.Text = itemName
			
			if table.find(inventory, itemName) then
				setGearButtonToOwned(gearViewport)
			else
				gearViewport.BuyCash.Label.Text = ClientFunctions.ConvertShort(itemInfo.Price)
				
				GuiAnimationModule.SetupShrinkButton(gearViewport.BuyCash)
				
				gearViewport.BuyCash.MouseButton1Click:Connect(function()
					if gearViewport.BuyCash.Label.Text ~= "OWNED" then
						GuiAnimationModule.ButtonPress(player, "PositiveClick")
						
						Remotes.BuyGearItem:FireServer(gearType, itemName)
					end
				end)
			end

			local viewModel = Instance.new("Model")
			viewModel.Name = "ViewModel"
			local referenceModel = GearItems[gearType][itemName]

			if referenceModel:IsA("Model") then
				for _, part in pairs(referenceModel:GetChildren()) do
					if part:IsA("MeshPart") or part:IsA("BasePart") then
						part:Clone().Parent = viewModel
					end
				end
			elseif referenceModel:IsA("MeshPart") or referenceModel:IsA("BasePart") then
				referenceModel:Clone().Parent = viewModel
			end

			local camera = Instance.new("Camera")
			camera.FieldOfView = 70
			camera.Parent = gearViewport.ViewportFrame

			viewModel.Parent = gearViewport.ViewportFrame
			gearViewport.ViewportFrame.CurrentCamera = camera
			
			gearViewport.Parent = GearFrame.GearContainer

			gearViewportModels[itemName] = {ViewportSetup = ViewportModelModule.new(gearViewport.ViewportFrame, camera), Theta = 0}

			gearViewportModels[itemName].ViewportSetup:SetModel(viewModel)
		end
	end
	
	local orientation = CFrame.new()

	gearViewportModelRenderStepped = game:GetService("RunService").RenderStepped:Connect(function(dt)
		for _, packDisplay in pairs(GearFrame.GearContainer:GetChildren()) do
			if packDisplay:IsA("Frame") then
				local cf, size = packDisplay.ViewportFrame.ViewModel:GetBoundingBox()
				local distance = gearViewportModels[packDisplay.Name].ViewportSetup:GetFitDistance(cf.Position)

				gearViewportModels[packDisplay.Name].Theta = gearViewportModels[packDisplay.Name].Theta + math.rad(20 * dt)
				orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), gearViewportModels[packDisplay.Name].Theta, 0)
				packDisplay.ViewportFrame.Camera.CFrame = CFrame.new(cf.Position) * orientation * CFrame.new(0, 0, distance)
			end
		end
	end)
end

Remotes.BuyGearItem.OnClientEvent:Connect(function(gearType, gearItem)
	if GearFrame.GearContainer:FindFirstChild(gearItem) then
		setGearButtonToOwned(GearFrame.GearContainer[gearItem])
	end
end)

for _, button in pairs(GearButtons:GetChildren()) do
	if button:IsA("TextButton") then
		GuiAnimationModule.SetupShrinkButton(button)
		
		button.MouseButton1Click:Connect(function()
			GuiAnimationModule.ButtonPress(player, "PositiveClick")
			
			if currentlySelectedGearButton then
				clearGearContainer()
				currentlySelectedGearButton.BackgroundColor3 = Color3.fromRGB(170, 255, 255)
				currentlySelectedGearButton.UIStroke.Color = Color3.fromRGB(255, 255, 255)
			end

			currentlySelectedGearButton = button
			button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			button.UIStroke.Color = Color3.fromRGB(0, 255, 255)
			
			setupGearFrame(button.Name)
		end)
	end
end

setupGearFrame("Wristband")