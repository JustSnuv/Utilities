--// StateService by Snuv \\--

local StateService = {}

local PlayerStates = {} -- [Player] = { [stateKey] = { value, timestamp, history? } }
local HistoryCap = 20

-- Creates a new state or overwrites an existing one
function StateService.SetState(Player: Player, Key: string, Value: any)
	local Now = tick()
	PlayerStates[Player] = PlayerStates[Player] or {}

	local Current = PlayerStates[Player][Key]

	if Current then
		Current.history = Current.history or {}
		table.insert(Current.history, { time = Now, value = Current.Value })
	end
	
	if Current and Current.history and #Current.history >= HistoryCap then
		table.remove(Current.history, 1)
	end

	PlayerStates[Player][Key] = {
		value = Value,
		timestamp = Now,
		history = Current and Current.history or nil
	}
end

-- Get current value of a state
function StateService.GetState(Player: Player, Key: string)
	local s = StateService.GetState(Player, Key)
	return s and s.value
end

-- Get historical values (if history is enabled)
function StateService.GetHistory(Player: Player, Key: string)
	local Entry = PlayerStates[Player]
	if Entry and Entry[Key] then
		return Entry[Key].history or {}
	end
	return {}
end

-- Check if player had a value at a past time
function StateService.WasState(Player: Player, Key: string, Time: number)
	local history = StateService.GetHistory(Player, Key)
	for i = #history, 1, -1 do
		if history[i].Time <= Time then
			return history[i].value
		end
	end
	return nil
end

-- Cleanup
function StateService.RemovePlayer(Player: Player)
	PlayerStates[Player] = nil
end

return StateService
