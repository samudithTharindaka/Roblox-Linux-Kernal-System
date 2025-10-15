--!strict
-- Constants.luau
-- Game-wide constants and configuration

local Constants = {}

-- Terminal Configuration
Constants.TERMINAL = {
	PROMPT_FORMAT = "%s@RobloxOS:%s$ ",
	MAX_OUTPUT_LINES = 500,
	HISTORY_SIZE = 100,
	TAB_COMPLETION_ENABLED = true,
}

-- Permissions
Constants.PERMISSIONS = {
	READ = 4,
	WRITE = 2,
	EXECUTE = 1,
	DEFAULT_FILE = 6, -- rw-
	DEFAULT_DIR = 7, -- rwx
	DEFAULT_EXECUTABLE = 7, -- rwx
}

-- System Paths
Constants.PATHS = {
	ROOT = "/",
	HOME = "/home",
	ETC = "/etc",
	VAR = "/var",
	VAR_LOG = "/var/log",
	USR = "/usr",
	USR_BIN = "/usr/bin",
	SRV = "/srv",
	TMP = "/tmp",
}

-- Logging
Constants.LOGS = {
	AUTH_LOG = "/var/log/auth.log",
	SYS_LOG = "/var/log/syslog",
	MAX_LOG_ENTRIES = 1000,
}

-- Networking
Constants.NETWORK = {
	IP_RANGE_START = "192.168.1.1",
	PORT_RANGE_MIN = 1,
	PORT_RANGE_MAX = 65535,
	COMMON_PORTS = {
		SSH = 22,
		HTTP = 80,
		HTTPS = 443,
		FTP = 21,
		TELNET = 23,
		SMTP = 25,
	},
	SCAN_DELAY_PER_PORT = 0.5, -- seconds
	MAX_CONNECTIONS = 10,
}

-- Security
Constants.SECURITY = {
	MAX_LOGIN_ATTEMPTS = 5,
	LOCKOUT_DURATION = 300, -- seconds
	SUDO_TOKEN_LIFETIME = 900, -- seconds
	BRUTEFORCE_ATTEMPTS_PER_SECOND = 2,
	SCAN_NOISE_THRESHOLD = 10, -- scans before alert
	ANTIVIRUS_SCAN_TIME = 5, -- seconds
}

-- Economy
Constants.ECONOMY = {
	STARTING_CURRENCY = 1000,
	HACK_SUCCESS_REWARD = 500,
	DEFENSE_SUCCESS_REWARD = 300,
	SNAPSHOT_COST = 100,
	EXPLOIT_KIT_COST = 1000,
}

-- Cooldowns (in seconds)
Constants.COOLDOWNS = {
	SNAPSHOT_CREATE = 300,
	SNAPSHOT_RESTORE = 600,
	MASS_SCAN = 60,
	EXPLOIT_USE = 30,
	BRUTEFORCE = 120,
}

-- Process limits
Constants.PROCESS = {
	MAX_PID = 9999,
	MAX_PROCESSES_PER_USER = 50,
	BASE_CPU_USAGE = 0.1,
	BASE_MEMORY_USAGE = 1024, -- KB
}

-- DataStore Configuration
Constants.DATASTORE = {
	VFS_KEY_PREFIX = "VFS_",
	PLAYER_STATE_KEY_PREFIX = "PlayerState_",
	SAVE_INTERVAL = 300, -- Auto-save every 5 minutes
	MAX_VFS_SIZE = 4000000, -- ~4MB limit for DataStore
}

-- UI Colors
Constants.COLORS = {
	TERMINAL_BG = Color3.fromRGB(20, 20, 30),
	TERMINAL_TEXT = Color3.fromRGB(200, 200, 200),
	PROMPT_COLOR = Color3.fromRGB(100, 255, 100),
	ERROR_COLOR = Color3.fromRGB(255, 100, 100),
	SUCCESS_COLOR = Color3.fromRGB(100, 255, 100),
	WARNING_COLOR = Color3.fromRGB(255, 200, 100),
	COMMAND_COLOR = Color3.fromRGB(255, 255, 100),
}

-- Commands
Constants.COMMANDS = {
	-- Will be populated by command modules
	FILESYSTEM = { "ls", "cd", "pwd", "mkdir", "rmdir", "rm", "touch", "cat", "cp", "mv", "chmod", "chown" },
	EDITING = { "nano", "ed" },
	SYSTEM = { "whoami", "date", "uptime", "htop", "ps", "kill", "clear" },
	NETWORK = { "ifconfig", "netstat", "listen", "connect", "send", "ping" },
	SECURITY = { "ufw", "authlog", "monitor", "scan" },
	HACKING = { "bruteforce", "exploit", "phish", "payload", "deploy", "sniff" },
	DEFENSE = { "restore", "snapshot", "isolate", "killprocess", "antivirus", "rollback" },
	ADMIN = { "sudo", "su", "adduser" },
}

-- Exploits Database
Constants.EXPLOITS = {
	{
		name = "ssh_backdoor_v1",
		targetService = "ssh",
		targetVersion = "1.0.0",
		successRate = 0.7,
		requiredSkill = 3,
		noiseLevel = 5,
	},
	{
		name = "http_overflow",
		targetService = "http",
		targetVersion = "0.9.0",
		successRate = 0.5,
		requiredSkill = 5,
		noiseLevel = 8,
	},
}

-- Wordlists for bruteforce
Constants.WORDLISTS = {
	common_passwords = {
		"password",
		"123456",
		"admin",
		"root",
		"qwerty",
		"letmein",
		"welcome",
		"monkey",
		"dragon",
		"master",
	},
}

return Constants

