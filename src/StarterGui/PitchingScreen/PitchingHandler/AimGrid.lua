local AimGrid = {}
AimGrid.__index = AimGrid

local uis = game:GetService("UserInputService")

local plr = game.Players.LocalPlayer
local plrGui = plr:WaitForChild("PlayerGui")

local gui = script:WaitForChild("MobileScreen")
local surface = script:WaitForChild("SurfaceGui")

-- Helper function to get actual size whether part uses Size or Scale
-- In Roblox, part.Size returns the actual rendered size for both Size and Scale modes
local function getActualSize(part)
	return part.Size
end

-- Multiplier is an optional Vector2 if the ball is going in the opposite direction/corner than it's supposed to
-- Ex. Vector2.new(-1, -1) will flip both x and y axes
function AimGrid.New(innerZone, outerZone, multiplier)
	local aimGrid = setmetatable({}, AimGrid)

	aimGrid.surface = surface:Clone()
	aimGrid.surface.Parent = outerZone

	aimGrid.gui = gui:Clone()
	aimGrid.gui.Parent = plrGui
	aimGrid.outerZone = outerZone
	aimGrid.innerZone = innerZone
	aimGrid.multiplier = multiplier or Vector2.new(1, 1)

	local screenOuterZone = aimGrid.gui.OuterZone
	local screenInnerZone = screenOuterZone.InnerZone
	local targetIndicator = screenOuterZone.Circle
	local surfaceTargetIndicator = aimGrid.surface.Circle

	aimGrid.targetIndicator = targetIndicator
	aimGrid.targetIndicatorColor = targetIndicator.ImageColor3
	aimGrid.surfaceTargetIndicator = surfaceTargetIndicator
	aimGrid.surfaceTargetIndicatorColor = surfaceTargetIndicator.ImageColor3

	-- Get actual sizes (handles both Size and Scale)
	local innerSize = getActualSize(innerZone)
	local outerSize = getActualSize(outerZone)

	print("[AimGrid] InnerZone (StrikeZone) Size:", innerSize)
	print("[AimGrid] OuterZone (ThrowSpot) Size:", outerSize)

	-- Calculate where strike zone center is relative to throw spot center
	local throwSpotCF = outerZone.CFrame
	local strikeZoneCF = innerZone.CFrame
	local strikeZoneCenterLocal = throwSpotCF:PointToObjectSpace(strikeZoneCF.Position)

	print("[AimGrid] StrikeZone center in ThrowSpot space:", strikeZoneCenterLocal)
	print("[AimGrid] StrikeZone center offset in studs - X:", strikeZoneCenterLocal.X, "Y:", strikeZoneCenterLocal.Y)

	-- Store the strike zone offset for mapping in GetTarget (normalized to [0,1] range)
	aimGrid.strikeZoneOffset = Vector2.new(
		strikeZoneCenterLocal.X / outerSize.X,
		strikeZoneCenterLocal.Y / outerSize.Y
	)

	-- Also store the actual offset in studs for calculations
	aimGrid.strikeZoneOffsetStuds = Vector2.new(strikeZoneCenterLocal.X, strikeZoneCenterLocal.Y)

	-- Calculate the relative size (strike zone size / throw spot size)
	-- This is the proportion the inner zone should be within the outer zone
	local relativeSizeX = innerSize.X / outerSize.X
	local relativeSizeY = innerSize.Y / outerSize.Y

	-- Make inner zone square by using the larger dimension
	local squareSize = math.max(relativeSizeX, relativeSizeY)

	-- Store the actual strike zone ratios for mapping
	aimGrid.innerRatioX = relativeSizeX
	aimGrid.innerRatioY = relativeSizeY
	aimGrid.squareSize = squareSize

	print("[AimGrid] Relative size ratios - X:", relativeSizeX, "Y:", relativeSizeY)
	print("[AimGrid] Square size (for display):", squareSize)
	print("[AimGrid] Strike zone offset (normalized):", aimGrid.strikeZoneOffset)

	-- Center the inner zone completely within the outer zone (make it square)
	screenInnerZone.AnchorPoint = Vector2.new(0.5, 0.5)
	screenInnerZone.Position = UDim2.new(0.5, 0, 0.5, 0)
	screenInnerZone.Size = UDim2.new(squareSize, 0, squareSize, 0)

	print("[AimGrid] Setting inner zone - Position:", screenInnerZone.Position, "Size:", screenInnerZone.Size)

	local aiming = false

	local function GetAim(io)
		local pos = io.Position
		local relativePos = Vector2.new(pos.X - screenOuterZone.AbsolutePosition.X, pos.Y - screenOuterZone.AbsolutePosition.Y)
		local uv = Vector2.new(relativePos.X / screenOuterZone.AbsoluteSize.X, relativePos.Y / screenOuterZone.AbsoluteSize.Y)

		return relativePos, uv
	end

	-- Helper function to convert UV to SurfaceGui position
	-- Calculates the actual target position and converts it to SurfaceGui UV for smooth transitions
	local function GetSurfaceGuiPosition(uv)
		-- Temporarily set UV to calculate target
		local tempUV = aimGrid.uv
		aimGrid.uv = uv

		-- Calculate the target position using the same logic as GetTarget
		local targetPos = nil
		local squareSize = aimGrid.squareSize
		local innerRatioX = aimGrid.innerRatioX
		local innerRatioY = aimGrid.innerRatioY
		local strikeZoneOffsetStuds = aimGrid.strikeZoneOffsetStuds
		local multiplier = aimGrid.multiplier
		local outerSize = getActualSize(aimGrid.outerZone)
		local innerSize = getActualSize(aimGrid.innerZone)

		-- Check if UV is within the square inner zone
		local innerLeft = 0.5 - squareSize / 2
		local innerRight = 0.5 + squareSize / 2
		local innerTop = 0.5 - squareSize / 2
		local innerBottom = 0.5 + squareSize / 2

		local isInInnerZone = 
			uv.X >= innerLeft and uv.X <= innerRight and
			uv.Y >= innerTop and uv.Y <= innerBottom

		-- Unified calculation for smooth transitions
		-- Calculate position relative to inner zone center
		local clickRelativeToCenter = Vector2.new(uv.X - 0.5, uv.Y - 0.5)

		-- Calculate the inner zone edge positions in UV space (relative to center)
		local innerEdgeLeft = innerLeft - 0.5
		local innerEdgeRight = innerRight - 0.5
		local innerEdgeTop = innerTop - 0.5
		local innerEdgeBottom = innerBottom - 0.5

		-- Calculate where the inner zone edges map to on the throw spot (in studs)
		local strikeZoneLeftEdge = strikeZoneOffsetStuds.X - innerSize.X / 2
		local strikeZoneRightEdge = strikeZoneOffsetStuds.X + innerSize.X / 2
		local strikeZoneTopEdge = strikeZoneOffsetStuds.Y + innerSize.Y / 2
		local strikeZoneBottomEdge = strikeZoneOffsetStuds.Y - innerSize.Y / 2

		-- Calculate available space on throw spot in each direction
		local throwSpotLeftExtent = -outerSize.X / 2
		local throwSpotRightExtent = outerSize.X / 2
		local throwSpotTopExtent = outerSize.Y / 2
		local throwSpotBottomExtent = -outerSize.Y / 2

		local availableLeft = strikeZoneLeftEdge - throwSpotLeftExtent
		local availableRight = throwSpotRightExtent - strikeZoneRightEdge
		local availableTop = throwSpotTopExtent - strikeZoneTopEdge
		local availableBottom = strikeZoneBottomEdge - throwSpotBottomExtent

		-- Map the distance outside inner zone to throw spot space
		local outerZoneSizeLeftUV = 0.5 - innerLeft
		local outerZoneSizeRightUV = innerRight - 0.5
		local outerZoneSizeTopUV = 0.5 - innerTop
		local outerZoneSizeBottomUV = innerBottom - 0.5

		local offset
		if isInInnerZone then
			-- Inside inner zone: map to strike zone
			-- Check if we're at or near the edge (for continuity)
			local isAtLeftEdge = math.abs(clickRelativeToCenter.X - innerEdgeLeft) < 0.001
			local isAtRightEdge = math.abs(clickRelativeToCenter.X - innerEdgeRight) < 0.001
			local isAtTopEdge = math.abs(clickRelativeToCenter.Y - innerEdgeTop) < 0.001
			local isAtBottomEdge = math.abs(clickRelativeToCenter.Y - innerEdgeBottom) < 0.001

			-- If at edge, use edge position directly for continuity
			if (isAtLeftEdge or isAtRightEdge) and (isAtTopEdge or isAtBottomEdge) then
				-- At corner - use corner position
				local offsetX = isAtLeftEdge and strikeZoneLeftEdge or strikeZoneRightEdge
				local offsetY = isAtTopEdge and strikeZoneTopEdge or strikeZoneBottomEdge
				offsetX = offsetX * multiplier.X
				offset = Vector2.new(offsetX, offsetY)
			elseif isAtLeftEdge or isAtRightEdge then
				-- At vertical edge - use edge X, calculate Y normally
				local clampedY = math.clamp(clickRelativeToCenter.Y, innerEdgeTop, innerEdgeBottom)
				local scaledClickY = (clampedY / squareSize) * innerRatioY
				scaledClickY = math.clamp(scaledClickY, -innerRatioY / 2, innerRatioY / 2)
				local positionInStrikeZoneY = (scaledClickY / innerRatioY) * innerSize.Y
				positionInStrikeZoneY = math.clamp(positionInStrikeZoneY, -innerSize.Y / 2, innerSize.Y / 2)
				local offsetX = (isAtLeftEdge and strikeZoneLeftEdge or strikeZoneRightEdge) * multiplier.X
				local offsetY = (positionInStrikeZoneY * multiplier.Y) + strikeZoneOffsetStuds.Y
				offset = Vector2.new(offsetX, offsetY)
			elseif isAtTopEdge or isAtBottomEdge then
				-- At horizontal edge - use edge Y, calculate X normally
				local clampedX = math.clamp(clickRelativeToCenter.X, innerEdgeLeft, innerEdgeRight)
				local scaledClickX = (clampedX / squareSize) * innerRatioX
				scaledClickX = math.clamp(scaledClickX, -innerRatioX / 2, innerRatioX / 2)
				local positionInStrikeZoneX = (scaledClickX / innerRatioX) * innerSize.X
				positionInStrikeZoneX = math.clamp(positionInStrikeZoneX, -innerSize.X / 2, innerSize.X / 2)
				local offsetX = (positionInStrikeZoneX * multiplier.X) + strikeZoneOffsetStuds.X
				offsetX = offsetX * multiplier.X
				local offsetY = isAtTopEdge and strikeZoneTopEdge or strikeZoneBottomEdge
				offset = Vector2.new(offsetX, offsetY)
			else
				-- Not at edge - use normal proportional mapping
				local clampedX = math.clamp(clickRelativeToCenter.X, innerEdgeLeft, innerEdgeRight)
				local clampedY = math.clamp(clickRelativeToCenter.Y, innerEdgeTop, innerEdgeBottom)

				-- Map from square inner zone to rectangular strike zone
				local scaledClick = Vector2.new(
					(clampedX / squareSize) * innerRatioX,
					(clampedY / squareSize) * innerRatioY
				)
				scaledClick = Vector2.new(
					math.clamp(scaledClick.X, -innerRatioX / 2, innerRatioX / 2),
					math.clamp(scaledClick.Y, -innerRatioY / 2, innerRatioY / 2)
				)
				local positionInStrikeZone = Vector2.new(
					(scaledClick.X / innerRatioX) * innerSize.X,
					(scaledClick.Y / innerRatioY) * innerSize.Y
				)
				positionInStrikeZone = Vector2.new(
					math.clamp(positionInStrikeZone.X, -innerSize.X / 2, innerSize.X / 2),
					math.clamp(positionInStrikeZone.Y, -innerSize.Y / 2, innerSize.Y / 2)
				)
				local positionInStrikeZoneWithMultiplier = positionInStrikeZone * multiplier
				offset = Vector2.new(
					positionInStrikeZoneWithMultiplier.X + strikeZoneOffsetStuds.X,
					positionInStrikeZoneWithMultiplier.Y + strikeZoneOffsetStuds.Y
				)
			end
		else
			-- Outside inner zone: interpolate smoothly from inner edge to outer edge
			-- Clamp coordinates to inner edge first to find the base position
			local clampedX = math.clamp(clickRelativeToCenter.X, innerEdgeLeft, innerEdgeRight)
			local clampedY = math.clamp(clickRelativeToCenter.Y, innerEdgeTop, innerEdgeBottom)

			-- Calculate distance from inner edge (positive = outside, negative = inside, 0 = at edge)
			local xDistanceFromInnerEdge = clickRelativeToCenter.X - clampedX
			local yDistanceFromInnerEdge = clickRelativeToCenter.Y - clampedY

			-- Calculate the position at the inner edge using the EXACT same logic as inner zone
			-- This ensures perfect continuity when crossing the boundary
			-- Use the same calculation as the inner zone's "Not at edge" case
			-- IMPORTANT: Use the actual clickRelativeToCenter coordinates (clamped to edge) to match inner zone
			local edgeScaledClick = Vector2.new(
				(clampedX / squareSize) * innerRatioX,
				(clampedY / squareSize) * innerRatioY
			)
			edgeScaledClick = Vector2.new(
				math.clamp(edgeScaledClick.X, -innerRatioX / 2, innerRatioX / 2),
				math.clamp(edgeScaledClick.Y, -innerRatioY / 2, innerRatioY / 2)
			)
			local edgePositionInStrikeZone = Vector2.new(
				(edgeScaledClick.X / innerRatioX) * innerSize.X,
				(edgeScaledClick.Y / innerRatioY) * innerSize.Y
			)
			edgePositionInStrikeZone = Vector2.new(
				math.clamp(edgePositionInStrikeZone.X, -innerSize.X / 2, innerSize.X / 2),
				math.clamp(edgePositionInStrikeZone.Y, -innerSize.Y / 2, innerSize.Y / 2)
			)
			local edgePositionWithMultiplier = edgePositionInStrikeZone * multiplier
			local edgeOffset = Vector2.new(
				edgePositionWithMultiplier.X + strikeZoneOffsetStuds.X,
				edgePositionWithMultiplier.Y + strikeZoneOffsetStuds.Y
			)

			-- Now interpolate from edge position outward based on distance from edge
			-- Use edgeOffset as the base to ensure perfect continuity at the boundary
			local offsetX, offsetY

			-- Calculate X offset - always interpolate smoothly from edgeOffset.X
			-- The interpolation ensures perfect continuity: at t=0, offsetX = edgeOffset.X
			if xDistanceFromInnerEdge < 0 then
				-- Left of inner zone - interpolate from left edge outward
				local distanceUV = -xDistanceFromInnerEdge
				local t = math.min(distanceUV / outerZoneSizeLeftUV, 1)
				-- FIX: outer edge target must be in ThrowSpot-local space (same space as edgeOffset)
				-- DO NOT add strikeZoneOffsetStuds here (was causing the right-side snap)
				local outerLeftEdgeInOffsetSpace = (throwSpotLeftExtent * multiplier.X)
				-- Interpolate smoothly: at t=0, offsetX = edgeOffset.X (perfect continuity)
				offsetX = edgeOffset.X + (outerLeftEdgeInOffsetSpace - edgeOffset.X) * t
			elseif xDistanceFromInnerEdge > 0 then
				-- Right of inner zone - interpolate from right edge outward
				local distanceUV = xDistanceFromInnerEdge
				local t = math.min(distanceUV / outerZoneSizeRightUV, 1)
				-- FIX: outer edge target must be in ThrowSpot-local space (same space as edgeOffset)
				-- DO NOT add strikeZoneOffsetStuds here (was causing the right-side snap)
				local outerRightEdgeInOffsetSpace = (throwSpotRightExtent * multiplier.X)
				-- Interpolate smoothly: at t=0, offsetX = edgeOffset.X (perfect continuity)
				offsetX = edgeOffset.X + (outerRightEdgeInOffsetSpace - edgeOffset.X) * t
			else
				-- X is exactly at inner edge - use edgeOffset.X directly for perfect continuity
				offsetX = edgeOffset.X
			end

			-- Calculate Y offset - always interpolate smoothly from edgeOffset.Y
			-- The interpolation ensures perfect continuity: at t=0, offsetY = edgeOffset.Y
			if yDistanceFromInnerEdge < 0 then
				-- Above inner zone - interpolate from top edge outward
				local distanceUV = -yDistanceFromInnerEdge
				local t = math.min(distanceUV / outerZoneSizeTopUV, 1)
				-- Interpolate smoothly: at t=0, offsetY = edgeOffset.Y (perfect continuity)
				offsetY = edgeOffset.Y + (throwSpotTopExtent - edgeOffset.Y) * t
			elseif yDistanceFromInnerEdge > 0 then
				-- Below inner zone - interpolate from bottom edge outward
				local distanceUV = yDistanceFromInnerEdge
				local t = math.min(distanceUV / outerZoneSizeBottomUV, 1)
				-- Interpolate smoothly: at t=0, offsetY = edgeOffset.Y (perfect continuity)
				offsetY = edgeOffset.Y + (throwSpotBottomExtent - edgeOffset.Y) * t
			else
				-- Y is exactly at inner edge - use edgeOffset.Y directly for perfect continuity
				offsetY = edgeOffset.Y
			end

			-- Apply multiplier to outer zone X offset for consistency with inner zone coordinate system
			-- This ensures smooth transitions and correct directional mapping

			print("[GetSurfaceGuiPosition] Outer zone - clickRelativeToCenter:", clickRelativeToCenter)
			print("[GetSurfaceGuiPosition] Outer zone - clampedX:", clampedX, "xDistanceFromInnerEdge:", xDistanceFromInnerEdge)
			print("[GetSurfaceGuiPosition] Outer zone - clampedY:", clampedY, "yDistanceFromInnerEdge:", yDistanceFromInnerEdge)
			print("[GetSurfaceGuiPosition] Outer zone - edgeOffset:", edgeOffset)
			print("[GetSurfaceGuiPosition] Outer zone - offsetX:", offsetX, "offsetY:", offsetY)

			offset = Vector2.new(offsetX, offsetY)
		end

		-- Convert offset to world space
		local throwSpotCF = aimGrid.outerZone.CFrame
		local worldOffset = CFrame.new(offset.X, offset.Y, 0)
		targetPos = (throwSpotCF * worldOffset).Position

		-- Restore original UV
		aimGrid.uv = tempUV

		-- Convert target position to SurfaceGui UV coordinates
		local throwSpotCFForUV = aimGrid.outerZone.CFrame
		local localPos = throwSpotCFForUV:PointToObjectSpace(targetPos)
		local outerSizeForUV = getActualSize(aimGrid.outerZone)

		-- Convert local position to UV coordinates
		-- SurfaceGui: X: 0 = left, 1 = right; Y: 0 = top, 1 = bottom
		-- Local space: X: -size/2 to +size/2, Y: -size/2 to +size/2
		-- For both zones, multiplier was applied to offset, so we need to invert X
		local uvX, uvY
		if isInInnerZone then
			-- Inner zone: multiplier was applied, so invert X to account for it
			uvX = (-localPos.X / outerSizeForUV.X) + 0.5  -- Invert X: multiplier was applied
			uvY = (-localPos.Y / outerSizeForUV.Y) + 0.5  -- Invert Y: world Y up = SurfaceGui Y down
		else
			-- Outer zone: multiplier was applied to offsetX, so invert X to account for it
			uvX = (-localPos.X / outerSizeForUV.X) + 0.5  -- Invert X: multiplier was applied
			uvY = (-localPos.Y / outerSizeForUV.Y) + 0.5  -- Invert Y: world Y up = SurfaceGui Y down
		end

		print("[GetSurfaceGuiPosition] isInInnerZone:", isInInnerZone)
		print("[GetSurfaceGuiPosition] localPos:", localPos)
		print("[GetSurfaceGuiPosition] offset (before world conversion):", offset)
		print("[GetSurfaceGuiPosition] targetPos:", targetPos)
		print("[GetSurfaceGuiPosition] UV:", uvX, uvY)

		-- Clamp to valid range
		uvX = math.clamp(uvX, 0, 1)
		uvY = math.clamp(uvY, 0, 1)

		return Vector2.new(uvX, uvY)
	end

	screenOuterZone.InputBegan:Connect(function(io)
		if aimGrid.frozen then return end
		if 	io.UserInputType == Enum.UserInputType.MouseButton1 or
			io.UserInputType == Enum.UserInputType.Touch
		then
			local relativePos, uv = GetAim(io)
			targetIndicator.Position = UDim2.new(0, relativePos.X, 0, relativePos.Y)

			-- Use helper function to get correct SurfaceGui position
			local surfaceUV = GetSurfaceGuiPosition(uv)
			surfaceTargetIndicator.Position = UDim2.new(surfaceUV.X, 0, surfaceUV.Y, 0)

			aiming = true
			targetIndicator.Visible = true
			surfaceTargetIndicator.Visible = true
		end		
	end)

	screenOuterZone.InputChanged:Connect(function(io)
		if aimGrid.frozen or not aiming then return end

		if 	io.UserInputType == Enum.UserInputType.MouseMovement or
			io.UserInputType == Enum.UserInputType.Touch
		then
			local relativePos, uv = GetAim(io)
			targetIndicator.Position = UDim2.new(0, relativePos.X, 0, relativePos.Y)

			-- Use helper function to get correct SurfaceGui position (smooth mapping)
			local surfaceUV = GetSurfaceGuiPosition(uv)
			surfaceTargetIndicator.Position = UDim2.new(surfaceUV.X, 0, surfaceUV.Y, 0)
		end
	end)

	screenOuterZone.InputEnded:Connect(function(io)
		if aimGrid.frozen then return end

		if 	io.UserInputType == Enum.UserInputType.MouseButton1 or
			io.UserInputType == Enum.UserInputType.Touch
		then
			local relativePos, uv = GetAim(io)

			print("[AimGrid] Input ended - UV:", uv, "RelativePos:", relativePos)
			print("[AimGrid] ScreenOuterZone - Position:", screenOuterZone.AbsolutePosition, "Size:", screenOuterZone.AbsoluteSize)
			print("[AimGrid] ScreenInnerZone - Position:", screenInnerZone.AbsolutePosition, "Size:", screenInnerZone.AbsoluteSize)

			-- Use the square inner zone bounds (what user sees) for detection
			local squareSize = aimGrid.squareSize
			local innerLeft = screenInnerZone.AbsolutePosition.X
			local innerRight = screenInnerZone.AbsolutePosition.X + screenInnerZone.AbsoluteSize.X
			local innerTop = screenInnerZone.AbsolutePosition.Y
			local innerBottom = screenInnerZone.AbsolutePosition.Y + screenInnerZone.AbsoluteSize.Y

			print("[AimGrid] Square inner zone bounds - Left:", innerLeft, "Right:", innerRight, "Top:", innerTop, "Bottom:", innerBottom)
			print("[AimGrid] Click position - X:", io.Position.X, "Y:", io.Position.Y)

			-- Check if click is in the square inner zone
			aimGrid.inStrikeZone =
				io.Position.X >= innerLeft and
				io.Position.X <= innerRight and
				io.Position.Y >= innerTop and
				io.Position.Y <= innerBottom

			print("[AimGrid] InStrikeZone (square inner zone):", aimGrid.inStrikeZone)

			aimGrid.uv = uv

			-- Update surface circle position using helper function (smooth mapping)
			local surfaceUV = GetSurfaceGuiPosition(uv)
			surfaceTargetIndicator.Position = UDim2.new(surfaceUV.X, 0, surfaceUV.Y, 0)

			aiming = false
		end
	end)

	return aimGrid
end

-- Call once pitching power bar has started, locks in aim
function AimGrid:Freeze()
	self.frozen = true
	self.targetIndicator.ImageColor3 = Color3.new(0.7, 0.7, 0.7)
	self.surfaceTargetIndicator.ImageColor3 = Color3.new(0.7, 0.7, 0.7)
end

function AimGrid:Reset()
	self.uv = nil
	self.frozen = false
	self.targetIndicator.ImageColor3 = self.targetIndicatorColor
	self.targetIndicator.Visible = false
	self.surfaceTargetIndicator.ImageColor3 = self.surfaceTargetIndicatorColor
	self.surfaceTargetIndicator.Visible = false
end

function AimGrid:GetTarget()
	if not self.uv then return false end

	print("[AimGrid:GetTarget] UV:", self.uv, "Multiplier:", self.multiplier)

	local size = getActualSize(self.outerZone)
	local innerSize = getActualSize(self.innerZone)

	-- Use the square size for detection (what user sees), but map to actual strike zone
	local squareSize = self.squareSize  -- Square size for display
	local innerRatioX = self.innerRatioX  -- Actual strike zone X ratio for mapping
	local innerRatioY = self.innerRatioY  -- Actual strike zone Y ratio for mapping
	local strikeZoneCenterOffset = self.strikeZoneOffset

	-- Check if UV is within the square inner zone (what user sees)
	local innerLeft = 0.5 - squareSize / 2
	local innerRight = 0.5 + squareSize / 2
	local innerTop = 0.5 - squareSize / 2
	local innerBottom = 0.5 + squareSize / 2

	local isInInnerZone = 
		self.uv.X >= innerLeft and self.uv.X <= innerRight and
		self.uv.Y >= innerTop and self.uv.Y <= innerBottom

	print("[AimGrid:GetTarget] Square inner zone bounds in UV:", innerLeft, innerRight, innerTop, innerBottom)
	print("[AimGrid:GetTarget] Actual strike zone ratios:", innerRatioX, innerRatioY)
	print("[AimGrid:GetTarget] Strike zone center offset:", strikeZoneCenterOffset)
	print("[AimGrid:GetTarget] Is in inner zone (square):", isInInnerZone)

	local offset
	if isInInnerZone then
		-- Map inner zone clicks to strike zone
		-- The inner zone is displayed as a square centered at 0.5, 0.5 in UI
		-- But the actual strike zone is rectangular and offset from throw spot center
		-- We need to ensure ALL clicks in the square map to valid positions within the strike zone

		-- Get the click position relative to the square center (0.5, 0.5)
		local clickRelativeToSquareCenter = Vector2.new(
			self.uv.X - 0.5,  -- Range: [-squareSize/2, +squareSize/2] when in square inner zone
			self.uv.Y - 0.5   -- Range: [-squareSize/2, +squareSize/2] when in square inner zone
		)

		print("[AimGrid:GetTarget] Click relative to square center:", clickRelativeToSquareCenter)
		print("[AimGrid:GetTarget] Square size:", squareSize)
		print("[AimGrid:GetTarget] Actual strike zone ratios:", innerRatioX, innerRatioY)
		print("[AimGrid:GetTarget] Strike zone offset (normalized):", strikeZoneCenterOffset)

		-- Map from square inner zone to rectangular strike zone
		-- Scale from square size to actual strike zone ratios
		-- This ensures clicks at the edge of the square map to the edge of the strike zone
		local scaledClick = Vector2.new(
			(clickRelativeToSquareCenter.X / squareSize) * innerRatioX,  -- Scale X: [-squareSize/2, +squareSize/2] -> [-innerRatioX/2, +innerRatioX/2]
			(clickRelativeToSquareCenter.Y / squareSize) * innerRatioY   -- Scale Y: [-squareSize/2, +squareSize/2] -> [-innerRatioY/2, +innerRatioY/2]
		)

		-- IMPORTANT: Clamp aggressively to ensure we ALWAYS stay within strike zone bounds
		-- This prevents clicks in the square from mapping outside the actual strike zone
		local clampedClick = Vector2.new(
			math.clamp(scaledClick.X, -innerRatioX / 2, innerRatioX / 2),
			math.clamp(scaledClick.Y, -innerRatioY / 2, innerRatioY / 2)
		)

		print("[AimGrid:GetTarget] Scaled click (from square to rectangle):", scaledClick)
		print("[AimGrid:GetTarget] Clamped click to actual strike zone bounds:", clampedClick)

		-- Convert clamped click to position within strike zone (in studs)
		-- Map the clamped click (in UV space relative to center) to strike zone space
		local positionInStrikeZone = Vector2.new(
			(clampedClick.X / innerRatioX) * innerSize.X,  -- Scale X: [-innerRatioX/2, +innerRatioX/2] -> [-innerSize.X/2, +innerSize.X/2]
			(clampedClick.Y / innerRatioY) * innerSize.Y   -- Scale Y: [-innerRatioY/2, +innerRatioY/2] -> [-innerSize.Y/2, +innerSize.Y/2]
		)

		-- Double-check: Ensure we're absolutely within strike zone bounds (in studs)
		positionInStrikeZone = Vector2.new(
			math.clamp(positionInStrikeZone.X, -innerSize.X / 2, innerSize.X / 2),
			math.clamp(positionInStrikeZone.Y, -innerSize.Y / 2, innerSize.Y / 2)
		)

		print("[AimGrid:GetTarget] Position in strike zone (relative to strike zone center):", positionInStrikeZone)
		print("[AimGrid:GetTarget] Strike zone center offset (studs):", self.strikeZoneOffsetStuds)

		-- Apply multiplier to position in strike zone (this handles screen-to-world coordinate conversion)
		local positionInStrikeZoneWithMultiplier = positionInStrikeZone * self.multiplier

		-- The strike zone offset is in throw spot's local space and should NOT be multiplied
		-- Add the offset to get position relative to throw spot center
		offset = Vector2.new(
			positionInStrikeZoneWithMultiplier.X + self.strikeZoneOffsetStuds.X,
			positionInStrikeZoneWithMultiplier.Y + self.strikeZoneOffsetStuds.Y
		)

		print("[AimGrid:GetTarget] Position in strike zone (after multiplier):", positionInStrikeZoneWithMultiplier)
		print("[AimGrid:GetTarget] Strike zone offset (NOT multiplied):", self.strikeZoneOffsetStuds)
		print("[AimGrid:GetTarget] Final offset (position + offset):", offset)
		print("[AimGrid:GetTarget] ===== END INNER ZONE MAPPING =====")
	else
		-- Outside inner zone: interpolate smoothly from inner edge to outer edge
		-- Use the same logic as GetSurfaceGuiPosition to ensure consistency

		-- Calculate position relative to inner zone center
		local clickRelativeToCenter = Vector2.new(self.uv.X - 0.5, self.uv.Y - 0.5)

		-- Calculate the inner zone edge positions in UV space (relative to center)
		local innerEdgeLeft = innerLeft - 0.5
		local innerEdgeRight = innerRight - 0.5
		local innerEdgeTop = innerTop - 0.5
		local innerEdgeBottom = innerBottom - 0.5

		-- Calculate available space on throw spot in each direction
		local throwSpotLeftExtent = -size.X / 2
		local throwSpotRightExtent = size.X / 2
		local throwSpotTopExtent = size.Y / 2
		local throwSpotBottomExtent = -size.Y / 2

		-- Map the distance outside inner zone to throw spot space
		local outerZoneSizeLeftUV = 0.5 - innerLeft
		local outerZoneSizeRightUV = innerRight - 0.5
		local outerZoneSizeTopUV = 0.5 - innerTop
		local outerZoneSizeBottomUV = innerBottom - 0.5

		-- Clamp coordinates to inner edge first to find the base position
		local clampedX = math.clamp(clickRelativeToCenter.X, innerEdgeLeft, innerEdgeRight)
		local clampedY = math.clamp(clickRelativeToCenter.Y, innerEdgeTop, innerEdgeBottom)

		-- Calculate distance from inner edge (positive = outside, negative = inside, 0 = at edge)
		local xDistanceFromInnerEdge = clickRelativeToCenter.X - clampedX
		local yDistanceFromInnerEdge = clickRelativeToCenter.Y - clampedY

		-- Calculate the position at the inner edge (using inner zone calculation)
		-- This ensures continuity when crossing the boundary
		local edgeScaledClick = Vector2.new(
			(clampedX / squareSize) * innerRatioX,
			(clampedY / squareSize) * innerRatioY
		)
		edgeScaledClick = Vector2.new(
			math.clamp(edgeScaledClick.X, -innerRatioX / 2, innerRatioX / 2),
			math.clamp(edgeScaledClick.Y, -innerRatioY / 2, innerRatioY / 2)
		)
		local edgePositionInStrikeZone = Vector2.new(
			(edgeScaledClick.X / innerRatioX) * innerSize.X,
			(edgeScaledClick.Y / innerRatioY) * innerSize.Y
		)
		edgePositionInStrikeZone = Vector2.new(
			math.clamp(edgePositionInStrikeZone.X, -innerSize.X / 2, innerSize.X / 2),
			math.clamp(edgePositionInStrikeZone.Y, -innerSize.Y / 2, innerSize.Y / 2)
		)
		local edgePositionWithMultiplier = edgePositionInStrikeZone * self.multiplier
		local edgeOffset = Vector2.new(
			edgePositionWithMultiplier.X + self.strikeZoneOffsetStuds.X,
			edgePositionWithMultiplier.Y + self.strikeZoneOffsetStuds.Y
		)

		-- Now interpolate from edge position outward based on distance from edge
		local offsetX, offsetY

		-- Calculate X offset - start from edgeOffset.X and interpolate outward
		-- Always interpolate smoothly - the interpolation formula ensures continuity at t=0
		if xDistanceFromInnerEdge < 0 then
			-- Left of inner zone - interpolate from left edge outward
			local distanceUV = -xDistanceFromInnerEdge
			local t = math.min(distanceUV / outerZoneSizeLeftUV, 1)
			-- FIX: outer edge target must be in ThrowSpot-local space (same space as edgeOffset)
			-- DO NOT add strikeZoneOffsetStuds here (was causing the right-side snap)
			local outerLeftEdgeInOffsetSpace = (throwSpotLeftExtent * self.multiplier.X)
			-- Interpolate smoothly: at t=0, offsetX = edgeOffset.X (perfect continuity)
			offsetX = edgeOffset.X + (outerLeftEdgeInOffsetSpace - edgeOffset.X) * t
		elseif xDistanceFromInnerEdge > 0 then
			-- Right of inner zone - interpolate from right edge outward
			local distanceUV = xDistanceFromInnerEdge
			local t = math.min(distanceUV / outerZoneSizeRightUV, 1)
			-- FIX: outer edge target must be in ThrowSpot-local space (same space as edgeOffset)
			-- DO NOT add strikeZoneOffsetStuds here (was causing the right-side snap)
			local outerRightEdgeInOffsetSpace = (throwSpotRightExtent * self.multiplier.X)
			-- Interpolate smoothly: at t=0, offsetX = edgeOffset.X (perfect continuity)
			offsetX = edgeOffset.X + (outerRightEdgeInOffsetSpace - edgeOffset.X) * t
		else
			-- X is exactly at inner edge - use edgeOffset.X directly for perfect continuity
			offsetX = edgeOffset.X
		end

		-- Calculate Y offset - start from edgeOffset.Y and interpolate outward
		-- Always interpolate smoothly - the interpolation formula ensures continuity at t=0
		if yDistanceFromInnerEdge < 0 then
			-- Above inner zone - interpolate from top edge outward
			local distanceUV = -yDistanceFromInnerEdge
			local t = math.min(distanceUV / outerZoneSizeTopUV, 1)
			-- Interpolate smoothly: at t=0, offsetY = edgeOffset.Y (perfect continuity)
			offsetY = edgeOffset.Y + (throwSpotTopExtent - edgeOffset.Y) * t
		elseif yDistanceFromInnerEdge > 0 then
			-- Below inner zone - interpolate from bottom edge outward
			local distanceUV = yDistanceFromInnerEdge
			local t = math.min(distanceUV / outerZoneSizeBottomUV, 1)
			-- Interpolate smoothly: at t=0, offsetY = edgeOffset.Y (perfect continuity)
			offsetY = edgeOffset.Y + (throwSpotBottomExtent - edgeOffset.Y) * t
		else
			-- Y is exactly at inner edge - use edgeOffset.Y directly for perfect continuity
			offsetY = edgeOffset.Y
		end

		offset = Vector2.new(offsetX, offsetY)

		print("[AimGrid:GetTarget] Outer zone - clickRelativeToCenter:", clickRelativeToCenter)
		print("[AimGrid:GetTarget] Outer zone - clampedX:", clampedX, "xDistanceFromInnerEdge:", xDistanceFromInnerEdge)
		print("[AimGrid:GetTarget] Outer zone - clampedY:", clampedY, "yDistanceFromInnerEdge:", yDistanceFromInnerEdge)
		print("[AimGrid:GetTarget] Outer zone - edgeOffset:", edgeOffset)
		print("[AimGrid:GetTarget] Outer zone - offsetX:", offsetX, "offsetY:", offsetY)
		print("[AimGrid:GetTarget] Mapped to throw spot - offset:", offset)
	end

	-- Convert offset to world space using throw spot's CFrame
	-- offset is in throw spot's local X/Y space (after multiplier)
	-- CFrame.new(offset.X, offset.Y, 0) creates a local offset, then we transform it by the throw spot's CFrame
	local throwSpotCF = self.outerZone.CFrame
	local worldOffset = CFrame.new(offset.X, offset.Y, 0)
	local targetPosition = (throwSpotCF * worldOffset).Position

	print("[AimGrid:GetTarget] ===== WORLD SPACE CONVERSION =====")
	print("[AimGrid:GetTarget] Offset (local space, after multiplier):", offset)
	print("[AimGrid:GetTarget] World offset CFrame (local):", worldOffset)
	print("[AimGrid:GetTarget] Throw spot CFrame:", throwSpotCF)
	print("[AimGrid:GetTarget] Throw spot position:", throwSpotCF.Position)
	print("[AimGrid:GetTarget] Throw spot RightVector:", throwSpotCF.RightVector)
	print("[AimGrid:GetTarget] Throw spot UpVector:", throwSpotCF.UpVector)
	print("[AimGrid:GetTarget] Target position (world):", targetPosition)
	print("[AimGrid:GetTarget] ===== END WORLD SPACE CONVERSION =====")

	print("[AimGrid:GetTarget] World offset:", worldOffset)
	print("[AimGrid:GetTarget] Target position:", targetPosition)
	print("[AimGrid:GetTarget] InStrikeZone:", self.inStrikeZone)

	-- Verify if target is actually in strike zone by checking against real strike zone
	local strikeZoneCF = self.innerZone.CFrame
	local strikeZoneLocal = strikeZoneCF:PointToObjectSpace(targetPosition)
	local strikeZoneHalfSize = innerSize / 2
	local actuallyInStrikeZone = 
		math.abs(strikeZoneLocal.X) <= strikeZoneHalfSize.X and
		math.abs(strikeZoneLocal.Y) <= strikeZoneHalfSize.Y

	print("[AimGrid:GetTarget] ===== VERIFICATION =====")
	print("[AimGrid:GetTarget] Strike zone CFrame:", strikeZoneCF)
	print("[AimGrid:GetTarget] Strike zone position:", strikeZoneCF.Position)
	print("[AimGrid:GetTarget] Target position (world):", targetPosition)
	print("[AimGrid:GetTarget] Target in StrikeZone object space:", strikeZoneLocal)
	print("[AimGrid:GetTarget] StrikeZone half size:", strikeZoneHalfSize)
	print("[AimGrid:GetTarget] StrikeZone full size:", innerSize)
	print("[AimGrid:GetTarget] X check: |", strikeZoneLocal.X, "| <=", strikeZoneHalfSize.X, "?", math.abs(strikeZoneLocal.X), "<=", strikeZoneHalfSize.X, "=", math.abs(strikeZoneLocal.X) <= strikeZoneHalfSize.X)
	print("[AimGrid:GetTarget] Y check: |", strikeZoneLocal.Y, "| <=", strikeZoneHalfSize.Y, "?", math.abs(strikeZoneLocal.Y), "<=", strikeZoneHalfSize.Y, "=", math.abs(strikeZoneLocal.Y) <= strikeZoneHalfSize.Y)
	print("[AimGrid:GetTarget] Actually in strike zone (verified):", actuallyInStrikeZone)
	print("[AimGrid:GetTarget] Reported inStrikeZone:", self.inStrikeZone)
	print("[AimGrid:GetTarget] ===== END VERIFICATION =====")

	-- If we're in the inner zone but verification fails, clamp the target to stay within strike zone
	if isInInnerZone and not actuallyInStrikeZone then
		warn("[AimGrid:GetTarget] ===== WARNING: Click in inner zone but target outside strike zone! Clamping... =====")
		warn("[AimGrid:GetTarget] Target position (before clamp):", targetPosition)
		warn("[AimGrid:GetTarget] Strike zone local:", strikeZoneLocal)
		warn("[AimGrid:GetTarget] Strike zone bounds: X: [-", strikeZoneHalfSize.X, ", +", strikeZoneHalfSize.X, "] Y: [-", strikeZoneHalfSize.Y, ", +", strikeZoneHalfSize.Y, "]")

		-- Clamp the target to stay within strike zone bounds
		local clampedLocal = Vector3.new(
			math.clamp(strikeZoneLocal.X, -strikeZoneHalfSize.X, strikeZoneHalfSize.X),
			math.clamp(strikeZoneLocal.Y, -strikeZoneHalfSize.Y, strikeZoneHalfSize.Y),
			strikeZoneLocal.Z
		)

		-- Convert back to world space
		targetPosition = strikeZoneCF:PointToWorldSpace(clampedLocal)
		actuallyInStrikeZone = true

		warn("[AimGrid:GetTarget] Target position (after clamp):", targetPosition)
	end

	return targetPosition, self.inStrikeZone
end

-- Update the SurfaceGui circle position to match the calculated target position
function AimGrid:UpdateSurfaceCircleFromTarget(targetPosition)
	-- Convert target position to ThrowSpot's local space
	local throwSpotCF = self.outerZone.CFrame
	local localPos = throwSpotCF:PointToObjectSpace(targetPosition)

	-- Get throw spot size
	local outerSize = getActualSize(self.outerZone)

	-- Convert local position to UV coordinates (0-1 range) for SurfaceGui
	-- SurfaceGui uses: X: 0 = left, 1 = right; Y: 0 = top, 1 = bottom
	-- Local space: X: -size/2 to +size/2, Y: -size/2 to +size/2
	-- We need to account for the multiplier that was applied in GetTarget
	-- The multiplier flips the coordinates, so we need to reverse that for display
	local adjustedLocalPos = Vector3.new(
		localPos.X * self.multiplier.X,  -- Reverse the multiplier to get back to screen-space orientation
		localPos.Y * self.multiplier.Y,  -- Reverse the multiplier to get back to screen-space orientation
		localPos.Z
	)

	-- Convert to UV coordinates
	local uvX = (adjustedLocalPos.X / outerSize.X) + 0.5  -- Convert from [-0.5, 0.5] to [0, 1]
	local uvY = (adjustedLocalPos.Y / outerSize.Y) + 0.5  -- Convert from [-0.5, 0.5] to [0, 1]

	-- Clamp to valid UV range
	uvX = math.clamp(uvX, 0, 1)
	uvY = math.clamp(uvY, 0, 1)

	-- Update surface circle position
	self.surfaceTargetIndicator.Position = UDim2.new(uvX, 0, uvY, 0)

	print("[AimGrid:UpdateSurfaceCircleFromTarget] Target:", targetPosition)
	print("[AimGrid:UpdateSurfaceCircleFromTarget] Local pos:", localPos)
	print("[AimGrid:UpdateSurfaceCircleFromTarget] Adjusted local pos (reversed multiplier):", adjustedLocalPos)
	print("[AimGrid:UpdateSurfaceCircleFromTarget] UV:", uvX, uvY)
end

function AimGrid:Destroy()
	self.gui:Destroy()
end

return AimGrid
