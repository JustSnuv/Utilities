--// Services
local TweenService = game:GetService("TweenService")

local ModelTweenService = {}
ModelTweenService.__index = ModelTweenService

function ModelTweenService:Create(Model: Model, Info: TweenInfo, Goal: CFrame)
	assert(Model and Model:IsA("Model"), "Expected model for tween")
	assert(Model.PrimaryPart, "Expected PrimaryPart of model")
	assert(Info, "Expected TweenInfo for tween")
	assert(Goal, "Expected goal for tween")
	
	local self = setmetatable({}, ModelTweenService)

	self.Model = Model
	self.Goal = Goal
	self.Info = Info
	self.Value = Instance.new("CFrameValue")
	self.Value.Value = Model.PrimaryPart.CFrame

	self.Completed = Instance.new("BindableEvent")
	self.Played = false
	self.IsPlaying = false

	self.Connection = self.Value:GetPropertyChangedSignal("Value"):Connect(function()
		if Model:IsDescendantOf(game) then
			Model:SetPrimaryPartCFrame(self.Value.Value)
		end
	end)

	self.Tween = TweenService:Create(self.Value, self.Info, { Value = Goal })
	self.Tween.Completed:Connect(function(State)
		self.IsPlaying = false
		self.Played = true
		self.Completed:Fire(State)
	end)
	
	return self
end

function ModelTweenService:Play(Setting: { PlayIfPlayed: boolean })
	Setting = Setting or { PlayIfPlayed = true }
	
	if not Setting.PlayIfPlayed then if self.Played then return end end
	if self.IsPlaying then return end

	self.Value.Value = self.Model.PrimaryPart.CFrame
	self.Tween = TweenService:Create(self.Value, self.Info, { Value = self.Goal })
	self.IsPlaying = true
	self.Played = true
	self.Tween:Play()
end

function ModelTweenService:Cancel()
	if self.IsPlaying then
		self.IsPlaying = false
		self.Tween:Cancel()
	end
end

function ModelTweenService:Destroy()
	if self.Connection then self.Connection:Disconnect() self.Connection = nil end
	if self.Value then self.Value:Destroy() self.Value = nil end
	if self.Completed then self.Completed:Destroy() self.Completed = nil end
end

return ModelTweenService
