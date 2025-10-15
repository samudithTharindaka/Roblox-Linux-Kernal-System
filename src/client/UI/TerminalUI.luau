--!strict
-- TerminalUI.luau
-- Terminal user interface creation and management

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Constants = require(game.ReplicatedStorage.Shared.Constants)

local TerminalUI = {}
TerminalUI.__index = TerminalUI

function TerminalUI.new(playerGui: PlayerGui)
	local self = setmetatable({}, TerminalUI)

	self.playerGui = playerGui
	self.screenGui = nil
	self.terminalFrame = nil
	self.outputFrame = nil
	self.outputLabel = nil
	self.inputBox = nil
	self.promptLabel = nil
	self.isVisible = false

	self:_createUI()

	return self
end

function TerminalUI:_createUI()
	-- Create ScreenGui
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "TerminalGui"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self.screenGui.Parent = self.playerGui

	-- Main Terminal Frame
	self.terminalFrame = Instance.new("Frame")
	self.terminalFrame.Name = "Terminal"
	self.terminalFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
	self.terminalFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
	self.terminalFrame.BackgroundColor3 = Constants.COLORS.TERMINAL_BG
	self.terminalFrame.BorderSizePixel = 2
	self.terminalFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
	self.terminalFrame.Parent = self.screenGui

	-- Add UICorner for rounded edges
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = self.terminalFrame

	-- Title Bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 30)
	titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = self.terminalFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = titleBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "RobloxOS Terminal"
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
		self:toggle()
	end)

	-- Output Frame (Scrolling)
	self.outputFrame = Instance.new("ScrollingFrame")
	self.outputFrame.Name = "OutputFrame"
	self.outputFrame.Size = UDim2.new(1, -20, 1, -80)
	self.outputFrame.Position = UDim2.new(0, 10, 0, 40)
	self.outputFrame.BackgroundTransparency = 1
	self.outputFrame.BorderSizePixel = 0
	self.outputFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.outputFrame.ScrollBarThickness = 8
	self.outputFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	self.outputFrame.Parent = self.terminalFrame

	-- Output Label (RichText enabled for colors)
	self.outputLabel = Instance.new("TextLabel")
	self.outputLabel.Name = "Output"
	self.outputLabel.Size = UDim2.new(1, -20, 1, 0)
	self.outputLabel.Position = UDim2.new(0, 5, 0, 0)
	self.outputLabel.BackgroundTransparency = 1
	self.outputLabel.Text = ""
	self.outputLabel.Font = Enum.Font.Code
	self.outputLabel.TextSize = 14
	self.outputLabel.TextColor3 = Constants.COLORS.TERMINAL_TEXT
	self.outputLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.outputLabel.TextYAlignment = Enum.TextYAlignment.Top
	self.outputLabel.RichText = true
	self.outputLabel.TextWrapped = true
	self.outputLabel.Parent = self.outputFrame

	-- Input Container
	local inputContainer = Instance.new("Frame")
	inputContainer.Name = "InputContainer"
	inputContainer.Size = UDim2.new(1, -20, 0, 30)
	inputContainer.Position = UDim2.new(0, 10, 1, -40)
	inputContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	inputContainer.BorderSizePixel = 1
	inputContainer.BorderColor3 = Color3.fromRGB(80, 80, 90)
	inputContainer.Parent = self.terminalFrame

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 4)
	inputCorner.Parent = inputContainer

	-- Prompt Label (uses TextService to calculate width dynamically)
	self.promptLabel = Instance.new("TextLabel")
	self.promptLabel.Name = "Prompt"
	self.promptLabel.Size = UDim2.new(0, 200, 1, 0) -- Will be updated dynamically
	self.promptLabel.Position = UDim2.new(0, 5, 0, 0)
	self.promptLabel.BackgroundTransparency = 1
	self.promptLabel.Text = "user@RobloxOS:~$ "
	self.promptLabel.Font = Enum.Font.Code
	self.promptLabel.TextSize = 14
	self.promptLabel.TextColor3 = Constants.COLORS.PROMPT_COLOR
	self.promptLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.promptLabel.TextWrapped = false
	self.promptLabel.Parent = inputContainer

	-- Input Box (positioned dynamically based on prompt width)
	self.inputBox = Instance.new("TextBox")
	self.inputBox.Name = "Input"
	self.inputBox.Size = UDim2.new(1, -210, 1, -4) -- Will be updated dynamically
	self.inputBox.Position = UDim2.new(0, 205, 0, 2) -- Will be updated dynamically
	self.inputBox.BackgroundTransparency = 1
	self.inputBox.Text = ""
	self.inputBox.PlaceholderText = "Enter command..."
	self.inputBox.Font = Enum.Font.Code
	self.inputBox.TextSize = 14
	self.inputBox.TextColor3 = Constants.COLORS.TERMINAL_TEXT
	self.inputBox.TextXAlignment = Enum.TextXAlignment.Left
	self.inputBox.ClearTextOnFocus = false
	self.inputBox.Parent = inputContainer

	-- Update layout initially
	self:_updateInputLayout()

	-- Make draggable (simple implementation)
	self:_makeDraggable()
end

function TerminalUI:_makeDraggable()
	local titleBar = self.terminalFrame:FindFirstChild("TitleBar")
	if not titleBar then
		return
	end

	local dragging = false
	local dragStart = nil
	local startPos = nil

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = self.terminalFrame.Position
		end
	end)

	titleBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			self.terminalFrame.Position =
				UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

function TerminalUI:show()
	self.terminalFrame.Visible = true
	self.isVisible = true
	self.inputBox:CaptureFocus()
end

function TerminalUI:hide()
	self.terminalFrame.Visible = false
	self.isVisible = false
end

function TerminalUI:toggle()
	if self.isVisible then
		self:hide()
	else
		self:show()
	end
end

function TerminalUI:setPrompt(prompt: string)
	self.promptLabel.Text = prompt
	self:_updateInputLayout()
end

function TerminalUI:_updateInputLayout()
	-- Wait for TextBounds to update
	task.wait()
	
	-- Get the actual width of the prompt text
	local promptWidth = self.promptLabel.TextBounds.X
	
	-- Add padding
	local padding = 10
	local totalPromptWidth = promptWidth + padding
	
	-- Update prompt label size
	self.promptLabel.Size = UDim2.new(0, totalPromptWidth, 1, 0)
	
	-- Update input box position and size
	local inputStartX = totalPromptWidth + 5
	self.inputBox.Position = UDim2.new(0, inputStartX, 0, 2)
	self.inputBox.Size = UDim2.new(1, -inputStartX - 10, 1, -4)
end

function TerminalUI:appendOutput(text: string)
	local currentText = self.outputLabel.Text
	if #currentText > 0 then
		self.outputLabel.Text = currentText .. "\n" .. text
	else
		self.outputLabel.Text = text
	end

	-- Update canvas size
	self.outputLabel.Size = UDim2.new(1, -20, 0, self.outputLabel.TextBounds.Y)
	self.outputFrame.CanvasSize = UDim2.new(0, 0, 0, self.outputLabel.TextBounds.Y + 10)

	-- Scroll to bottom
	self.outputFrame.CanvasPosition = Vector2.new(0, self.outputFrame.CanvasSize.Y.Offset)
end

function TerminalUI:clearOutput()
	self.outputLabel.Text = ""
	self.outputFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
end

function TerminalUI:getInput(): string
	return self.inputBox.Text
end

function TerminalUI:clearInput()
	self.inputBox.Text = ""
end

function TerminalUI:focusInput()
	self.inputBox:CaptureFocus()
end

function TerminalUI:connectInputSubmit(callback: (string) -> ())
	self.inputBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local text = self.inputBox.Text
			if #text > 0 then
				callback(text)
				self:clearInput()
			end
			self:focusInput()
		end
	end)
end

function TerminalUI:destroy()
	if self.screenGui then
		self.screenGui:Destroy()
	end
end

return TerminalUI

