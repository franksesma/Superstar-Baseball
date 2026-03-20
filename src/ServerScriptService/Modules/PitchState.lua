-- ServerScriptService/Modules/PitchState.lua
-- Centralized per-pitch state (server-only, no remotes)

local PitchState = {}

local nextPitchId = 0
local states = {}  -- [pitchId] = { pitcher, inStrikeZone, swung, missed }

function PitchState.newPitch(ball: BasePart, pitcher: any, inStrikeZone: boolean?): number
	nextPitchId += 1
	local pid = nextPitchId
	if ball then ball:SetAttribute("PitchId", pid) end
	states[pid] = {
		pitcher = pitcher,
		inStrikeZone = inStrikeZone == true,
		swung = false,
		missed = false,
	}
	return pid
end

function PitchState.setInZoneById(pid: number, inStrikeZone: boolean)
	if states[pid] then states[pid].inStrikeZone = inStrikeZone == true end
end

function PitchState.setInZoneByBall(ball: BasePart, inStrikeZone: boolean)
	if not ball then return end
	local pid = ball:GetAttribute("PitchId")
	if pid then PitchState.setInZoneById(pid, inStrikeZone) end
end

function PitchState.markSwingMissById(pid: number, didHit: boolean)
	if states[pid] then
		states[pid].swung = true
		states[pid].missed = (didHit == false)
	end
end

function PitchState.markSwingMissByBall(ball: BasePart, didHit: boolean)
	if not ball then return end
	local pid = ball:GetAttribute("PitchId")
	if pid then PitchState.markSwingMissById(pid, didHit) end
end

function PitchState.getById(pid: number)
	return states[pid]
end

function PitchState.getByBall(ball: BasePart)
	if not ball then return nil end
	local pid = ball:GetAttribute("PitchId")
	if not pid then return nil end
	return states[pid], pid
end

function PitchState.clearById(pid: number)
	states[pid] = nil
end

return PitchState
