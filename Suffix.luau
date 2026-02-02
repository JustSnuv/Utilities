--// Suffix by Snuv \\--

local Suffix = {}
local Classic = true

-- Round helpers
local function roundDecimal(n, decimals)
	decimals = decimals or 1
	local mult = 10 ^ decimals
	return math.floor(n * mult + 0.5) / mult
end

-- Adds commas to large numbers
local function addCommas(num)
	local str = tostring(math.floor(num))
	-- Pattern logic: find groups of 3 digits and add a comma
	local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	-- Remove leading comma if it exists (happens with exact multiples of 3)
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return formatted
end

-- Predefined base suffixes
local baseSuffixes = {
	Custom = {
		{1e6, "M"},
		{1e9, "B"},
		{1e12, "T"},
		{1e15, "KT"},
		{1e18, "MT"},
		{1e21, "BT"},
		{1e24, "TT"},
	},
	Classic = {
		{1e6, "M"},
		{1e9, "B"},
		{1e12, "T"},
		{1e15, "Qa"},
		{1e18, "Qi"},
		{1e21, "Sx"},
		{1e24, "Sp"},
		{1e27, "Oc"},
		{1e30, "No"},
		{1e33, "Dc"},
		{1e36, "Ud"},
		{1e39, "Dd"},
		{1e42, "Td"},
		{1e45, "Qad"},
		{1e48, "Qid"},
		{1e51, "Sxd"},
		{1e54, "Spd"},
	}
}

local function formatLargeNumber(Input, Suffixes)
	-- Iterate backwards through suffixes to find the largest match
	for i = #Suffixes, 1, -1 do
		local limit, suffix = Suffixes[i][1], Suffixes[i][2]
		if Input >= limit then
			local scaled = Input / limit
			local rounded = roundDecimal(scaled)
			
			-- If the rounded number is >= 1000 (e.g. 1,200M), add commas to it
			local displayValue = (rounded >= 1000) and addCommas(rounded) or tostring(rounded)
			return displayValue .. suffix
		end
	end
	
	-- For numbers smaller than the first suffix (1M)
	if Input >= 1000 then
		return addCommas(Input)
	end
	return tostring(roundDecimal(Input))
end

-- Adds a suffix to large numbers
function Suffix.Number(n: number?): string
	assert(typeof(n) == "number", "[Suffix.Number] input must be a number")
	
	if n >= 1.7976931348e308 then -- Greater than max float
		return "Infinite"
	elseif n < 0 then
		-- Handle negatives by formatting the absolute value and prepending "-"
		return "-" .. formatLargeNumber(math.abs(n), Classic and baseSuffixes.Classic or baseSuffixes.Custom)
	else
		return formatLargeNumber(n, Classic and baseSuffixes.Classic or baseSuffixes.Custom)
	end
end

-- Get only the suffix for a number
function Suffix.GetSuffix(n)
	assert(typeof(n) == "number", "[Suffix.GetSuffix] input must be a number")

	local suffixes = Classic and baseSuffixes.Classic or baseSuffixes.Custom
	local suffix = ""
	
	for i = #suffixes, 1, -1 do
		if n >= suffixes[i][1] then
			suffix = suffixes[i][2]
			break
		end
	end

	return suffix
end

-- Time formatting helper
local timeUnits = {
	{86400, "day"},
	{3600, "hour"},
	{60, "minute"},
	{1, "second"}
}

-- Format time (single = largest unit only, all = stacked)
function Suffix.Time(seconds, mode)
	assert(typeof(seconds) == "number", "[Suffix.Time] seconds must be a number")
	mode = mode or "single" -- "single" or "all"

	local result = {}
	local remaining = seconds

	for _, unit in ipairs(timeUnits) do
		local unitValue, unitName = unit[1], unit[2]
		if remaining >= unitValue then
			local count = math.floor(remaining / unitValue)
			remaining = remaining - (count * unitValue)
			table.insert(result, count .. " " .. unitName .. (count > 1 and "s" or ""))
			if mode == "single" then
				break
			end
		end
	end

	if #result == 0 then
		return "0 seconds"
	end

	return table.concat(result, ", ")
end

return table.freeze(Suffix)
