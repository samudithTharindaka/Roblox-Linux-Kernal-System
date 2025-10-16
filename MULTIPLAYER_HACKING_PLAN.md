# Multiplayer Password Hacking System - Implementation Plan

## 🎮 Core Concept

Players can discover, communicate with, and hack each other's systems to steal passwords and gain unauthorized access to their virtual machines.

---

## 📋 Features to Implement

### 1. **Password System** ✅ (Partially Done)
- [x] User class has password hashing
- [ ] Add password setup on first login
- [ ] Password change command
- [ ] Password strength indicator
- [ ] Failed login attempt tracking per IP

### 2. **Player Discovery & Networking**
- [ ] `players` command - list all online players with their IPs
- [ ] `whois <ip>` - get info about a player (name, uptime, services)
- [ ] `finger <username>` - get user information
- [ ] Network map visualization

### 3. **Inter-Player Communication**
- [ ] `msg <player> <message>` - send direct message
- [ ] `chat` - global chat room
- [ ] `mail <player>` - send email-like message
- [ ] Inbox system to receive messages

### 4. **Hacking Mechanics**

#### A. Reconnaissance (Safe)
- [ ] `scan <ip>` - Already exists, make it work on real players
- [ ] `probe <ip>` - Deep scan for vulnerabilities
- [ ] `enum <ip>` - Enumerate users and services
- [ ] `traceroute <ip>` - Show connection path

#### B. Password Attacks (Noisy, Logged)
- [ ] `bruteforce <ip> <username>` - Try common passwords (REAL implementation)
  - Takes time (1 attempt per 2 seconds)
  - Target gets alerts after 3 attempts
  - Success rate based on password strength
  - Can be blocked by firewall/rate limiting
  
- [ ] `dictionary <ip> <username> <wordlist>` - Use wordlist file
  - Reads from VFS file
  - Target can detect and block
  
- [ ] `crack <hash>` - Crack stolen password hash
  - If attacker steals hash from compromised system
  - Takes significant time

#### C. Social Engineering (Requires Target Interaction)
- [ ] `phish <player>` - Send fake login prompt
  - Target receives message with fake system alert
  - If they respond with password, attacker gets it
  - Target can report phishing (penalty for attacker)
  
- [ ] `impersonate <player>` - Pretend to be someone else
  - Send messages as fake admin/friend
  - Requires social manipulation skills

#### D. Exploits (Technical, Skill-Based)
- [ ] `exploit <ip> <service>` - Exploit vulnerable service
  - Only works if target hasn't patched
  - Success gives shell access
  
- [ ] `backdoor install <ip>` - Install persistent backdoor
  - Requires prior access
  - Gives permanent access until detected
  
- [ ] `keylog <ip>` - Install keylogger
  - Captures passwords when typed
  - Can be detected by antivirus
  
- [ ] `mitm <ip>` - Man-in-the-middle attack
  - Intercepts communications
  - Requires being on same "subnet"

#### E. Advanced Techniques
- [ ] `inject <ip> <payload>` - Code injection
- [ ] `overflow <ip> <service>` - Buffer overflow exploit
- [ ] `privilege_escalate` - Gain root after initial access
- [ ] `harvest` - Extract all passwords from compromised system

### 5. **System Access After Hack**
- [ ] `ssh <ip>` - Connect to remote system
  - Requires password or compromised credentials
  - Opens remote terminal session
  
- [ ] `su <username>` - Switch to another user
  - Requires knowing their password
  
- [ ] Remote command execution: `ssh <ip> <command>`
  - Run single command on remote system
  
- [ ] File transfer: `scp <source> <destination>`
  - Copy files between systems

### 6. **Defense Mechanisms**

#### Passive Defenses
- [ ] Strong password requirements
- [ ] Firewall rules (already partially implemented)
- [ ] Service version updates to patch exploits
- [ ] Encryption for stored passwords (hashing already done)
- [ ] Login attempt rate limiting

#### Active Defenses
- [ ] `monitor` - Real-time intrusion detection (enhanced)
  - Shows active connections
  - Alerts on suspicious activity
  - Can auto-block IPs
  
- [ ] `block <ip>` - Manually block IP address
  - Prevents all connections from that IP
  
- [ ] `lockdown` - Emergency security mode
  - Closes all ports
  - Requires admin password to access
  
- [ ] `honeypot create <port>` - Fake vulnerable service
  - Logs attackers who try to exploit it
  - Can trace back to attacker IP
  
- [ ] `tripwire <file>` - Alert when file is accessed
  - Detects unauthorized file reads
  
- [ ] `forensics` - Investigate past attacks
  - Shows attack timeline
  - Identifies attacker techniques

#### Recovery
- [ ] `revoke_access <user>` - Remove compromised credentials
- [ ] `audit_users` - Check for unauthorized users
- [ ] `clean_backdoors` - Scan and remove backdoors
- [ ] `reset_passwords` - Force password reset

### 7. **Reputation & Consequences**
- [ ] **Attacker Reputation**: Successful hacks increase "hacker" score
- [ ] **Defender Reputation**: Successful defenses increase "security" score
- [ ] **Bounties**: Place bounties on attackers
- [ ] **Alliances**: Form groups for mutual protection
- [ ] **Blacklist**: Community-driven IP blacklist

### 8. **Notifications & Alerts**
- [ ] Real-time notifications for:
  - Someone scanning your IP
  - Failed login attempts
  - Successful login from new IP
  - File modifications
  - Service status changes
  - Messages received

---

## 🔧 Technical Implementation

### Data Structures

```lua
-- Player Session Enhancement
PlayerSession = {
    -- Existing fields...
    
    -- New fields for multiplayer
    isPublic = true,  -- Can other players see this VM?
    activeConnections = {},  -- Who is connected to me
    connectionAttempts = {},  -- Track connection attempts per IP
    blockedIPs = {},  -- Manually blocked IPs
    trustedIPs = {},  -- Whitelisted IPs
    notifications = {},  -- Pending notifications
    reputation = {
        hacker = 0,  -- Attack success score
        defender = 0,  -- Defense success score
        reported = 0,  -- Times reported for abuse
    },
}

-- Password Attempt Tracking
PasswordAttempt = {
    sourceIP = "192.168.1.50",
    timestamp = 1234567890,
    username = "admin",
    success = false,
    method = "bruteforce",  -- or "phish", "keylog", etc.
}

-- Remote Connection
RemoteConnection = {
    sessionId = "abc123",
    sourcePlayer = Player,
    targetPlayer = Player,
    username = "hacker",
    establishedAt = 1234567890,
    isAuthorized = false,  -- Did they login properly?
}
```

### New Services

#### NetworkService
```lua
NetworkService = {
    -- Player registry
    RegisterPlayer(player, ip, isPublic),
    UnregisterPlayer(player),
    GetOnlinePlayers() -> {PlayerInfo},
    GetPlayerByIP(ip) -> PlayerInfo,
    
    -- Connection management
    CreateConnection(source, target) -> Connection,
    CloseConnection(connectionId),
    SendData(connectionId, data),
    
    -- Security
    IsIPBlocked(sourceIP, targetPlayer) -> boolean,
    RecordConnectionAttempt(sourceIP, targetPlayer, success),
    GetConnectionHistory(player) -> {Attempts},
}
```

#### MessagingService (Enhanced)
```lua
MessagingService = {
    SendDirectMessage(from, to, message),
    SendGlobalMessage(from, message),
    SendPhishingAttempt(from, to, payload),
    GetInbox(player) -> {Messages},
}
```

#### HackingService
```lua
HackingService = {
    -- Attack execution
    AttemptBruteforce(attacker, targetIP, username) -> result,
    AttemptPhishing(attacker, target, payload) -> result,
    AttemptExploit(attacker, targetIP, exploitName) -> result,
    
    -- Success handling
    GrantAccess(attacker, target, accessLevel),
    StealCredentials(attacker, target) -> credentials,
    
    -- Detection
    CheckDefenses(target) -> defensiveCapabilities,
    TriggerAlert(target, alertType, details),
}
```

### Command Implementation Examples

#### `bruteforce` (Enhanced - Real Implementation)
```lua
bruteforce = {
    description = "Attempt password brute force against player",
    usage = "bruteforce <ip> <username>",
    execute = function(context, args)
        local targetIP = args[1]
        local username = args[2]
        
        -- Find target player
        local targetPlayer = NetworkService:GetPlayerByIP(targetIP)
        if not targetPlayer then
            return {success = false, output = "Host unreachable"}
        end
        
        -- Check if blocked
        if NetworkService:IsIPBlocked(context.playerState.ipAddress, targetPlayer) then
            return {success = false, output = "Connection refused: IP blocked"}
        end
        
        -- Check rate limiting
        if not HackingService:CanAttemptAttack(context.player, targetPlayer) then
            return {success = false, output = "Rate limit exceeded. Try again later."}
        end
        
        -- Alert target after 3 attempts
        local attempts = NetworkService:GetConnectionHistory(targetPlayer, context.playerState.ipAddress)
        if #attempts >= 3 then
            HackingService:TriggerAlert(targetPlayer, "BRUTEFORCE", {
                sourceIP = context.playerState.ipAddress,
                username = username,
                attempts = #attempts + 1
            })
        end
        
        -- Attempt bruteforce
        local result = HackingService:AttemptBruteforce(
            context.player,
            targetIP,
            username
        )
        
        if result.success then
            -- Store stolen credentials
            context.playerState.stolenCredentials = context.playerState.stolenCredentials or {}
            table.insert(context.playerState.stolenCredentials, {
                ip = targetIP,
                username = username,
                password = result.password,
                obtainedAt = os.time()
            })
            
            return {
                success = true,
                output = string.format(
                    "SUCCESS! Password found: %s\nUse 'ssh %s@%s' to login",
                    result.password,
                    username,
                    targetIP
                )
            }
        else
            return {
                success = false,
                output = string.format(
                    "Bruteforce failed. Tried %d passwords.\nTarget may have detected the attack.",
                    result.attemptCount
                )
            }
        end
    end
}
```

#### `ssh` (Remote Login)
```lua
ssh = {
    description = "Connect to remote system",
    usage = "ssh [username@]<ip>",
    execute = function(context, args)
        local target = args[1]
        local username, ip = string.match(target, "(.+)@(.+)")
        
        if not username then
            ip = target
            username = "root"
        end
        
        -- Find target player
        local targetPlayer = NetworkService:GetPlayerByIP(ip)
        if not targetPlayer then
            return {success = false, output = "ssh: connect to host " .. ip .. " failed"}
        end
        
        -- Check for stolen credentials
        local hasCredentials = false
        if context.playerState.stolenCredentials then
            for _, cred in ipairs(context.playerState.stolenCredentials) do
                if cred.ip == ip and cred.username == username then
                    hasCredentials = true
                    break
                end
            end
        end
        
        if not hasCredentials then
            -- Prompt for password
            return {
                success = false,
                output = string.format(
                    "%s@%s's password: [Password prompt would appear here]\nUse 'bruteforce' or 'phish' to obtain credentials first.",
                    username,
                    ip
                )
            }
        end
        
        -- Create remote connection
        local connection = NetworkService:CreateConnection(context.player, targetPlayer)
        
        -- Log the intrusion
        HackingService:TriggerAlert(targetPlayer, "UNAUTHORIZED_LOGIN", {
            sourceIP = context.playerState.ipAddress,
            username = username
        })
        
        -- Switch to remote session
        context.remoteSession = {
            connection = connection,
            targetPlayer = targetPlayer,
            targetIP = ip,
            username = username
        }
        
        return {
            success = true,
            output = string.format(
                "Connected to %s\nYou are now controlling their system.\nType 'exit' to disconnect.",
                ip
            )
        }
    end
}
```

#### `players` (Discovery)
```lua
players = {
    description = "List online players and their IPs",
    usage = "players",
    execute = function(context, args)
        local onlinePlayers = NetworkService:GetOnlinePlayers()
        
        local output = "Online Players:\n\n"
        output = output .. "IP              USERNAME       UPTIME    STATUS\n"
        
        for _, playerInfo in ipairs(onlinePlayers) do
            if playerInfo.isPublic then
                local uptime = os.time() - playerInfo.vmUptime
                local hours = math.floor(uptime / 3600)
                local minutes = math.floor((uptime % 3600) / 60)
                
                output = output .. string.format(
                    "%-15s %-14s %02dh %02dm  %s\n",
                    playerInfo.ip,
                    playerInfo.username,
                    hours,
                    minutes,
                    playerInfo.isSecure and "🔒" or "🔓"
                )
            end
        end
        
        return {success = true, output = output}
    end
}
```

---

## 🎮 Gameplay Flow Example

### Scenario: Player A Hacks Player B

1. **Discovery**
   ```bash
   [PlayerA] players
   # Shows PlayerB at 192.168.1.50
   
   [PlayerA] scan 192.168.1.50
   # Discovers open SSH port and web server
   ```

2. **Initial Attack**
   ```bash
   [PlayerA] bruteforce 192.168.1.50 admin
   # Takes 30 seconds, tries passwords
   # PlayerB receives alert: "WARNING: Brute force detected from 192.168.1.25"
   ```

3. **Defense (PlayerB's perspective)**
   ```bash
   [PlayerB] authlog
   # Sees failed login attempts from 192.168.1.25
   
   [PlayerB] block 192.168.1.25
   # Blocks PlayerA's IP
   ```

4. **Escalation (PlayerA)**
   ```bash
   [PlayerA] phish admin@192.168.1.50
   # Sends fake system alert to PlayerB
   # PlayerB receives: "SYSTEM ALERT: Your password may be compromised. Reply with current password to verify."
   
   # If PlayerB falls for it and replies with password...
   # PlayerA receives: "Password captured: MySecurePassword123"
   ```

5. **Access Gained**
   ```bash
   [PlayerA] ssh admin@192.168.1.50
   # Successfully logs in with stolen password
   # PlayerB gets alert: "WARNING: New login from 192.168.1.25"
   
   [PlayerA@192.168.1.50] ls
   # Now browsing PlayerB's files!
   
   [PlayerA@192.168.1.50] cat secret_data.txt
   # Stealing sensitive information
   
   [PlayerA@192.168.1.50] backdoor install
   # Installing persistent access
   ```

6. **Recovery (PlayerB)**
   ```bash
   [PlayerB] killall ssh
   # Kicks out attacker
   
   [PlayerB] passwd
   # Changes password
   
   [PlayerB] clean_backdoors
   # Removes installed backdoors
   
   [PlayerB] snapshot restore safe_backup
   # Restores from backup
   ```

---

## 🛡️ Balance & Fair Play

### Attack Success Rates
- **Weak password (< 8 chars, common)**: 70% bruteforce success
- **Medium password (8-12 chars, mixed)**: 30% bruteforce success
- **Strong password (13+ chars, complex)**: 5% bruteforce success
- **Phishing**: 50% success (depends on target falling for it)
- **Exploits**: 40% success (if service is vulnerable)

### Cooldowns & Costs
- **Bruteforce**: 2 minute cooldown, 100 currency
- **Exploit**: 30 second cooldown, 200 currency
- **Phishing**: 5 minute cooldown, 50 currency
- **Advanced attacks**: 5 minute cooldown, 500 currency

### Penalties for Abuse
- Attacking same player repeatedly: Reputation penalty
- Failed attacks: Tracked and visible to community
- Reported for griefing: Temporary IP ban from multiplayer

### Rewards
- **Successful hack**: 500 currency + reputation
- **Successful defense**: 300 currency + reputation
- **First time hacking player**: Bonus 200 currency
- **Detecting attack early**: 100 currency

---

## 📅 Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Enhance password system with setup flow
- [ ] Implement player discovery (`players`, `whois`)
- [ ] Create NetworkService for player registry
- [ ] Add basic inter-player messaging

### Phase 2: Hacking Mechanics (Week 2)
- [ ] Real bruteforce implementation
- [ ] Phishing system with player interaction
- [ ] Exploit database with real effects
- [ ] Credential storage and management

### Phase 3: Remote Access (Week 3)
- [ ] SSH remote login system
- [ ] Remote command execution
- [ ] Session management (switch between local/remote)
- [ ] File transfer between systems

### Phase 4: Defense & Monitoring (Week 4)
- [ ] Enhanced monitoring with real-time alerts
- [ ] IP blocking and firewall improvements
- [ ] Honeypot system
- [ ] Forensics and attack timeline

### Phase 5: Polish & Balance (Week 5)
- [ ] Reputation system
- [ ] Economy balancing
- [ ] Cooldowns and rate limits
- [ ] Notifications UI
- [ ] Tutorial for new players

---

## 🚀 Quick Start for Devs

After implementing:

```bash
# Player Setup
passwd set MySecurePassword123

# Attack someone
players
scan 192.168.1.50
bruteforce 192.168.1.50 admin
ssh admin@192.168.1.50

# Defend yourself
monitor
block 192.168.1.25
honeypot create 8080
clean_backdoors
```

---

## ⚠️ Safety & Moderation

- All hacking is simulated within the game
- No real credentials or data involved
- Anti-abuse systems to prevent griefing
- Report system for malicious behavior
- Age-appropriate content (educational focus)
- Clear tutorials on consent-based gameplay

---

This system creates a **deep, emergent multiplayer experience** where players can be hackers, defenders, or both! 🎮🔐

