--!strict
-- Utils.luau
-- Shared utility functions

local Utils = {}

-- Split a string by delimiter
function Utils.split(str: string, delimiter: string): { string }
	local result = {}
	local pattern = string.format("([^%s]+)", delimiter)
	for match in string.gmatch(str, pattern) do
		table.insert(result, match)
	end
	return result
end

-- Trim whitespace from string
function Utils.trim(str: string): string
	return string.match(str, "^%s*(.-)%s*$") or ""
end

-- Join path components
function Utils.joinPath(...: string): string
	local parts = { ... }
	local path = ""
	for i, part in ipairs(parts) do
		if i == 1 then
			path = part
		else
			if not string.match(path, "/$") and not string.match(part, "^/") then
				path = path .. "/" .. part
			elseif string.match(path, "/$") and string.match(part, "^/") then
				path = path .. string.sub(part, 2)
			else
				path = path .. part
			end
		end
	end
	return path
end

-- Normalize path (resolve . and ..)
function Utils.normalizePath(path: string): string
	local parts = Utils.split(path, "/")
	local normalized = {}

	for _, part in ipairs(parts) do
		if part == "." or part == "" then
			-- Skip current directory and empty parts
			continue
		elseif part == ".." then
			-- Go up one directory
			if #normalized > 0 then
				table.remove(normalized)
			end
		else
			table.insert(normalized, part)
		end
	end

	local result = "/" .. table.concat(normalized, "/")
	return result
end

-- Get parent directory
function Utils.getParentPath(path: string): string
	local parts = Utils.split(path, "/")
	if #parts <= 1 then
		return "/"
	end
	table.remove(parts)
	return "/" .. table.concat(parts, "/")
end

-- Get filename from path
function Utils.getFileName(path: string): string
	local parts = Utils.split(path, "/")
	return parts[#parts] or ""
end

-- Check if path is absolute
function Utils.isAbsolutePath(path: string): boolean
	return string.sub(path, 1, 1) == "/"
end

-- Format timestamp
function Utils.formatTimestamp(timestamp: number): string
	local dateTime = DateTime.fromUnixTimestamp(timestamp)
	return dateTime:FormatLocalTime("YYYY-MM-DD HH:mm:ss", "en-us")
end

-- Format file size
function Utils.formatFileSize(size: number): string
	if size < 1024 then
		return string.format("%dB", size)
	elseif size < 1024 * 1024 then
		return string.format("%.1fK", size / 1024)
	elseif size < 1024 * 1024 * 1024 then
		return string.format("%.1fM", size / (1024 * 1024))
	else
		return string.format("%.1fG", size / (1024 * 1024 * 1024))
	end
end

-- Format permissions as rwx string
function Utils.formatPermissions(permissions: any): string
	local r = permissions.read and "r" or "-"
	local w = permissions.write and "w" or "-"
	local x = permissions.execute and "x" or "-"
	return r .. w .. x
end

-- Parse permissions from string or octal
function Utils.parsePermissions(mode: string): any
	local perms = {
		read = false,
		write = false,
		execute = false,
	}

	-- Try octal format first (e.g., "7" or "777")
	local octal = tonumber(mode)
	if octal then
		-- Use last digit for user permissions
		local digit = octal % 10
		perms.read = bit32.band(digit, 4) > 0
		perms.write = bit32.band(digit, 2) > 0
		perms.execute = bit32.band(digit, 1) > 0
		return perms
	end

	-- Parse rwx format
	if string.find(mode, "r") then
		perms.read = true
	end
	if string.find(mode, "w") then
		perms.write = true
	end
	if string.find(mode, "x") then
		perms.execute = true
	end

	return perms
end

-- Deep copy table
function Utils.deepCopy(original: any): any
	local copy
	if type(original) == "table" then
		copy = {}
		for key, value in pairs(original) do
			copy[key] = Utils.deepCopy(value)
		end
	else
		copy = original
	end
	return copy
end

-- Generate random IP address
function Utils.generateIP(): string
	local a = math.random(192, 192)
	local b = math.random(168, 168)
	local c = math.random(1, 1)
	local d = math.random(2, 254)
	return string.format("%d.%d.%d.%d", a, b, c, d)
end

-- Hash string (simple hash for passwords)
function Utils.hash(str: string, salt: string?): string
	local combined = str .. (salt or "")
	local hash = 0
	for i = 1, #combined do
		hash = (hash * 31 + string.byte(combined, i)) % (2 ^ 31 - 1)
	end
	return string.format("%08x", hash)
end

-- Generate random string
function Utils.randomString(length: number): string
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local result = ""
	for i = 1, length do
		local idx = math.random(1, #chars)
		result = result .. string.sub(chars, idx, idx)
	end
	return result
end

-- Parse command line with quotes
function Utils.parseCommandLine(input: string): { string }
	local args = {}
	local current = ""
	local inQuotes = false
	local quoteChar = nil

	for i = 1, #input do
		local char = string.sub(input, i, i)

		if (char == '"' or char == "'") and not inQuotes then
			inQuotes = true
			quoteChar = char
		elseif char == quoteChar and inQuotes then
			inQuotes = false
			quoteChar = nil
		elseif char == " " and not inQuotes then
			if #current > 0 then
				table.insert(args, current)
				current = ""
			end
		else
			current = current .. char
		end
	end

	if #current > 0 then
		table.insert(args, current)
	end

	return args
end

-- Color text (returns color tag for RichText)
function Utils.colorText(text: string, color: Color3): string
	local r = math.floor(color.R * 255)
	local g = math.floor(color.G * 255)
	local b = math.floor(color.B * 255)
	return string.format('<font color="rgb(%d,%d,%d)">%s</font>', r, g, b, text)
end

return Utils

