local TweenService = game:GetService("TweenService")

local flowers = script.Parent.Flowers:GetChildren()
local unclaimedNumbers = {}

for i = 1, #flowers/2 do
	local idx = math.random(#flowers)
	flowers[idx]:Destroy()
	table.remove(flowers, idx)
end

for i = 1, #flowers do
	table.insert(unclaimedNumbers, i)
end
for _, flower in flowers do
	local num = Instance.new("NumberValue", flower)
	num.Value = .2
	
	num.Changed:Connect(function(value)
		flower:ScaleTo(value)
	end)
	
	flower:ScaleTo(num.Value)
	
	local num = unclaimedNumbers[math.random(#unclaimedNumbers)]
	table.remove(unclaimedNumbers, table.find(unclaimedNumbers, num))
	flower:SetAttribute("Order", num)
end

table.sort(flowers, function(a, b)
	return a:GetAttribute("Order") < b:GetAttribute("Order")
end)
for _, flower in flowers do
	local num = flower:FindFirstChildOfClass("NumberValue")
	
	local delay = math.random(.1, .2)
	TweenService:Create(num, TweenInfo.new(.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, delay), {Value = 1}):Play()
	task.wait(delay)
	local pop = script.Pop:Clone()
	pop.Parent = workspace
	pop:Play()
	
	task.delay(2, function()
		pop:Destroy()
	end)
end

for _, object in script.Parent:GetDescendants() do
	if object:IsA("BasePart") then
		TweenService:Create(object, TweenInfo.new(1, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
	end
end
task.wait(1.2)
script.Parent:Destroy()
