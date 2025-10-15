--!strict
-- VFS.luau
-- Virtual File System class with permissions and directory tree

local Types = require(game.ReplicatedStorage.Shared.Types)
local Constants = require(game.ReplicatedStorage.Shared.Constants)
local Utils = require(game.ReplicatedStorage.Shared.Utils)

local VFS = {}
VFS.__index = VFS

type FileMetadata = Types.FileMetadata
type Permission = Types.Permission

function VFS.new(owner: string)
	local self = setmetatable({}, VFS)

	self.root = {}
	self.owner = owner
	self.snapshots = {}

	-- Initialize default directory structure
	self:_initializeStructure()

	return self
end

function VFS:_initializeStructure()
	-- Create root directories
	self:createDirectory("/home", "root")
	self:createDirectory("/etc", "root")
	self:createDirectory("/var", "root")
	self:createDirectory("/var/log", "root")
	self:createDirectory("/usr", "root")
	self:createDirectory("/usr/bin", "root")
	self:createDirectory("/srv", "root")
	self:createDirectory("/tmp", "root")

	-- Create user home directory
	self:createDirectory("/home/" .. self.owner, self.owner)

	-- Create initial log files
	self:createFile("/var/log/auth.log", "", self.owner)
	self:createFile("/var/log/syslog", "", self.owner)

	-- Create welcome file
	local welcomeMsg = "Welcome to RobloxOS!\n\nType 'help' for available commands.\n"
	self:createFile("/home/" .. self.owner .. "/welcome.txt", welcomeMsg, self.owner)
end

function VFS:_resolvePath(path: string, currentDir: string): string
	if Utils.isAbsolutePath(path) then
		return Utils.normalizePath(path)
	else
		return Utils.normalizePath(Utils.joinPath(currentDir, path))
	end
end

function VFS:_getNode(path: string): any?
	local parts = Utils.split(path, "/")
	local current = self.root

	for _, part in ipairs(parts) do
		if part == "" then
			continue
		end

		if not current[part] then
			return nil
		end

		current = current[part]
	end

	return current
end

function VFS:_createNode(path: string, isDirectory: boolean, owner: string, content: string?): boolean
	local parentPath = Utils.getParentPath(path)
	local fileName = Utils.getFileName(path)

	if fileName == "" then
		return false
	end

	local parentNode = self:_getNode(parentPath)
	if not parentNode then
		return false
	end

	-- Check if already exists
	if parentNode[fileName] then
		return false
	end

	-- Create node
	local node: any = {
		name = fileName,
		isDirectory = isDirectory,
		owner = owner,
		permissions = {
			read = true,
			write = true,
			execute = isDirectory,
		},
		timestamp = os.time(),
		size = content and #content or 0,
		executable = false,
	}

	if not isDirectory then
		node.content = content or ""
	end

	parentNode[fileName] = node

	return true
end

function VFS:createDirectory(path: string, owner: string, currentDir: string?): boolean
	local fullPath = self:_resolvePath(path, currentDir or "/")
	return self:_createNode(fullPath, true, owner, nil)
end

function VFS:createFile(path: string, content: string, owner: string, currentDir: string?): boolean
	local fullPath = self:_resolvePath(path, currentDir or "/")
	return self:_createNode(fullPath, false, owner, content)
end

function VFS:readFile(path: string, user: string, currentDir: string?): (boolean, string?)
	local fullPath = self:_resolvePath(path, currentDir or "/")
	local node = self:_getNode(fullPath)

	if not node then
		return false, "File not found"
	end

	if node.isDirectory then
		return false, "Is a directory"
	end

	-- Check read permission
	if not self:checkPermission(fullPath, user, "read") then
		return false, "Permission denied"
	end

	return true, node.content
end

function VFS:writeFile(path: string, content: string, user: string, currentDir: string?): (boolean, string?)
	local fullPath = self:_resolvePath(path, currentDir or "/")
	local node = self:_getNode(fullPath)

	if not node then
		return false, "File not found"
	end

	if node.isDirectory then
		return false, "Is a directory"
	end

	-- Check write permission
	if not self:checkPermission(fullPath, user, "write") then
		return false, "Permission denied"
	end

	node.content = content
	node.size = #content
	node.timestamp = os.time()

	return true, nil
end

function VFS:listDirectory(path: string, user: string, currentDir: string?): (boolean, { any }?)
	local fullPath = self:_resolvePath(path, currentDir or "/")
	local node = self:_getNode(fullPath)

	if not node then
		return false, nil
	end

	if not node.isDirectory then
		return false, nil
	end

	-- Check read permission
	if not self:checkPermission(fullPath, user, "read") then
		return false, nil
	end

	local entries = {}
	for name, childNode in pairs(node) do
		if type(childNode) == "table" and childNode.name then
			table.insert(entries, childNode)
		end
	end

	return true, entries
end

function VFS:exists(path: string, currentDir: string?): boolean
	local fullPath = self:_resolvePath(path, currentDir or "/")
	return self:_getNode(fullPath) ~= nil
end

function VFS:isDirectory(path: string, currentDir: string?): boolean
	local fullPath = self:_resolvePath(path, currentDir or "/")
	local node = self:_getNode(fullPath)
	return node ~= nil and node.isDirectory == true
end

function VFS:delete(path: string, user: string, currentDir: string?): (boolean, string?)
	local fullPath = self:_resolvePath(path, currentDir or "/")

	if fullPath == "/" then
		return false, "Cannot delete root directory"
	end

	local node = self:_getNode(fullPath)
	if not node then
		return false, "File not found"
	end

	-- Check write permission on parent
	local parentPath = Utils.getParentPath(fullPath)
	if not self:checkPermission(parentPath, user, "write") then
		return false, "Permission denied"
	end

	-- Check if directory is empty
	if node.isDirectory then
		for name, child in pairs(node) do
			if type(child) == "table" and child.name then
				return false, "Directory not empty"
			end
		end
	end

	-- Delete the node
	local parentNode = self:_getNode(parentPath)
	local fileName = Utils.getFileName(fullPath)
	parentNode[fileName] = nil

	return true, nil
end

function VFS:copy(source: string, destination: string, user: string, currentDir: string?): (boolean, string?)
	local srcPath = self:_resolvePath(source, currentDir or "/")
	local dstPath = self:_resolvePath(destination, currentDir or "/")

	-- Check source exists and we can read it
	if not self:checkPermission(srcPath, user, "read") then
		return false, "Permission denied on source"
	end

	local srcNode = self:_getNode(srcPath)
	if not srcNode then
		return false, "Source not found"
	end

	-- Check destination parent exists and we can write
	local dstParent = Utils.getParentPath(dstPath)
	if not self:checkPermission(dstParent, user, "write") then
		return false, "Permission denied on destination"
	end

	-- Create copy
	if srcNode.isDirectory then
		return false, "Cannot copy directories (not implemented)"
	end

	return self:createFile(dstPath, srcNode.content, user, "/")
end

function VFS:move(source: string, destination: string, user: string, currentDir: string?): (boolean, string?)
	-- Copy then delete
	local success, err = self:copy(source, destination, user, currentDir)
	if not success then
		return false, err
	end

	return self:delete(source, user, currentDir)
end

function VFS:chmod(path: string, mode: string, user: string, currentDir: string?): (boolean, string?)
	local fullPath = self:_resolvePath(path, currentDir or "/")
	local node = self:_getNode(fullPath)

	if not node then
		return false, "File not found"
	end

	-- Only owner can chmod
	if node.owner ~= user and user ~= "root" then
		return false, "Permission denied: not owner"
	end

	local perms = Utils.parsePermissions(mode)
	node.permissions = perms

	return true, nil
end

function VFS:chown(path: string, newOwner: string, user: string, currentDir: string?): (boolean, string?)
	-- Only root can chown
	if user ~= "root" then
		return false, "Permission denied: root required"
	end

	local fullPath = self:_resolvePath(path, currentDir or "/")
	local node = self:_getNode(fullPath)

	if not node then
		return false, "File not found"
	end

	node.owner = newOwner
	return true, nil
end

function VFS:checkPermission(path: string, user: string, permissionType: "read" | "write" | "execute"): boolean
	local node = self:_getNode(path)
	if not node then
		return false
	end

	-- Root has all permissions
	if user == "root" then
		return true
	end

	-- Owner check
	if node.owner == user then
		return node.permissions[permissionType] == true
	end

	-- For now, simple check (could be extended with groups)
	return node.permissions[permissionType] == true
end

function VFS:createSnapshot(name: string): boolean
	local snapshot = {
		name = name,
		timestamp = os.time(),
		data = Utils.deepCopy(self.root),
	}
	self.snapshots[name] = snapshot
	return true
end

function VFS:restoreSnapshot(name: string): (boolean, string?)
	local snapshot = self.snapshots[name]
	if not snapshot then
		return false, "Snapshot not found"
	end

	self.root = Utils.deepCopy(snapshot.data)
	return true, nil
end

function VFS:listSnapshots(): { any }
	local list = {}
	for name, snapshot in pairs(self.snapshots) do
		table.insert(list, {
			name = name,
			timestamp = snapshot.timestamp,
		})
	end
	return list
end

function VFS:serialize(): string
	local data = {
		root = self.root,
		owner = self.owner,
		snapshots = self.snapshots,
	}
	return game:GetService("HttpService"):JSONEncode(data)
end

function VFS:deserialize(data: string)
	local decoded = game:GetService("HttpService"):JSONDecode(data)
	self.root = decoded.root
	self.owner = decoded.owner
	self.snapshots = decoded.snapshots or {}
end

return VFS

