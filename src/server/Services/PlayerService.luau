--!strict
-- PlayerService.luau
-- Manages player sessions, VFS, and state

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFS = require(script.Parent.Parent.Classes.VFS)
local User = require(script.Parent.Parent.Classes.User)
local AuditLog = require(script.Parent.Parent.Classes.AuditLog)
local Process = require(script.Parent.Parent.Classes.Process)
local Service = require(script.Parent.Parent.Classes.Service)
local CommandExecutor = require(script.Parent.Parent.Modules.CommandExecutor)
local DataPersistence = require(script.Parent.DataPersistence)
local Utils = require(ReplicatedStorage.Shared.Utils)
local Constants = require(ReplicatedStorage.Shared.Constants)

-- Command modules
local FileSystemCommands = require(script.Parent.Parent.Commands.FileSystemCommands)
local SystemCommands = require(script.Parent.Parent.Commands.SystemCommands)
local NetworkingCommands = require(script.Parent.Parent.Commands.NetworkingCommands)
local SecurityCommands = require(script.Parent.Parent.Commands.SecurityCommands)
local HackingCommands = require(script.Parent.Parent.Commands.HackingCommands)

local PlayerService = {}
PlayerService.__index = PlayerService

function PlayerService.new()
	local self = setmetatable({}, PlayerService)

	self.playerSessions = {}
	self.dataPersistence = DataPersistence.new()

	-- Auto-save loop
	task.spawn(function()
		while true do
			task.wait(Constants.DATASTORE.SAVE_INTERVAL)
			self:autoSaveAll()
		end
	end)

	return self
end

function PlayerService:createSession(player: Player)
	local userId = player.UserId
	local username = player.Name

	-- Try to load existing data
	local savedData = self.dataPersistence:loadPlayerData(userId)

	local session = {
		player = player,
		userId = userId,
		username = username,
		vfs = nil,
		user = nil,
		auditLog = nil,
		executor = nil,
		playerState = {
			currentUser = username,
			currentDirectory = "/home/" .. username,
			ipAddress = Utils.generateIP(),
			vmUptime = os.time(),
			commandHistory = {},
			environment = {},
		},
		processes = {},
		services = {},
	}

	-- Initialize or restore VFS
	if savedData and savedData.vfs then
		session.vfs = VFS.new(username)
		session.vfs:deserialize(savedData.vfs)
	else
		session.vfs = VFS.new(username)
	end

	-- Initialize or restore User
	if savedData and savedData.user then
		session.user = User.deserialize(savedData.user)
	else
		session.user = User.new(username, userId)
		session.user:grantSudo() -- Grant sudo by default for testing
	end

	-- Initialize or restore AuditLog
	if savedData and savedData.auditLog then
		session.auditLog = AuditLog.new(username)
		session.auditLog:deserialize(savedData.auditLog)
	else
		session.auditLog = AuditLog.new(username)
	end

	-- Restore player state
	if savedData and savedData.playerState then
		session.playerState.currentDirectory = savedData.playerState.currentDirectory or session.playerState.currentDirectory
		session.playerState.ipAddress = savedData.playerState.ipAddress or session.playerState.ipAddress
		session.playerState.commandHistory = savedData.playerState.commandHistory or {}
		session.playerState.environment = savedData.playerState.environment or {}
	end

	-- Create command executor
	session.executor = CommandExecutor.new(session.playerState, session.vfs, session.user, session.auditLog)

	-- Store network service reference in executor context
	session.networkService = self.networkService

	-- Register all commands
	session.executor:registerCommands(FileSystemCommands)
	session.executor:registerCommands(SystemCommands)
	session.executor:registerCommands(NetworkingCommands)
	session.executor:registerCommands(SecurityCommands)
	session.executor:registerCommands(HackingCommands)
	session.executor:registerCommands(MultiplayerCommands)

	-- Add nano command (special handling for editor)
	session.executor:registerCommand("nano", {
		description = "Edit file with nano editor",
		usage = "nano <file>",
		minArgs = 1,
		maxArgs = 1,
		execute = function(context: any, args: { string })
			local file = args[1]

			-- Try to read existing file
			local success, content = context.vfs:readFile(file, context.user.username, context.playerState.currentDirectory)

			if not success then
				-- Create new file
				content = ""
			end

			-- Send editor open request to client
			local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
			if remotesFolder then
				local openEditor = remotesFolder:FindFirstChild("OpenEditor")
				if openEditor then
					openEditor:FireClient(player, file, content)
				end
			end

			return {
				success = true,
				output = "",
			}
		end,
	})

	-- Add ps command (show processes)
	session.executor:registerCommand("ps", {
		description = "Show running processes",
		usage = "ps",
		minArgs = 0,
		maxArgs = 0,
		execute = function(context: any, args: { string })
			local lines = { "  PID  USER       CPU%  MEM   STATUS    COMMAND" }

			for _, proc in ipairs(session.processes) do
				local info = proc:getInfo()
				local line = string.format(
					"%5d  %-10s %4.1f  %4dK %-9s %s",
					info.pid,
					info.owner,
					info.cpuUsage,
					info.memoryUsage,
					info.status,
					info.name
				)
				table.insert(lines, line)
			end

			return {
				success = true,
				output = table.concat(lines, "\n"),
			}
		end,
	})

	-- Add htop command (show detailed process info)
	session.executor:registerCommand("htop", {
		description = "Interactive process viewer",
		usage = "htop",
		minArgs = 0,
		maxArgs = 0,
		execute = function(context: any, args: { string })
			local output = [[CPU: [||||||||||||||||||||||||                    ] 54.2%
MEM: [||||||||||||||                              ] 32.1%

  PID  USER       CPU%  MEM   STATUS    COMMAND
]]

			for _, proc in ipairs(session.processes) do
				local info = proc:getInfo()
				output = output
					.. string.format(
						"%5d  %-10s %4.1f  %4dK %-9s %s\n",
						info.pid,
						info.owner,
						info.cpuUsage,
						info.memoryUsage,
						info.status,
						info.name
					)
			end

			return {
				success = true,
				output = output,
			}
		end,
	})

	-- Initialize some default processes
	table.insert(session.processes, Process.new("init", "root", "/sbin/init"))
	table.insert(session.processes, Process.new("systemd", "root", "/lib/systemd/systemd"))
	table.insert(session.processes, Process.new("bash", username, "/bin/bash"))

	-- Log session creation
	session.auditLog:addEntry(username, "SESSION_START", "User logged in", "info", session.playerState.ipAddress)

	-- Store session
	self.playerSessions[userId] = session

	-- Register player with NetworkService
	if self.networkService then
		self.networkService:registerPlayer(player, session.playerState.ipAddress, true)
	end

	-- Send initial prompt to client
	self:updatePrompt(player)

	print(string.format("[PlayerService] Session created for %s (IP: %s)", username, session.playerState.ipAddress))

	return session
end

function PlayerService:getSession(player: Player): any?
	return self.playerSessions[player.UserId]
end

function PlayerService:destroySession(player: Player)
	local userId = player.UserId
	local session = self.playerSessions[userId]

	if not session then
		return
	end

	-- Save data
	self:saveSession(player)

	-- Unregister from NetworkService
	if self.networkService then
		self.networkService:unregisterPlayer(player)
	end

	-- Log session end
	session.auditLog:addEntry(session.username, "SESSION_END", "User logged out", "info", session.playerState.ipAddress)

	-- Clean up
	self.playerSessions[userId] = nil

	print(string.format("[PlayerService] Session destroyed for %s", player.Name))
end

function PlayerService:saveSession(player: Player): boolean
	local session = self:getSession(player)
	if not session then
		return false
	end

	local dataString =
		self.dataPersistence:serializePlayerState(session.playerState, session.vfs, session.user, session.auditLog)

	return self.dataPersistence:savePlayerData(player.UserId, dataString)
end

function PlayerService:autoSaveAll()
	print("[PlayerService] Auto-saving all player data...")
	for userId, session in pairs(self.playerSessions) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			self:saveSession(player)
		end
	end
end

function PlayerService:executeCommand(player: Player, command: string)
	local session = self:getSession(player)
	if not session then
		warn("No session for player", player.Name)
		return
	end

	-- Add to history
	table.insert(session.playerState.commandHistory, command)

	-- Add networkService to executor context
	session.executor.networkService = self.networkService

	-- Execute command
	local result = session.executor:execute(command)

	-- Send result to client
	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if remotesFolder then
		local commandResult = remotesFolder:FindFirstChild("CommandResult")
		if commandResult then
			commandResult:FireClient(player, result)
		end
	end

	return result
end

function PlayerService:updatePrompt(player: Player)
	local session = self:getSession(player)
	if not session then
		return
	end

	local prompt = string.format(
		Constants.TERMINAL.PROMPT_FORMAT,
		session.username,
		session.playerState.currentDirectory
	)

	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if remotesFolder then
		local updatePrompt = remotesFolder:FindFirstChild("UpdatePrompt")
		if updatePrompt then
			updatePrompt:FireClient(player, prompt)
		end
	end
end

function PlayerService:saveFile(player: Player, fileName: string, content: string)
	local session = self:getSession(player)
	if not session then
		return
	end

	local success, err =
		session.vfs:writeFile(fileName, content, session.user.username, session.playerState.currentDirectory)

	if not success then
		-- Try to create the file if it doesn't exist
		success = session.vfs:createFile(fileName, content, session.user.username, session.playerState.currentDirectory)
	end

	-- Log the file save
	if success then
		session.auditLog:addEntry(session.username, "FILE_WRITE", "Saved file: " .. fileName, "info")
	end
end

return PlayerService

