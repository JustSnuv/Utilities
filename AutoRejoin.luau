--// Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

--// Player
local Player = Players.LocalPlayer

--// Variables

local LastInputTime = os.clock()

local Config = {
	AFK_LIMIT = 18 * 60
}

local AutoRejoin = {}

function AutoRejoin.Initialize()
	local function MarkActive()
		LastInputTime = os.clock()
	end

	UserInputService.InputBegan:Connect(MarkActive)
	UserInputService.InputChanged:Connect(MarkActive)

	task.spawn(function()
		while task.wait(5) do
			if os.clock() - LastInputTime >= Config.AFK_LIMIT then
				if Player and Player.Parent then
					local success, err = pcall(function()
						TeleportService:Teleport(game.PlaceId, Player)
					end)

					if success then 
						break 
					else
						warn("Teleport failed, retrying in 10 seconds...")
						task.wait(10)
					end
				end
			end
		end
	end)
end

return table.freeze(AutoRejoin)
