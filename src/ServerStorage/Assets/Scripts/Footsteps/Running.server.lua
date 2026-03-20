local ModuleScript = {}

local running = true;
local Connection = nil;
local Humanoid = script.Parent.Parent:WaitForChild("Humanoid")

local function WhileRunning() 
    if script.Parent.Materials.Value == "Grass" then
        script.Parent.Grass:Play()
    elseif script.Parent.Materials.Value == "Water" then
        script.Parent.Splash:Play()
    elseif script.Parent.Materials.Value == "Wood" then
        script.Parent.Wood:Play()
    elseif script.Parent.Materials.Value == "Ice" then
        script.Parent.Ice:Play()
    elseif script.Parent.Materials.Value == "Plastic" then
        script.Parent.Plastic:Play()
    elseif script.Parent.Materials.Value == "WoodPlanks" then
        script.Parent.WoodPlanks:Play()
    elseif script.Parent.Materials.Value == "Cobblestone" then
        script.Parent.Cobblestone:Play()
    elseif script.Parent.Materials.Value == "Fabric" then
        script.Parent.Fabric:Play()
    elseif script.Parent.Materials.Value == "CMetal" then
        script.Parent.Diamond:Play()
    elseif script.Parent.Materials.Value == "Metal" then
        script.Parent.Metal:Play()
    elseif script.Parent.Materials.Value == "DiamondPlate" then
        script.Parent.Diamond:Play()
    elseif script.Parent.Materials.Value == "Concrete" then
        script.Parent.Concrete:Play()
    elseif script.Parent.Materials.Value == "Slate" then
        script.Parent.Dirt:Play()
    elseif script.Parent.Materials.Value == "Foil" then
        script.Parent.Foil:Play()
    elseif script.Parent.Materials.Value == "Brick" then
        script.Parent.Brick:Play()
    elseif script.Parent.Materials.Value == "Granite" then
        script.Parent.Granite:Play()
    elseif script.Parent.Materials.Value == "Marble" then
        script.Parent.Marble:Play()
    elseif script.Parent.Materials.Value == "Sand" then
        script.Parent.Sand:Play()
    elseif script.Parent.Materials.Value == "Pebble" then
        script.Parent.Pebble:Play()	
    end
end 

local function isRunning()
    if running and Humanoid.Parent.HumanoidRootPart.Velocity.magnitude > 1 then
        return true
    end
end


Humanoid.Jumping:connect(function()
    running = false;
end)


local function doWhileRunning()
    Connection:disconnect();
    running = true;
    while (isRunning()) do
        WhileRunning()
		task.wait(0.351)
    end
    running = false;
    Connection = Humanoid.Running:connect(doWhileRunning);
end

Connection = Humanoid.Running:connect(doWhileRunning)

return ModuleScript