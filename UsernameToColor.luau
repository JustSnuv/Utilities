--// UsernameToColor by Snuv \\--
local UsernameToColor = {}

function UsernameToColor.GetColor(Username: string, DarkMode: boolean)
	DarkMode = DarkMode or false

	local Hash = 0
	for i = 1, #Username do
		Hash = (Hash * 31 + string.byte(Username, i)) % 16777216 -- 2^24
	end

	local brightness = DarkMode and 180 or 130

	local R = math.floor(Hash / 65536) % 256
	local G = math.floor(Hash / 256) % 256
	local B = Hash % 256

	local max = math.max(R, G, B)
	if max > 0 then
		local Scale = brightness / max
		R = math.floor(R * Scale)
		G = math.floor(G * Scale)
		B = math.floor(B * Scale)
	end

	return R, G, B
end

return UsernameToColor 
