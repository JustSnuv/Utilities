--// Tick by Snuv \\--

--// Services
local RunService = game:GetService("RunService")

local Tick = {}
Tick.__index = Tick

function Tick.new()
	local self = setmetatable({}, Tick)

	self._tasks = {}
	self._running = true

	RunService.Heartbeat:Connect(function(dt)
		if not self._running then return end

		for _, taskData in pairs(self._tasks) do
			taskData.Accumulator += dt

			while taskData.Accumulator >= taskData.Interval do
				taskData.Accumulator -= taskData.Interval
				taskData.Callback()
			end
		end
	end)

	return self
end

function Tick:HookTick(interval: number, callback: () -> ())
	assert(type(interval) == "number", "Interval must be number")
	assert(type(callback) == "function", "Callback must be function")

	local id = newproxy(true)

	local taskData = {
		BaseInterval = interval,
		Interval = interval,
		Speed = 1,
		Accumulator = 0,
		Callback = callback
	}

	self._tasks[id] = taskData

	return {
		Disconnect = function()
			self._tasks[id] = nil
		end,

		SetInterval = function(newInterval)
			taskData.BaseInterval = newInterval
			taskData.Interval = newInterval / taskData.Speed
		end,

		SetSpeed = function(multiplier)
			taskData.Speed = multiplier
			taskData.Interval = taskData.BaseInterval / multiplier
		end
	}
end

return Tick
