--!strict
-- User.luau
-- User management class

local Types = require(game.ReplicatedStorage.Shared.Types)
local Utils = require(game.ReplicatedStorage.Shared.Utils)

local User = {}
User.__index = User

function User.new(username: string, uid: number, player: Player?)
	local self = setmetatable({}, User)

	self.username = username
	self.uid = uid
	self.player = player -- Store player reference
	self.groups = { "users" }
	self.homeDirectory = "/home/" .. username
	self.passwordHash = Utils.hash("changeme", username) -- Default password
	self.sudoEnabled = false
	self.sudoToken = nil
	self.sudoTokenExpiry = 0
	self.loginAttempts = 0
	self.lockedUntil = 0

	return self
end

function User:setPassword(newPassword: string)
	self.passwordHash = Utils.hash(newPassword, self.username)
end

function User:verifyPassword(password: string): boolean
	return self.passwordHash == Utils.hash(password, self.username)
end

function User:attemptLogin(password: string): (boolean, string?)
	-- Check if locked out
	if os.time() < self.lockedUntil then
		local remaining = self.lockedUntil - os.time()
		return false, string.format("Account locked. Try again in %d seconds", remaining)
	end

	-- Verify password
	if self:verifyPassword(password) then
		self.loginAttempts = 0
		return true, nil
	end

	-- Failed login
	self.loginAttempts += 1

	local Constants = require(game.ReplicatedStorage.Shared.Constants)
	if self.loginAttempts >= Constants.SECURITY.MAX_LOGIN_ATTEMPTS then
		self.lockedUntil = os.time() + Constants.SECURITY.LOCKOUT_DURATION
		return false, "Too many failed attempts. Account locked."
	end

	return false, string.format("Invalid password (%d/%d attempts)", self.loginAttempts, Constants.SECURITY.MAX_LOGIN_ATTEMPTS)
end

function User:grantSudo()
	self.sudoEnabled = true
end

function User:revokeSudo()
	self.sudoEnabled = false
	self.sudoToken = nil
end

function User:activateSudoToken()
	if not self.sudoEnabled then
		return false
	end

	local Constants = require(game.ReplicatedStorage.Shared.Constants)
	self.sudoToken = Utils.randomString(32)
	self.sudoTokenExpiry = os.time() + Constants.SECURITY.SUDO_TOKEN_LIFETIME

	return true
end

function User:hasSudoAccess(): boolean
	if not self.sudoEnabled then
		return false
	end

	if not self.sudoToken then
		return false
	end

	if os.time() > self.sudoTokenExpiry then
		self.sudoToken = nil
		return false
	end

	return true
end

function User:addToGroup(group: string)
	if not table.find(self.groups, group) then
		table.insert(self.groups, group)
	end
end

function User:removeFromGroup(group: string)
	local idx = table.find(self.groups, group)
	if idx then
		table.remove(self.groups, idx)
	end
end

function User:isInGroup(group: string): boolean
	return table.find(self.groups, group) ~= nil
end

function User:serialize(): string
	local data = {
		username = self.username,
		uid = self.uid,
		groups = self.groups,
		homeDirectory = self.homeDirectory,
		passwordHash = self.passwordHash,
		sudoEnabled = self.sudoEnabled,
	}
	return game:GetService("HttpService"):JSONEncode(data)
end

function User.deserialize(data: string, player: Player?): any
	local decoded = game:GetService("HttpService"):JSONDecode(data)
	local user = User.new(decoded.username, decoded.uid, player)
	user.groups = decoded.groups
	user.homeDirectory = decoded.homeDirectory
	user.passwordHash = decoded.passwordHash
	user.sudoEnabled = decoded.sudoEnabled
	return user
end

return User

