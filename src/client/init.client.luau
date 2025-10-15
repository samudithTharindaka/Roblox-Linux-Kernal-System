--!strict
-- init.client.luau
-- Main client initialization

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TerminalController = require(script.Controllers.TerminalController)

-- Wait for player to load
local player = Players.LocalPlayer
player:WaitForChild("PlayerGui")

-- Wait a moment for server to initialize
task.wait(1)

-- Initialize terminal controller
local terminalController = TerminalController.new()

-- Show welcome message
terminalController:showWelcome()

-- Show terminal by default
terminalController.terminalUI:show()

print("RobloxOS Client initialized for", player.Name)
