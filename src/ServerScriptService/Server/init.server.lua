local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.Services

local cachedModules = {}

for _, moduleScript in Services:GetDescendants() do
	if moduleScript:IsA("ModuleScript") then
		cachedModules[moduleScript.Name] = require(moduleScript)
	end
end

local requiredModule = require(script.CachedModules) 
requiredModule.Cache = cachedModules
requiredModule.CacheLoaded = true

for moduleName, moduleScript in cachedModules do
	moduleScript.cachedModules = cachedModules
	if typeof(moduleScript.init) == "function" then
		moduleScript.init()
	end
end

--Services.GameService.StartGame:Fire()

