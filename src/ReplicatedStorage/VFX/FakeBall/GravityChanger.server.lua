local gravity_multiplier = .1



gravity_multiplier = (gravity_multiplier * -1) + 1
local force = Instance.new("BodyForce",script.Parent)
while script.Parent.GravityOn.Value do
	force.Force = Vector3.new(
		0,
		game.Workspace.Gravity * script.Parent.Mass * gravity_multiplier,
		0
	)
	wait(0.1)
end