--// SoundService by Snuv \\--

local Debris = game:GetService("Debris")

local SoundService = {}

function SoundService.New(Parent: any,
	SoundData:
		{ Name: string?, Id: string?, StartPos: number? },
	Settings:
		{  Pitch: number?, Volume: number?, Looped: boolean?, PlaybackSpeed: number?, Lenght: number?, RollOffMaxDistance: number? }
)

	assert(SoundData.Id or typeof(SoundData.Id) == "string", "[Library-Sound]: SoundData passed was incomplete.")
	assert(SoundData.StartPos or typeof(SoundData.StartPos) == "number", "[Library-Sound]: SoundData passed was incomplete.")

	local Sound = Instance.new("Sound")
	Sound.Name = SoundData.Name or "Sound"
	Sound.SoundId = SoundData.Id
	Sound.Volume = Settings.Volume or 1
	Sound.PlaybackSpeed = Settings.PlaybackSpeed or 1
	Sound.Looped = Settings.Looped or false
	Sound.RollOffMaxDistance = Settings.RollOffMaxDistance or 10000
	
	if Settings.Pitch and Settings.Pitch ~= 1 then
		local Pitch = Instance.new("PitchShiftSoundEffect", Sound)
		Pitch.Octave = Settings.Pitch or 1
	end

	Sound.Parent = Parent
	repeat
		task.wait(0.01)
	until Sound.IsLoaded
	Sound.TimePosition = SoundData.StartPos

	if Settings.Looped and Settings.Looped == true then
		return Sound
	else
		Sound:Play()
		Debris:AddItem(Sound, Settings.Lenght or Sound.TimeLength)
	end
end

return table.freeze(SoundService)
