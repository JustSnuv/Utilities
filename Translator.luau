--// Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

--// Variables
local player = Players.LocalPlayer
local defaultLanguageCode = "EN"

local Translations = {}

--// Functions

local function getLanguageCode(localeId: string): string
	local index = string.find(localeId, "-")
	if index then
		return string.sub(localeId, 1, index - 1)
	else
		return localeId
	end
end

local playerLanguageCode = string.upper(getLanguageCode(player.LocaleId or "en"))

local translationsList = require(script:WaitForChild("RawTranslations"))

local keyLookup = {}

for _, translation in pairs(translationsList) do
	if translation.Key then
		keyLookup[translation.Key] = translation
	end
end

for _, translation in pairs(translationsList) do
	for key, value in pairs(translation) do
		if type(value) == "string" and string.find(value, "{b}") then
			local newValue = value
				:gsub("{b}", '<font transparency="0">')
				:gsub("{/b}", "</font>")
			translation[key] = newValue
		end
	end
end

local function getTranslation(key: string): string
	local translation = keyLookup[key]

	if not translation then
		warn("[Translation Missing] No translation found for key:", key)
		return ""
	end

	local value = translation[playerLanguageCode]
	if not value then
		value = translation[defaultLanguageCode]
	end

	return value or ""
end

function Translations.translateUI(uiParent: Instance)
	for _, element in pairs(uiParent:GetDescendants()) do
		local key = element:GetAttribute("HatchTranslationKey")
		if key and element:IsA("TextLabel") or element:IsA("TextButton") then
			local translationValue = getTranslation(key)
			element.Text = translationValue
		end
	end
end

function Translations.translate(key: string)
	local translation = keyLookup[key]
	if not translation then
		warn("[Translation Missing] No translation found for key:", key)
		return ""
	end

	local value = translation[playerLanguageCode] or translation[defaultLanguageCode] or ""
	return value
end
 
return table.freeze(Translations)
