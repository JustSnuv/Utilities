--// Suffix by Snuv \\--

local Suffix = {}
local Classic = true

-- Round helpers
local function roundDecimal(n, decimals)
	decimals = decimals or 2
	local mult = 10 ^ decimals
	return math.floor(n * mult + 0.5) / mult
end

-- Adds commas to large numbers
local function addCommas(num)
	local str = tostring(math.floor(num))
	local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return formatted
end

-- Predefined base suffixes
local baseSuffixes = {
	Custom = {
		{1e6, "M"}, {1e9, "B"}, {1e12, "T"}, {1e15, "KT"}, {1e18, "MT"}, {1e21, "BT"}, {1e24, "TT"},
	},
	Classic = {
		{1e6, "M"}, {1e9, "B"}, {1e12, "T"}, {1e15, "Qa"}, {1e18, "Qi"}, {1e21, "Sx"}, {1e24, "Sp"},
		{1e27, "Oc"}, {1e30, "No"}, {1e33, "Dc"}, {1e36, "Ud"}, {1e39, "Dd"}, {1e42, "Td"},
	}
}

local function formatLargeNumber(Input, Suffixes, useScientific)
	-- Scientific Mode Toggle
	if useScientific and Input >= 1e6 then
		local exponent = math.floor(math.log10(Input))
		local mantissa = Input / (10 ^ exponent)
		return string.format("%.2fe%d", mantissa, exponent)
	end

	-- Standard Suffix Logic
	for i = #Suffixes, 1, -1 do
		local limit, suffix = Suffixes[i][1], Suffixes[i][2]
		if Input >= limit then
			local scaled = Input / limit
			local rounded = roundDecimal(scaled, 1)
			local displayValue = (rounded >= 1000) and addCommas(rounded) or tostring(rounded)
			return displayValue .. suffix
		end
	end

	if Input >= 1000 then
		return addCommas(Input)
	end
	return tostring(roundDecimal(Input, 1))
end

-- n: The number
-- scientific: boolean (true for scientific, nil/false for suffixes)
function Suffix.Number(n: number?, scientific: boolean?): string
	local val = n or 0
	if val >= 1.79e308 then return "Infinite" end

	local suffixes = Classic and baseSuffixes.Classic or baseSuffixes.Custom
	local result = formatLargeNumber(math.abs(val), suffixes, scientific)

	return (val < 0 and "-" or "") .. result
end

-- Time formatting helper
local timeUnits = {
	{86400, "d"}, {3600, "h"}, {60, "m"}, {1, "s"}
}

function Suffix.Time(seconds, mode)
	local remaining = math.max(0, seconds)
	local result = {}

	for _, unit in ipairs(timeUnits) do
		local val, name = unit[1], unit[2]
		if remaining >= val then
			local count = math.floor(remaining / val)
			remaining -= (count * val)
			table.insert(result, count .. name)
			if mode == "single" then break end
		end
	end

	return #result > 0 and table.concat(result, " ") or "0s"
end

return table.freeze(Suffix)
