--!strict
-- Process.luau
-- Process simulation class

local Types = require(game.ReplicatedStorage.Shared.Types)

local Process = {}
Process.__index = Process

local nextPID = 1

function Process.new(name: string, owner: string, command: string)
	local self = setmetatable({}, Process)

	self.pid = nextPID
	nextPID = nextPID + 1

	if nextPID > 9999 then
		nextPID = 1
	end

	self.name = name
	self.owner = owner
	self.command = command
	self.cpuUsage = math.random(1, 15) / 10 -- Random CPU usage between 0.1-1.5%
	self.memoryUsage = math.random(512, 4096) -- Random memory in KB
	self.status = "running"
	self.startTime = os.time()
	self.logs = {}

	return self
end

function Process:getUptime(): number
	return os.time() - self.startTime
end

function Process:setStatus(newStatus: "running" | "sleeping" | "stopped" | "zombie")
	self.status = newStatus
end

function Process:addLog(message: string)
	table.insert(self.logs, {
		timestamp = os.time(),
		message = message,
	})
end

function Process:getLogs(): { any }
	return self.logs
end

function Process:kill(): boolean
	if self.status == "zombie" then
		return false
	end
	self.status = "stopped"
	return true
end

function Process:getInfo(): Types.Process
	return {
		pid = self.pid,
		name = self.name,
		owner = self.owner,
		cpuUsage = self.cpuUsage,
		memoryUsage = self.memoryUsage,
		status = self.status,
		startTime = self.startTime,
		command = self.command,
	}
end

-- Update CPU usage (simulated)
function Process:updateMetrics()
	-- Randomly fluctuate CPU usage
	local change = (math.random() - 0.5) * 0.2
	self.cpuUsage = math.max(0.1, math.min(10, self.cpuUsage + change))

	-- Occasionally change status
	if math.random() < 0.05 then
		if self.status == "running" then
			self.status = "sleeping"
		elseif self.status == "sleeping" then
			self.status = "running"
		end
	end
end

function Process:serialize(): string
	return game:GetService("HttpService"):JSONEncode(self:getInfo())
end

return Process

