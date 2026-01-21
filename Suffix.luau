--// Suffix by Snuv \\--

local Suffix = {}

-- Round helpers
local function roundDecimal(n, decimals)
	decimals = decimals or 1
	local mult = 10 ^ decimals
	return math.floor(n * mult + 0.5) / mult
end

-- Adds commas to large numbers
local function addCommas(num)
	local left, digits, right = string.match(tostring(num), '^([^%d]*%d)(%d*)(.-)$')
	digits = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return left .. digits .. right
end

-- Predefined base suffixes (start at 1 million)
local baseSuffixes = {
	{1e6, "M"},
	{1e9, "B"},
	{1e12, "T"},
	{1e21, "KT"},
	{1e32, "MT"},
	{1e43, "BT"},
	{1e54, "TT"},
}

-- Adds a suffix to large numbers
function Suffix.Number(n)
	assert(typeof(n) == "number", "[Suffix.Number] input must be a number")

	-- Numbers below 1 million show full number
	if n < 1e6 then
		if n >= 1000 then
			return addCommas(math.floor(n))
		else
			return tostring(roundDecimal(n))
		end
	end

	local value, suffix = 1, ""
	for _, entry in ipairs(baseSuffixes) do
		if n >= entry[1] then
			value, suffix = entry[1], entry[2]
		else
			break
		end
	end

	local scaled = n / value
	local display = roundDecimal(scaled)

	-- Format string with commas if needed
	local str = tostring(display)
	if display >= 1000 then
		str = addCommas(math.floor(display))
	end

	return str .. suffix
end

-- Get only the suffix for a number
function Suffix.GetSuffix(n)
	assert(typeof(n) == "number", "[Suffix.GetSuffix] input must be a number")

	if n < 1e6 then
		return "" -- no suffix for numbers below 1 million
	end

	local suffix = ""
	for _, entry in ipairs(baseSuffixes) do
		if n >= entry[1] then
			suffix = entry[2]
		else
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

	for _, unit in ipairs(timeUnits) do
		local unitValue, unitName = unit[1], unit[2]
		if seconds >= unitValue then
			local count = math.floor(seconds / unitValue)
			seconds = seconds - (count * unitValue)
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
