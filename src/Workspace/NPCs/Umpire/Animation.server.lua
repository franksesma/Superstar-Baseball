local idleAnim = script.Parent.Humanoid:LoadAnimation(script.Parent.Animations.Idle)
local strikeAnim = script.Parent.Humanoid:LoadAnimation(script.Parent.Animations.Strike)
local strikeOutAnim1 = script.Parent.Humanoid:LoadAnimation(script.Parent.Animations.Strikeout1)
local strikeOutAnim2 = script.Parent.Humanoid:LoadAnimation(script.Parent.Animations.Strikeout2)
local strikeOutAnim3 = script.Parent.Humanoid:LoadAnimation(script.Parent.Animations.Strikeout3)

local strikeoutAnims = {strikeOutAnim1, strikeOutAnim2, strikeOutAnim3}

local Events = script.Parent.Events

Events.PlayStrikeAnim.Event:Connect(function()
	strikeAnim:Play()
end)

Events.PlayStrikeoutAnim.Event:Connect(function()
	strikeoutAnims[math.random(1, #strikeoutAnims)]:Play()
end)

wait(2.5)

idleAnim.Looped = true
idleAnim:Play()