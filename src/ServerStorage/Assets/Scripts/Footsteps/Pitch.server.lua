local ModuleScript = {}

while task.wait(.3) do
    x = script.Parent:GetChildren()
    for i = 1,#x do
        if x[i]:IsA("Sound") then
            x[i].Pitch = x[i].Pitch - 0.1
        end
    end
    
    task.wait(.3)
    
    x = script.Parent:GetChildren()
    for i = 1,#x do
        if x[i]:IsA("Sound") then
            x[i].Pitch = x[i].Pitch - 0.1
        end
    end
    
    task.wait(.3)
    
    x = script.Parent:GetChildren()
    for i = 1,#x do
        if x[i]:IsA("Sound") then
            x[i].Pitch = x[i].Pitch + 0.2
        end
    end
    
    task.wait(.3)
    
    x = script.Parent:GetChildren()
    for i = 1,#x do
        if x[i]:IsA("Sound") then
            x[i].Pitch = x[i].Pitch - 0.1
        end
    end
    
    task.wait(.3)
    
    x = script.Parent:GetChildren()
    for i = 1,#x do
        if x[i]:IsA("Sound") then
            x[i].Pitch = x[i].Pitch + 0.1
        end
    end
end

return ModuleScript