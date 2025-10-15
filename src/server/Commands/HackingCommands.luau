--!strict
-- HackingCommands.luau
-- Hacking and offensive security commands (simulated)

local Types = require(game.ReplicatedStorage.Shared.Types)
local Constants = require(game.ReplicatedStorage.Shared.Constants)

local HackingCommands = {}

-- bruteforce - attempt password brute force
HackingCommands.bruteforce = {
	description = "Attempt password brute force attack",
	usage = "bruteforce -t <target> -u <user> -p <wordlist>",
	minArgs = 6,
	maxArgs = 6,
	execute = function(context: any, args: { string }): Types.CommandResult
		-- Parse arguments
		local target, user, wordlist
		for i = 1, #args, 2 do
			local flag = args[i]
			local value = args[i + 1]

			if flag == "-t" then
				target = value
			elseif flag == "-u" then
				user = value
			elseif flag == "-p" then
				wordlist = value
			end
		end

		if not target or not user or not wordlist then
			return {
				success = false,
				output = "bruteforce: missing required arguments",
				errorCode = 1,
			}
		end

		-- Log the attack (VERY NOISY!)
		context.auditLog:addEntry(
			context.user.username,
			"BRUTEFORCE",
			string.format("Brute force attack against %s@%s", user, target),
			"critical",
			context.playerState.ipAddress
		)

		-- Simulate brute force attempt
		local output = string.format(
			[[Starting brute force attack...
Target: %s
User: %s
Wordlist: %s

Trying passwords:
  password... FAILED
  123456... FAILED
  admin... FAILED
  root... FAILED
  qwerty... FAILED
  ...

Attack detected and blocked by target firewall.
0/100 passwords tried before lockout.]],
			target,
			user,
			wordlist
		)

		return {
			success = false,
			output = output,
			errorCode = 1,
		}
	end,
}

-- exploit - use an exploit against a target
HackingCommands.exploit = {
	description = "Use an exploit against a target service",
	usage = "exploit <target> <exploitName>",
	minArgs = 2,
	maxArgs = 2,
	execute = function(context: any, args: { string }): Types.CommandResult
		local target = args[1]
		local exploitName = args[2]

		-- Log the exploit attempt
		context.auditLog:addEntry(
			context.user.username,
			"EXPLOIT",
			string.format("Exploit attempt: %s against %s", exploitName, target),
			"critical",
			context.playerState.ipAddress
		)

		-- Check if exploit exists
		local exploitFound = false
		for _, exploit in ipairs(Constants.EXPLOITS) do
			if exploit.name == exploitName then
				exploitFound = true
				break
			end
		end

		if not exploitFound then
			return {
				success = false,
				output = string.format("exploit: unknown exploit '%s'", exploitName),
				errorCode = 1,
			}
		end

		-- Simulate exploit attempt (usually fails or detected)
		local success = math.random() < 0.2 -- 20% success rate for simulation

		if success then
			return {
				success = true,
				output = string.format(
					[[Exploit '%s' launched against %s

[+] Target vulnerable!
[+] Exploit successful
[+] Access granted

You now have a shell on %s]],
					exploitName,
					target,
					target
				),
			}
		else
			return {
				success = false,
				output = string.format(
					[[Exploit '%s' launched against %s

[-] Target not vulnerable or patched
[-] Exploit failed
[-] Intrusion detection system alerted]],
					exploitName,
					target
				),
				errorCode = 1,
			}
		end
	end,
}

-- phish - craft phishing message
HackingCommands.phish = {
	description = "Craft a phishing message",
	usage = "phish <target>",
	minArgs = 1,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		local target = args[1]

		context.auditLog:addEntry(
			context.user.username,
			"PHISH",
			"Phishing attempt against " .. target,
			"warning",
			context.playerState.ipAddress
		)

		return {
			success = true,
			output = string.format(
				[[Crafting phishing message for %s...

Message template created. 
Use 'send' command to deliver the phishing payload.

Note: Social engineering requires player interaction.]],
				target
			),
		}
	end,
}

-- payload - create or manage payloads
HackingCommands.payload = {
	description = "Create or manage exploit payloads",
	usage = "payload [create|list] [name]",
	minArgs = 1,
	maxArgs = 2,
	execute = function(context: any, args: { string }): Types.CommandResult
		local action = args[1]

		if action == "create" then
			if #args < 2 then
				return {
					success = false,
					output = "payload: missing payload name",
					errorCode = 1,
				}
			end

			local name = args[2]

			context.auditLog:addEntry(context.user.username, "PAYLOAD_CREATE", "Created payload: " .. name, "warning")

			return {
				success = true,
				output = string.format(
					[[Payload '%s' created successfully.

Type: Backdoor
Size: 4.2KB
Signature: 0x%s

Use 'deploy' command to deliver payload.]],
					name,
					require(game.ReplicatedStorage.Shared.Utils).randomString(8)
				),
			}
		elseif action == "list" then
			return {
				success = true,
				output = [[Available payloads:

  backdoor_v1    (4.2KB)  - Remote access backdoor
  keylogger      (2.1KB)  - Keystroke logger
  worm_basic     (8.5KB)  - Self-replicating worm

Use 'payload create <name>' to create a new payload.]],
			}
		else
			return {
				success = false,
				output = "payload: invalid action. Use: create or list",
				errorCode = 1,
			}
		end
	end,
}

-- deploy - deploy a payload
HackingCommands.deploy = {
	description = "Deploy a payload to target",
	usage = "deploy <payload> <target>",
	minArgs = 2,
	maxArgs = 2,
	execute = function(context: any, args: { string }): Types.CommandResult
		local payload = args[1]
		local target = args[2]

		context.auditLog:addEntry(
			context.user.username,
			"DEPLOY",
			string.format("Deploy %s to %s", payload, target),
			"critical",
			context.playerState.ipAddress
		)

		-- Simulate deployment
		local success = math.random() < 0.3 -- 30% success

		if success then
			return {
				success = true,
				output = string.format(
					[[Deploying payload '%s' to %s...

[+] Connection established
[+] Uploading payload... done
[+] Executing payload... done
[+] Backdoor active on port 4444

Payload deployed successfully!]],
					payload,
					target
				),
			}
		else
			return {
				success = false,
				output = string.format(
					[[Deploying payload '%s' to %s...

[-] Connection established
[-] Uploading payload... detected!
[-] Antivirus blocked payload
[-] Deployment failed]],
					payload,
					target
				),
				errorCode = 1,
			}
		end
	end,
}

-- sniff - packet sniffer
HackingCommands.sniff = {
	description = "Sniff network packets",
	usage = "sniff [interface]",
	minArgs = 0,
	maxArgs = 1,
	execute = function(context: any, args: { string }): Types.CommandResult
		local interface = args[1] or "eth0"

		context.auditLog:addEntry(context.user.username, "SNIFF", "Started packet sniffer on " .. interface, "warning")

		return {
			success = true,
			output = string.format(
				[[Starting packet sniffer on %s...

Captured packets:
  192.168.1.10:34521 -> 192.168.1.20:80   HTTP GET /index.html
  192.168.1.15:22    -> 192.168.1.30:4567 SSH-2.0-OpenSSH_7.4
  192.168.1.10:44231 -> 192.168.1.25:443  TLS1.3 (encrypted)

Press Ctrl+C to stop sniffing...]],
				interface
			),
		}
	end,
}

return HackingCommands

