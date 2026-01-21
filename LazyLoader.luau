--// LazyLoader by Snuv \\--

local LazyLoader = {}
local loadedModules = {}
local loadingModules = {}

-- Load a single module with Initialize lifecycle
function LazyLoader.Get(module, options, data)
	assert(typeof(module) == "Instance" and module:IsA("ModuleScript"),
		"Expected ModuleScript")

	if loadedModules[module] then
		return loadedModules[module]
	end

	if loadingModules[module] then
		error("Circular dependency detected: " .. module:GetFullName())
	end

	loadingModules[module] = true
	local success, result = pcall(require, module)
	loadingModules[module] = nil

	if not success then
		error("Failed to require " .. module:GetFullName())
	end

	-- Lifecycle hook with data
	if type(result.Initialize) == "function" then
		task.spawn(function()
			result.Initialize(data) 
		end)
	end

	loadedModules[module] = result
	return result
end

-- Load all modules in a folder in deterministic order
function LazyLoader.InitializeFolder(folder, data)
	-- You can sort modules by name to ensure order if necessary
	local modules = folder:GetChildren()
	table.sort(modules, function(a, b) return a.Name < b.Name end)

	for _, module in ipairs(modules) do
		if module:IsA("ModuleScript") then
			LazyLoader.Get(module, nil, data)
		end
	end
end

return LazyLoader
