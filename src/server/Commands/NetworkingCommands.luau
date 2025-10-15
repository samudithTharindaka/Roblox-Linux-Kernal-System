--!strict
-- NetworkingCommands.luau
-- Networking and service-related commands

local Types = require(game.ReplicatedStorage.Shared.Types)
local Constants = require(game.ReplicatedStorage.Shared.Constants)

local NetworkingCommands = {}

-- ifconfig - show network interface configuration
NetworkingCommands.ifconfig = {
	description = "Show network interface configuration",
	usage = "ifconfig",
	minArgs = 0,
	maxArgs = 0,
	execute = function(context: any, args: { string }): Types.CommandResult
		local output = string.format(
			[[eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet %s  netmask 255.255.255.0  broadcast 192.168.1.255
        ether 00:0c:29:xx:xx:xx  txqueuelen 1000
        RX packets 1234  bytes 567890
        TX packets 890  bytes 123456]],
			context.playerState.ipAddress
		)

		return {
			success = true,
			output = output,
		}
	end,
}

-- netstat - show network statistics and connections
NetworkingCommands.netstat = {
	description = "Show network statistics and open ports",
	usage = "netstat",
	minArgs = 0,
	maxArgs = 0,
	execute = function(context: any, args: { string }): Types.CommandResult
		-- Get network service from game context (placeholder)
		local output = "Active Internet connections\n"
		output = output .. "Proto  Local Address          Foreign Address        State\n"

		-- This would integrate with NetworkService to show actual connections
		-- For now, show placeholder
		output = output .. "tcp    0.0.0.0:22            0.0.0.0:*              LISTEN\n"
		output = output .. "tcp    " .. context.playerState.ipAddress .. ":80    0.0.0.0:*              LISTEN\n"

		return {
			success = true,
			output = output,
		}
	end,
}

-- ping - test network connectivity
NetworkingCommands.ping = {
	description = "Test network connectivity to target",
	usage = "ping <ip>",
	minArgs = 1,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		local targetIP = args[1]

		-- Validate IP format (simple check)
		if not string.match(targetIP, "%d+%.%d+%.%d+%.%d+") then
			return {
				success = false,
				output = "ping: invalid IP address",
				errorCode = 1,
			}
		end

		-- Simulate ping (in real implementation, would check player registry)
		local latency = math.random(10, 100)
		local output = string.format(
			[[PING %s 56(84) bytes of data.
64 bytes from %s: icmp_seq=1 ttl=64 time=%d ms
64 bytes from %s: icmp_seq=2 ttl=64 time=%d ms
64 bytes from %s: icmp_seq=3 ttl=64 time=%d ms

--- %s ping statistics ---
3 packets transmitted, 3 received, 0%% packet loss]],
			targetIP,
			targetIP,
			latency,
			targetIP,
			latency + math.random(-5, 5),
			targetIP,
			latency + math.random(-5, 5),
			targetIP
		)

		-- Log the ping attempt
		context.auditLog:addEntry(
			context.user.username,
			"PING",
			"Pinged " .. targetIP,
			"info",
			context.playerState.ipAddress
		)

		return {
			success = true,
			output = output,
		}
	end,
}

-- listen - start a service on a port
NetworkingCommands.listen = {
	description = "Start a service listening on a port",
	usage = "listen <port> <serviceName>",
	minArgs = 2,
	maxArgs = 2,
	execute = function(context: any, args: { string }): Types.CommandResult
		local port = tonumber(args[1])
		local serviceName = args[2]

		if not port or port < 1 or port > 65535 then
			return {
				success = false,
				output = "listen: invalid port number",
				errorCode = 1,
			}
		end

		-- This would integrate with NetworkService
		-- For now, just log it
		context.auditLog:addEntry(
			context.user.username,
			"SERVICE_START",
			string.format("Started %s on port %d", serviceName, port),
			"info"
		)

		return {
			success = true,
			output = string.format("Service '%s' now listening on port %d", serviceName, port),
		}
	end,
}

-- connect - connect to a remote service
NetworkingCommands.connect = {
	description = "Connect to a remote service",
	usage = "connect <ip>:<port>",
	minArgs = 1,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		local target = args[1]
		local ip, port = string.match(target, "([%d%.]+):(%d+)")

		if not ip or not port then
			return {
				success = false,
				output = "connect: invalid target format. Use ip:port",
				errorCode = 1,
			}
		end

		-- Log connection attempt
		context.auditLog:addEntry(
			context.user.username,
			"CONNECT",
			string.format("Attempted connection to %s:%s", ip, port),
			"info",
			context.playerState.ipAddress
		)

		return {
			success = true,
			output = string.format("Attempting connection to %s:%s...\nConnection established.", ip, port),
		}
	end,
}

-- send - send data to a connection
NetworkingCommands.send = {
	description = "Send data to a connection",
	usage = "send <connection> <payload>",
	minArgs = 2,
	maxArgs = 999,
	execute = function(context: any, args: { string }): Types.CommandResult
		local connection = args[1]
		local payload = table.concat(args, " ", 2)

		return {
			success = true,
			output = string.format("Sent %d bytes to connection %s", #payload, connection),
		}
	end,
}

return NetworkingCommands

