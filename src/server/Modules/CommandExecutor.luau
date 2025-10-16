--!strict
-- CommandExecutor.luau
-- Executes parsed commands with proper context

local CommandParser = require(script.Parent.CommandParser)
local Types = require(game.ReplicatedStorage.Shared.Types)

local CommandExecutor = {}
CommandExecutor.__index = CommandExecutor

function CommandExecutor.new(playerState: any, vfs: any, user: any, auditLog: any)
	local self = setmetatable({}, CommandExecutor)

	self.playerState = playerState
	self.vfs = vfs
	self.user = user
	self.auditLog = auditLog
	self.commandRegistry = {}
	self.environment = {
		HOME = user.homeDirectory,
		USER = user.username,
		PWD = playerState.currentDirectory,
	}

	return self
end

function CommandExecutor:registerCommand(name: string, commandDef: any)
	self.commandRegistry[name] = commandDef
end

function CommandExecutor:registerCommands(commands: { [string]: any })
	for name, commandDef in pairs(commands) do
		self:registerCommand(name, commandDef)
	end
end

function CommandExecutor:execute(input: string): Types.CommandResult
	-- Parse the command
	local parsed = CommandParser.parse(input)

	if not parsed then
		return {
			success = false,
			output = "No command entered",
			errorCode = 1,
		}
	end

	-- Check if command exists
	if not CommandParser.isValidCommand(parsed.command, self.commandRegistry) then
		return {
			success = false,
			output = string.format("%s: command not found", parsed.command),
			errorCode = 127,
		}
	end

	-- Expand variables in arguments
	local expandedArgs = CommandParser.expandVariables(parsed.args, self.environment)

	-- Validate arguments
	local valid, err = CommandParser.validateArgs(parsed.command, expandedArgs, self.commandRegistry)
	if not valid then
		return {
			success = false,
			output = err or "Invalid arguments",
			errorCode = 1,
		}
	end

	-- Log the command
	self.auditLog:addEntry(self.user.username, "COMMAND", parsed.command .. " " .. table.concat(expandedArgs, " "), "info")

	-- Execute the command
	local commandDef = self.commandRegistry[parsed.command]
	local context = {
		user = self.user,
		playerState = self.playerState,
		vfs = self.vfs,
		auditLog = self.auditLog,
		environment = self.environment,
		executor = self,
		networkService = self.networkService, -- Add networkService to context
	}

	local success, result = pcall(commandDef.execute, context, expandedArgs)

	if not success then
		return {
			success = false,
			output = "Internal error: " .. tostring(result),
			errorCode = 1,
		}
	end

	-- Handle output redirection
	if parsed.redirectOutput and result.success then
		local redirectSuccess, redirectErr
		if parsed.redirectMode == "overwrite" then
			redirectSuccess, redirectErr = self.vfs:writeFile(
				parsed.redirectOutput,
				result.output,
				self.user.username,
				self.playerState.currentDirectory
			)
		elseif parsed.redirectMode == "append" then
			local existingSuccess, existingContent = self.vfs:readFile(
				parsed.redirectOutput,
				self.user.username,
				self.playerState.currentDirectory
			)
			local newContent = (existingSuccess and existingContent or "") .. result.output
			redirectSuccess, redirectErr = self.vfs:writeFile(
				parsed.redirectOutput,
				newContent,
				self.user.username,
				self.playerState.currentDirectory
			)
		end

		if not redirectSuccess then
			return {
				success = false,
				output = "Redirection failed: " .. (redirectErr or "unknown error"),
				errorCode = 1,
			}
		end

		-- Suppress output when redirecting
		result.output = ""
	end

	-- Handle pipes (simple implementation - pass output as input to next command)
	if parsed.pipeToCommand and result.success then
		-- Store the output in a temporary variable
		self.environment["PIPE_INPUT"] = result.output
		-- Execute the piped command
		return self:execute(parsed.pipeToCommand)
	end

	return result
end

function CommandExecutor:getCommandList(): { string }
	local commands = {}
	for name in pairs(self.commandRegistry) do
		table.insert(commands, name)
	end
	table.sort(commands)
	return commands
end

function CommandExecutor:getCommandHelp(command: string): string?
	local commandDef = self.commandRegistry[command]
	if not commandDef then
		return nil
	end

	return commandDef.help or commandDef.description or "No help available"
end

return CommandExecutor

