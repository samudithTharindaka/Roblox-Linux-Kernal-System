--!strict
-- MultiplayerCommands.luau
-- Commands for multiplayer interaction and hacking

local Types = require(game.ReplicatedStorage.Shared.Types)
local Constants = require(game.ReplicatedStorage.Shared.Constants)
local Utils = require(game.ReplicatedStorage.Shared.Utils)

local MultiplayerCommands = {}

-- players - list online players
MultiplayerCommands.players = {
	description = "List online players and their network information",
	usage = "players",
	minArgs = 0,
	maxArgs = 0,
	execute = function(context: any, args: { string }): Types.CommandResult
		-- Get NetworkService from server context
		local networkService = context.networkService
		if not networkService then
			return {
				success = false,
				output = "Network service not available",
				errorCode = 1,
			}
		end

		local onlinePlayers = networkService:getOnlinePlayers()

		if #onlinePlayers == 0 then
			return {
				success = true,
				output = "No other players online",
			}
		end

		local output = "Online Players:\n\n"
		output = output .. string.format("%-15s %-14s %-8s %s\n", "IP ADDRESS", "USERNAME", "UPTIME", "STATUS")
		output = output .. string.rep("-", 55) .. "\n"

		for _, playerInfo in ipairs(onlinePlayers) do
			if playerInfo.isPublic and playerInfo.username ~= context.user.username then
				local uptime = os.time() - playerInfo.vmUptime
				local hours = math.floor(uptime / 3600)
				local minutes = math.floor((uptime % 3600) / 60)

				local status = playerInfo.isSecure and "SECURE" or "OPEN"

				output = output .. string.format(
					"%-15s %-14s %02dh %02dm  %s\n",
					playerInfo.ip,
					playerInfo.username,
					hours,
					minutes,
					status
				)
			end
		end

		return {
			success = true,
			output = output,
		}
	end,
}

-- whois - get information about an IP
MultiplayerCommands.whois = {
	description = "Get information about a player by IP address",
	usage = "whois <ip>",
	minArgs = 1,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		local targetIP = args[1]
		local networkService = context.networkService

		if not networkService then
			return {
				success = false,
				output = "Network service not available",
				errorCode = 1,
			}
		end

		local targetPlayer = networkService:getPlayerByIP(targetIP)
		if not targetPlayer then
			return {
				success = false,
				output = "whois: " .. targetIP .. ": Host not found",
				errorCode = 1,
			}
		end

		local playerInfo = networkService:getPlayerInfo(targetPlayer)
		if not playerInfo then
			return {
				success = false,
				output = "whois: Unable to retrieve player information",
				errorCode = 1,
			}
		end

		local uptime = os.time() - playerInfo.vmUptime
		local hours = math.floor(uptime / 3600)
		local minutes = math.floor((uptime % 3600) / 60)

		local output = string.format(
			[[Player Information for %s:

Username:      %s
IP Address:    %s
VM Uptime:     %dh %dm
Public Access: %s
Security:      %s
Services:      %s
]],
			targetIP,
			playerInfo.username,
			playerInfo.ip,
			hours,
			minutes,
			playerInfo.isPublic and "Yes" or "No",
			playerInfo.isSecure and "SECURED" or "VULNERABLE",
			table.concat(playerInfo.services, ", ")
		)

		-- Log the whois lookup
		context.auditLog:addEntry(
			context.user.username,
			"WHOIS",
			"Queried information for " .. targetIP,
			"info",
			context.playerState.ipAddress
		)

		return {
			success = true,
			output = output,
		}
	end,
}

-- block - block an IP address
MultiplayerCommands.block = {
	description = "Block an IP address from accessing your system",
	usage = "block <ip>",
	minArgs = 1,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		local targetIP = args[1]
		local networkService = context.networkService

		if not networkService then
			return {
				success = false,
				output = "Network service not available",
				errorCode = 1,
			}
		end

		-- Don't allow blocking yourself
		if targetIP == context.playerState.ipAddress then
			return {
				success = false,
				output = "block: Cannot block your own IP address",
				errorCode = 1,
			}
		end

		networkService:blockIP(context.user.player, targetIP)

		context.auditLog:addEntry(
			context.user.username,
			"IP_BLOCK",
			"Blocked IP address: " .. targetIP,
			"warning"
		)

		return {
			success = true,
			output = string.format("IP address %s has been blocked", targetIP),
		}
	end,
}

-- unblock - unblock an IP address
MultiplayerCommands.unblock = {
	description = "Unblock a previously blocked IP address",
	usage = "unblock <ip>",
	minArgs = 1,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		local targetIP = args[1]
		local networkService = context.networkService

		if not networkService then
			return {
				success = false,
				output = "Network service not available",
				errorCode = 1,
			}
		end

		networkService:unblockIP(context.user.player, targetIP)

		context.auditLog:addEntry(
			context.user.username,
			"IP_UNBLOCK",
			"Unblocked IP address: " .. targetIP,
			"info"
		)

		return {
			success = true,
			output = string.format("IP address %s has been unblocked", targetIP),
		}
	end,
}

-- passwd - set/change password
MultiplayerCommands.passwd = {
	description = "Change your password",
	usage = "passwd [new_password]",
	minArgs = 0,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		if #args == 0 then
			return {
				success = true,
				output = [[Usage: passwd <new_password>

Password Requirements:
- Minimum 6 characters
- Mix of letters and numbers recommended
- Avoid common passwords

Strong passwords protect against brute force attacks!]],
			}
		end

		local newPassword = args[1]

		-- Validate password strength
		if #newPassword < 6 then
			return {
				success = false,
				output = "passwd: Password too short (minimum 6 characters)",
				errorCode = 1,
			}
		end

		-- Check for common weak passwords
		local weakPasswords = { "password", "123456", "admin", "root", "qwerty", "12345678" }
		if table.find(weakPasswords, string.lower(newPassword)) then
			return {
				success = false,
				output = "passwd: Password too common. Choose a stronger password.",
				errorCode = 1,
			}
		end

		-- Set new password
		context.user:setPassword(newPassword)

		-- Calculate password strength
		local strength = "Weak"
		if #newPassword >= 12 and string.match(newPassword, "%d") and string.match(newPassword, "%a") then
			strength = "Strong"
		elseif #newPassword >= 8 and (string.match(newPassword, "%d") or string.match(newPassword, "%a")) then
			strength = "Medium"
		end

		context.auditLog:addEntry(
			context.user.username,
			"PASSWORD_CHANGE",
			"Password changed (Strength: " .. strength .. ")",
			"warning"
		)

		return {
			success = true,
			output = string.format(
				"Password updated successfully\nPassword strength: %s\n\nYour system is now %s protected against attacks.",
				strength,
				strength == "Strong" and "well" or strength == "Medium" and "moderately" or "poorly"
			),
		}
	end,
}

-- connections - show active connections
MultiplayerCommands.connections = {
	description = "Show active network connections and recent attempts",
	usage = "connections",
	minArgs = 0,
	maxArgs = 0,
	execute = function(context: any, args: { string }): Types.CommandResult
		local networkService = context.networkService

		if not networkService then
			return {
				success = false,
				output = "Network service not available",
				errorCode = 1,
			}
		end

		local recentAttempts = networkService:getRecentAttempts(context.user.player, 300) -- Last 5 minutes
		local stats = networkService:getPlayerStats(context.user.player)

		local output = "Network Connection Status:\n\n"

		-- Statistics
		output = output .. string.format("Total Attempts: %d\n", stats.totalAttempts)
		output = output .. string.format("Successful: %d  |  Failed: %d\n", stats.successfulLogins, stats.failedLogins)
		output = output .. string.format("Unique Attackers: %d\n", stats.uniqueAttackers)
		output = output .. string.format("Blocked IPs: %d\n\n", stats.blockedIPs)

		-- Recent attempts
		if #recentAttempts > 0 then
			output = output .. "Recent Connection Attempts (Last 5 minutes):\n\n"
			output = output .. string.format("%-15s %-10s %-12s %s\n", "SOURCE IP", "USER", "METHOD", "RESULT")
			output = output .. string.rep("-", 55) .. "\n"

			for i = math.max(1, #recentAttempts - 10), #recentAttempts do
				local attempt = recentAttempts[i]
				local result = attempt.success and "SUCCESS" or "FAILED"
				output = output .. string.format(
					"%-15s %-10s %-12s %s\n",
					attempt.sourceIP,
					attempt.username,
					attempt.method,
					result
				)
			end
		else
			output = output .. "No recent connection attempts.\n"
		end

		return {
			success = true,
			output = output,
		}
	end,
}

return MultiplayerCommands

