local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ShopItems = ReplicatedStorage.ShopItems
local SharedModules = ReplicatedStorage.SharedModules
local SharedData = ReplicatedStorage.SharedData

local ViewportFrame = script.Parent.ViewportFrame

local ViewportModelModule = require(SharedModules.ViewportModel)
local ClientFunctions = require(SharedModules.ClientFunctions)
local ShopPackItemsModule =  require(SharedModules.ShopPackItems)

local itemName = script.Parent.ItemName.Value
local packItemType = script.Parent.PackItemType.Value
local packName = script.Parent.PackName.Value

local player = Players.LocalPlayer

script.Parent.Size = UDim2.new(0,0,0,0)

spawn(function()
	if script.Parent.BigRoll.Value then
		ClientFunctions.PlayAudioSound(player, "BigRoll")
	end

	script.Parent:TweenSize(UDim2.new(0.25, 0, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Bounce, 0.5, true)
	wait(3)
	script.Parent:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.5, true)
	wait(0.5)
	script.Parent.Parent:Destroy()
end)

if packItemType == "Emote" then
	local playerData = SharedData:FindFirstChild(player.Name)
	if playerData then
		displayCharacter = playerData:FindFirstChild("EmoteShopDisplayCharacter")
	end
	
	if displayCharacter then
		local worldModel = Instance.new("WorldModel")
		worldModel.Name = "ViewModel"
		local dummy = displayCharacter:Clone()
		dummy.Name = "ViewModel"

		local animateScript = dummy:FindFirstChild("Animate")
		if animateScript then
			animateScript:Destroy() -- Remove default animations
		end

		local animation = Instance.new("Animation")
		animation.AnimationId = ShopItems[packItemType][itemName].AnimationId

		local camera = Instance.new("Camera")
		camera.FieldOfView = 70
		camera.Parent = ViewportFrame

		worldModel.Parent = ViewportFrame
		dummy.Parent = worldModel

		ViewportFrame.CurrentCamera = camera

		local humanoid = dummy:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if animator then
				animator = Instance.new("Animator")
				animator.Parent = humanoid
			end

			local animTrack = animator:LoadAnimation(animation)
			animTrack.Looped = true
			animTrack:Play()
		end
		
		local vpfModel = ViewportModelModule.new(ViewportFrame, camera)
		local cf, size = worldModel:GetBoundingBox()

		vpfModel:SetModel(worldModel)

		local theta = math.pi
		local orientation = CFrame.new()
		local distance = vpfModel:GetFitDistance(cf.Position) * 0.6

		viewportModelRenderStepped = game:GetService("RunService").RenderStepped:Connect(function(dt)
			theta = theta + math.rad(20 * dt)
			orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), theta, 0)
			camera.CFrame = CFrame.new(cf.Position) * orientation * CFrame.new(0, 0, distance)
		end)
	end
elseif packItemType ~= "Trail" and packItemType ~= "Explosion" then
	local viewModel = Instance.new("Model")
	local referenceModel = ShopItems[packItemType][itemName]

	for _, part in pairs(referenceModel:GetChildren()) do
		if part:IsA("MeshPart") or part:IsA("BasePart") then
			part:Clone().Parent = viewModel
		end
	end

	local camera = Instance.new("Camera")
	camera.FieldOfView = 70
	camera.Parent = ViewportFrame

	viewModel.Parent = ViewportFrame
	ViewportFrame.CurrentCamera = camera

	local vpfModel = ViewportModelModule.new(ViewportFrame, camera)
	local cf, size = viewModel:GetBoundingBox()

	vpfModel:SetModel(viewModel)

	local theta = 0
	local orientation = CFrame.new()
	local distance = vpfModel:GetFitDistance(cf.Position)
	
	viewportModelRenderStepped = game:GetService("RunService").RenderStepped:Connect(function(dt)
		theta = theta + math.rad(20 * dt)
		orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), theta, 0)
		camera.CFrame = CFrame.new(cf.Position) * orientation * CFrame.new(0, 0, distance)
	end)
else
	script.Parent.TrailIcon.Image = ShopPackItemsModule[packName][itemName].Icon
	script.Parent.TrailIcon.Visible = true
	script.Parent.ViewportFrame.Visible = false
end