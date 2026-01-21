--// CoreGUI by Snuv \\--

local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local CoreGUI = {}

function CoreGUI.Toggle(Type: Enum.CoreGuiType, Enable: boolean)
	if not Type then return end

	local Disabled = false
	local DisableConnection

	DisableConnection = RunService.Heartbeat:Connect(function()
		if not Disabled then
			local success, err = pcall(function()
				StarterGui:SetCoreGuiEnabled(Type, Enable)
			end)

			if success then
				Disabled = true
				DisableConnection:Disconnect()
			end
		end
	end)
end

return table.freeze(CoreGUI)
