--!strict
-- TerminalController.luau
-- Client-side terminal controller

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local TerminalUI = require(script.Parent.Parent.UI.TerminalUI)
local NanoEditor = require(script.Parent.Parent.UI.NanoEditor)
local HtopViewer = require(script.Parent.Parent.UI.HtopViewer)
local TerminalButton = require(script.Parent.Parent.UI.TerminalButton)
local Constants = require(ReplicatedStorage.Shared.Constants)
local Utils = require(ReplicatedStorage.Shared.Utils)

local TerminalController = {}
TerminalController.__index = TerminalController

function TerminalController.new()
	local self = setmetatable({}, TerminalController)

	self.player = Players.LocalPlayer
	self.playerGui = self.player:WaitForChild("PlayerGui")

	-- Create UIs
	self.terminalUI = TerminalUI.new(self.playerGui)
	self.nanoEditor = NanoEditor.new(self.playerGui)
	self.htopViewer = HtopViewer.new(self.playerGui)
	self.terminalButton = TerminalButton.new(self.playerGui)

	-- Command history
	self.commandHistory = {}
	self.historyIndex = 0

	-- Remote events (will be created by server)
	self.remotes = {
		executeCommand = nil,
		commandResult = nil,
		updatePrompt = nil,
		openEditor = nil,
		saveFile = nil,
		openHtop = nil,
	}

	self:_setupRemotes()
	self:_setupInput()
	self:_setupNanoEditor()
	self:_setupTerminalButton()

	return self
end

function TerminalController:_setupRemotes()
	-- Wait for remote events to be created by server
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotesFolder then
		warn("Failed to find Remotes folder")
		return
	end

	self.remotes.executeCommand = remotesFolder:WaitForChild("ExecuteCommand", 10)
	self.remotes.commandResult = remotesFolder:WaitForChild("CommandResult", 10)
	self.remotes.updatePrompt = remotesFolder:WaitForChild("UpdatePrompt", 10)
	self.remotes.openEditor = remotesFolder:WaitForChild("OpenEditor", 10)
	self.remotes.saveFile = remotesFolder:WaitForChild("SaveFile", 10)

	-- Listen for command results
	if self.remotes.commandResult then
		self.remotes.commandResult.OnClientEvent:Connect(function(result)
			self:_handleCommandResult(result)
		end)
	end

	-- Listen for prompt updates
	if self.remotes.updatePrompt then
		self.remotes.updatePrompt.OnClientEvent:Connect(function(prompt)
			self.terminalUI:setPrompt(prompt)
		end)
	end

	-- Listen for editor open requests
	if self.remotes.openEditor then
		self.remotes.openEditor.OnClientEvent:Connect(function(fileName, content)
			self.nanoEditor:open(fileName, content)
		end)
	end
end

function TerminalController:_setupInput()
	-- Connect terminal input
	self.terminalUI:connectInputSubmit(function(command)
		self:_executeCommand(command)
	end)

	-- Toggle terminal with backtick/tilde key
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.BackSlash or input.KeyCode == Enum.KeyCode.Backquote then
			self.terminalUI:toggle()
			self.terminalButton:setTerminalState(self.terminalUI.isVisible)
		end

		-- Command history navigation
		if self.terminalUI.isVisible and self.terminalUI.inputBox:IsFocused() then
			if input.KeyCode == Enum.KeyCode.Up then
				self:_navigateHistory(-1)
			elseif input.KeyCode == Enum.KeyCode.Down then
				self:_navigateHistory(1)
			end
		end
	end)
end

function TerminalController:_setupNanoEditor()
	-- Handle save
	self.nanoEditor:onSave(function(fileName, content)
		if self.remotes.saveFile then
			self.remotes.saveFile:FireServer(fileName, content)
			self.terminalUI:appendOutput(Utils.colorText("File saved: " .. fileName, Constants.COLORS.SUCCESS_COLOR))
		end
	end)

	-- Handle close
	self.nanoEditor:onClose(function()
		self.terminalUI:focusInput()
	end)
end

function TerminalController:_setupTerminalButton()
	-- Handle button toggle
	self.terminalButton:onToggle(function()
		self.terminalUI:toggle()
		self.terminalButton:setTerminalState(self.terminalUI.isVisible)
	end)

	-- Show button
	self.terminalButton:show()
end

function TerminalController:_executeCommand(command: string)
	-- Add to history
	if #command > 0 then
		table.insert(self.commandHistory, command)
		self.historyIndex = #self.commandHistory + 1

		-- Limit history size
		if #self.commandHistory > Constants.TERMINAL.HISTORY_SIZE then
			table.remove(self.commandHistory, 1)
		end
	end

	-- Display command in output with timestamp
	local timestamp = os.date("%H:%M:%S")
	local timestampFormatted = Utils.colorText(string.format("[%s]", timestamp), Constants.COLORS.PROMPT_COLOR)
	self.terminalUI:appendOutput(timestampFormatted .. " " .. command)

	-- Handle special client-side commands
	if command == "clear" or command == "cls" then
		self.terminalUI:clearOutput()
		return
	end

	-- Send to server for execution
	if self.remotes.executeCommand then
		self.remotes.executeCommand:FireServer(command)
	end
end

function TerminalController:_handleCommandResult(result: any)
	if result.output then
		-- Check for special markers
		if string.find(result.output, "__CLEAR_SCREEN__") then
			self.terminalUI:clearOutput()
		else
			-- Color the output based on success
			local output = result.output
			if not result.success and #output > 0 then
				output = Utils.colorText(output, Constants.COLORS.ERROR_COLOR)
			end

			self.terminalUI:appendOutput(output)
		end
	end
end

function TerminalController:_navigateHistory(direction: number)
	if #self.commandHistory == 0 then
		return
	end

	self.historyIndex = self.historyIndex + direction

	-- Clamp index
	if self.historyIndex < 1 then
		self.historyIndex = 1
	elseif self.historyIndex > #self.commandHistory + 1 then
		self.historyIndex = #self.commandHistory + 1
	end

	-- Set input
	if self.historyIndex <= #self.commandHistory then
		self.terminalUI.inputBox.Text = self.commandHistory[self.historyIndex]
	else
		self.terminalUI.inputBox.Text = ""
	end
end

function TerminalController:showWelcome()
	local green = Constants.COLORS.PROMPT_COLOR
	local gray = Constants.COLORS.TERMINAL_TEXT
	local yellow = Constants.COLORS.WARNING_COLOR
	
	local welcome = Utils.colorText("╔════════════════════════════════════════════╗", green) .. "\n"
	welcome = welcome .. Utils.colorText("║       Welcome to RobloxOS Simulator       ║", green) .. "\n"
	welcome = welcome .. Utils.colorText("║            Linux-like Environment         ║", green) .. "\n"
	welcome = welcome .. Utils.colorText("╚════════════════════════════════════════════╝", green) .. "\n\n"
	welcome = welcome .. Utils.colorText("Type 'help' to see available commands.", gray) .. "\n"
	welcome = welcome .. Utils.colorText("Type 'history' to see your command history.", gray) .. "\n"
	welcome = welcome .. Utils.colorText("Press ` (backtick) or click the button to toggle terminal.", gray) .. "\n\n"
	welcome = welcome .. Utils.colorText("System initialized. Have fun hacking!", yellow)

	self.terminalUI:appendOutput(welcome)
	
	-- Update button state
	self.terminalButton:setTerminalState(self.terminalUI.isVisible)
end

function TerminalController:destroy()
	self.terminalUI:destroy()
	self.nanoEditor:destroy()
	self.htopViewer:destroy()
	self.terminalButton:destroy()
end

return TerminalController

