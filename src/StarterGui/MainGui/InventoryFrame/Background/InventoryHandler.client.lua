local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")

local SharedDataFolder = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local Remotes = ReplicatedStorage.RemoteEvents
local GameValues = ReplicatedStorage.GameValues
local CurrentGameStatsFolder = ReplicatedStorage.CurrentGameStats
local SharedGUIs = ReplicatedStorage.SharedGUIs

local ViewportModelModule = require(SharedModules.ViewportModel)
local GuiAnimationModule = require(SharedModules.GuiAnimation)
local ShopPackItems = require(SharedModules.ShopPackItems)
local ShopPackTypesModule = require(SharedModules.ShopPackTypes)
local RarityProbability = require(SharedModules.RarityProbability)

local player = Players.LocalPlayer

local InventoryFrame = script.Parent.InventoryFrame
local SortButtons = InventoryFrame.Background.Sort
local InventoryContainer = InventoryFrame.Container
local SellButton = InventoryFrame.Sell
local ExitButton = script.Parent.ExitButton

GuiAnimationModule.ExitButtonPressed(player, script.Parent.Parent, ExitButton)

local sellMode = false
local viewportModelRenderStepped = nil
local viewportModels = {}
local currentSortSelected = "Bat"

local playerData = SharedDataFolder:WaitForChild(player.Name, 3)
if playerData then
	local foundCharacter = playerData:WaitForChild("EmoteShopDisplayCharacter", 3)
		
	if foundCharacter then 
		displayCharacter = foundCharacter:Clone()
	end
end

GuiAnimationModule.SetupShrinkButton(SellButton)

SellButton.MouseButton1Click:Connect(function()
	if currentSortSelected == "Bat" or currentSortSelected == "Trail" or currentSortSelected == "Glove" or currentSortSelected == "Emote" or currentSortSelected == "Explosion" then
		sellMode = not sellMode
		
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		
		for i,v in pairs (InventoryContainer.ItemHolder:GetChildren()) do
			if v:IsA("TextButton") and v.Name ~= "Wooden Bat" and v.Name ~= "Old Glove" and v.Name ~= "Normal Trail" and v.Name ~= "Fireworks" and v.Sell.TextLabel.Text ~= "Sell: 0" then
				print("make visible?")
				v.Sell.Visible = sellMode
			end
		end
	end
end)

local rarityOrder = {
	Legendary = {order = 1, color = Color3.fromRGB(255, 170, 0)}, 
	Epic = {order = 2, color = Color3.fromRGB(170, 85, 255)}, 
	Rare = {order = 3, color = Color3.fromRGB(0, 255, 255)}, 
	Uncommon = {order = 4, color = Color3.fromRGB(85, 255, 0)}, 
	Common = {order = 5, color = Color3.fromRGB(229, 229, 229)},
}

local function findRarityByName(itemName)
	for i,v in pairs (ShopPackItems) do
		if type(v) == "table" then
			for name, details in pairs(v) do
				if name == itemName and details.Rarity then
 					return details.Rarity
				end
			end
		end		
	end	
end

local function findPackTypeByItemName(itemName)
	for i,v in pairs (ShopPackItems) do
		if type(v) == "table" then
			for name, details in pairs(v) do
				if name == itemName then
					return i
				end
			end
		end		
	end	
end

local function findIconByName(itemName)
    for i, v in pairs(ShopPackItems) do
        if type(v) == "table" then
            for name, details in pairs(v) do
                if name == itemName and details.Icon then
                    return details.Icon
                end
            end
        end
    end
end

local function sortItemsByRarity(inventoryData)
	local sortedItems = {}
	
	for itemName, quantity in pairs(inventoryData) do
		local itemRarity = findRarityByName(itemName) 
		table.insert(sortedItems, {
			name = itemName,
			quantity = quantity,
			rarity = itemRarity
		})
	end
	
	table.sort(sortedItems, function(a, b)
		local rarityA = a.rarity
		local rarityB = b.rarity
		local orderA = rarityOrder[rarityA] and rarityOrder[rarityA].order 
		local orderB = rarityOrder[rarityB] and rarityOrder[rarityB].order 
		return orderA < orderB
	end)
	
	return sortedItems
end

local function setupEmoteViewport(itemFrame, itemName)
	if displayCharacter then
		local emotes = ReplicatedStorage:WaitForChild("ShopItems"):WaitForChild(currentSortSelected)

		local worldModel = Instance.new("WorldModel")
		worldModel.Name = "ViewModel"
		local dummy = displayCharacter:Clone()
		dummy.Name = "ViewModel"

		local animateScript = dummy:FindFirstChild("Animate")
		if animateScript then
			animateScript:Destroy() -- Remove default animations
		end

		local animation = Instance.new("Animation")
		animation.AnimationId = emotes[itemName].AnimationId

		local camera = Instance.new("Camera")
		camera.FieldOfView = 70
		camera.Parent = itemFrame.ViewportFrame

		worldModel.Parent = itemFrame.ViewportFrame
		dummy.Parent = worldModel

		itemFrame.ViewportFrame.CurrentCamera = camera

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

		viewportModels[itemName] = {ViewportSetup = ViewportModelModule.new(itemFrame.ViewportFrame, camera), Theta = math.pi}
		viewportModels[itemName].ViewportSetup:SetModel(worldModel)
	end
end

local function setupViewport(itemFrame, itemName, shopType)
	local Models;
	
	if shopType == "Pack" then
		Models = ReplicatedStorage:WaitForChild("ShopItems"):WaitForChild(currentSortSelected)
	elseif shopType == "Gear" then
		Models = ReplicatedStorage:WaitForChild("Gear"):WaitForChild(currentSortSelected)
	end
	
	local model = Models:FindFirstChild(itemName)

	if not model then
		print("Model not found")
		return
	end

	
	local clonedModel;
	
	if model:IsA("BasePart") or model:IsA("MeshPart") then
		clonedModel = Instance.new("Model")
		model:Clone().Parent = clonedModel
	else
		clonedModel = model:Clone()
	end
	clonedModel.Name = "ViewModel"
	local camera = Instance.new("Camera")
	camera.FieldOfView = 70
	camera.Parent = itemFrame.ViewportFrame

	itemFrame.ViewportFrame.CurrentCamera = camera
	clonedModel.Parent = itemFrame.ViewportFrame
	
	viewportModels[itemName] = {ViewportSetup = ViewportModelModule.new(itemFrame.ViewportFrame, camera), Theta = 0}

	viewportModels[itemName].ViewportSetup:SetModel(clonedModel)
	
	local cf = clonedModel:GetBoundingBox()
	local distance = viewportModels[itemName].ViewportSetup:GetFitDistance(cf.Position)
	camera.CFrame = CFrame.new(cf.Position + Vector3.new(0, 0, distance), cf.Position)
end

local function startViewportRenderstepped()
	local orientation = CFrame.new()

	viewportModelRenderStepped = game:GetService("RunService").RenderStepped:Connect(function(dt)
		for _, button in pairs(InventoryContainer.ItemHolder:GetChildren()) do
			if button:IsA("TextButton") and viewportModels[button.Name] ~= nil then
				local cf, size = button.ViewportFrame.ViewModel:GetBoundingBox()
				local distance = viewportModels[button.Name].ViewportSetup:GetFitDistance(cf.Position)

				viewportModels[button.Name].Theta = viewportModels[button.Name].Theta + math.rad(20 * dt)
				orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), viewportModels[button.Name].Theta, 0)
				button.ViewportFrame.Camera.CFrame = CFrame.new(cf.Position) * orientation * CFrame.new(0, 0, distance)
			end
		end
	end)
end

local function clearItemContainer()
	for _, child in ipairs(InventoryContainer.ItemHolder:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	if viewportModelRenderStepped ~= nil then
		viewportModelRenderStepped:Disconnect()
		viewportModelRenderStepped = nil
	end

	viewportModels = {}
end

local function equipItem(itemName, shopType)
	Remotes.EquipItem:FireServer(currentSortSelected, itemName, shopType)

	for i, itemFrame in ipairs(InventoryContainer.ItemHolder:GetChildren()) do
		if itemFrame:IsA("TextButton") and itemFrame:FindFirstChild("EquippedCheck") then
			itemFrame.EquippedCheck.Visible = false
		end
	end

	local itemFrame = InventoryContainer.ItemHolder:FindFirstChild(itemName)
	if itemFrame and itemFrame:FindFirstChild("EquippedCheck") then
		itemFrame.EquippedCheck.Visible = true
	end
end

local function calculateSellPrice(item)
	local Rarity = findRarityByName(item)
	local packType = findPackTypeByItemName(item)
	if Rarity and packType then
		if ShopPackTypesModule[packType] then
			return ShopPackTypesModule[packType].Price * RarityProbability.ResaleValue[Rarity]
		else
			return 0
		end
	end
end


local function showInventoryItems(itemType, inventoryData, equippedItem)
	clearItemContainer()
	
	sellMode = false

    local ItemTemplate = game.ReplicatedStorage.SharedGUIs.Item
    local sortedItems = sortItemsByRarity(inventoryData)

	for i, item in ipairs(sortedItems) do
        local itemName = item.name
        local itemDetails = item.quantity

        local itemFrame = ItemTemplate:Clone()
        itemFrame.Name = itemName
        itemFrame.Parent = InventoryContainer.ItemHolder

        itemFrame.ItemName.Text = itemName
        if itemDetails > 1 then
            itemFrame.Rarity.Text = "Owned: " .. itemDetails
        else
            itemFrame.Rarity.Text = ""
        end

		local itemRarity = findRarityByName(itemName)
		itemFrame.UIGradientPack.Enabled = true
		itemFrame.UIStroke.UIGradient:Destroy()
		local uiGradient = SharedGUIs.StylesUI["UIGradient"..itemRarity]:Clone()
		uiGradient.Rotation = 90
		uiGradient.Parent = itemFrame.UIStroke
		
        local rarityData = rarityOrder[itemRarity]
        itemFrame.BackgroundColor3 = rarityData.color

        if itemType == "Trail" or itemType == "Explosion" then
            local icon = findIconByName(itemName)
            if icon then
                itemFrame.ImageLabel.Image = icon
                itemFrame.ImageLabel.Visible = true
                itemFrame.ViewportFrame.Visible = false
			end
		elseif itemType == "Emote" then
			itemFrame.ImageLabel.Visible = false
			itemFrame.ViewportFrame.Visible = true
			setupEmoteViewport(itemFrame, itemName)
        else
            itemFrame.ImageLabel.Visible = false
            itemFrame.ViewportFrame.Visible = true
            setupViewport(itemFrame, itemName, "Pack")
        end

        if equippedItem == itemName then
            itemFrame.EquippedCheck.Visible = true
        else
            itemFrame.EquippedCheck.Visible = false
        end

		local sellPrice = calculateSellPrice(itemName)
		
		if sellPrice > 0 then
			itemFrame.Sell.TextLabel.Text = "Sell: " .. sellPrice
			
			GuiAnimationModule.SetupShrinkButton(itemFrame.Sell)

			itemFrame.Sell.MouseButton1Click:Connect(function()
				GuiAnimationModule.ButtonPress(player, "PositiveClick")
	            local success, inventoryData, equippedItem = pcall(function()
	                return Remotes.GetInventory:InvokeServer(currentSortSelected)
	            end)

	            if equippedItem == itemName then
	                if itemDetails > 1 then
	                    itemFrame.Rarity.Text = "Owned: " .. itemDetails
	                else
	                    if currentSortSelected == "Bat" then
	                        equipItem("Wooden Bat", "Pack")
	                    elseif currentSortSelected == "Glove" then
							equipItem("Old Glove", "Pack")
	                    elseif currentSortSelected == "Trail" then
							equipItem("Normal Trail", "Pack")
						elseif currentSortSelected == "Explosion" then
							equipItem("Fireworks", "Pack")
	                    end
	                end
	            end

	            Remotes.SellItem:FireServer(itemType, itemName)
			end)
		end

        itemFrame.MouseButton1Click:Connect(function()
            if not sellMode then
                GuiAnimationModule.ButtonPress(player, "PositiveClick")
                equipItem(itemName, "Pack")
            end
        end)
    end

    startViewportRenderstepped()
end

local function showGearInventory(gearType, gearInventory, equippedGear)
	clearItemContainer()
	
	local removeButton = SharedGUIs.Item:Clone()
	removeButton.ItemName.Text = "No "..gearType
	removeButton.Name = ""
	removeButton.UIGradientGear.Enabled = true
	removeButton.Icon.Visible = true
	removeButton.Rarity:Destroy()
	removeButton.Icon.Image = "http://www.roblox.com/asset/?id=73784415340496"
	removeButton.Parent = InventoryContainer.ItemHolder
	
	if equippedGear == removeButton.Name then
		removeButton.EquippedCheck.Visible = true
	end
	
	removeButton.MouseButton1Click:Connect(function()
		GuiAnimationModule.ButtonPress(player, "PositiveClick")

		equipItem(removeButton.Name, "Gear")
	end)
	
	for _, gearItem in pairs(gearInventory) do
		local gearButton = SharedGUIs.Item:Clone()
		gearButton.ItemName.Text = gearItem
		gearButton.UIGradientGear.Enabled = true
		gearButton.Name = gearItem
		gearButton.Rarity:Destroy()
		gearButton.Parent = InventoryContainer.ItemHolder
		
		setupViewport(gearButton, gearItem, "Gear")
		
		if equippedGear == gearButton.Name then
			gearButton.EquippedCheck.Visible = true
		end
		
		gearButton.MouseButton1Click:Connect(function()
			GuiAnimationModule.ButtonPress(player, "PositiveClick")
			
			equipItem(gearItem, "Gear")
		end)
	end
	
	startViewportRenderstepped()
end

local function ShowInventory()
	if currentSortSelected then
		if currentSortSelected == "Emote" or currentSortSelected == "BattingGlove" then
			InventoryContainer.NoticeLabel.Visible = true
			
			if currentSortSelected == "Emote" then
				InventoryContainer.NoticeLabel.Text = "Equipped emotes appear if you earn an MVP award in the post-game results"
			elseif currentSortSelected == "BattingGlove" then
				InventoryContainer.NoticeLabel.Text = "Equipped batting gloves appear when you are at-bat"
			end
		else
			InventoryContainer.NoticeLabel.Visible = false
		end
		
		if currentSortSelected == "Bat" or currentSortSelected == "Glove" or currentSortSelected == "Trail" or currentSortSelected == "Emote" or currentSortSelected == "Explosion" then -- PACK
			local success, inventoryData, equippedItem = pcall(function()
				return Remotes.GetInventory:InvokeServer(currentSortSelected)
			end)

			if success and inventoryData then
	            showInventoryItems(currentSortSelected, inventoryData, equippedItem)
			end
		else -- GEAR
			local gearInventory, equippedGear = Remotes.GetGearInventory:InvokeServer(currentSortSelected)
			
			if gearInventory and equippedGear then
				showGearInventory(currentSortSelected, gearInventory, equippedGear)
			end
		end
    end
end

ShowInventory()

local sortButtonsTable = {
	"Bat",
	"Glove",
	"Trail",
	"Emote",
	"Explosion",
	"Wristband",
	"BattingGlove"
}


local buttonPressed = false

for i, button in pairs(sortButtonsTable) do
	local button = SortButtons:FindFirstChild(button)
	if button:IsA("TextButton") then
		GuiAnimationModule.SetupShrinkButton(button)
		button.MouseButton1Click:Connect(function()
			if button.Name ~= currentSortSelected and not buttonPressed then
				buttonPressed = true
				GuiAnimationModule.ButtonPress(player, "PositiveClick")
				
				SortButtons[currentSortSelected].BackgroundColor3 = Color3.fromRGB(170, 255, 255)
				SortButtons[currentSortSelected].UIStroke.Color = Color3.fromRGB(255, 255, 255)
				currentSortSelected = button.Name
				SortButtons[currentSortSelected].BackgroundColor3 = Color3.fromRGB(0, 170, 255)
				SortButtons[currentSortSelected].UIStroke.Color = Color3.fromRGB(0, 255, 255)
				pcall(function()
					sellMode = false
					InventoryContainer.Visible = true
					ShowInventory()
				end)
				buttonPressed = false
			end
		end) 
	end
end

Remotes.UpdateInventory.OnClientEvent:Connect(function(itemType)
	if currentSortSelected == itemType then
		ShowInventory()
	end
end)