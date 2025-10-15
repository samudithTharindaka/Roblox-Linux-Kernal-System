--!strict
-- DataPersistence.luau
-- Handles DataStore persistence for player data

local DataStoreService = game:GetService("DataStoreService")
local Constants = require(game.ReplicatedStorage.Shared.Constants)

local DataPersistence = {}
DataPersistence.__index = DataPersistence

local playerDataStore = DataStoreService:GetDataStore("RobloxOS_PlayerData_v1")

function DataPersistence.new()
	local self = setmetatable({}, DataPersistence)

	self.saveQueue = {}
	self.lastSaveTime = {}

	return self
end

function DataPersistence:loadPlayerData(userId: number): any?
	local success, data = pcall(function()
		return playerDataStore:GetAsync(tostring(userId))
	end)

	if success and data then
		return data
	end

	return nil
end

function DataPersistence:savePlayerData(userId: number, data: any): boolean
	-- Rate limiting
	local lastSave = self.lastSaveTime[userId] or 0
	if os.time() - lastSave < 5 then
		warn("Save rate limited for user", userId)
		return false
	end

	local success = pcall(function()
		playerDataStore:SetAsync(tostring(userId), data)
	end)

	if success then
		self.lastSaveTime[userId] = os.time()
		return true
	else
		warn("Failed to save data for user", userId)
		return false
	end
end

function DataPersistence:queueSave(userId: number, data: any)
	self.saveQueue[userId] = data
end

function DataPersistence:processSaveQueue()
	for userId, data in pairs(self.saveQueue) do
		local success = self:savePlayerData(userId, data)
		if success then
			self.saveQueue[userId] = nil
		end
	end
end

function DataPersistence:serializePlayerState(playerState: any, vfs: any, user: any, auditLog: any): string
	local data = {
		playerState = {
			currentDirectory = playerState.currentDirectory,
			ipAddress = playerState.ipAddress,
			vmUptime = playerState.vmUptime,
			commandHistory = playerState.commandHistory,
			environment = playerState.environment,
		},
		vfs = vfs:serialize(),
		user = user:serialize(),
		auditLog = auditLog:serialize(),
		timestamp = os.time(),
	}

	return game:GetService("HttpService"):JSONEncode(data)
end

function DataPersistence:deserializePlayerState(dataString: string): any?
	local success, data = pcall(function()
		return game:GetService("HttpService"):JSONDecode(dataString)
	end)

	if success then
		return data
	end

	return nil
end

return DataPersistence

