-- ReplicatedStorage/SharedModules/PitchMath.lua
-- Shared deterministic path math for both server & clients (server-authoritative hitbox + client mirror)

local PitchMath = {}

-- Simple seeded RNG (deterministic across server/clients when given the same seed)
local function seededRand(seed: number?)
	local m = 4294967296 -- 2^32
	local s = (tonumber(seed) or 1) % m
	-- LCG constants (Numerical Recipes)
	local A = 1664525
	local C = 1013904223
	return function()
		s = (A * s + C) % m
		return s / m
	end
end

local function clamp01(x: number): number
	if x < 0 then return 0 end
	if x > 1 then return 1 end
	return x
end

local function norm01(now: number, t0: number, duration: number): number
	if duration <= 0 then return 1 end
	return clamp01((now - t0) / duration)
end

local function lerp(a: Vector3, b: Vector3, t: number): Vector3
	return a + (b - a) * t
end

local function quadBezier(p0: Vector3, p1: Vector3, p2: Vector3, u: number): Vector3
	local l1 = lerp(p0, p1, u)
	local l2 = lerp(p1, p2, u)
	return lerp(l1, l2, u)
end

local function cubicBezier(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: number): Vector3
	local v = 1 - u
	return (v ^ 3) * p0 + 3 * (v ^ 2) * u * p1 + 3 * v * (u ^ 2) * p2 + (u ^ 3) * p3
end

local function tornadoPos(p0: Vector3, p1: Vector3, p2: Vector3, u: number, amp: number, freq: number): Vector3
	local base = quadBezier(p0, p1, p2, u)
	local side = math.sin(u * freq * math.pi * 2) * amp
	return base + Vector3.new(side, 0, 0)
end

-- params:
--   style: "bezier" | "cubic" | "direct" | "tornado" | "physics"
--   p0, p1, p2 [, p3] : Vector3
--   duration: number
--   t0: number (server time origin from workspace:GetServerTimeNow())
--   seed: number? (optional – for deterministic cosmetics)
--   amp, freq: number? (tornado)
--   origin, velocity, gravity: Vector3? (physics)
function PitchMath.position(params: any, now: number): Vector3
	-- basic guards / defaults
	local style = params.style or "bezier"
	local t0 = params.t0 or now
	local duration = params.duration or 1
	local u = norm01(now, t0, duration)
	-- seeded RNG available if you want cosmetic jitter (kept but unused by default)
	local _rand = (params.seed ~= nil) and seededRand(params.seed) or nil

	if style == "direct" then
		-- p0 -> p2 linear
		return (params.p0 :: Vector3):Lerp(params.p2 :: Vector3, u)

	elseif style == "tornado" then
		return tornadoPos(params.p0 :: Vector3, params.p1 :: Vector3, params.p2 :: Vector3, u, params.amp or 2, params.freq or 4)

	elseif style == "cubic" and params.p3 then
		-- If you ever want subtle deterministic jitter, enable the lines below:
		-- if _rand then
		-- 	local j = 0 -- set >0 for tiny spice, e.g. 0.05
		-- 	local jitter = function() return (_rand() - 0.5) * j end
		-- 	local p1 = (params.p1 :: Vector3) + Vector3.new(jitter(), jitter(), jitter())
		-- 	local p2 = (params.p2 :: Vector3) + Vector3.new(jitter(), jitter(), jitter())
		-- 	return cubicBezier(params.p0 :: Vector3, p1, p2, params.p3 :: Vector3, u)
		-- end
		return cubicBezier(params.p0 :: Vector3, params.p1 :: Vector3, params.p2 :: Vector3, params.p3 :: Vector3, u)

	elseif style == "physics" and params.origin and params.velocity then
		local g = params.gravity or Vector3.new(0, -196.2, 0)
		local t = u * duration
		return (params.origin :: Vector3) + (params.velocity :: Vector3) * t + 0.5 * g * (t * t)
	end

	-- default quadratic bezier
	return quadBezier(params.p0 :: Vector3, params.p1 :: Vector3, params.p2 :: Vector3, u)
end

return PitchMath
