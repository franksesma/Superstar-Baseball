local GuiAnimation = {}

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local BUTTON_GROW_SIZE = 0.9
local GROW_CLICK_SIZE = 1

local BUTTON_SHRINK_SIZE = 1.1
local SHRINK_CLICK_SIZE = 1.2

local MOUSE_ENTER_DURATION = .2
local CLICK_DURATION = .2

local function playHoverSound()
	if Players.LocalPlayer:FindFirstChild("PlayerScripts") == nil then return end
	
	local newSound = Players.LocalPlayer.PlayerScripts.SoundScript.HoverSound:Clone()
	newSound.Parent = SoundService
	newSound:Play()
	Debris:AddItem(newSound, newSound.TimeLength)
end

local function onMouseEnter(button, originalSize, sizeModifier)
	local hoverSize = UDim2.new(
		originalSize.X.Scale/sizeModifier, originalSize.X.Offset/sizeModifier,
		originalSize.Y.Scale/sizeModifier, originalSize.Y.Offset/sizeModifier
	)

	button:TweenSize(hoverSize, "Out", "Sine", MOUSE_ENTER_DURATION, true)
	playHoverSound()
end

local function onMouseLeave(button, originalSize)
	button:TweenSize(originalSize, "Out", "Sine", MOUSE_ENTER_DURATION, true)
end


local function onMouseClick(button, originalSize, sizeModifier)
	local clickSize = UDim2.new(
		originalSize.X.Scale/sizeModifier, originalSize.X.Offset/sizeModifier,
		originalSize.Y.Scale/sizeModifier, originalSize.Y.Offset/sizeModifier
	)

	button:TweenSize(clickSize, "Out", "Sine", CLICK_DURATION, true)
end

-- weak keys so destroyed buttons fall out automatically
local trackedButtons = setmetatable({}, { __mode = "k" })
local gamepadConnsStarted = false

local function applyGamepadIcons(button, enabled)
	-- guard if button is gone or not in tree
	if not button or button.Parent == nil then return end

	local gp = button:FindFirstChild("GamepadBind")
	local kb = button:FindFirstChild("KBMBind")
	if gp and kb then
		gp.Visible = enabled
		kb.Visible = not enabled
	end
end

local function refreshAll()
	local enabled = UserInputService.GamepadEnabled
	for button in pairs(trackedButtons) do
		applyGamepadIcons(button, enabled)
	end
end

local function ensureGamepadSignals()
	if gamepadConnsStarted then return end
	gamepadConnsStarted = true

	UserInputService.GamepadConnected:Connect(function()
		refreshAll()
	end)

	UserInputService.GamepadDisconnected:Connect(function()
		-- GamepadEnabled can stay true if another pad is still connected,
		-- so just refresh from GamepadEnabled.
		refreshAll()
	end)
end

function GuiAnimation.EnableGamePadSupport(button)
	trackedButtons[button] = true
	ensureGamepadSignals()
	applyGamepadIcons(button, UserInputService.GamepadEnabled)
end

function GuiAnimation.SetupGrowButton(button)
	local originalSize = button.Size

	if button:FindFirstChild("GamepadBind") then
		GuiAnimation.EnableGamePadSupport(button)
	end

	button.MouseEnter:connect(function()
		onMouseEnter(button, originalSize, BUTTON_GROW_SIZE)
	end)

	button.MouseLeave:connect(function()
		onMouseLeave(button, originalSize)
	end)

	button.MouseButton1Down:connect(function()
		onMouseClick(button, originalSize, GROW_CLICK_SIZE)
	end)

	button.MouseButton1Up:connect(function()
		onMouseEnter(button, originalSize, BUTTON_GROW_SIZE)
	end)
end

function GuiAnimation.SetupShrinkButton(button)
	local originalSize = button.Size

	if button:FindFirstChild("GamepadBind") then
		GuiAnimation.EnableGamePadSupport(button)
	end

	button.MouseEnter:connect(function()
		onMouseEnter(button, originalSize, BUTTON_SHRINK_SIZE)
	end)

	button.MouseLeave:connect(function()
		onMouseLeave(button, originalSize)
	end)

	button.MouseButton1Down:connect(function()
		onMouseClick(button, originalSize, SHRINK_CLICK_SIZE)
	end)

	button.MouseButton1Up:connect(function()
		onMouseEnter(button, originalSize, BUTTON_SHRINK_SIZE)
	end)
end

function GuiAnimation.ButtonPress(player, soundName)
	if player:FindFirstChild("PlayerScripts") then
		player.PlayerScripts.SoundScript[soundName]:Play()
	end
end

function GuiAnimation.ExitButtonPressed(player, frame, button)
	local exitPressed = false

	local function exitGui()
		if not exitPressed and frame.Visible then
			exitPressed = true
			GuiAnimation.ButtonPress(player, "PositiveClick")
			frame.Visible = false
			exitPressed = false
		end
	end

	GuiAnimation.SetupShrinkButton(button)

	button.MouseButton1Click:connect(function()
		exitGui()
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe then
			if input.KeyCode == Enum.KeyCode.ButtonB then
				exitGui()
			end
		end
	end)
end

function GuiAnimation.DisplayAbilityUnusable(player, abilityType)
	player.PlayerGui.AbilityPower.AbilityButtons[abilityType].Disabled.Visible = true
	player.PlayerGui.AbilityPower.AbilityButtons[abilityType].Disabled.Position = UDim2.new(0,0,0,0)
	player.PlayerGui.AbilityPower.AbilityButtons[abilityType].Disabled.Size = UDim2.new(1,0,1,0)
end

function GuiAnimation.DisplayAbilityCooldown(player, abilityType, cooldownTime)
	if player:FindFirstChild("PlayerGui") then
		GuiAnimation.DisplayAbilityUnusable(player, abilityType)
		
		player.PlayerGui.AbilityPower.AbilityButtons[abilityType].Disabled:TweenSizeAndPosition(UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 1, 0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, cooldownTime, true)
	end
end

return GuiAnimation
