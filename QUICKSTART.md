# Quick Start Guide

## Installation & Setup

### Prerequisites
1. Install [Rojo](https://rojo.space/) (v7.0+)
2. Install [Aftman](https://github.com/LPGhatguy/aftman) (optional, for tool management)
3. Have Roblox Studio installed

### Starting the Development Server

1. Open a terminal in the project directory
2. Run:
   ```bash
   rojo serve
   ```
3. Open Roblox Studio
4. Install the [Rojo plugin](https://rojo.space/docs/v7/getting-started/installation/)
5. Click "Connect" in the Rojo plugin panel
6. The project will sync to Studio

### Testing the Game

1. Click "Play" in Roblox Studio
2. The terminal should automatically open
3. **Toggle terminal**:
   - Press `` ` `` (backtick key), OR
   - Click the floating button in the bottom-right corner

## First Commands to Try

### Basic Navigation
```bash
# See where you are
pwd

# List files
ls

# Read the welcome file
cat welcome.txt

# Change directory
cd /etc

# Go back home
cd ~
```

### Create Files and Directories
```bash
# Create a directory
mkdir projects

# Create a file
touch projects/test.txt

# Edit with nano (GUI editor)
nano projects/test.txt
# Type some content, press Ctrl+S to save, Ctrl+X to exit
```

### System Information
```bash
# Who am I?
whoami

# What's my IP?
ifconfig

# Show processes
ps

# Interactive process viewer
htop

# System uptime
uptime
```

### File Permissions
```bash
# Create a script
touch myscript.sh

# Make it executable
chmod +x myscript.sh

# Check permissions
ls -l myscript.sh
```

### Security Commands
```bash
# View recent activity
authlog

# Create a system snapshot (backup)
snapshot create backup1

# View snapshots
snapshot list

# Check firewall
ufw status

# Allow a port
ufw allow 8080
```

### Networking
```bash
# Ping another IP
ping 192.168.1.100

# Scan for open ports (noisy!)
scan 192.168.1.100

# Start a service
listen 8080 myservice

# Show network connections
netstat
```

### Hacking (Simulated)
```bash
# Port scan a target
scan 192.168.1.50 1-1000

# Try brute force (will likely fail)
bruteforce -t 192.168.1.50 -u admin -p common_passwords

# Create a payload
payload create backdoor

# View available exploits
# (Use exploit command with specific target)
exploit 192.168.1.50 ssh_backdoor_v1
```

### Defense
```bash
# Monitor for attacks
monitor

# Create backup before testing
snapshot create before_test

# If compromised, restore
snapshot restore before_test

# Isolate from network
isolate

# Scan for malware
antivirus scan /
```

## Keyboard & Controls

- `` ` `` (Backtick): Toggle terminal
- **Button** (bottom-right): Click to toggle terminal
- `Up/Down Arrow`: Navigate command history
- `Ctrl+S` (in nano): Save file
- `Ctrl+X` (in nano): Exit editor
- `ESC` (in nano): Exit without saving

## Tips

1. **Use `help`**: Type `help` to see all available commands
2. **Use `help <command>`**: Get detailed help for a specific command
3. **Command History**: Use Up/Down arrows to recall previous commands
4. **Tab Completion**: (Coming soon) Tab to autocomplete commands and filenames
5. **Sudo**: Many commands require `sudo` for elevated permissions
6. **Snapshots**: Create regular snapshots before experimenting

## Common Issues

### Terminal Won't Open
- Press `` ` `` (backtick key, usually above Tab)
- Click the floating button in the bottom-right corner
- Check that the client script loaded (check Output window in Studio)

### Commands Not Working
- Make sure you're connected via Rojo
- Check the Output window for errors
- Try restarting the game in Studio

### Permission Denied
- Try using `sudo` before the command
- Example: `sudo chown newuser file.txt`
- Check file permissions with `ls -l`

### Can't Save Files
- Make sure you have write permission in the directory
- Try creating the file first with `touch filename`
- Then edit with `nano filename`

## Data Persistence

Your data is automatically saved:
- **Auto-save**: Every 5 minutes
- **On Leave**: When you leave the game
- **Manual Save**: Happens automatically after most commands

Saved data includes:
- All files and directories
- Command history
- User settings
- Audit logs
- Current directory

## Next Steps

1. **Explore the filesystem**: Navigate through `/etc`, `/var/log`, `/usr/bin`
2. **Create projects**: Make directories and files for your "code"
3. **Try hacking**: Scan other players (in multiplayer) or simulate attacks
4. **Set up defenses**: Configure firewall, create snapshots, monitor activity
5. **Learn commands**: Use `help` to discover all available commands

## Multiplayer (Coming Soon)

When playing with others:
- Each player has their own VM with unique IP
- You can scan and connect to other players
- Hacking is consensual and simulated
- Defenders earn points for detecting attacks
- Attackers earn points for successful infiltration

## Development

### Project Structure
```
src/
├── client/          # Client-side code
│   ├── UI/         # Terminal, Editor, Viewers
│   └── Controllers/ # Terminal controller
├── server/         # Server-side code
│   ├── Classes/    # VFS, User, Process, etc.
│   ├── Commands/   # Command implementations
│   ├── Modules/    # Parser, Executor
│   └── Services/   # Player service, Persistence
└── shared/         # Shared code
    ├── Types.luau
    ├── Constants.luau
    └── Utils.luau
```

### Adding Custom Commands

Edit files in `src/server/Commands/` and register them in `PlayerService.luau`.

See README.md for detailed development guide.

## Support

For issues or questions:
1. Check the README.md
2. Review the code documentation
3. Check Roblox Output window for errors

Enjoy your Linux simulation experience! 🐧💻

