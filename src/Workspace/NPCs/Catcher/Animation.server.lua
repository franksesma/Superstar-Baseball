local idleAnim = script.Parent.Humanoid:LoadAnimation(script.Parent.Animations.Idle)

wait(1)

idleAnim.Looped = true
idleAnim:Play()