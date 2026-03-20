script.Parent.Orientation = Vector3.new(script.Parent.Orientation.X, 0, script.Parent.Orientation.Z)

wait()
game.TweenService:Create(script.Parent, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, math.huge), {Orientation = Vector3.new(script.Parent.Orientation.X, 360, script.Parent.Orientation.Z)}):Play()