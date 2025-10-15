--!strict
-- SystemCommands.luau
-- System information and utility commands

local Types = require(game.ReplicatedStorage.Shared.Types)
local Utils = require(game.ReplicatedStorage.Shared.Utils)

local SystemCommands = {}

-- whoami - print current username
SystemCommands.whoami = {
	description = "Print current username",
	usage = "whoami",
	minArgs = 0,
	maxArgs = 0,
	execute = function(context: any, args: { string }): Types.CommandResult
		return {
			success = true,
			output = context.user.username,
		}
	end,
}

-- date - print current date/time
SystemCommands.date = {
	description = "Print current date and time",
	usage = "date",
	minArgs = 0,
	maxArgs = 0,
	execute = function(context: any, args: { string }): Types.CommandResult
		local timestamp = os.time()
		return {
			success = true,
			output = Utils.formatTimestamp(timestamp),
		}
	end,
}

-- uptime - show system uptime
SystemCommands.uptime = {
	description = "Show system uptime",
	usage = "uptime",
	minArgs = 0,
	maxArgs = 0,
	execute = function(context: any, args: { string }): Types.CommandResult
		local uptime = os.time() - context.playerState.vmUptime
		local hours = math.floor(uptime / 3600)
		local minutes = math.floor((uptime % 3600) / 60)

		return {
			success = true,
			output = string.format("up %d hours, %d minutes", hours, minutes),
		}
	end,
}

-- clear - clear terminal
SystemCommands.clear = {
	description = "Clear terminal screen",
	usage = "clear",
	minArgs = 0,
	maxArgs = 0,
	execute = function(context: any, args: { string }): Types.CommandResult
		return {
			success = true,
			output = "\n\n__CLEAR_SCREEN__\n\n", -- Special marker for client
		}
	end,
}

-- echo - print text
SystemCommands.echo = {
	description = "Print text",
	usage = "echo <text>",
	minArgs = 0,
	maxArgs = 999,
	execute = function(context: any, args: { string }): Types.CommandResult
		return {
			success = true,
			output = table.concat(args, " "),
		}
	end,
}

-- help - show available commands
SystemCommands.help = {
	description = "Show available commands",
	usage = "help [command]",
	minArgs = 0,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		if #args == 1 then
			-- Show help for specific command
			local command = args[1]
			local help = context.executor:getCommandHelp(command)

			if not help then
				return {
					success = false,
					output = "help: no help for '" .. command .. "'",
					errorCode = 1,
				}
			end

			return {
				success = true,
				output = help,
			}
		else
			-- List all commands
			local commands = context.executor:getCommandList()
			local output = "Available commands:\n\n"

			for _, cmd in ipairs(commands) do
				local help = context.executor:getCommandHelp(cmd)
				output = output .. string.format("  %-15s %s\n", cmd, help or "")
			end

			output = output .. "\nType 'help <command>' for more information on a specific command."

			return {
				success = true,
				output = output,
			}
		end
	end,
}

-- history - show command history
SystemCommands.history = {
	description = "Show command history",
	usage = "history",
	minArgs = 0,
	maxArgs = 0,
	execute = function(context: any, args: { string }): Types.CommandResult
		local lines = {}
		for i, cmd in ipairs(context.playerState.commandHistory) do
			table.insert(lines, string.format("%4d  %s", i, cmd))
		end

		return {
			success = true,
			output = table.concat(lines, "\n"),
		}
	end,
}

-- sudo - execute command with elevated privileges
SystemCommands.sudo = {
	description = "Execute command with root privileges",
	usage = "sudo <command>",
	minArgs = 1,
	maxArgs = 999,
	execute = function(context: any, args: { string }): Types.CommandResult
		-- Check if user has sudo enabled
		if not context.user.sudoEnabled then
			context.auditLog:addEntry(
				context.user.username,
				"SUDO_DENIED",
				"User attempted sudo without permission",
				"warning"
			)
			return {
				success = false,
				output = context.user.username .. " is not in the sudoers file. This incident will be reported.",
				errorCode = 1,
			}
		end

		-- Activate sudo token
		context.user:activateSudoToken()

		-- Execute the command
		local command = table.concat(args, " ")
		local result = context.executor:execute(command)

		-- Log sudo usage
		context.auditLog:addEntry(context.user.username, "SUDO", "Executed: " .. command, "warning")

		return result
	end,
}

-- su - switch user
SystemCommands.su = {
	description = "Switch user (not fully implemented)",
	usage = "su <user>",
	minArgs = 0,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		return {
			success = false,
			output = "su: user switching not yet implemented",
			errorCode = 1,
		}
	end,
}

return SystemCommands

