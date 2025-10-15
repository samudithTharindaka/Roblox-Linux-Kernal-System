--!strict
-- HtopViewer.luau
-- Process viewer UI (like htop)

local Constants = require(game.ReplicatedStorage.Shared.Constants)

local HtopViewer = {}
HtopViewer.__index = HtopViewer

function HtopViewer.new(playerGui: PlayerGui)
	local self = setmetatable({}, HtopViewer)

	self.playerGui = playerGui
	self.screenGui = nil
	self.viewerFrame = nil
	self.contentLabel = nil
	self.isVisible = false

	self:_createUI()

	return self
end

function HtopViewer:_createUI()
	-- Create ScreenGui
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "HtopViewerGui"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self.screenGui.Parent = self.playerGui

	-- Viewer Frame
	self.viewerFrame = Instance.new("Frame")
	self.viewerFrame.Name = "HtopViewer"
	self.viewerFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
	self.viewerFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
	self.viewerFrame.BackgroundColor3 = Constants.COLORS.TERMINAL_BG
	self.viewerFrame.BorderSizePixel = 2
	self.viewerFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
	self.viewerFrame.Visible = false
	self.viewerFrame.Parent = self.screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = self.viewerFrame

	-- Title Bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 30)
	titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = self.viewerFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = titleBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "htop - Process Viewer"
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 16
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Close Button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 25, 0, 25)
	closeButton.Position = UDim2.new(1, -30, 0, 2.5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "X"
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.TextSize = 14
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 4)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		self:close()
	end)

	-- Content Scrolling Frame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ContentScroll"
	scrollFrame.Size = UDim2.new(1, -20, 1, -50)
	scrollFrame.Position = UDim2.new(0, 10, 0, 40)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scrollFrame.Parent = self.viewerFrame

	-- Content Label
	self.contentLabel = Instance.new("TextLabel")
	self.contentLabel.Name = "Content"
	self.contentLabel.Size = UDim2.new(1, -20, 1, 0)
	self.contentLabel.Position = UDim2.new(0, 5, 0, 0)
	self.contentLabel.BackgroundTransparency = 1
	self.contentLabel.Text = ""
	self.contentLabel.Font = Enum.Font.Code
	self.contentLabel.TextSize = 14
	self.contentLabel.TextColor3 = Constants.COLORS.TERMINAL_TEXT
	self.contentLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.contentLabel.TextYAlignment = Enum.TextYAlignment.Top
	self.contentLabel.RichText = true
	self.contentLabel.TextWrapped = true
	self.contentLabel.Parent = scrollFrame
end

function HtopViewer:open(processData: string)
	self.contentLabel.Text = processData
	self.viewerFrame.Visible = true
	self.isVisible = true

	-- Update canvas size
	self.contentLabel.Size = UDim2.new(1, -20, 0, self.contentLabel.TextBounds.Y)
	local scrollFrame = self.viewerFrame:FindFirstChild("ContentScroll")
	if scrollFrame then
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, self.contentLabel.TextBounds.Y + 10)
	end
end

function HtopViewer:close()
	self.viewerFrame.Visible = false
	self.isVisible = false
end

function HtopViewer:update(processData: string)
	self.contentLabel.Text = processData

	-- Update canvas size
	self.contentLabel.Size = UDim2.new(1, -20, 0, self.contentLabel.TextBounds.Y)
	local scrollFrame = self.viewerFrame:FindFirstChild("ContentScroll")
	if scrollFrame then
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, self.contentLabel.TextBounds.Y + 10)
	end
end

function HtopViewer:destroy()
	if self.screenGui then
		self.screenGui:Destroy()
	end
end

return HtopViewer

