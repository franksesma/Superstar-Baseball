local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local UserInputService = game:GetService("UserInputService")

local Remotes = ReplicatedStorage.RemoteEvents
local SharedDataFolder = ReplicatedStorage.SharedData
local SharedModules = ReplicatedStorage.SharedModules
local SharedUI = ReplicatedStorage.SharedGUIs
local PurchaseEvents = ReplicatedStorage.PurchaseEvents
local GameValues = ReplicatedStorage.GameValues
local CameraValues = GameValues.CameraValues

local StylesModule = require(SharedModules.Styles)
local RarityProbability = require(SharedModules.RarityProbability)
local ClientFunctions = require(SharedModules.ClientFunctions)
local GuiAnimationModule = require(SharedModules.GuiAnimation)
local SpinCostsModule = require(SharedModules.SpinCosts)

local StyleSubFrame = script.Parent.StyleSubFrame
local SpinsPurchaseFrame = script.Parent.SpinsPurchaseFrame
local SpinConfirmationFrame = script.Parent.SpinConfirmation
local SpinsPurchaseButtons = SpinsPurchaseFrame.Background.ButtonsFrame
local RarityChancesFrame = StyleSubFrame.RarityChances.ItemHolder
local ButtonsFrame = StyleSubFrame.ButtonsFrame
local SpinFrame = StyleSubFrame.SpinFrame
local StyleInfoFrame = StyleSubFrame.StyleInfo
local StyleInventory = StyleSubFrame.StyleInventory
local ExitButton = StyleSubFrame.ExitButton
local SlotGiftButton = StyleSubFrame.GiftButton
local NormalOddsButton = StyleSubFrame.NormalOdds
local LuckyOddsButton = StyleSubFrame.LuckyOdds
local LimitedStylesButton = StyleSubFrame.LimitedStyles
local LimitedStylesInventoryFrame = StyleSubFrame.LimitedStylesFrame
local LimitedStylesInventoryFrameScrollingFrame = LimitedStylesInventoryFrame.Background.Container.ItemHolder

local player = Players.LocalPlayer
local currentStyleTypeSelected = "Offensive"
local playerDataFolder = SharedDataFolder:WaitForChild(player.Name)

local spinning = false
local spinningType = "Normal"
local paidRandomItemsBanned = false
local currentlyViewedOdds = "Normal"
local currentSpinPreference = ""
local currentEquippedStyleName = nil
local pendingSpinType = nil
local pendingStyleType = nil

local success, result = pcall(function()
	return PolicyService:GetPolicyInfoForPlayerAsync(player)
end)

if success and result.ArePaidRandomItemsRestricted then
	paidRandomItemsBanned = true
end

local rarityRank = {}
do
	for i, rarity in ipairs(RarityProbability.StylesRarityList) do
		rarityRank[rarity] = i
	end
end

local function isMythicOrHigher(rarity: string?)
	return rarity == "Mythic" or rarity == "Superstar"
end

local function getEquippedRarity(styleType: string)
	if not currentEquippedStyleName then return nil end
	local stylesForType = StylesModule[styleType.."Styles"]
	local info = stylesForType and stylesForType[currentEquippedStyleName]
	return info and info.Rarity or nil
end

local function openSpinConfirmation(styleType: string, spinType: string)
	pendingStyleType = styleType
	pendingSpinType = spinType

	-- optional UI text fill if you have these labels
	local rarity = getEquippedRarity(styleType)
	local name = currentEquippedStyleName

	local sub = SpinConfirmationFrame.Background
	local title = sub:FindFirstChild("Title")
	local desc = sub:FindFirstChild("Description")

	if title and title:IsA("TextLabel") then
		title.Text = "⚠️ Replace Your Current Style?"
	end

	if desc and desc:IsA("TextLabel") then
		if name and rarity then
			desc.Text = ("You’re about to spin away from your %s %s.\nThis cannot be undone."):format(string.upper(rarity), name)
		else
			desc.Text = "You’re about to spin again.\nThis will replace your current style."
		end
	end

	SpinConfirmationFrame.Visible = true
end

local function closeSpinConfirmation()
	SpinConfirmationFrame.Visible = false
	pendingStyleType = nil
	pendingSpinType = nil
end

local function showRarityList(styleType)
	for _, guiObject in pairs(RarityChancesFrame:GetChildren()) do
		if guiObject:IsA("TextButton") or guiObject:IsA("TextLabel") then
			guiObject:Destroy()
		end
	end

	local stylesForType = StylesModule[styleType.."Styles"]
	local function rarityHasAvailableStyle(rarity)
		for _, styleInfo in pairs(stylesForType) do
			if styleInfo.Rarity == rarity and (styleInfo.Available ~= false) then
				return true
			end
		end
		return false
	end

	-- choose which chance table to use
	local chanceTable
	if currentlyViewedOdds == "Lucky" then
		chanceTable = RarityProbability.StylesLuckyProbability
	else
		chanceTable = RarityProbability.StylesProbability
	end

	for _, rarity in ipairs(RarityProbability.StylesRarityList) do
		local chance = chanceTable and chanceTable[rarity]

		if chance and chance > 0 and rarityHasAvailableStyle(rarity) then
			local rarityButton = script.RarityButton:Clone()
			rarityButton.Name = rarity

			SharedUI.StylesUI["UIGradient"..rarity]:Clone().Parent = rarityButton.UIStroke

			rarityButton.RarityLabel.Text = string.upper(rarity).." ("..chance.."%)"
			rarityButton.BackgroundColor3 = RarityProbability.Colors[rarity]
			rarityButton.Parent = RarityChancesFrame

			for styleName, styleInfo in pairs(stylesForType) do
				if styleInfo.Rarity == rarity and (styleInfo.Available ~= false) then
					local styleLabel = script.StyleLabel:Clone()
					styleLabel.Name = styleName
					styleLabel.Label.Text = styleName
					styleLabel.Visible = false
					styleLabel.Parent = RarityChancesFrame

					if currentSpinPreference == styleName then
						styleLabel.Label.Text = "> "..styleName.." <"
					end

					SharedUI.StylesUI["UIGradient"..rarity]:Clone().Parent = styleLabel.Label

					GuiAnimationModule.SetupGrowButton(styleLabel)

					styleLabel.Activated:Connect(function()
						GuiAnimationModule.ButtonPress(player, "PositiveClick")
						Remotes.SelectPreference:FireServer(styleType, styleName)
					end)

					styleLabel:SetAttribute("StyleLabelButton", true)
				end
			end

			rarityButton:SetAttribute("RarityButton", true)
			rarityButton.Hidden.Value = true

			GuiAnimationModule.SetupShrinkButton(rarityButton)

			rarityButton.MouseButton1Click:Connect(function()
				GuiAnimationModule.ButtonPress(player, "PositiveClick")

				rarityButton.Hidden.Value = not rarityButton.Hidden.Value

				for _, rarityLabel in pairs(RarityChancesFrame:GetChildren()) do
					if rarityLabel:GetAttribute("StyleLabelButton") then
						local info = StylesModule[styleType.."Styles"][rarityLabel.Name]
						if info and info.Rarity == rarity then
							rarityLabel.Visible = not rarityButton.Hidden.Value
						else
							rarityLabel.Visible = false
						end
					elseif rarityLabel:GetAttribute("RarityButton") and rarityLabel ~= rarityButton then
						rarityLabel.Hidden.Value = true
						rarityLabel.DropdownIcon.Image = "http://www.roblox.com/asset/?id=129771845643086"
					end
				end

				if rarityButton.Hidden.Value then
					rarityButton.DropdownIcon.Image = "http://www.roblox.com/asset/?id=129771845643086"
				else
					rarityButton.DropdownIcon.Image = "http://www.roblox.com/asset/?id=98347577969495"
				end
			end)
		end
	end
end


local function updateAbilityInfo(styleType, styleName)
	StyleInfoFrame.StyleName.Text = styleName.." ("..StylesModule[styleType.."Styles"][styleName].SubType..")"
	StyleInfoFrame.StyleName.TextColor3 = RarityProbability.Colors[StylesModule[styleType.."Styles"][styleName].Rarity]
	StyleInfoFrame.UltimateTitle.Text = StylesModule[styleType.."Styles"][styleName].Ultimate..":"
	StyleInfoFrame.UltimateDescription.Text = StylesModule[styleType.."Styles"][styleName].UltimateDescription
	
	if StylesModule[styleType.."Styles"][styleName].SubType == "Pitching" then
		local abilitiesString = table.concat(StylesModule[styleType.."Styles"][styleName].PitchAbilities, ", ")
		
		StyleInfoFrame.AbilityTitle.Text = "Pitches:"
		StyleInfoFrame.AbilityDescription.Text = abilitiesString
	else
		StyleInfoFrame.AbilityTitle.Text = StylesModule[styleType.."Styles"][styleName].Ability..":"
		StyleInfoFrame.AbilityDescription.Text = StylesModule[styleType.."Styles"][styleName].AbilityDescription
	end
end

local function showCharacterPowerUp()
	local stylesLockerCharacter = workspace.StylesLocker:FindFirstChild("StylesLockerCharacter")
	if stylesLockerCharacter 
		and stylesLockerCharacter:FindFirstChild("Humanoid") 
		and stylesLockerCharacter.Humanoid:FindFirstChild("Animator")
	then
		local humanoid = stylesLockerCharacter.Humanoid
		local characterAnimations = player.Character.Animate.Animations
		local stylePowerUpAnim = humanoid.Animator:LoadAnimation(characterAnimations.Actions.StylePowerUp)

		for _, object in pairs(stylesLockerCharacter.HumanoidRootPart.AbilityTransformationEffects:GetDescendants()) do
			if object:IsA("ParticleEmitter") or object:IsA("PointLight") then
				object.Enabled = true
			elseif object:IsA("Attachment") then
				for _, particle in pairs(object:GetDescendants()) do
					if particle:IsA("ParticleEmitter") then
						particle.Enabled = true
					end
				end
			end
		end
		stylesLockerCharacter.HumanoidRootPart.AbilityTransformationEffects.Sound.Volume = 0.05
		stylesLockerCharacter.HumanoidRootPart.AbilityTransformationEffects.Sound:Play()
		spawn(function()
			wait(3)
			if stylesLockerCharacter and stylesLockerCharacter:FindFirstChild("HumanoidRootPart") then
				for _, object in pairs(stylesLockerCharacter.HumanoidRootPart.AbilityTransformationEffects:GetDescendants()) do
					if object:IsA("ParticleEmitter") or object:IsA("PointLight") then
						object.Enabled = false
					elseif object:IsA("Attachment") then
						for _, particle in pairs(object:GetDescendants()) do
							if particle:IsA("ParticleEmitter") then
								particle.Enabled = false
							end
						end
					end
				end
			end
		end)
		
		stylePowerUpAnim:Play()
	end
end

local function setupLimitedInventory(styleType, limitedInventory, equippedLimitedStyleName)
	for _, guiObject in pairs(LimitedStylesInventoryFrameScrollingFrame:GetChildren()) do
		if guiObject:IsA("Frame") then
			guiObject:Destroy()
		end
	end

	-- no limited styles owned
	if not limitedInventory then return end

	for styleName, count in pairs(limitedInventory) do
		local styleInfo = StylesModule[styleType.."Styles"][styleName]
		if styleInfo then
			local rarity = styleInfo.Rarity
			local frame = script.LimitedStyleInventoryButtonFrame:Clone()
			frame.Name = styleName

			local styleButton = frame.StyleButton
			styleButton.StyleName.Text = styleName
			styleButton.BackgroundColor3 = RarityProbability.Colors[rarity]
			styleButton[styleType.."StyleIcon"].Visible = true
			if SharedUI.StylesUI:FindFirstChild("UIGradient"..rarity) then
				SharedUI.StylesUI["UIGradient"..rarity]:Clone().Parent = styleButton.UIStroke
				SharedUI.StylesUI["UIGradient"..rarity]:Clone().Parent = styleButton.StyleName
			end

			-- if your Limited frame has a count label, update it
			if frame:FindFirstChild("CountLabel") then
				frame.CountLabel.Text = "x"..tostring(count)
			end

			-- show EQUIPPED for the currently active limited style
			if equippedLimitedStyleName == styleName then
				styleButton.ActionLabel.Visible = true
				styleButton.ActionLabel.Text = "EQUIPPED"
			else
				styleButton.ActionLabel.Visible = false
			end

			GuiAnimationModule.SetupShrinkButton(styleButton)

			styleButton.MouseButton1Click:Connect(function()
				if spinning then return end

				GuiAnimationModule.ButtonPress(player, "PositiveClick")

				Remotes.EquipLimitedStyle:FireServer(styleType, styleName)

				-- update labels locally instantly
				for _, other in pairs(LimitedStylesInventoryFrameScrollingFrame:GetChildren()) do
					if other:IsA("Frame") and other:FindFirstChild("StyleButton") then
						other.StyleButton.ActionLabel.Visible = false
					end
				end

				styleButton.ActionLabel.Visible = true
				styleButton.ActionLabel.Text = "EQUIPPED"
				updateAbilityInfo(styleType, styleName)
				
				currentEquippedStyleName = styleName
				
				showCharacterPowerUp()
			end)

			frame.Parent = LimitedStylesInventoryFrameScrollingFrame
		end
	end
end

local function setupInventory(equippedStyle, styleInventory, styleType, equippedSlotNum, equippedLimitedStyleName)
	--local oldCanvasPosition = 
	for _, guiObject in pairs(StyleInventory.Container.ItemHolder:GetChildren()) do
		if guiObject:IsA("Frame") then
			guiObject:Destroy()
		end
	end
	
	--StyleInventory.Container.ItemHolder.CanvasPosition = Vector2.new(0,0)
	
	local MAX_SLOTS = 6
	local ownedSlots = playerDataFolder[styleType.."StyleSlots"].Value
	local unpurchasedSlots = MAX_SLOTS - ownedSlots
	
	for i = 1, MAX_SLOTS do
		if i <= ownedSlots then
			if styleInventory[i] ~= nil then
				local styleInventoryButtonFrame = script.StyleInventoryButtonFrame:Clone()
				styleInventoryButtonFrame.Name = i
				styleInventoryButtonFrame.SlotNumber.Value = i
				
				local rarity = StylesModule[styleType.."Styles"][styleInventory[i].StyleName].Rarity
				
				local styleEquipButton = styleInventoryButtonFrame.StyleButton
				styleEquipButton[styleType.."StyleIcon"].Visible = true
				styleEquipButton.StyleName.Text = styleInventory[i].StyleName
				styleEquipButton.BackgroundColor3 = RarityProbability.Colors[StylesModule[styleType.."Styles"][styleInventory[i].StyleName].Rarity]
				SharedUI.StylesUI["UIGradient"..rarity]:Clone().Parent = styleEquipButton.UIStroke
				SharedUI.StylesUI["UIGradient"..rarity]:Clone().Parent = styleEquipButton.StyleName

				if i ~= equippedSlotNum or equippedLimitedStyleName ~= nil then
					--styleInventoryButtonFrame.LayoutOrder = 1
					
					GuiAnimationModule.SetupShrinkButton(styleEquipButton)

					styleEquipButton.MouseButton1Click:Connect(function()
						if not spinning then
							GuiAnimationModule.ButtonPress(player, "PositiveClick")
							
							Remotes.EquipStyle:FireServer(styleType, i)
							
							if (ClientFunctions.PlayerIsDefender(player) or ClientFunctions.PlayerIsBaserunner(player) or GameValues.CurrentBatter.Value == player) and GameValues.BallHit.Value then
								return
							else
								showCharacterPowerUp()
							end
						end
					end)
				else
					styleEquipButton.ActionLabel.Visible = true
					styleEquipButton.ActionLabel.Text = "EQUIPPED"
				end
				
				if styleInventory[i].Reserved then
					styleInventoryButtonFrame.ReserveButton.TextLabel.Text = "UNLOCK"
					styleInventoryButtonFrame.ReserveButton.BackgroundColor3 = Color3.fromRGB(85, 0, 0)
				end
				
				GuiAnimationModule.SetupShrinkButton(styleInventoryButtonFrame.ReserveButton)
				
				styleInventoryButtonFrame.ReserveButton.MouseButton1Click:Connect(function()
					if not spinning then
						GuiAnimationModule.ButtonPress(player, "PositiveClick")
						
						Remotes.ReserveStyle:FireServer(styleType, styleInventory[i].StyleName, i)
					end
				end)

				styleInventoryButtonFrame.Parent = StyleInventory.Container.ItemHolder
			else
				local styleInventoryButtonFrame = script.StyleInventoryButtonFrame:Clone()
				styleInventoryButtonFrame.SlotNumber.Value = i
				styleInventoryButtonFrame.ReserveButton.Visible = false
				styleInventoryButtonFrame.Name = "Empty"
				styleInventoryButtonFrame.LayoutOrder = 1
				local styleEquipButton = styleInventoryButtonFrame.StyleButton
				styleEquipButton.StyleName.Text = "Empty"
				styleEquipButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				styleInventoryButtonFrame.Parent = StyleInventory.Container.ItemHolder
			end
		else
			if StyleInventory.Container.ItemHolder:FindFirstChild("Unpurchased") == nil then
				local styleInventoryButtonFrame = script.StyleInventoryButtonFrame:Clone()
				styleInventoryButtonFrame.SlotNumber.Value = i
				styleInventoryButtonFrame.ReserveButton.Visible = false
				styleInventoryButtonFrame.Name = "Unpurchased"
				styleInventoryButtonFrame.LayoutOrder = 1
				local styleEquipButton = styleInventoryButtonFrame.StyleButton
				styleEquipButton.StyleName.Text = "LOCKED"
				styleEquipButton.ActionLabel.Visible = true
				styleEquipButton.ActionLabel.Text = "PURCHASE"
				styleEquipButton.PurchasePrice.Visible = true
				styleInventoryButtonFrame.Parent = StyleInventory.Container.ItemHolder

				local success, productInfo = pcall(function()
				 	local productID = StylesModule.SlotUpgrades[styleType][ownedSlots]
					
					if styleType == "Offensive" then
						return MarketplaceService:GetProductInfo(productID, Enum.InfoType.Product)
					else
						return MarketplaceService:GetProductInfo(productID, Enum.InfoType.Product)
					end
				end)
				
				if success and productInfo then
					styleEquipButton.PurchasePrice.Label.Text = productInfo.PriceInRobux
				end
				
				GuiAnimationModule.SetupShrinkButton(styleEquipButton)

				styleEquipButton.MouseButton1Click:Connect(function()
					if not spinning then
						GuiAnimationModule.ButtonPress(player, "PositiveClick")

						PurchaseEvents.StyleSlotUpgrade:FireServer(styleType)
					end
				end)
			end
		end
	end
end

local function setupStyleType(styleType)
	StyleSubFrame.StyleTitle.Text = "CURRENT "..string.upper(currentStyleTypeSelected).." STYLE:"
	
	local equippedStyleName, styleInventory, spinPreference, equippedStyleSlotNum, limitedInventory, equippedLimitedStyleName = Remotes.GetStyleData:InvokeServer(styleType)

	currentSpinPreference = spinPreference
	currentEquippedStyleName = equippedStyleName
	
	showRarityList(styleType)

	updateAbilityInfo(styleType, equippedStyleName)
	
	setupInventory(equippedStyleName, styleInventory, styleType, equippedStyleSlotNum, equippedLimitedStyleName)
	setupLimitedInventory(styleType, limitedInventory, equippedLimitedStyleName)
end

local function updateSpinTimer()
	local timeLeft = playerDataFolder.SpinRewardTimer.Value
	local minutes = math.floor(timeLeft / 60)
	local seconds = timeLeft % 60
	SpinFrame.FreeSpins.Label.Text = string.format("1 FREE SPIN IN %02d:%02d", minutes, seconds)

	if playerDataFolder.SpinRewardTimer.Value == 0 then
		SpinFrame.FreeSpins.Label.Text = "CLAIM 1 FREE SPIN"
	end
end

local function updatePityCounters()
	local pityCount = playerDataFolder.PityStyleSpinsCount.Value
	local pityCountLucky = playerDataFolder.PityLuckySpinsCount.Value
	
	StyleSubFrame.PityCounters.LuckyPity.Text = "Lucky Pity:  "..pityCountLucky.."/"..RarityProbability.PitySpinsRequired.LuckySpin.." Done"
	StyleSubFrame.PityCounters.StylePity.Text = "Pity:  "..pityCount.."/"..RarityProbability.PitySpinsRequired.StyleSpin.." Done"
end

setupStyleType(currentStyleTypeSelected)

GuiAnimationModule.SetupShrinkButton(ButtonsFrame.Defensive)
ButtonsFrame.Defensive.MouseButton1Click:Connect(function()
	if not spinning then
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		currentStyleTypeSelected = "Defensive"
		ButtonsFrame.Defensive.UIStroke.Color = Color3.fromRGB(255, 255, 255)
		
		ButtonsFrame.Offensive.UIStroke.Color = Color3.fromRGB(0, 0, 0)
		
		setupStyleType(currentStyleTypeSelected)
	end
end)

GuiAnimationModule.SetupShrinkButton(ButtonsFrame.Offensive)
ButtonsFrame.Offensive.MouseButton1Click:Connect(function()
	if not spinning then
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		currentStyleTypeSelected = "Offensive"
		ButtonsFrame.Offensive.UIStroke.Color = Color3.fromRGB(255, 255, 255)
		
		ButtonsFrame.Defensive.UIStroke.Color = Color3.fromRGB(0, 0, 0)
		
		setupStyleType(currentStyleTypeSelected)
	end
end)

GuiAnimationModule.SetupShrinkButton(SpinFrame.SpinButton)
local spinDebounce = false

SpinFrame.SpinButton.MouseButton1Click:Connect(function()
	if not spinDebounce then
		spinDebounce = true
		
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		
		if not spinning then
			local rarity = getEquippedRarity(currentStyleTypeSelected)
			if isMythicOrHigher(rarity) then
				openSpinConfirmation(currentStyleTypeSelected, "Normal")
				spinDebounce = false
				return
			end

			Remotes.StyleSpin:FireServer(currentStyleTypeSelected, "Normal")
			wait(1)
		else
			if not script.Parent.IsInitialRoll.Value and spinningType == "Normal" then
				spinning = false
				wait(0.5)
			end
		end
		
		spinDebounce = false
	end
end)

GuiAnimationModule.SetupShrinkButton(SpinFrame.LuckySpinButton)
SpinFrame.LuckySpinButton.MouseButton1Click:Connect(function()
	if not spinDebounce then
		spinDebounce = true

		GuiAnimationModule.ButtonPress(player, "PositiveClick")

		if not spinning then
			local rarity = getEquippedRarity(currentStyleTypeSelected)
			if isMythicOrHigher(rarity) then
				openSpinConfirmation(currentStyleTypeSelected, "Lucky")
				spinDebounce = false
				return
			end

			Remotes.StyleSpin:FireServer(currentStyleTypeSelected, "Lucky")
			wait(1)
		else
			if not script.Parent.IsInitialRoll.Value and spinningType == "Lucky" then
				spinning = false
				wait(0.5)
			end
		end

		spinDebounce = false
	end
end)

GuiAnimationModule.SetupShrinkButton(SpinFrame.BuySpins)
SpinFrame.BuySpins.MouseButton1Click:Connect(function()
	if not paidRandomItemsBanned then 
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		StyleSubFrame.Visible = false
		SpinsPurchaseFrame.Visible = true
	else
		ClientFunctions.Notification(player, "Sorry, this action is currently disabled in your region!", "Alert")
	end
end)

GuiAnimationModule.SetupShrinkButton(LimitedStylesButton)
LimitedStylesButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	LimitedStylesInventoryFrame.Visible = not LimitedStylesInventoryFrame.Visible
	
	if LimitedStylesInventoryFrame.Visible then
		if player.PlayerGui:FindFirstChild("PlayerSelectGifting") then
			player.PlayerGui.PlayerSelectGifting:Destroy()
		end
	end
end)

GuiAnimationModule.SetupShrinkButton(LimitedStylesInventoryFrame.Background.ExitButton)
LimitedStylesInventoryFrame.Background.ExitButton.Activated:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	LimitedStylesInventoryFrame.Visible = false
end)

GuiAnimationModule.SetupShrinkButton(SpinFrame.FreeSpins)
SpinFrame.FreeSpins.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	Remotes.ClaimFreeSpin:FireServer()
end)


updateSpinTimer()

playerDataFolder.SpinRewardTimer.Changed:Connect(function()
	updateSpinTimer()
end)

updatePityCounters()

playerDataFolder.PityStyleSpinsCount.Changed:Connect(function()
	updatePityCounters()
end)

playerDataFolder.PityLuckySpinsCount.Changed:Connect(function()
	updatePityCounters()
end)

GuiAnimationModule.SetupShrinkButton(NormalOddsButton)
NormalOddsButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	currentlyViewedOdds = "Normal"
	NormalOddsButton.UIStroke.Color = Color3.fromRGB(255, 255, 255)
	LuckyOddsButton.UIStroke.Color = Color3.fromRGB(0, 0, 0)
	showRarityList(currentStyleTypeSelected)
end)

GuiAnimationModule.SetupShrinkButton(LuckyOddsButton)
LuckyOddsButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	currentlyViewedOdds = "Lucky"
	LuckyOddsButton.UIStroke.Color = Color3.fromRGB(255, 255, 255)
	NormalOddsButton.UIStroke.Color = Color3.fromRGB(0, 0, 0)
	showRarityList(currentStyleTypeSelected)
end)

GuiAnimationModule.SetupShrinkButton(SpinsPurchaseButtons.LuckyOdds)
SpinsPurchaseButtons.LuckyOdds.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	SpinsPurchaseFrame.Background.NormalSpinsFrame.Visible = false
	SpinsPurchaseFrame.Background.LuckySpinsFrame.Visible = true
	SpinsPurchaseButtons.LuckyOdds.UIStroke.Color = Color3.fromRGB(255, 255, 255)
	SpinsPurchaseButtons.NormalOdds.UIStroke.Color = Color3.fromRGB(0, 0, 0)
end)

GuiAnimationModule.SetupShrinkButton(SpinsPurchaseButtons.NormalOdds)
SpinsPurchaseButtons.NormalOdds.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	SpinsPurchaseFrame.Background.NormalSpinsFrame.Visible = true
	SpinsPurchaseFrame.Background.LuckySpinsFrame.Visible = false
	SpinsPurchaseButtons.NormalOdds.UIStroke.Color = Color3.fromRGB(255, 255, 255)
	SpinsPurchaseButtons.LuckyOdds.UIStroke.Color = Color3.fromRGB(0, 0, 0)
end)

GuiAnimationModule.SetupShrinkButton(SpinsPurchaseFrame.Background.ExitButton)
SpinsPurchaseFrame.Background.ExitButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	StyleSubFrame.Visible = true
	SpinsPurchaseFrame.Visible = false
end)

for _, buySpinFrame in pairs(SpinsPurchaseFrame.Background.NormalSpinsFrame:GetChildren())  do
	if buySpinFrame:IsA("Frame") then
		
		buySpinFrame.BuyCash.Label.Text = ClientFunctions.ConvertShort(SpinCostsModule[buySpinFrame.Name].CashPrice)
		
		GuiAnimationModule.SetupShrinkButton(buySpinFrame.BuyCash)
		buySpinFrame.BuyCash.MouseButton1Click:Connect(function()
			GuiAnimationModule.ButtonPress(player, "PositiveClick")
			Remotes.BuyStyleSpinsCash:FireServer(buySpinFrame.Name)
		end)
		
		local success, productInfo = pcall(function()
			return MarketplaceService:GetProductInfo(SpinCostsModule[buySpinFrame.Name].DevProductID, Enum.InfoType.Product)
		end)
		
		if success and productInfo then
			buySpinFrame.BuyRobux.Label.Text = productInfo.PriceInRobux
		end
		
		GuiAnimationModule.SetupShrinkButton(buySpinFrame.BuyRobux)
		buySpinFrame.BuyRobux.MouseButton1Click:Connect(function()
			GuiAnimationModule.ButtonPress(player, "PositiveClick")
			PurchaseEvents.DevProductPurchase:FireServer(SpinCostsModule[buySpinFrame.Name].DevProductID)
		end)
		
		GuiAnimationModule.SetupShrinkButton(buySpinFrame.GiftButton)
		buySpinFrame.GiftButton.MouseButton1Click:Connect(function()
			GuiAnimationModule.ButtonPress(player, "PositiveClick")
			ClientFunctions.LoadGifting("DevProduct", SpinCostsModule[buySpinFrame.Name].GiftProductID)
		end)
	end
end

for _, buySpinFrame in pairs(SpinsPurchaseFrame.Background.LuckySpinsFrame:GetChildren())  do
	if buySpinFrame:IsA("Frame") then
		local success, productInfo = pcall(function()
			return MarketplaceService:GetProductInfo(SpinCostsModule[buySpinFrame.Name].DevProductID, Enum.InfoType.Product)
		end)

		if success and productInfo then
			buySpinFrame.BuyRobux.Label.Text = productInfo.PriceInRobux
		end

		GuiAnimationModule.SetupShrinkButton(buySpinFrame.BuyRobux)
		buySpinFrame.BuyRobux.MouseButton1Click:Connect(function()
			GuiAnimationModule.ButtonPress(player, "PositiveClick")
			PurchaseEvents.DevProductPurchase:FireServer(SpinCostsModule[buySpinFrame.Name].DevProductID)
		end)
		
		GuiAnimationModule.SetupShrinkButton(buySpinFrame.GiftButton)
		buySpinFrame.GiftButton.MouseButton1Click:Connect(function()
			GuiAnimationModule.ButtonPress(player, "PositiveClick")
			ClientFunctions.LoadGifting("DevProduct", SpinCostsModule[buySpinFrame.Name].GiftProductID)
		end)
	end
end


if playerDataFolder.StyleSpins.Value == 1 then
	SpinFrame.SpinsLeft.Text = playerDataFolder.StyleSpins.Value.." SPIN"
else
	SpinFrame.SpinsLeft.Text = playerDataFolder.StyleSpins.Value.." SPINS"
end
playerDataFolder.StyleSpins.Changed:Connect(function()
	if playerDataFolder.StyleSpins.Value == 1 then
		SpinFrame.SpinsLeft.Text = playerDataFolder.StyleSpins.Value.." SPIN"
	else
		SpinFrame.SpinsLeft.Text = playerDataFolder.StyleSpins.Value.." SPINS"
	end
end)

if playerDataFolder.LuckySpins.Value == 1 then
	SpinFrame.LuckySpinsLeft.Text = playerDataFolder.LuckySpins.Value.." LUCKY SPIN"
else
	SpinFrame.LuckySpinsLeft.Text = playerDataFolder.LuckySpins.Value.." LUCKY SPINS"
end
playerDataFolder.LuckySpins.Changed:Connect(function()
	if playerDataFolder.LuckySpins.Value == 1 then
		SpinFrame.LuckySpinsLeft.Text = playerDataFolder.LuckySpins.Value.." LUCKY SPIN"
	else
		SpinFrame.LuckySpinsLeft.Text = playerDataFolder.LuckySpins.Value.." LUCKY SPINS"
	end
end)

Remotes.StyleSlotUpgrade.OnClientEvent:Connect(function(styleType, styleInventory, equippedStyle, equippedSlotNum, equippedLimitedStyleName, limitedInventory)
	if styleType ~= currentStyleTypeSelected then return end
	
	currentEquippedStyleName = equippedStyle
	
	updateAbilityInfo(styleType, equippedStyle)
	setupInventory(equippedStyle, styleInventory, styleType, equippedSlotNum, equippedLimitedStyleName)
	setupLimitedInventory(styleType, limitedInventory, equippedLimitedStyleName)
end)

Remotes.SelectPreference.OnClientEvent:Connect(function(styleType, abilityName)
	if currentStyleTypeSelected ~= styleType then return end

	currentSpinPreference = abilityName

	for _, abilityLabel in pairs(RarityChancesFrame:GetChildren()) do
		if abilityLabel:GetAttribute("StyleLabelButton") then
			if abilityLabel.Name == abilityName then
				abilityLabel.Label.Text = "> "..abilityName.." <"
			else
				abilityLabel.Label.Text = abilityLabel.Name
			end
		end
	end
end)

Remotes.StyleSpin.OnClientEvent:Connect(function(styleRolled, styleType, styleInventory, equippedStyle, spinType, slotNumber, limitedInventory, equippedLimitedStyleName)
	spinning = true
	spinningType = spinType
	
	local availableStyles = {}  

	for styleName, info in pairs(StylesModule[styleType.."Styles"]) do
		if info.Available ~= false then
			table.insert(availableStyles, styleName)
		end
	end

	local spinDuration = 2.5 
	local spinSpeed = 0.1
	local elapsedTime = 0  
	
	if spinType == "Normal" then
		if not script.Parent.IsInitialRoll.Value then
			SpinFrame.SpinButton.TextLabel.Text = "SKIP"
		else
			SpinFrame.SpinButton.TextLabel.Text = "SPINNING"
			SpinFrame.ArrowIcon.Visible = false
			if StyleSubFrame:FindFirstChild("ExitArrowIcon") then
				StyleSubFrame.ExitArrowIcon.Visible = true
			end
		end
	elseif spinType == "Lucky" then
		if not script.Parent.IsInitialRoll.Value then
			SpinFrame.LuckySpinButton.TextLabel.Text = "SKIP"
		else
			SpinFrame.LuckySpinButton.TextLabel.Text = "SPINNING"
			SpinFrame.ArrowIcon.Visible = false
			if StyleSubFrame:FindFirstChild("ExitArrowIcon") then
				StyleSubFrame.ExitArrowIcon.Visible = true
			end
		end
	end

	local function spinText()
		while elapsedTime < spinDuration and spinning do
			local randomStyle = availableStyles[math.random(1, #availableStyles)]
			updateAbilityInfo(styleType, randomStyle)
			ClientFunctions.PlayAudioSound(player, "SpinSound")
			wait(spinSpeed)
			elapsedTime = elapsedTime + spinSpeed
		end

		updateAbilityInfo(styleType, styleRolled)
		setupInventory(equippedStyle, styleInventory, styleType, slotNumber, equippedLimitedStyleName)
		setupLimitedInventory(styleType, limitedInventory, equippedLimitedStyleName)
		
		currentEquippedStyleName = equippedStyle
		
		if spinType == "Normal" then
			SpinFrame.SpinButton.TextLabel.Text = "SPIN"
		elseif spinType == "Lucky" then
			SpinFrame.LuckySpinButton.TextLabel.Text = "LUCKY SPIN"
		end
		showCharacterPowerUp()
		
		--if script.Parent.IsInitialRoll.Value then
		--	wait(2)
		--	script.Parent.IsInitialRoll.Value = false
		--end
	end

	spinText()
	
	spinning = false
end)

Remotes.ReserveStyle.OnClientEvent:Connect(function(styleType, styleName, reserved, reservedSlotNum)
	if reserved then
		for _, styleButton in pairs(StyleInventory.Container.ItemHolder:GetChildren()) do
			if styleButton:IsA("Frame") 
				and styleButton:FindFirstChild("SlotNumber") 
				and styleButton.SlotNumber.Value == reservedSlotNum
			then
				styleButton.ReserveButton.TextLabel.Text = "UNLOCK"
				styleButton.ReserveButton.BackgroundColor3 = Color3.fromRGB(85, 0, 0)
				break
			end
		end
	else
		for _, styleButton in pairs(StyleInventory.Container.ItemHolder:GetChildren()) do
			if styleButton:IsA("Frame") 
				and styleButton:FindFirstChild("SlotNumber") 
				and styleButton.SlotNumber.Value == reservedSlotNum
			then
				styleButton.ReserveButton.TextLabel.Text = "LOCK"
				styleButton.ReserveButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
				break
			end
		end
	end
end)

local exitPressed = false

local function exitGui()
	if not exitPressed and script.Parent.Visible then
		exitPressed = true
		GuiAnimationModule.ButtonPress(player, "PositiveClick")
		script.Parent.Visible = false
		
		player.Character.States.InStylesLocker.Value = false
		
		ClientFunctions.ToggleStylesGuiView(true)

		ClientFunctions.HandleStyleCameraToggle(player)
		
		exitPressed = false
	end
end

GuiAnimationModule.SetupShrinkButton(SlotGiftButton)
SlotGiftButton.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")
	LimitedStylesInventoryFrame.Visible = false
	ClientFunctions.LoadGifting("Style Slot", currentStyleTypeSelected)
end)

local confirmYes = SpinConfirmationFrame.Background.SubFrame.YesButton
local confirmNo  = SpinConfirmationFrame.Background.SubFrame.NoButton

GuiAnimationModule.SetupShrinkButton(confirmYes)
GuiAnimationModule.SetupShrinkButton(confirmNo)

confirmYes.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick")

	if spinning then
		closeSpinConfirmation()
		return
	end

	if pendingStyleType and pendingSpinType then
		local styleTypeToSend = pendingStyleType
		local spinTypeToSend = pendingSpinType

		closeSpinConfirmation()

		Remotes.StyleSpin:FireServer(styleTypeToSend, spinTypeToSend)
	end
end)

confirmNo.MouseButton1Click:Connect(function()
	GuiAnimationModule.ButtonPress(player, "PositiveClick") -- or PositiveClick if you don't have it
	closeSpinConfirmation()
end)


GuiAnimationModule.SetupShrinkButton(ExitButton)
ExitButton.MouseButton1Click:connect(function()
	exitGui()
	
	if script.Parent.IsInitialRoll.Value then
		script.Parent.IsInitialRoll.Value = false
		
		if player:FindFirstChild("PlayerGui") then
			if player.PlayerGui:FindFirstChild("DailyRewardsGui") then
				player.PlayerGui.DailyRewardsGui.Enabled = true
			end

			if player.PlayerGui:FindFirstChild("MetavisionAd") then
				player.PlayerGui.MetavisionAd.Enabled = true
			end

			if player.PlayerGui:FindFirstChild("UpdateNotice") then
				player.PlayerGui.UpdateNotice.Enabled = true
			end
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe then
		if input.KeyCode == Enum.KeyCode.ButtonB then
			exitGui()
		end
	end
end)