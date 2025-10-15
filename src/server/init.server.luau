--!strict
-- init.server.luau
-- Main server initialization

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerService = require(script.Services.PlayerService)

print("[RobloxOS] Server starting...")

-- Create remotes folder
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

-- Create remote events
local executeCommandRemote = Instance.new("RemoteEvent")
executeCommandRemote.Name = "ExecuteCommand"
executeCommandRemote.Parent = remotesFolder

local commandResultRemote = Instance.new("RemoteEvent")
commandResultRemote.Name = "CommandResult"
commandResultRemote.Parent = remotesFolder

local updatePromptRemote = Instance.new("RemoteEvent")
updatePromptRemote.Name = "UpdatePrompt"
updatePromptRemote.Parent = remotesFolder

local openEditorRemote = Instance.new("RemoteEvent")
openEditorRemote.Name = "OpenEditor"
openEditorRemote.Parent = remotesFolder

local saveFileRemote = Instance.new("RemoteEvent")
saveFileRemote.Name = "SaveFile"
saveFileRemote.Parent = remotesFolder

print("[RobloxOS] Remote events created")

-- Initialize PlayerService
local playerService = PlayerService.new()

print("[RobloxOS] PlayerService initialized")

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	print(string.format("[RobloxOS] Player %s joined, creating session...", player.Name))

	-- Wait a moment for player to fully load
	task.wait(0.5)

	-- Create player session
	playerService:createSession(player)

	print(string.format("[RobloxOS] Session created for %s", player.Name))
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	print(string.format("[RobloxOS] Player %s leaving, saving session...", player.Name))

	-- Save and destroy session
	playerService:destroySession(player)

	print(string.format("[RobloxOS] Session destroyed for %s", player.Name))
end)

-- Handle command execution
executeCommandRemote.OnServerEvent:Connect(function(player, command)
	if type(command) ~= "string" then
		warn("[RobloxOS] Invalid command from", player.Name)
		return
	end

	-- Rate limiting (simple)
	local session = playerService:getSession(player)
	if session then
		-- Execute command
		playerService:executeCommand(player, command)

		-- Update prompt (in case directory changed)
		playerService:updatePrompt(player)
	end
end)

-- Handle file save
saveFileRemote.OnServerEvent:Connect(function(player, fileName, content)
	if type(fileName) ~= "string" or type(content) ~= "string" then
		warn("[RobloxOS] Invalid file save from", player.Name)
		return
	end

	playerService:saveFile(player, fileName, content)
end)

-- Handle existing players (for Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		playerService:createSession(player)
	end)
end

-- Graceful shutdown handler
game:BindToClose(function()
	print("[RobloxOS] Server shutting down, saving all player data...")

	-- Save all sessions
	playerService:autoSaveAll()

	-- Wait a moment for saves to complete
	task.wait(2)

	print("[RobloxOS] Shutdown complete")
end)

print("[RobloxOS] Server fully initialized and ready!")
