-- ReplicatedStorage/SharedModules/PlateDistance.lua

local MARGIN_OF_ERROR = 2

local Pitching     = workspace:WaitForChild("Pitching")
local strikeZone   = Pitching:WaitForChild("StrikeZone")
local Plates       = workspace:WaitForChild("Plates")
local fakeHomeBase = Plates:WaitForChild("Fake Home Base")

local module = {}

----------------------------------------------------------------
-- Strike-zone UV helper (center-based, no corner skew)
-- Returns Vector2(u, v) in [0,1]x[0,1], where:
--   u: left(0) → right(1)
--   v: bottom(1) → top(0) in screen terms; i.e. higher Y = smaller v
----------------------------------------------------------------
local function getRelativePos(pos: Vector3): Vector2
	local size = strikeZone.Size
	local localPos = strikeZone.CFrame:PointToObjectSpace(pos)

	-- Map from [-size/2 .. +size/2] to [0..1]
	local u = math.clamp((localPos.X / size.X) + 0.5, 0, 1)
	local v = math.clamp(1 - ((localPos.Y / size.Y) + 0.5), 0, 1)

	return Vector2.new(u, v)
end

----------------------------------------------------------------
-- Distance of the ball from the front/back of the plate (Z in plate space)
-- Returns: dist, margin
----------------------------------------------------------------
function module:getRelativeDistToPlate(pos: Vector3, usinPracticeFakeHomeBase: boolean): (number, number)
	local thisFakeHomeBase = fakeHomeBase
	
	if usinPracticeFakeHomeBase and workspace:FindFirstChild("BattingCage") then
		thisFakeHomeBase = workspace.BattingCage["Fake Home Base"]
	end
	
	local relPos = thisFakeHomeBase.CFrame:PointToObjectSpace(pos)
	return relPos.Z, (thisFakeHomeBase.Size.Z / 2) + MARGIN_OF_ERROR
end

----------------------------------------------------------------
-- 2D click distance on strike-zone UVs (consistent across the zone)
----------------------------------------------------------------
function module:getBallRelativeDist(ballPos: Vector3, clickPos: Vector3): number
	local b = getRelativePos(ballPos)
	local c = getRelativePos(clickPos)
	return (b - c).Magnitude
end

----------------------------------------------------------------
-- (Optional) Click scalars for yaw/pitch mapping in [0..1]
-- Uses strike-zone object space to avoid tiny 1-stud clamps.
----------------------------------------------------------------
function module:getClickScalars(ballPos: Vector3, clickPos: Vector3): (number, number)
	-- Work in strike-zone object space
	local b = strikeZone.CFrame:PointToObjectSpace(ballPos)
	local c = strikeZone.CFrame:PointToObjectSpace(clickPos)

	-- ΔX across half-width; ΔY across half-height
	local dx = (c.X - b.X) / (strikeZone.Size.X * 0.5)   -- [-1..1]
	local dy = (b.Y - c.Y) / (strikeZone.Size.Y * 0.5)   -- [-1..1], up is positive

	dx = math.clamp(dx, -1, 1)
	dy = math.clamp(dy, -1, 1)

	-- Map to [0..1]
	local xScalar = (dx + 1) * 0.5
	local yScalar = (dy + 1) * 0.5

	return xScalar, yScalar
end

return module
