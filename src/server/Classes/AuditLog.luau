--!strict
-- AuditLog.luau
-- Audit logging system

local Types = require(game.ReplicatedStorage.Shared.Types)
local Constants = require(game.ReplicatedStorage.Shared.Constants)
local Utils = require(game.ReplicatedStorage.Shared.Utils)

local AuditLog = {}
AuditLog.__index = AuditLog

function AuditLog.new(owner: string)
	local self = setmetatable({}, AuditLog)

	self.owner = owner
	self.entries = {}
	self.maxEntries = Constants.LOGS.MAX_LOG_ENTRIES

	return self
end

function AuditLog:addEntry(
	user: string,
	action: string,
	details: string,
	severity: "info" | "warning" | "critical"?,
	sourceIP: string?
)
	local entry: Types.AuditLogEntry = {
		timestamp = os.time(),
		user = user,
		action = action,
		details = details,
		severity = severity or "info",
		sourceIP = sourceIP,
	}

	table.insert(self.entries, entry)

	-- Trim old entries if exceeding max
	if #self.entries > self.maxEntries then
		table.remove(self.entries, 1)
	end

	return entry
end

function AuditLog:getEntries(filter: { user: string?, action: string?, severity: string?, since: number? }?): { Types.AuditLogEntry }
	if not filter then
		return self.entries
	end

	local filtered = {}
	for _, entry in ipairs(self.entries) do
		local matches = true

		if filter.user and entry.user ~= filter.user then
			matches = false
		end

		if filter.action and entry.action ~= filter.action then
			matches = false
		end

		if filter.severity and entry.severity ~= filter.severity then
			matches = false
		end

		if filter.since and entry.timestamp < filter.since then
			matches = false
		end

		if matches then
			table.insert(filtered, entry)
		end
	end

	return filtered
end

function AuditLog:getRecentEntries(count: number): { Types.AuditLogEntry }
	local result = {}
	local startIdx = math.max(1, #self.entries - count + 1)

	for i = startIdx, #self.entries do
		table.insert(result, self.entries[i])
	end

	return result
end

function AuditLog:formatEntry(entry: Types.AuditLogEntry): string
	local timestamp = Utils.formatTimestamp(entry.timestamp)
	local severityTag = string.upper(entry.severity)
	local sourceInfo = entry.sourceIP and (" from " .. entry.sourceIP) or ""

	return string.format(
		"[%s] [%s] %s: %s%s - %s",
		timestamp,
		severityTag,
		entry.user,
		entry.action,
		sourceInfo,
		entry.details
	)
end

function AuditLog:formatEntries(entries: { Types.AuditLogEntry }?): string
	local entriesToFormat = entries or self.entries
	local lines = {}

	for _, entry in ipairs(entriesToFormat) do
		table.insert(lines, self:formatEntry(entry))
	end

	return table.concat(lines, "\n")
end

function AuditLog:clear()
	self.entries = {}
end

function AuditLog:serialize(): string
	local data = {
		owner = self.owner,
		entries = self.entries,
	}
	return game:GetService("HttpService"):JSONEncode(data)
end

function AuditLog:deserialize(data: string)
	local decoded = game:GetService("HttpService"):JSONDecode(data)
	self.owner = decoded.owner
	self.entries = decoded.entries or {}
end

return AuditLog

