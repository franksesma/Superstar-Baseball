local idleAnim = script.Parent.Humanoid:LoadAnimation(script.Parent.Animations.Idle)

wait()

idleAnim.Looped = true
idleAnim:Play()