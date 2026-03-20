local tweenInfo = TweenInfo.new(.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

for _, v in script.Parent:GetDescendants() do
	if v:IsA("BasePart") or v:IsA("Texture") or v:IsA("Decal") then
		game:GetService("TweenService"):Create(v, tweenInfo, {
			LocalTransparencyModifier = 1;
		}):Play()
	end
end
