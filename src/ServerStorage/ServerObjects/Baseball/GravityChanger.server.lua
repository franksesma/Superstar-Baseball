--------------------------------------------------------------------
--  Local-script inside each Baseball
--------------------------------------------------------------------
local GRAVITY_SCALE = 0.10					-- same constant!
local body			= script.Parent

local force = Instance.new("BodyForce")
force.Parent = body

while body.GravityOn.Value do
	force.Force = Vector3.new(
		0,
		workspace.Gravity * body.AssemblyMass * (1 - GRAVITY_SCALE),
		0
	)
	task.wait(0.1)
end
