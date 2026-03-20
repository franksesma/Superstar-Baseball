local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local VFXModule = {}

function VFXModule.PlaceModel(model, position)
	if model.PrimaryPart then
		model:SetPrimaryPartCFrame(CFrame.new(position))
	end
end

function VFXModule.ShrinkModel(model, duration)
	local originalSizes = {}
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			originalSizes[part] = part.Size
			local Tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0, 0, 0)})
			Tween:Play()
		end
	end
end

function VFXModule.GrowModel(model, duration)
	local originalSizes = {}
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			originalSizes[part] = part.Size
			part.Size = Vector3.new(0, 0, 0)
		end
	end
	for part, originalSize in pairs(originalSizes) do
		local Tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = originalSize})
		Tween:Play()
	end
end

function VFXModule.FadeModel(model, fadeIn, duration)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local Goal = {Transparency = fadeIn and 0 or 1}
			local Tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Goal)
			Tween:Play()
			if not fadeIn then
				Tween.Completed:Connect(function()
					if model then
						model:Destroy()
					end
				end)
			end
		end
	end
end

function VFXModule.SpinModel(model, speed)
	if model.PrimaryPart then
		local connection
		connection = RunService.Heartbeat:Connect(function(deltaTime)
			if not model.Parent then
				connection:Disconnect()
			else
				local rotation = CFrame.Angles(0, math.rad(speed * deltaTime), 0)
				model:SetPrimaryPartCFrame(model.PrimaryPart.CFrame * rotation)
			end
		end)
	end
end

function VFXModule.SpinMotor(motor, speed)
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not motor.Parent then
			connection:Disconnect()
		else
			motor.C0 = motor.C0 * CFrame.Angles(0, math.rad(speed), 0)
		end
	end)
end


function VFXModule.TransferEffects(model, targetPart, duration)
	local sourcePart
	for _, obj in ipairs(model:GetChildren()) do
		if obj:IsA("BasePart") then
			sourcePart = obj
			break
		end
	end
	if sourcePart and targetPart then
		for _, obj in ipairs(sourcePart:GetChildren()) do
			if obj:IsA("Attachment") or obj:IsA("ParticleEmitter") then
				local clone = obj:Clone()
				clone.Parent = targetPart
				if obj:IsA("ParticleEmitter") or obj:IsA("Attachment") then
					if duration then
						task.delay(duration, function()
							clone:Destroy()
						end)
					end
				end
			end
		end
	end
end

function VFXModule.SeismicRocksEffect(parentFolder, riseHeight, riseTime, fadeTime, delayBetween)
    delayBetween = delayBetween or 0.2 

    for _, folder in ipairs(parentFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, rock in ipairs(folder:GetChildren()) do
                if rock:IsA("Model") then
                    for _, part in ipairs(rock:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Transparency = 1
                            part.CanCollide = false
                        end
                    end
                end
            end
        end
    end

    local rocks = {}
    for _, folder in ipairs(parentFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, rock in ipairs(folder:GetChildren()) do
                if rock:IsA("Model") and rock.PrimaryPart then
                    table.insert(rocks, rock)
                end
            end
        end
    end

    table.sort(rocks, function(a, b)
        return a.Name < b.Name
    end)

    for i, rock in ipairs(rocks) do
        task.delay((i - 1) * delayBetween, function()
            local originalPos = rock.PrimaryPart.Position
            local undergroundPos = originalPos - Vector3.new(0, riseHeight, 0)

            rock:SetPrimaryPartCFrame(CFrame.new(undergroundPos))

            local centerCFrame = rock.PrimaryPart.CFrame + Vector3.new(0,8,0)
            for j = 1, math.random(4, 6) do
                local brick = Instance.new("Part")
                brick.Size = Vector3.new(1, 1, 1)
                brick.Shape = Enum.PartType.Block
                brick.Anchored = false
                brick.CanCollide = true
                brick.CFrame = centerCFrame
                brick.BrickColor = BrickColor.new("Brown")
                brick.Parent = game.Workspace

                local randomDirection = Vector3.new(math.random(-2, 2), math.random(5, 10), math.random(-2, 2))
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(5000, 5000, 5000)
                bodyVelocity.Velocity = randomDirection
                bodyVelocity.Parent = brick
                game:GetService("Debris"):AddItem(bodyVelocity, .3)

                task.delay(1, function()
                    VFXModule.FadeModel(brick, false, fadeTime)
                    task.delay(fadeTime, function()
                        brick:Destroy()
                    end)
                end)
            end

            for _, part in ipairs(rock:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 0

                    local randomYSize = math.random(8, 12)
                    part.Size = Vector3.new(part.Size.X, randomYSize, part.Size.Z)
                end
            end

            local randomRotation = math.random(-25, 25)

            local rotationCFrame = CFrame.Angles(math.rad(randomRotation), math.rad(randomRotation), math.rad(randomRotation))
			rock:SetPrimaryPartCFrame(rock.PrimaryPart.CFrame * rotationCFrame)

            local Tween = TweenService:Create(
                rock.PrimaryPart,
                TweenInfo.new(riseTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = originalPos}
            )
            Tween:Play()

            task.delay(riseTime, function()
                VFXModule.FadeModel(rock, false, fadeTime)
                task.delay(fadeTime, function()
                    rock:Destroy()
                end)
            end)
        end)
    end
end



return VFXModule
