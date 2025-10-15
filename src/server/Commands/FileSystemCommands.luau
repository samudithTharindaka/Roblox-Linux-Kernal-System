--!strict
-- FileSystemCommands.luau
-- Filesystem-related commands (ls, cd, pwd, mkdir, etc.)

local Types = require(game.ReplicatedStorage.Shared.Types)
local Utils = require(game.ReplicatedStorage.Shared.Utils)
local Constants = require(game.ReplicatedStorage.Shared.Constants)

local FileSystemCommands = {}

-- ls - list directory contents
FileSystemCommands.ls = {
	description = "List directory contents",
	usage = "ls [path]",
	minArgs = 0,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		local path = args[1] or context.playerState.currentDirectory
		local success, entries = context.vfs:listDirectory(path, context.user.username, context.playerState.currentDirectory)

		if not success then
			return {
				success = false,
				output = "ls: cannot access '" .. path .. "': No such file or directory",
				errorCode = 2,
			}
		end

		if #entries == 0 then
			return {
				success = true,
				output = "",
			}
		end

		-- Format output
		local lines = {}
		for _, entry in ipairs(entries) do
			local perms = Utils.formatPermissions(entry.permissions)
			local size = Utils.formatFileSize(entry.size)
			local timestamp = Utils.formatTimestamp(entry.timestamp)
			local name = entry.name
			if entry.isDirectory then
				name = name .. "/"
			elseif entry.executable then
				name = name .. "*"
			end

			local line = string.format("%s %s %8s %s %s", perms, entry.owner, size, timestamp, name)
			table.insert(lines, line)
		end

		return {
			success = true,
			output = table.concat(lines, "\n"),
		}
	end,
}

-- cd - change directory
FileSystemCommands.cd = {
	description = "Change directory",
	usage = "cd <path>",
	minArgs = 1,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		local path = args[1]

		-- Handle special cases
		if path == "~" then
			path = context.user.homeDirectory
		elseif path == "-" then
			-- Previous directory (not implemented)
			return {
				success = false,
				output = "cd: OLDPWD not set",
				errorCode = 1,
			}
		end

		-- Resolve path
		local fullPath = Utils.isAbsolutePath(path) and Utils.normalizePath(path)
			or Utils.normalizePath(Utils.joinPath(context.playerState.currentDirectory, path))

		-- Check if directory exists
		if not context.vfs:exists(fullPath, "/") then
			return {
				success = false,
				output = "cd: " .. path .. ": No such file or directory",
				errorCode = 1,
			}
		end

		if not context.vfs:isDirectory(fullPath, "/") then
			return {
				success = false,
				output = "cd: " .. path .. ": Not a directory",
				errorCode = 1,
			}
		end

		-- Change directory
		context.playerState.currentDirectory = fullPath
		context.environment.PWD = fullPath

		return {
			success = true,
			output = "",
		}
	end,
}

-- pwd - print working directory
FileSystemCommands.pwd = {
	description = "Print working directory",
	usage = "pwd",
	minArgs = 0,
	maxArgs = 0,
	execute = function(context: any, args: { string }): Types.CommandResult
		return {
			success = true,
			output = context.playerState.currentDirectory,
		}
	end,
}

-- mkdir - create directory
FileSystemCommands.mkdir = {
	description = "Create directory",
	usage = "mkdir <name>",
	minArgs = 1,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		local name = args[1]
		local success = context.vfs:createDirectory(name, context.user.username, context.playerState.currentDirectory)

		if not success then
			return {
				success = false,
				output = "mkdir: cannot create directory '" .. name .. "': File exists or permission denied",
				errorCode = 1,
			}
		end

		return {
			success = true,
			output = "",
		}
	end,
}

-- rmdir - remove directory
FileSystemCommands.rmdir = {
	description = "Remove empty directory",
	usage = "rmdir <name>",
	minArgs = 1,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		local name = args[1]
		local success, err = context.vfs:delete(name, context.user.username, context.playerState.currentDirectory)

		if not success then
			return {
				success = false,
				output = "rmdir: failed to remove '" .. name .. "': " .. (err or "Unknown error"),
				errorCode = 1,
			}
		end

		return {
			success = true,
			output = "",
		}
	end,
}

-- rm - remove file/directory
FileSystemCommands.rm = {
	description = "Remove file or directory",
	usage = "rm <target>",
	minArgs = 1,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		local target = args[1]
		local success, err = context.vfs:delete(target, context.user.username, context.playerState.currentDirectory)

		if not success then
			return {
				success = false,
				output = "rm: cannot remove '" .. target .. "': " .. (err or "Unknown error"),
				errorCode = 1,
			}
		end

		return {
			success = true,
			output = "",
		}
	end,
}

-- touch - create or update file timestamp
FileSystemCommands.touch = {
	description = "Create file or update timestamp",
	usage = "touch <file>",
	minArgs = 1,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		local file = args[1]

		-- Check if file exists
		if context.vfs:exists(file, context.playerState.currentDirectory) then
			-- Update timestamp (not fully implemented, would need VFS method)
			return {
				success = true,
				output = "",
			}
		else
			-- Create new file
			local success = context.vfs:createFile(file, "", context.user.username, context.playerState.currentDirectory)

			if not success then
				return {
					success = false,
					output = "touch: cannot touch '" .. file .. "': Permission denied",
					errorCode = 1,
				}
			end

			return {
				success = true,
				output = "",
			}
		end
	end,
}

-- cat - display file contents
FileSystemCommands.cat = {
	description = "Display file contents",
	usage = "cat <file>",
	minArgs = 1,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		local file = args[1]
		local success, content = context.vfs:readFile(file, context.user.username, context.playerState.currentDirectory)

		if not success then
			return {
				success = false,
				output = "cat: " .. file .. ": " .. (content or "No such file or directory"),
				errorCode = 1,
			}
		end

		return {
			success = true,
			output = content or "",
		}
	end,
}

-- head - display first n lines
FileSystemCommands.head = {
	description = "Display first n lines of file",
	usage = "head <file> [n]",
	minArgs = 1,
	maxArgs = 2,
	execute = function(context: any, args: { string }): Types.CommandResult
		local file = args[1]
		local n = tonumber(args[2]) or 10

		local success, content = context.vfs:readFile(file, context.user.username, context.playerState.currentDirectory)

		if not success then
			return {
				success = false,
				output = "head: " .. file .. ": " .. (content or "No such file or directory"),
				errorCode = 1,
			}
		end

		local lines = Utils.split(content or "", "\n")
		local result = {}
		for i = 1, math.min(n, #lines) do
			table.insert(result, lines[i])
		end

		return {
			success = true,
			output = table.concat(result, "\n"),
		}
	end,
}

-- tail - display last n lines
FileSystemCommands.tail = {
	description = "Display last n lines of file",
	usage = "tail <file> [n]",
	minArgs = 1,
	maxArgs = 2,
	execute = function(context: any, args: { string }): Types.CommandResult
		local file = args[1]
		local n = tonumber(args[2]) or 10

		local success, content = context.vfs:readFile(file, context.user.username, context.playerState.currentDirectory)

		if not success then
			return {
				success = false,
				output = "tail: " .. file .. ": " .. (content or "No such file or directory"),
				errorCode = 1,
			}
		end

		local lines = Utils.split(content or "", "\n")
		local result = {}
		local startIdx = math.max(1, #lines - n + 1)

		for i = startIdx, #lines do
			table.insert(result, lines[i])
		end

		return {
			success = true,
			output = table.concat(result, "\n"),
		}
	end,
}

-- cp - copy file
FileSystemCommands.cp = {
	description = "Copy file",
	usage = "cp <source> <destination>",
	minArgs = 2,
	maxArgs = 2,
	execute = function(context: any, args: { string }): Types.CommandResult
		local source = args[1]
		local destination = args[2]

		local success, err =
			context.vfs:copy(source, destination, context.user.username, context.playerState.currentDirectory)

		if not success then
			return {
				success = false,
				output = "cp: cannot copy '" .. source .. "' to '" .. destination .. "': " .. (err or "Unknown error"),
				errorCode = 1,
			}
		end

		return {
			success = true,
			output = "",
		}
	end,
}

-- mv - move/rename file
FileSystemCommands.mv = {
	description = "Move or rename file",
	usage = "mv <source> <destination>",
	minArgs = 2,
	maxArgs = 2,
	execute = function(context: any, args: { string }): Types.CommandResult
		local source = args[1]
		local destination = args[2]

		local success, err =
			context.vfs:move(source, destination, context.user.username, context.playerState.currentDirectory)

		if not success then
			return {
				success = false,
				output = "mv: cannot move '" .. source .. "' to '" .. destination .. "': " .. (err or "Unknown error"),
				errorCode = 1,
			}
		end

		return {
			success = true,
			output = "",
		}
	end,
}

-- chmod - change file permissions
FileSystemCommands.chmod = {
	description = "Change file permissions",
	usage = "chmod <mode> <file>",
	minArgs = 2,
	maxArgs = 2,
	execute = function(context: any, args: { string }): Types.CommandResult
		local mode = args[1]
		local file = args[2]

		local success, err = context.vfs:chmod(file, mode, context.user.username, context.playerState.currentDirectory)

		if not success then
			return {
				success = false,
				output = "chmod: cannot change permissions of '" .. file .. "': " .. (err or "Unknown error"),
				errorCode = 1,
			}
		end

		return {
			success = true,
			output = "",
		}
	end,
}

-- chown - change file owner
FileSystemCommands.chown = {
	description = "Change file owner (requires root)",
	usage = "chown <user> <file>",
	minArgs = 2,
	maxArgs = 2,
	execute = function(context: any, args: { string }): Types.CommandResult
		local newOwner = args[1]
		local file = args[2]

		-- Check if user is root or has sudo
		local effectiveUser = context.user.username
		if context.user:hasSudoAccess() then
			effectiveUser = "root"
		end

		local success, err =
			context.vfs:chown(file, newOwner, effectiveUser, context.playerState.currentDirectory)

		if not success then
			return {
				success = false,
				output = "chown: cannot change ownership of '" .. file .. "': " .. (err or "Unknown error"),
				errorCode = 1,
			}
		end

		return {
			success = true,
			output = "",
		}
	end,
}

return FileSystemCommands

