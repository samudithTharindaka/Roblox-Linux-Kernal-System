--!strict
-- NanoEditor.luau
-- Simple text editor UI (like nano)

local UserInputService = game:GetService("UserInputService")
local Constants = require(game.ReplicatedStorage.Shared.Constants)

local NanoEditor = {}
NanoEditor.__index = NanoEditor

function NanoEditor.new(playerGui: PlayerGui)
	local self = setmetatable({}, NanoEditor)

	self.playerGui = playerGui
	self.screenGui = nil
	self.editorFrame = nil
	self.textBox = nil
	self.statusBar = nil
	self.fileName = ""
	self.isVisible = false
	self.onSaveCallback = nil
	self.onCloseCallback = nil

	self:_createUI()

	return self
end

function NanoEditor:_createUI()
	-- Create ScreenGui
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "NanoEditorGui"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self.screenGui.Parent = self.playerGui

	-- Editor Frame
	self.editorFrame = Instance.new("Frame")
	self.editorFrame.Name = "NanoEditor"
	self.editorFrame.Size = UDim2.new(0.7, 0, 0.7, 0)
	self.editorFrame.Position = UDim2.new(0.15, 0, 0.15, 0)
	self.editorFrame.BackgroundColor3 = Constants.COLORS.TERMINAL_BG
	self.editorFrame.BorderSizePixel = 2
	self.editorFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
	self.editorFrame.Visible = false
	self.editorFrame.Parent = self.screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = self.editorFrame

	-- Title Bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 30)
	titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = self.editorFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = titleBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Nano Editor"
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

	-- Text Box (Main editing area)
	self.textBox = Instance.new("TextBox")
	self.textBox.Name = "TextBox"
	self.textBox.Size = UDim2.new(1, -20, 1, -70)
	self.textBox.Position = UDim2.new(0, 10, 0, 40)
	self.textBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	self.textBox.BorderSizePixel = 1
	self.textBox.BorderColor3 = Color3.fromRGB(60, 60, 70)
	self.textBox.Text = ""
	self.textBox.Font = Enum.Font.Code
	self.textBox.TextSize = 14
	self.textBox.TextColor3 = Constants.COLORS.TERMINAL_TEXT
	self.textBox.TextXAlignment = Enum.TextXAlignment.Left
	self.textBox.TextYAlignment = Enum.TextYAlignment.Top
	self.textBox.ClearTextOnFocus = false
	self.textBox.MultiLine = true
	self.textBox.TextWrapped = true
	self.textBox.Parent = self.editorFrame

	local textCorner = Instance.new("UICorner")
	textCorner.CornerRadius = UDim.new(0, 4)
	textCorner.Parent = self.textBox

	-- Status Bar
	self.statusBar = Instance.new("Frame")
	self.statusBar.Name = "StatusBar"
	self.statusBar.Size = UDim2.new(1, 0, 0, 30)
	self.statusBar.Position = UDim2.new(0, 0, 1, -30)
	self.statusBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	self.statusBar.BorderSizePixel = 0
	self.statusBar.Parent = self.editorFrame

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 8)
	statusCorner.Parent = self.statusBar

	local helpLabel = Instance.new("TextLabel")
	helpLabel.Name = "Help"
	helpLabel.Size = UDim2.new(1, -20, 1, 0)
	helpLabel.Position = UDim2.new(0, 10, 0, 0)
	helpLabel.BackgroundTransparency = 1
	helpLabel.Text = "^S: Save  |  ^X: Exit  |  ESC: Cancel"
	helpLabel.Font = Enum.Font.SourceSans
	helpLabel.TextSize = 12
	helpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	helpLabel.TextXAlignment = Enum.TextXAlignment.Left
	helpLabel.Parent = self.statusBar

	-- Key bindings
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not self.isVisible then
			return
		end

		if gameProcessed then
			return
		end

		-- Ctrl+S: Save
		if input.KeyCode == Enum.KeyCode.S and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			self:save()
		end

		-- Ctrl+X or ESC: Exit
		if
			(input.KeyCode == Enum.KeyCode.X and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl))
			or input.KeyCode == Enum.KeyCode.Escape
		then
			self:close()
		end
	end)
end

function NanoEditor:open(fileName: string, content: string)
	self.fileName = fileName
	self.textBox.Text = content or ""
	self.editorFrame.Visible = true
	self.isVisible = true

	-- Update title
	local titleLabel = self.editorFrame.TitleBar:FindFirstChild("Title")
	if titleLabel then
		titleLabel.Text = "Nano Editor - " .. fileName
	end

	self.textBox:CaptureFocus()
end

function NanoEditor:close()
	self.editorFrame.Visible = false
	self.isVisible = false

	if self.onCloseCallback then
		self.onCloseCallback()
	end
end

function NanoEditor:save()
	if self.onSaveCallback then
		self.onSaveCallback(self.fileName, self.textBox.Text)
	end
end

function NanoEditor:onSave(callback: (string, string) -> ())
	self.onSaveCallback = callback
end

function NanoEditor:onClose(callback: () -> ())
	self.onCloseCallback = callback
end

function NanoEditor:destroy()
	if self.screenGui then
		self.screenGui:Destroy()
	end
end

return NanoEditor

