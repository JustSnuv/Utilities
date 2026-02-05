--// CoreGUI by Snuv \\--

local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local CoreGUI = {}

function CoreGUI.Toggle(Type: any, Enable: boolean)
	if Type == nil then return end

	local Success = false
	local Connection

	Connection = RunService.Heartbeat:Connect(function()
		local ok, err = pcall(function()
			if typeof(Type) == "EnumItem" then
				StarterGui:SetCoreGuiEnabled(Type, Enable)
			elseif typeof(Type) == "string" then
				StarterGui:SetCore(Type, Enable)
			end
		end)

		if ok then
			Connection:Disconnect()
		end
	end)
end

return table.freeze(CoreGUI)
