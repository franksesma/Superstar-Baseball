local part = script.Parent -- the part
local partspeed = 0.005 -- speed of the spin

while task.wait() do

	part.CFrame = part.CFrame * CFrame.Angles(0,partspeed,0) -- the spin of the part

end
