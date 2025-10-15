--!strict
-- TerminalButton.luau
-- Floating button to toggle terminal

local Constants = require(game.ReplicatedStorage.Shared.Constants)

local TerminalButton = {}
TerminalButton.__index = TerminalButton

function TerminalButton.new(playerGui: PlayerGui)
	local self = setmetatable({}, TerminalButton)

	self.playerGui = playerGui
	self.screenGui = nil
	self.button = nil
	self.isTerminalOpen = false
	self.onToggleCallback = nil

	self:_createUI()

	return self
end

function TerminalButton:_createUI()
	-- Create ScreenGui
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "TerminalButtonGui"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self.screenGui.DisplayOrder = 100 -- Always on top
	self.screenGui.Parent = self.playerGui

	-- Main Button
	self.button = Instance.new("TextButton")
	self.button.Name = "TerminalButton"
	self.button.Size = UDim2.new(0, 60, 0, 60)
	self.button.Position = UDim2.new(1, -80, 1, -80) -- Bottom right corner
	self.button.AnchorPoint = Vector2.new(0, 0)
	self.button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	self.button.BorderSizePixel = 0
	self.button.AutoButtonColor = false
	self.button.Text = ""
	self.button.Parent = self.screenGui

	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = self.button

	-- Icon (Terminal symbol)
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = ">"
	icon.Font = Enum.Font.SourceSansBold
	icon.TextSize = 32
	icon.TextColor3 = Constants.COLORS.PROMPT_COLOR
	icon.Parent = self.button

	-- Tooltip
	local tooltip = Instance.new("TextLabel")
	tooltip.Name = "Tooltip"
	tooltip.Size = UDim2.new(0, 150, 0, 30)
	tooltip.Position = UDim2.new(0, -160, 0.5, -15)
	tooltip.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	tooltip.BorderSizePixel = 0
	tooltip.Text = "Terminal (` key)"
	tooltip.Font = Enum.Font.SourceSans
	tooltip.TextSize = 14
	tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
	tooltip.Visible = false
	tooltip.Parent = self.button

	local tooltipCorner = Instance.new("UICorner")
	tooltipCorner.CornerRadius = UDim.new(0, 6)
	tooltipCorner.Parent = tooltip

	-- Stroke for better visibility
	local stroke = Instance.new("UIStroke")
	stroke.Color = Constants.COLORS.PROMPT_COLOR
	stroke.Thickness = 2
	stroke.Transparency = 0.5
	stroke.Parent = self.button

	-- Gradient for depth
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 70)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 40)),
	})
	gradient.Rotation = 45
	gradient.Parent = self.button

	-- Hover effects
	self.button.MouseEnter:Connect(function()
		self:_onHover(true)
	end)

	self.button.MouseLeave:Connect(function()
		self:_onHover(false)
	end)

	-- Click handler
	self.button.MouseButton1Click:Connect(function()
		self:_onClick()
	end)

	-- Pulse animation when terminal is open
	self:_startPulseAnimation()
end

function TerminalButton:_onHover(isHovering: boolean)
	local button = self.button
	local tooltip = button:FindFirstChild("Tooltip")

	if isHovering then
		-- Scale up slightly
		button:TweenSize(UDim2.new(0, 65, 0, 65), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)

		-- Show tooltip
		if tooltip then
			tooltip.Visible = true
		end

		-- Brighten stroke
		local stroke = button:FindFirstChild("UIStroke")
		if stroke then
			stroke.Transparency = 0.2
		end
	else
		-- Scale back
		button:TweenSize(UDim2.new(0, 60, 0, 60), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)

		-- Hide tooltip
		if tooltip then
			tooltip.Visible = false
		end

		-- Dim stroke
		local stroke = button:FindFirstChild("UIStroke")
		if stroke then
			stroke.Transparency = 0.5
		end
	end
end

function TerminalButton:_onClick()
	-- Trigger bounce animation
	local button = self.button
	button:TweenSize(UDim2.new(0, 55, 0, 55), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
	task.wait(0.1)
	button:TweenSize(UDim2.new(0, 60, 0, 60), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)

	-- Call callback
	if self.onToggleCallback then
		self.onToggleCallback()
	end
end

function TerminalButton:_startPulseAnimation()
	task.spawn(function()
		local stroke = self.button:FindFirstChild("UIStroke")
		if not stroke then
			return
		end

		while self.button and self.button.Parent do
			if self.isTerminalOpen then
				-- Pulse when terminal is open
				for i = 1, 10 do
					stroke.Transparency = 0.2 + (math.sin(i / 3) * 0.3)
					task.wait(0.1)
				end
			else
				task.wait(0.5)
			end
		end
	end)
end

function TerminalButton:setTerminalState(isOpen: boolean)
	self.isTerminalOpen = isOpen

	local icon = self.button:FindFirstChild("Icon")
	if icon then
		if isOpen then
			icon.Text = "−" -- Minimize symbol
			icon.TextColor3 = Constants.COLORS.WARNING_COLOR
		else
			icon.Text = ">" -- Terminal symbol
			icon.TextColor3 = Constants.COLORS.PROMPT_COLOR
		end
	end

	-- Update button color
	if isOpen then
		self.button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	else
		self.button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	end
end

function TerminalButton:onToggle(callback: () -> ())
	self.onToggleCallback = callback
end

function TerminalButton:show()
	self.button.Visible = true
end

function TerminalButton:hide()
	self.button.Visible = false
end

function TerminalButton:destroy()
	if self.screenGui then
		self.screenGui:Destroy()
	end
end

return TerminalButton

