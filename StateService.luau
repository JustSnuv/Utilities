--// StateService by Snuv \\--

local StateService = {}

local PlayerStates = {} -- [Player] = { [stateKey] = { value, timestamp, history? } }

-- Creates a new state or overwrites an existing one
function StateService.SetState(player: Player, key: string, value: any)
	local now = tick()
	PlayerStates[player] = PlayerStates[player] or {}

	local current = PlayerStates[player][key]

	if current then
		current.history = current.history or {}
		table.insert(current.history, { time = now, value = current.value })
	end

	PlayerStates[player][key] = {
		value = value,
		timestamp = now,
		history = current and current.history or nil
	}
end

-- Get current value of a state
function StateService.GetState(player: Player, key: string)
	local entry = PlayerStates[player]
	return entry and entry[key]
end

-- Get historical values (if history is enabled)
function StateService.GetHistory(player: Player, key: string)
	local entry = PlayerStates[player]
	if entry and entry[key] then
		return entry[key].history or {}
	end
	return {}
end

-- Check if player had a value at a past time
function StateService.WasState(player: Player, key: string, time: number)
	local history = StateService.GetHistory(player, key)
	for i = #history, 1, -1 do
		if history[i].time <= time then
			return history[i].value
		end
	end
	return nil
end

-- Cleanup
function StateService.RemovePlayer(player: Player)
	PlayerStates[player] = nil
end

return StateService
