-- AimGrid.lua (UI-ONLY)
-- Click and hold inside OuterZone to start aiming. Cursor moves with your drag: drag right = cursor right.
-- Uses UserInputService for drag position so you can drag anywhere on screen (no bounds).

local AimGrid = {}
AimGrid.__index = AimGrid

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local plrGui = plr:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- Template: MobileScreen (ScreenGui) with OuterZone (ImageButton) -> Circle
local guiTemplate = script:WaitForChild("MobileScreen")

local function safeDestroyExisting(screenName: string)
	local existing = plrGui:FindFirstChild(screenName)
	if existing and existing:IsA("ScreenGui") then
		existing:Destroy()
	end
end

function AimGrid.New(mouseFrame: GuiObject, opts: table?)
	opts = opts or {}

	local self = setmetatable({}, AimGrid)
	self.Changed = Instance.new("BindableEvent")
	self._conns = {}
	self.frozen = false
	self.mouseFrame = mouseFrame
	self.uv = nil

	local screenName = opts.ScreenName or "MobileScreen"
	safeDestroyExisting(screenName)

	self.gui = guiTemplate:Clone()
	self.gui.Name = screenName
	self.gui.ResetOnSpawn = false
	self.gui.Enabled = true
	self.gui.IgnoreGuiInset = true
	self.gui.DisplayOrder = opts.DisplayOrder or 999999
	self.gui.Parent = plrGui

	local outer: GuiObject = self.gui:WaitForChild("OuterZone")
	outer.BackgroundTransparency = 1
	outer.ZIndex = 999998
	outer.Active = true
	outer.Selectable = false

	-- Circle exists in template but we don't show it while aiming
	local circle = outer:FindFirstChild("Circle")
	if circle and circle:IsA("GuiObject") then
		circle.Visible = false
	end

	self.outer = outer

	local aiming = false
	local dragStartScreen = Vector2.zero
	local dragStartUV = Vector2.new(0.5, 0.5)

	local function setUvAndFire(uv: Vector2)
		self.uv = uv
		self.Changed:Fire(uv)
	end

	-- Sensitivity: higher = cursor moves more per pixel of drag (was 1.2, ~4 = much snappier)
	local sensitivity = 4
	local function applyDragToUV(currentScreen: Vector2): Vector2
		local vp = camera.ViewportSize
		if vp.X <= 0 or vp.Y <= 0 then return self.uv or Vector2.new(0.5, 0.5) end
		local delta = currentScreen - dragStartScreen
		local scaleX = sensitivity / vp.X
		local scaleY = sensitivity / vp.Y
		local newX = math.clamp(dragStartUV.X + delta.X * scaleX, 0, 1)
		local newY = math.clamp(dragStartUV.Y + delta.Y * scaleY, 0, 1)
		return Vector2.new(newX, newY)
	end

	-- Start: click/hold inside OuterZone only
	table.insert(self._conns, outer.InputBegan:Connect(function(io)
		if self.frozen then return end
		if io.UserInputType ~= Enum.UserInputType.MouseButton1 and io.UserInputType ~= Enum.UserInputType.Touch then return end
		aiming = true
		dragStartScreen = io.Position
		dragStartUV = self.uv or Vector2.new(0.5, 0.5)
	end))

	-- Move: use UserInputService so we get position even when finger is OUTSIDE OuterZone (no bounds)
	table.insert(self._conns, UserInputService.InputChanged:Connect(function(io)
		if self.frozen or not aiming then return end
		if io.UserInputType ~= Enum.UserInputType.MouseMovement and io.UserInputType ~= Enum.UserInputType.Touch then return end
		local uv = applyDragToUV(io.Position)
		setUvAndFire(uv)
	end))

	-- Do NOT end drag on OuterZone.InputEnded — that fires when finger *leaves* the zone (touch leaves element),
	-- which would stop the drag as soon as you drag outside. We only end on actual finger lift (UIS.InputEnded).
	-- (OuterZone.InputEnded connection omitted intentionally.)

	-- End drag only when finger is actually lifted (anywhere on screen)
	table.insert(self._conns, UserInputService.InputEnded:Connect(function(io)
		if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
			aiming = false
		end
	end))

	-- Default aim at center before first drag (so batting cursor has a position)
	self.uv = Vector2.new(0.5, 0.5)
	self.Changed:Fire(self.uv)

	return self
end

function AimGrid:Destroy()
	if self._conns then
		for _, c in ipairs(self._conns) do
			c:Disconnect()
		end
	end
	self._conns = nil

	if self.Changed then
		self.Changed:Destroy()
		self.Changed = nil
	end

	if self.gui then
		self.gui:Destroy()
		self.gui = nil
	end
end

return AimGrid