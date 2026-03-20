local PitchTypes = {}

PitchTypes.Data = {
	Fastball =  { Curve = 2.0, Arc = 5,  Power = -0.2 },
	Nitroball =  { Curve = 2.0, Arc = 2,  Power = -0.1 },
	Curveball = { Curve = 1.9, Arc = 5,  Power = -0.3 },
	Sinker =    { Curve = 2.0, Arc = 10, Power = -0.4 },
	Changeup =  { Curve = 2.0, Arc = 6,  Power = -0.45 },
	Knuckleball = { Curve = 2.0, Arc = 5, Power = -0.5,},
	Slider =    { Curve = 1.8, Arc = 4,  Power = -0.3 },
	Cutter =    { Curve = 1.85, Arc = 4, Power = -0.35 },
	Splitter =  { Curve = 2.1, Arc = 12, Power = -0.4 },
	Eephus =    { Curve = 2.0, Arc = 28, Power = -0.95 }, 
	Riser  = { Curve = 2.1,  Arc = -3, Power = -0.3 },
	Slurve = { Curve = 1.75, Arc = 8,  Power = -0.3 },
	Slowball =  { Curve = 2.0, Arc = 5,  Power = -0.5},
	Forkball = { Curve = 2.05, Arc = 14, Power = -0.3 },
}

function PitchTypes.CalculateMiddle(PitchType, From, Target)
	PitchType = string.lower(PitchType)
	PitchType = PitchType:gsub("^%l", string.upper)

	local pitchData = PitchTypes.Data[PitchType]
	if pitchData then
		return ((Target + From) / pitchData.Curve) + Vector3.new(0, pitchData.Arc, 0)
	end
	return (Target + From) / 2
end

return PitchTypes