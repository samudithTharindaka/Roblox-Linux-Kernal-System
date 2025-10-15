--!strict
-- SecurityCommands.luau
-- Security, firewall, and monitoring commands

local Types = require(game.ReplicatedStorage.Shared.Types)
local Constants = require(game.ReplicatedStorage.Shared.Constants)

local SecurityCommands = {}

-- ufw - firewall management
SecurityCommands.ufw = {
	description = "Manage firewall rules",
	usage = "ufw [allow|deny|status] [port]",
	minArgs = 1,
	maxArgs = 2,
	execute = function(context: any, args: { string }): Types.CommandResult
		local action = args[1]

		if action == "status" then
			return {
				success = true,
				output = [[Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere]],
			}
		elseif action == "allow" or action == "deny" then
			if #args < 2 then
				return {
					success = false,
					output = "ufw: missing port number",
					errorCode = 1,
				}
			end

			local port = tonumber(args[2])
			if not port then
				return {
					success = false,
					output = "ufw: invalid port number",
					errorCode = 1,
				}
			end

			context.auditLog:addEntry(
				context.user.username,
				"FIREWALL",
				string.format("%s port %d", action:upper(), port),
				"warning"
			)

			return {
				success = true,
				output = string.format("Rule added: %s port %d", action, port),
			}
		else
			return {
				success = false,
				output = "ufw: invalid action. Use: allow, deny, or status",
				errorCode = 1,
			}
		end
	end,
}

-- authlog - show authentication log
SecurityCommands.authlog = {
	description = "Show authentication log",
	usage = "authlog [n]",
	minArgs = 0,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		local count = tonumber(args[1]) or 20

		-- Get recent entries from audit log
		local entries = context.auditLog:getRecentEntries(count)
		local output = context.auditLog:formatEntries(entries)

		if #output == 0 then
			output = "No log entries found"
		end

		return {
			success = true,
			output = output,
		}
	end,
}

-- monitor - start monitoring for suspicious activity
SecurityCommands.monitor = {
	description = "Monitor for suspicious network activity",
	usage = "monitor",
	minArgs = 0,
	maxArgs = 0,
	execute = function(context: any, args: { string }): Types.CommandResult
		return {
			success = true,
			output = [[Monitoring started. Watching for:
- Port scans
- Brute force attempts
- Unusual connection patterns
- Unauthorized access attempts

Press Ctrl+C to stop monitoring...]],
		}
	end,
}

-- scan - port scanner
SecurityCommands.scan = {
	description = "Scan target for open ports",
	usage = "scan <ip> [startPort-endPort]",
	minArgs = 1,
	maxArgs = 2,
	execute = function(context: any, args: { string }): Types.CommandResult
		local targetIP = args[1]
		local portRange = args[2] or "1-1000"

		-- Validate IP
		if not string.match(targetIP, "%d+%.%d+%.%d+%.%d+") then
			return {
				success = false,
				output = "scan: invalid IP address",
				errorCode = 1,
			}
		end

		-- Parse port range
		local startPort, endPort = string.match(portRange, "(%d+)%-(%d+)")
		startPort = tonumber(startPort) or 1
		endPort = tonumber(endPort) or 1000

		-- Log the scan (NOISY!)
		context.auditLog:addEntry(
			context.user.username,
			"PORT_SCAN",
			string.format("Scanning %s ports %d-%d", targetIP, startPort, endPort),
			"warning",
			context.playerState.ipAddress
		)

		-- Simulate scan results
		local output = string.format("Scanning %s...\n\n", targetIP)
		output = output .. "PORT     STATE    SERVICE\n"

		-- Randomly show some open ports
		local commonPorts = { 22, 80, 443, 3306, 8080 }
		for _, port in ipairs(commonPorts) do
			if port >= startPort and port <= endPort then
				output = output .. string.format("%-8d %-8s %s\n", port, "open", "unknown")
			end
		end

		output = output .. string.format("\nScan complete. Scanned %d ports.", endPort - startPort + 1)

		return {
			success = true,
			output = output,
		}
	end,
}

-- snapshot - create filesystem snapshot
SecurityCommands.snapshot = {
	description = "Manage filesystem snapshots",
	usage = "snapshot [create|restore|list] [name]",
	minArgs = 1,
	maxArgs = 2,
	execute = function(context: any, args: { string }): Types.CommandResult
		local action = args[1]

		if action == "create" then
			if #args < 2 then
				return {
					success = false,
					output = "snapshot: missing snapshot name",
					errorCode = 1,
				}
			end

			local name = args[2]
			local success = context.vfs:createSnapshot(name)

			if success then
				context.auditLog:addEntry(context.user.username, "SNAPSHOT_CREATE", "Created snapshot: " .. name, "info")

				return {
					success = true,
					output = "Snapshot '" .. name .. "' created successfully",
				}
			else
				return {
					success = false,
					output = "Failed to create snapshot",
					errorCode = 1,
				}
			end
		elseif action == "restore" then
			if #args < 2 then
				return {
					success = false,
					output = "snapshot: missing snapshot name",
					errorCode = 1,
				}
			end

			local name = args[2]
			local success, err = context.vfs:restoreSnapshot(name)

			if success then
				context.auditLog:addEntry(
					context.user.username,
					"SNAPSHOT_RESTORE",
					"Restored snapshot: " .. name,
					"warning"
				)

				return {
					success = true,
					output = "Snapshot '" .. name .. "' restored successfully",
				}
			else
				return {
					success = false,
					output = "Failed to restore snapshot: " .. (err or "Unknown error"),
					errorCode = 1,
				}
			end
		elseif action == "list" then
			local snapshots = context.vfs:listSnapshots()

			if #snapshots == 0 then
				return {
					success = true,
					output = "No snapshots found",
				}
			end

			local lines = { "Available snapshots:\n" }
			for _, snapshot in ipairs(snapshots) do
				local timestamp = require(game.ReplicatedStorage.Shared.Utils).formatTimestamp(snapshot.timestamp)
				table.insert(lines, string.format("  %s (%s)", snapshot.name, timestamp))
			end

			return {
				success = true,
				output = table.concat(lines, "\n"),
			}
		else
			return {
				success = false,
				output = "snapshot: invalid action. Use: create, restore, or list",
				errorCode = 1,
			}
		end
	end,
}

-- isolate - disconnect from network
SecurityCommands.isolate = {
	description = "Disconnect VM from network (quarantine)",
	usage = "isolate",
	minArgs = 0,
	maxArgs = 0,
	execute = function(context: any, args: { string }): Types.CommandResult
		context.auditLog:addEntry(context.user.username, "ISOLATE", "VM isolated from network", "critical")

		return {
			success = true,
			output = "VM isolated from network. All connections terminated.\nRun 'unisolate' to reconnect.",
		}
	end,
}

-- antivirus - scan for malware
SecurityCommands.antivirus = {
	description = "Scan for malware and payloads",
	usage = "antivirus scan [path]",
	minArgs = 1,
	maxArgs = 2,
	execute = function(context: any, args: { string }): Types.CommandResult
		local action = args[1]

		if action ~= "scan" then
			return {
				success = false,
				output = "antivirus: invalid action. Use: scan",
				errorCode = 1,
			}
		end

		local path = args[2] or "/"

		return {
			success = true,
			output = string.format(
				[[Scanning %s...

Scanned 142 files
Found 0 threats
Scan complete in 5 seconds]],
				path
			),
		}
	end,
}

return SecurityCommands

