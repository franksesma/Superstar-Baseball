local TweenService = game:GetService("TweenService")
local folder = script.Parent

local angle20 = math.rad(20)
local tweenTime = 6 -- seconds for each tween (same for both directions)

-- Gather all BeamBase parts in the folder
local beamBases = {}
for _, child in folder:GetChildren() do
    if child:IsA("Part") and child.Name == "BeamBase" then
        beamBases[#beamBases+1] = child
    end
end

-- Tween function for a single BeamBase rotating up/down smoothly at constant speed
local function startTweenLoop(part)
    -- Store the original orientation
    local baseCFrame
    if part.GetPivot then
        baseCFrame = part:GetPivot()
    else
        baseCFrame = part.CFrame
    end

    -- Loop: down → up → down → up ... at constant speed
    local function tweenLoop(direction)
        -- Always calculate target CFrame from original
        local targetCFrame
        if direction == "down" then
            targetCFrame = baseCFrame * CFrame.Angles(-angle20, 0, 0)
        else
            targetCFrame = baseCFrame * CFrame.Angles(angle20, 0, 0)
        end

        local tween = TweenService:Create(part, TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = targetCFrame})
        tween.Completed:Connect(function()
            -- Next direction
            if direction == "down" then
                tweenLoop("up")
            else
                tweenLoop("down")
            end
        end)
        tween:Play()
    end

    -- Start at original, then begin the loop
    part.CFrame = baseCFrame
    tweenLoop("down")
end

-- Start a coroutine for each BeamBase
for _, part in beamBases do
    coroutine.wrap(function()
        startTweenLoop(part)
    end)()
end

