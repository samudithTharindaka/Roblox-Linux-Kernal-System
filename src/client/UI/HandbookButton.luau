--!strict
-- HandbookButton.luau
-- Floating button to toggle handbook

local Constants = require(game.ReplicatedStorage.Shared.Constants)

local HandbookButton = {}
HandbookButton.__index = HandbookButton

function HandbookButton.new(playerGui: PlayerGui)
	local self = setmetatable({}, HandbookButton)

	self.playerGui = playerGui
	self.screenGui = nil
	self.button = nil
	self.isHandbookOpen = false
	self.onToggleCallback = nil

	self:_createUI()

	return self
end

function HandbookButton:_createUI()
	-- Create ScreenGui
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "HandbookButtonGui"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self.screenGui.DisplayOrder = 100
	self.screenGui.Parent = self.playerGui

	-- Main Button
	self.button = Instance.new("TextButton")
	self.button.Name = "HandbookButton"
	self.button.Size = UDim2.new(0, 60, 0, 60)
	self.button.Position = UDim2.new(1, -150, 1, -80) -- Left of terminal button
	self.button.AnchorPoint = Vector2.new(0, 0)
	self.button.BackgroundColor3 = Color3.fromRGB(40, 60, 100)
	self.button.BorderSizePixel = 0
	self.button.AutoButtonColor = false
	self.button.Text = ""
	self.button.Parent = self.screenGui

	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = self.button

	-- Icon (Book symbol)
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "📖"
	icon.Font = Enum.Font.SourceSansBold
	icon.TextSize = 32
	icon.Parent = self.button

	-- Tooltip
	local tooltip = Instance.new("TextLabel")
	tooltip.Name = "Tooltip"
	tooltip.Size = UDim2.new(0, 160, 0, 30)
	tooltip.Position = UDim2.new(0, -170, 0.5, -15)
	tooltip.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	tooltip.BorderSizePixel = 0
	tooltip.Text = "Handbook (F1 key)"
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
	stroke.Color = Color3.fromRGB(100, 150, 255)
	stroke.Thickness = 2
	stroke.Transparency = 0.5
	stroke.Parent = self.button

	-- Gradient for depth
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 80, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 50, 90)),
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

	-- Pulse animation
	self:_startPulseAnimation()
end

function HandbookButton:_onHover(isHovering: boolean)
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

function HandbookButton:_onClick()
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

function HandbookButton:_startPulseAnimation()
	task.spawn(function()
		local stroke = self.button:FindFirstChild("UIStroke")
		if not stroke then
			return
		end

		while self.button and self.button.Parent do
			-- Gentle pulse effect
			for i = 1, 10 do
				stroke.Transparency = 0.5 + (math.sin(i / 3) * 0.2)
				task.wait(0.1)
			end
		end
	end)
end

function HandbookButton:setHandbookState(isOpen: boolean)
	self.isHandbookOpen = isOpen

	local icon = self.button:FindFirstChild("Icon")
	if icon then
		if isOpen then
			icon.Text = "📕" -- Closed book
			self.button.BackgroundColor3 = Color3.fromRGB(70, 90, 130)
		else
			icon.Text = "📖" -- Open book
			self.button.BackgroundColor3 = Color3.fromRGB(40, 60, 100)
		end
	end
end

function HandbookButton:onToggle(callback: () -> ())
	self.onToggleCallback = callback
end

function HandbookButton:show()
	self.button.Visible = true
end

function HandbookButton:hide()
	self.button.Visible = false
end

function HandbookButton:destroy()
	if self.screenGui then
		self.screenGui:Destroy()
	end
end

return HandbookButton


