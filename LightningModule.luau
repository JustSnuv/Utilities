
--// Services
local Lighting = game:GetService("Lighting")

--// Variables
local LightProperties = {
	["Lighting"] = {
		"Ambient", "Brightness", "ClockTime", "ColorShift_Bottom", "ColorShift_Top",
		"EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ExposureCompensation",
		"GeographicLatitude", "GlobalShadows", "OutdoorAmbient", "ShadowSoftness",
	},
	["Atmosphere"] = { "Color", "Decay", "Density", "Glare", "Haze", "Offset" },
	["Clouds"] = { "Color", "Cover", "Density", "Enabled" },
	["Sky"] = {
		"CelestialBodiesShown", "MoonAngularSize", "MoonTextureId", "SkyboxBk", "SkyboxDn",
		"SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp", "SkyboxOrientation", "StarCount",
		"SunAngularSize", "SunTextureId",
	},
	["BloomEffect"] = { "Intensity", "Size", "Threshold", "Enabled" },
	["BlurEffect"] = { "Size", "Enabled" },
	["ColorCorrectionEffect"] = { "Brightness", "Contrast", "Saturation", "TintColor", "Enabled" },
	["DepthOfFieldEffect"] = { "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity", "Enabled" },
	["SunRaysEffect"] = { "Intensity", "Spread", "Enabled" },
}

local LightingSaver = {}

--// Helper
local function SerializeTable(val, indent)
	indent = indent or 1
	local tabs = string.rep("\t", indent)
	local result = "{\n"

	for k, v in pairs(val) do
		local key = type(k) == "string" and '["' .. k .. '"]' or "[" .. k .. "]"
		local value

		if type(v) == "table" then
			value = SerializeTable(v, indent + 1)
		elseif type(v) == "string" then
			value = '"' .. v .. '"'
		else
			value = tostring(v)
		end

		result = result .. tabs .. key .. " = " .. value .. ",\n"
	end

	return result .. string.rep("\t", indent - 1) .. "}"
end

function IsHex(text)
	return (tostring(text)):match("^%s*%#?(%x%x%x%x%x%x)%s*$") ~= nil
end

function IsVector3(text)
	return #(tostring(text)):split(",") == 3
end

function LightingSaver.Save(self: any)
	local toSave = { Lighting }
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then table.insert(toSave, clouds) end

	local Data = {}

	for _, child in Lighting:GetChildren() do
		if LightProperties[child.ClassName] then
			table.insert(toSave, child)
		end
	end

	for _, Inst in toSave do
		local className = Inst.ClassName
		Data[className] = {}
		for _, prop in LightProperties[className] do
			local val = Inst[prop]
			if typeof(val) == "Color3" then
				Data[className][prop] = "#" .. val:ToHex()
			elseif typeof(val) == "boolean" or type(val) == "number" then
				Data[className][prop] = val
			else
				Data[className][prop] = tostring(val)
			end
		end
	end

	return Data
end

--// Main functions

-- Creates a physical ModuleScript containing the data
function LightingSaver.ExportToModule(self: any, name: string, parent: Instance)
	local data = self:Save()
	local source = "-- Lighting Preset Generated " .. os.date("%x") .. "\n"
	source = source .. "return " .. SerializeTable(data)

	local newModule = Instance.new("ModuleScript")
	newModule.Name = name or "NewLightingPreset"
	newModule.Source = source
	newModule.Parent = parent or game.ServerStorage

	return newModule
end

function LightingSaver.Load(self: any, Data: any)
	-- Clear old effects
	for _, Obj in pairs(Lighting:GetChildren()) do
		if not Obj:IsA("Configuration") and not Obj:GetAttribute("Keep") then
			Obj:Destroy()
		end
	end

	for className, props in Data do
		local RealInst
		if className == "Lighting" then
			RealInst = Lighting
		elseif className == "Clouds" then
			RealInst = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds", workspace.Terrain)
		else
			RealInst = Instance.new(className)
			RealInst.Parent = Lighting
		end

		for prop, value in props do
			if type(value) == "string" and IsHex(value) then
				RealInst[prop] = Color3.fromHex(value)
			elseif type(value) == "string" and IsVector3(value) then
				local parts = value:split(",")
				RealInst[prop] = Vector3.new(tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3]))
			else
				RealInst[prop] = value
			end
		end
	end
end

return LightingSaver
