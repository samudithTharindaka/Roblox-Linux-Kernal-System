--!strict
-- Service.luau
-- Network service class

local Types = require(game.ReplicatedStorage.Shared.Types)

local Service = {}
Service.__index = Service

function Service.new(port: number, name: string, owner: string, handler: string?, version: string?)
	local self = setmetatable({}, Service)

	self.port = port
	self.name = name
	self.owner = owner
	self.handler = handler or "/usr/bin/" .. name
	self.version = version or "1.0.0"
	self.isPublic = false
	self.connections = {}
	self.startTime = os.time()
	self.totalConnections = 0

	return self
end

function Service:setPublic(isPublic: boolean)
	self.isPublic = isPublic
end

function Service:addConnection(sourceIP: string): number
	local connectionId = #self.connections + 1
	self.connections[connectionId] = {
		sourceIP = sourceIP,
		connectedAt = os.time(),
	}
	self.totalConnections += 1
	return connectionId
end

function Service:removeConnection(connectionId: number)
	self.connections[connectionId] = nil
end

function Service:getActiveConnections(): number
	local count = 0
	for _ in pairs(self.connections) do
		count += 1
	end
	return count
end

function Service:getInfo(): Types.Service
	return {
		port = self.port,
		name = self.name,
		owner = self.owner,
		handler = self.handler,
		version = self.version,
		isPublic = self.isPublic,
	}
end

function Service:getUptime(): number
	return os.time() - self.startTime
end

function Service:serialize(): string
	return game:GetService("HttpService"):JSONEncode(self:getInfo())
end

return Service

