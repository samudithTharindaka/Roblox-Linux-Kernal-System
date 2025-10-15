# Roblox LinuxOS Simulator

A fully-featured Linux-like operating system simulator inside Roblox with multiplayer support, hacking mechanics, and security features.

## Features

### Core Systems
- **Terminal UI**: Fullscreen terminal with command history, tab completion, and scrollable output
- **Toggle Button**: Floating button in bottom-right corner to easily open/close terminal
- **Virtual File System (VFS)**: Complete filesystem with permissions, ownership, and directory structure
- **Process Simulator**: Simulated processes with CPU/memory usage tracking
- **Networking**: Virtual networking with services, ports, and connections
- **User Management**: User accounts with sudo support and password protection
- **Audit Logging**: Comprehensive logging of all system actions

### Commands Implemented

#### Filesystem Commands
- `ls` - List directory contents
- `cd` - Change directory
- `pwd` - Print working directory
- `mkdir` - Create directory
- `rmdir` - Remove directory
- `rm` - Remove files
- `touch` - Create/update files
- `cat` - Display file contents
- `head/tail` - Show first/last lines
- `cp` - Copy files
- `mv` - Move/rename files
- `chmod` - Change permissions
- `chown` - Change owner

#### System Commands
- `whoami` - Show current user
- `date` - Show current date/time
- `uptime` - Show system uptime
- `clear` - Clear terminal
- `echo` - Print text
- `help` - Show command help
- `history` - Show command history
- `sudo` - Execute with elevated privileges
- `ps` - Show processes
- `htop` - Interactive process viewer

#### Networking Commands
- `ifconfig` - Show network configuration
- `netstat` - Show network connections
- `ping` - Test connectivity
- `listen` - Start service on port
- `connect` - Connect to remote service
- `send` - Send data to connection

#### Security Commands
- `ufw` - Manage firewall rules
- `authlog` - View authentication log
- `monitor` - Monitor for suspicious activity
- `scan` - Port scanner
- `snapshot` - Create/restore VFS snapshots
- `isolate` - Disconnect from network
- `antivirus` - Scan for malware

#### Hacking Commands (Simulated)
- `bruteforce` - Attempt password brute force
- `exploit` - Use exploits against services
- `phish` - Craft phishing messages
- `payload` - Create/manage payloads
- `deploy` - Deploy payloads to targets
- `sniff` - Packet sniffer

#### Editing
- `nano` - Full-featured text editor with save/cancel

## Architecture

### Client Side
- **TerminalUI**: Terminal window with input/output
- **NanoEditor**: Text editor interface
- **HtopViewer**: Process viewer interface
- **TerminalController**: Manages client-side terminal logic

### Server Side
- **Classes**: VFS, User, Process, Service, AuditLog (OOP architecture)
- **Commands**: Modular command system organized by category
- **Services**: PlayerService, DataPersistence
- **Modules**: CommandParser, CommandExecutor

### Shared
- **Types**: Type definitions for all data structures
- **Constants**: Game-wide configuration
- **Utils**: Shared utility functions

## File Structure

```
src/
├── client/
│   ├── init.client.luau          # Client initialization
│   ├── Controllers/
│   │   └── TerminalController.luau
│   └── UI/
│       ├── TerminalUI.luau       # Terminal interface
│       ├── TerminalButton.luau   # Toggle button
│       ├── NanoEditor.luau       # Text editor
│       └── HtopViewer.luau       # Process viewer
├── server/
│   ├── init.server.luau          # Server initialization
│   ├── Classes/
│   │   ├── VFS.luau              # Virtual file system
│   │   ├── User.luau             # User management
│   │   ├── Process.luau          # Process simulation
│   │   ├── Service.luau          # Network services
│   │   └── AuditLog.luau         # Audit logging
│   ├── Commands/
│   │   ├── FileSystemCommands.luau
│   │   ├── SystemCommands.luau
│   │   ├── NetworkingCommands.luau
│   │   ├── SecurityCommands.luau
│   │   └── HackingCommands.luau
│   ├── Modules/
│   │   ├── CommandParser.luau    # Command parsing
│   │   └── CommandExecutor.luau  # Command execution
│   └── Services/
│       ├── PlayerService.luau    # Player session management
│       └── DataPersistence.luau  # DataStore handling
└── shared/
    ├── Types.luau                # Type definitions
    ├── Constants.luau            # Configuration
    └── Utils.luau                # Utility functions
```

## Getting Started

### Using Rojo

1. Install [Rojo](https://rojo.space/)
2. Clone this repository
3. Run `rojo serve` to start the development server
4. Connect from Roblox Studio using the Rojo plugin

### In-Game Usage

1. Press `` ` `` (backtick) to toggle the terminal
2. Type `help` to see available commands
3. Use arrow keys to navigate command history
4. Try commands like `ls`, `pwd`, `cd`, etc.

### Example Session

```bash
user@RobloxOS:~$ ls
welcome.txt

user@RobloxOS:~$ cat welcome.txt
Welcome to RobloxOS!

user@RobloxOS:~$ mkdir myproject
user@RobloxOS:~$ cd myproject
user@RobloxOS:~/myproject$ touch script.sh
user@RobloxOS:~/myproject$ nano script.sh
# (Editor opens - write some content, press Ctrl+S to save, Ctrl+X to exit)

user@RobloxOS:~/myproject$ cat script.sh
echo "Hello from RobloxOS!"

user@RobloxOS:~/myproject$ chmod +x script.sh
user@RobloxOS:~/myproject$ ls -l
rwx user     0B  2025-10-15 12:34:56 script.sh*
```

## Data Persistence

Player data is automatically saved to DataStore:
- VFS state (files, directories, permissions)
- User settings and passwords
- Audit logs
- Command history
- Current directory and environment

Auto-save occurs every 5 minutes, and on player leave.

## Security Features

### Permissions System
- Read, write, execute permissions per file
- Owner-based access control
- Sudo support for elevated operations

### Audit Logging
- All commands logged with timestamp
- Security events tracked (scans, exploits, etc.)
- Severity levels: info, warning, critical

### Hacking Simulation
- Port scanning (noisy, generates logs)
- Brute force attacks (rate-limited, lockouts)
- Exploits (success based on versions, patches)
- Payload deployment (detectable by antivirus)

### Defense Mechanisms
- Firewall (ufw) to block ports
- Monitoring for suspicious activity
- Snapshots for recovery
- Network isolation
- Antivirus scanning

## Customization

### Adding New Commands

1. Create command in appropriate Commands file:

```lua
MyCommands.mycommand = {
    description = "My command description",
    usage = "mycommand <args>",
    minArgs = 1,
    maxArgs = 2,
    execute = function(context: any, args: { string })
        -- Command implementation
        return {
            success = true,
            output = "Command output",
        }
    end,
}
```

2. Register in `PlayerService.luau`:

```lua
session.executor:registerCommands(MyCommands)
```

### Modifying Constants

Edit `src/shared/Constants.luau` to adjust:
- Terminal settings
- Security parameters
- Economy values
- Cooldowns
- Colors

## Roadmap

### MVP ✅
- Terminal UI
- VFS with permissions
- Core commands
- Basic networking
- Hacking/defense mechanics
- DataStore persistence

### v1 (Future)
- Process execution and scheduling
- Full service implementation
- Multiplayer networking
- Economy system
- Progression/unlocks
- AI attacker NPCs

### v2 (Future)
- Story/mission mode
- CTF events
- Custom scripting language
- Visual network map
- Leaderboards
- Advanced exploits

## Contributing

This is a demonstration project showcasing advanced Roblox game development with:
- OOP architecture
- Modular command system
- Client-server communication
- Data persistence
- Complex UI systems

Feel free to extend and modify for your own projects!

## License

This project is provided as-is for educational purposes.

## Credits

Created for Roblox LinuxOS Simulator
Based on real Linux systems and security concepts
