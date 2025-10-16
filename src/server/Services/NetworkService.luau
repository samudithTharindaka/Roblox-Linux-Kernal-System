--!strict
-- NetworkService.luau
-- Manages multiplayer networking, player discovery, and connections

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage.Shared.Utils)

local NetworkService = {}
NetworkService.__index = NetworkService

export type PlayerInfo = {
	player: Player,
	username: string,
	ip: string,
	vmUptime: number,
	isPublic: boolean,
	isSecure: boolean,
	services: { string },
}

export type ConnectionAttempt = {
	sourceIP: string,
	timestamp: number,
	username: string,
	success: boolean,
	method: string,
}

function NetworkService.new()
	local self = setmetatable({}, NetworkService)

	-- Player registry
	self.onlinePlayers = {} :: { [number]: PlayerInfo } -- Indexed by UserId
	self.ipToPlayer = {} :: { [string]: number } -- IP to UserId mapping

	-- Connection tracking
	self.connectionAttempts = {} :: { [number]: { ConnectionAttempt } } -- Per target UserId
	self.blockedIPs = {} :: { [number]: { string } } -- Per player UserId
	self.activeConnections = {} :: { [string]: any } -- connectionId -> connection data

	return self
end

-- Player Registry

function NetworkService:registerPlayer(player: Player, ip: string, isPublic: boolean?)
	local info: PlayerInfo = {
		player = player,
		username = player.Name,
		ip = ip,
		vmUptime = os.time(),
		isPublic = isPublic ~= false, -- Default to public
		isSecure = false, -- Will be updated based on security measures
		services = { "ssh" }, -- Default services
	}

	self.onlinePlayers[player.UserId] = info
	self.ipToPlayer[ip] = player.UserId

	print(string.format("[NetworkService] Registered %s at %s (Public: %s)", player.Name, ip, tostring(info.isPublic)))
end

function NetworkService:unregisterPlayer(player: Player)
	local info = self.onlinePlayers[player.UserId]
	if info then
		self.ipToPlayer[info.ip] = nil
		self.onlinePlayers[player.UserId] = nil
		print(string.format("[NetworkService] Unregistered %s", player.Name))
	end
end

function NetworkService:getOnlinePlayers(): { PlayerInfo }
	local players = {}
	for _, info in pairs(self.onlinePlayers) do
		table.insert(players, info)
	end
	return players
end

function NetworkService:getPlayerByIP(ip: string): Player?
	local userId = self.ipToPlayer[ip]
	if userId then
		local info = self.onlinePlayers[userId]
		return info and info.player or nil
	end
	return nil
end

function NetworkService:getPlayerInfo(player: Player): PlayerInfo?
	return self.onlinePlayers[player.UserId]
end

function NetworkService:updatePlayerSecurity(player: Player, isSecure: boolean)
	local info = self.onlinePlayers[player.UserId]
	if info then
		info.isSecure = isSecure
	end
end

-- Connection Management

function NetworkService:recordConnectionAttempt(
	sourceIP: string,
	targetPlayer: Player,
	username: string,
	success: boolean,
	method: string
)
	local userId = targetPlayer.UserId

	if not self.connectionAttempts[userId] then
		self.connectionAttempts[userId] = {}
	end

	local attempt: ConnectionAttempt = {
		sourceIP = sourceIP,
		timestamp = os.time(),
		username = username,
		success = success,
		method = method,
	}

	table.insert(self.connectionAttempts[userId], attempt)

	-- Limit history size
	if #self.connectionAttempts[userId] > 100 then
		table.remove(self.connectionAttempts[userId], 1)
	end

	print(
		string.format(
			"[NetworkService] Connection attempt: %s -> %s (%s) - %s",
			sourceIP,
			targetPlayer.Name,
			method,
			success and "SUCCESS" or "FAILED"
		)
	)
end

function NetworkService:getConnectionHistory(targetPlayer: Player, sourceIP: string?): { ConnectionAttempt }
	local userId = targetPlayer.UserId
	local attempts = self.connectionAttempts[userId] or {}

	if sourceIP then
		-- Filter by source IP
		local filtered = {}
		for _, attempt in ipairs(attempts) do
			if attempt.sourceIP == sourceIP then
				table.insert(filtered, attempt)
			end
		end
		return filtered
	end

	return attempts
end

function NetworkService:getRecentAttempts(targetPlayer: Player, timeWindow: number?): { ConnectionAttempt }
	local window = timeWindow or 300 -- Default 5 minutes
	local cutoff = os.time() - window
	local attempts = self.connectionAttempts[targetPlayer.UserId] or {}

	local recent = {}
	for _, attempt in ipairs(attempts) do
		if attempt.timestamp >= cutoff then
			table.insert(recent, attempt)
		end
	end

	return recent
end

-- IP Blocking

function NetworkService:blockIP(player: Player, ip: string)
	local userId = player.UserId

	if not self.blockedIPs[userId] then
		self.blockedIPs[userId] = {}
	end

	if not table.find(self.blockedIPs[userId], ip) then
		table.insert(self.blockedIPs[userId], ip)
		print(string.format("[NetworkService] %s blocked IP: %s", player.Name, ip))
	end
end

function NetworkService:unblockIP(player: Player, ip: string)
	local userId = player.UserId
	local blocked = self.blockedIPs[userId]

	if blocked then
		local idx = table.find(blocked, ip)
		if idx then
			table.remove(blocked, idx)
			print(string.format("[NetworkService] %s unblocked IP: %s", player.Name, ip))
		end
	end
end

function NetworkService:isIPBlocked(sourceIP: string, targetPlayer: Player): boolean
	local userId = targetPlayer.UserId
	local blocked = self.blockedIPs[userId] or {}
	return table.find(blocked, sourceIP) ~= nil
end

function NetworkService:getBlockedIPs(player: Player): { string }
	return self.blockedIPs[player.UserId] or {}
end

-- Attack Detection

function NetworkService:detectBruteforce(targetPlayer: Player, sourceIP: string): boolean
	-- Check for multiple failed attempts in short time
	local recentAttempts = self:getRecentAttempts(targetPlayer, 60) -- Last minute

	local failedCount = 0
	for _, attempt in ipairs(recentAttempts) do
		if attempt.sourceIP == sourceIP and not attempt.success and attempt.method == "bruteforce" then
			failedCount = failedCount + 1
		end
	end

	return failedCount >= 5 -- 5 failed attempts in 1 minute = attack
end

function NetworkService:shouldRateLimit(sourceIP: string, targetPlayer: Player): boolean
	local attempts = self:getRecentAttempts(targetPlayer, 10) -- Last 10 seconds

	local count = 0
	for _, attempt in ipairs(attempts) do
		if attempt.sourceIP == sourceIP then
			count = count + 1
		end
	end

	return count >= 3 -- Max 3 attempts per 10 seconds
end

-- Notifications

function NetworkService:sendAlert(targetPlayer: Player, alertType: string, details: any)
	-- Send to client via RemoteEvent
	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if remotesFolder then
		local securityAlert = remotesFolder:FindFirstChild("SecurityAlert")
		if securityAlert then
			securityAlert:FireClient(targetPlayer, alertType, details)
		end
	end
end

-- Statistics

function NetworkService:getPlayerStats(player: Player): any
	local userId = player.UserId
	local attempts = self.connectionAttempts[userId] or {}

	local stats = {
		totalAttempts = #attempts,
		successfulLogins = 0,
		failedLogins = 0,
		blockedIPs = #(self.blockedIPs[userId] or {}),
		uniqueAttackers = {},
	}

	for _, attempt in ipairs(attempts) do
		if attempt.success then
			stats.successfulLogins = stats.successfulLogins + 1
		else
			stats.failedLogins = stats.failedLogins + 1
		end

		if not stats.uniqueAttackers[attempt.sourceIP] then
			stats.uniqueAttackers[attempt.sourceIP] = true
		end
	end

	local count = 0
	for _ in pairs(stats.uniqueAttackers) do
		count = count + 1
	end
	stats.uniqueAttackers = count

	return stats
end

return NetworkService

