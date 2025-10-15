--!strict
-- CommandParser.luau
-- Parses and tokenizes command input

local Utils = require(game.ReplicatedStorage.Shared.Utils)

local CommandParser = {}

export type ParsedCommand = {
	command: string,
	args: { string },
	redirectOutput: string?,
	redirectMode: "overwrite" | "append"?,
	pipeToCommand: string?,
}

-- Parse a command line with support for quotes, redirection, and pipes
function CommandParser.parse(input: string): ParsedCommand?
	if not input or #input == 0 then
		return nil
	end

	-- Trim input
	input = Utils.trim(input)

	if #input == 0 then
		return nil
	end

	-- Check for pipe
	local pipePos = string.find(input, "|")
	local pipeToCommand = nil
	if pipePos then
		pipeToCommand = string.sub(input, pipePos + 1)
		input = string.sub(input, 1, pipePos - 1)
		pipeToCommand = Utils.trim(pipeToCommand)
	end

	-- Check for output redirection
	local redirectOutput = nil
	local redirectMode: "overwrite" | "append"? = nil

	-- Check for append (>>)
	local appendPos = string.find(input, ">>")
	if appendPos then
		redirectOutput = string.sub(input, appendPos + 2)
		input = string.sub(input, 1, appendPos - 1)
		redirectOutput = Utils.trim(redirectOutput)
		redirectMode = "append"
	else
		-- Check for overwrite (>)
		local overwritePos = string.find(input, ">")
		if overwritePos then
			redirectOutput = string.sub(input, overwritePos + 1)
			input = string.sub(input, 1, overwritePos - 1)
			redirectOutput = Utils.trim(redirectOutput)
			redirectMode = "overwrite"
		end
	end

	-- Parse the main command and arguments
	local tokens = Utils.parseCommandLine(input)

	if #tokens == 0 then
		return nil
	end

	local command = tokens[1]
	local args = {}

	for i = 2, #tokens do
		table.insert(args, tokens[i])
	end

	return {
		command = command,
		args = args,
		redirectOutput = redirectOutput,
		redirectMode = redirectMode,
		pipeToCommand = pipeToCommand,
	}
end

-- Expand environment variables in arguments (e.g., $HOME)
function CommandParser.expandVariables(args: { string }, environment: { [string]: string }): { string }
	local expanded = {}

	for _, arg in ipairs(args) do
		local result = arg

		-- Replace $VAR or ${VAR}
		result = string.gsub(result, "%$(%w+)", function(varName)
			return environment[varName] or ""
		end)

		result = string.gsub(result, "%${(%w+)}", function(varName)
			return environment[varName] or ""
		end)

		table.insert(expanded, result)
	end

	return expanded
end

-- Check if command is valid (exists in command registry)
function CommandParser.isValidCommand(command: string, commandRegistry: { [string]: any }): boolean
	return commandRegistry[command] ~= nil
end

-- Validate arguments for a command
function CommandParser.validateArgs(command: string, args: { string }, commandRegistry: { [string]: any }): (boolean, string?)
	local commandDef = commandRegistry[command]
	if not commandDef then
		return false, "Command not found"
	end

	-- Check minimum arguments
	if commandDef.minArgs and #args < commandDef.minArgs then
		return false, string.format("Missing required arguments. Usage: %s", commandDef.usage or "")
	end

	-- Check maximum arguments
	if commandDef.maxArgs and #args > commandDef.maxArgs then
		return false, string.format("Too many arguments. Usage: %s", commandDef.usage or "")
	end

	return true, nil
end

return CommandParser

