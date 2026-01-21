--// Signals by Snuv \\--

--// Services
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

--// Internal Helper
local function EnsureFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

--// Folders
local Signals = EnsureFolder(script.Parent.Parent, "Remotes")
local Locked = EnsureFolder(ServerStorage, "Remotes")

--// Type
type settingsType = {
	Name: string,
	Locked: boolean
}

--// Module
local signal = {}

-- Helper lookup
local function GetSignal(name: string): RemoteEvent?
	return Signals:FindFirstChild(name) or Locked:FindFirstChild(name)
end

-- ===== Module Functions ===== --

function signal.new(settings: settingsType): RemoteEvent?
	if RunService:IsClient() then
		error("Clients are not allowed to create signals.", 2)
	end

	assert(settings.Name, "Signal needs a name to be created.")
	settings.Locked = settings.Locked or false

	-- Prevent accidental duplicates
	local existing = GetSignal(settings.Name)
	if existing then
		return existing
	end

	local parent = settings.Locked and Locked or Signals

	local newSignal = Instance.new("RemoteEvent")
	newSignal.Name = settings.Name
	newSignal.Parent = parent

	return newSignal
end

function signal.destroy(name: string)
	local event = GetSignal(name)
	if event then
		event:Destroy()
	end
end

function signal.get(name: string, createIfInvalid: boolean?): RemoteEvent?
	local event = GetSignal(name)
	if event then
		return event
	end

	if createIfInvalid and RunService:IsServer() then
		return signal.new({ Name = name, Locked = false })
	end
end

return table.freeze(signal)
