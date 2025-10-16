--!strict
-- HandbookUI.luau
-- Interactive handbook/guide for players

local UserInputService = game:GetService("UserInputService")
local Constants = require(game.ReplicatedStorage.Shared.Constants)

local HandbookUI = {}
HandbookUI.__index = HandbookUI

function HandbookUI.new(playerGui: PlayerGui)
	local self = setmetatable({}, HandbookUI)

	self.playerGui = playerGui
	self.screenGui = nil
	self.handbookFrame = nil
	self.contentFrame = nil
	self.searchBox = nil
	self.isVisible = false
	self.currentTab = "basics"
	self.tabs = {}

	self:_createUI()
	self:_loadContent()

	return self
end

function HandbookUI:_createUI()
	-- Create ScreenGui
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "HandbookGui"
	self.screenGui.ResetOnSpawn = false
	self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self.screenGui.DisplayOrder = 50
	self.screenGui.Parent = self.playerGui

	-- Main Handbook Frame
	self.handbookFrame = Instance.new("Frame")
	self.handbookFrame.Name = "Handbook"
	self.handbookFrame.Size = UDim2.new(0.7, 0, 0.8, 0)
	self.handbookFrame.Position = UDim2.new(0.15, 0, 0.1, 0)
	self.handbookFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	self.handbookFrame.BorderSizePixel = 0
	self.handbookFrame.Visible = false
	self.handbookFrame.Parent = self.screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = self.handbookFrame

	local shadow = Instance.new("UIStroke")
	shadow.Color = Color3.fromRGB(0, 0, 0)
	shadow.Thickness = 3
	shadow.Transparency = 0.5
	shadow.Parent = self.handbookFrame

	-- Title Bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = self.handbookFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = titleBar

	-- Title Icon
	local titleIcon = Instance.new("TextLabel")
	titleIcon.Size = UDim2.new(0, 40, 0, 40)
	titleIcon.Position = UDim2.new(0, 10, 0, 5)
	titleIcon.BackgroundTransparency = 1
	titleIcon.Text = "📖"
	titleIcon.Font = Enum.Font.SourceSansBold
	titleIcon.TextSize = 32
	titleIcon.Parent = titleBar

	-- Title Text
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -140, 1, 0)
	titleLabel.Position = UDim2.new(0, 55, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Hacker's Handbook - Learn Linux & Security"
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 20
	titleLabel.TextColor3 = Constants.COLORS.PROMPT_COLOR
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Close Button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 35, 0, 35)
	closeButton.Position = UDim2.new(1, -45, 0, 7.5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "✕"
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.TextSize = 20
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		self:hide()
	end)

	-- Search Bar
	local searchContainer = Instance.new("Frame")
	searchContainer.Name = "SearchContainer"
	searchContainer.Size = UDim2.new(1, -20, 0, 40)
	searchContainer.Position = UDim2.new(0, 10, 0, 60)
	searchContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	searchContainer.BorderSizePixel = 0
	searchContainer.Parent = self.handbookFrame

	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, 8)
	searchCorner.Parent = searchContainer

	local searchIcon = Instance.new("TextLabel")
	searchIcon.Size = UDim2.new(0, 30, 1, 0)
	searchIcon.Position = UDim2.new(0, 5, 0, 0)
	searchIcon.BackgroundTransparency = 1
	searchIcon.Text = "🔍"
	searchIcon.Font = Enum.Font.SourceSans
	searchIcon.TextSize = 18
	searchIcon.Parent = searchContainer

	self.searchBox = Instance.new("TextBox")
	self.searchBox.Name = "SearchBox"
	self.searchBox.Size = UDim2.new(1, -45, 1, -8)
	self.searchBox.Position = UDim2.new(0, 40, 0, 4)
	self.searchBox.BackgroundTransparency = 1
	self.searchBox.PlaceholderText = "Search commands, topics, or guides..."
	self.searchBox.Text = ""
	self.searchBox.Font = Enum.Font.SourceSans
	self.searchBox.TextSize = 14
	self.searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	self.searchBox.TextXAlignment = Enum.TextXAlignment.Left
	self.searchBox.ClearTextOnFocus = false
	self.searchBox.Parent = searchContainer

	self.searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		self:_filterContent(self.searchBox.Text)
	end)

	-- Tab Bar
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, -20, 0, 45)
	tabBar.Position = UDim2.new(0, 10, 0, 110)
	tabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	tabBar.BorderSizePixel = 0
	tabBar.Parent = self.handbookFrame

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 8)
	tabCorner.Parent = tabBar

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	tabLayout.Padding = UDim.new(0, 5)
	tabLayout.Parent = tabBar

	-- Create Tabs
	local tabData = {
		{ id = "basics", icon = "🎓", text = "Basics" },
		{ id = "commands", icon = "⌨️", text = "Commands" },
		{ id = "hacking", icon = "💀", text = "Hacking" },
		{ id = "defense", icon = "🛡️", text = "Defense" },
		{ id = "tips", icon = "💡", text = "Pro Tips" },
	}

	for _, tab in ipairs(tabData) do
		self:_createTab(tabBar, tab.id, tab.icon, tab.text)
	end

	-- Content Area
	local contentScroll = Instance.new("ScrollingFrame")
	contentScroll.Name = "ContentScroll"
	contentScroll.Size = UDim2.new(1, -20, 1, -175)
	contentScroll.Position = UDim2.new(0, 10, 0, 165)
	contentScroll.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	contentScroll.BorderSizePixel = 0
	contentScroll.ScrollBarThickness = 10
	contentScroll.ScrollBarImageColor3 = Constants.COLORS.PROMPT_COLOR
	contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	contentScroll.Parent = self.handbookFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 8)
	contentCorner.Parent = contentScroll

	self.contentFrame = Instance.new("Frame")
	self.contentFrame.Name = "Content"
	self.contentFrame.Size = UDim2.new(1, -20, 1, 0)
	self.contentFrame.Position = UDim2.new(0, 10, 0, 10)
	self.contentFrame.BackgroundTransparency = 1
	self.contentFrame.Parent = contentScroll

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Padding = UDim.new(0, 15)
	contentLayout.Parent = self.contentFrame

	-- Auto-resize canvas
	contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
	end)
end

function HandbookUI:_createTab(parent: Frame, id: string, icon: string, text: string)
	local tab = Instance.new("TextButton")
	tab.Name = id
	tab.Size = UDim2.new(0, 130, 1, -10)
	tab.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	tab.BorderSizePixel = 0
	tab.Text = icon .. " " .. text
	tab.Font = Enum.Font.SourceSansBold
	tab.TextSize = 14
	tab.TextColor3 = Color3.fromRGB(200, 200, 200)
	tab.Parent = parent

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 6)
	tabCorner.Parent = tab

	self.tabs[id] = tab

	tab.MouseButton1Click:Connect(function()
		self:_switchTab(id)
	end)

	tab.MouseEnter:Connect(function()
		if self.currentTab ~= id then
			tab.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
		end
	end)

	tab.MouseLeave:Connect(function()
		if self.currentTab ~= id then
			tab.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		end
	end)
end

function HandbookUI:_switchTab(tabId: string)
	-- Update tab appearance
	for id, tab in pairs(self.tabs) do
		if id == tabId then
			tab.BackgroundColor3 = Constants.COLORS.PROMPT_COLOR
			tab.TextColor3 = Color3.fromRGB(0, 0, 0)
		else
			tab.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
			tab.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end

	self.currentTab = tabId
	self:_updateContent(tabId)
end

function HandbookUI:_updateContent(tabId: string)
	-- Clear existing content
	for _, child in ipairs(self.contentFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Load content based on tab
	if tabId == "basics" then
		self:_loadBasicsContent()
	elseif tabId == "commands" then
		self:_loadCommandsContent()
	elseif tabId == "hacking" then
		self:_loadHackingContent()
	elseif tabId == "defense" then
		self:_loadDefenseContent()
	elseif tabId == "tips" then
		self:_loadTipsContent()
	end
end

function HandbookUI:_createSection(title: string, content: string, orderIndex: number)
	local section = Instance.new("Frame")
	section.Name = "Section_" .. title
	section.Size = UDim2.new(1, 0, 0, 0)
	section.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
	section.BorderSizePixel = 0
	section.LayoutOrder = orderIndex
	section.Parent = self.contentFrame

	local sectionCorner = Instance.new("UICorner")
	sectionCorner.CornerRadius = UDim.new(0, 8)
	sectionCorner.Parent = section

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 15)
	padding.PaddingBottom = UDim.new(0, 15)
	padding.PaddingLeft = UDim.new(0, 15)
	padding.PaddingRight = UDim.new(0, 15)
	padding.Parent = section

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 25)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 18
	titleLabel.TextColor3 = Constants.COLORS.PROMPT_COLOR
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Top
	titleLabel.Parent = section

	-- Content
	local contentLabel = Instance.new("TextLabel")
	contentLabel.Name = "Content"
	contentLabel.Size = UDim2.new(1, 0, 0, 0)
	contentLabel.Position = UDim2.new(0, 0, 0, 30)
	contentLabel.BackgroundTransparency = 1
	contentLabel.Text = content
	contentLabel.Font = Enum.Font.SourceSans
	contentLabel.TextSize = 14
	contentLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	contentLabel.TextXAlignment = Enum.TextXAlignment.Left
	contentLabel.TextYAlignment = Enum.TextYAlignment.Top
	contentLabel.TextWrapped = true
	contentLabel.Parent = section

	-- Auto-size
	local textBounds = contentLabel.TextBounds
	contentLabel.Size = UDim2.new(1, 0, 0, textBounds.Y)
	section.Size = UDim2.new(1, 0, 0, textBounds.Y + 50)

	return section
end

function HandbookUI:_loadContent()
	self:_switchTab("basics")
end

function HandbookUI:_loadBasicsContent()
	self:_createSection(
		"🎮 Welcome to RobloxOS!",
		[[This is a Linux-like operating system where you can learn hacking and cybersecurity in a fun, safe environment!

You control a virtual computer with:
• A terminal (command line) to type commands
• A file system to store files and folders
• Network tools to connect with other players
• Security tools to protect yourself
• Hacking tools to practice ethical hacking (simulated!)

Everything you do here is SIMULATED and SAFE. No real hacking!]],
		1
	)

	self:_createSection(
		"🖥️ What is a Terminal?",
		[[The terminal is a text-based interface where you type commands instead of clicking buttons.

Think of it like texting with your computer! You type what you want to do, and the computer responds.

Example:
YOU TYPE: ls
COMPUTER SHOWS: Your list of files

It might seem weird at first, but it's actually super powerful once you learn it!]],
		2
	)

	self:_createSection(
		"📁 Understanding Files & Folders",
		[[Just like on your phone or computer, you can:
• Create files (like documents or notes)
• Make folders to organize things
• Move files around
• Delete stuff you don't need

Commands to try:
• ls - See what's in your current folder
• cd foldername - Go into a folder
• mkdir test - Create a new folder called "test"
• nano myfile.txt - Create and edit a file]],
		3
	)

	self:_createSection(
		"🌐 Your IP Address",
		[[Every computer on a network has an IP address - it's like your home address, but for computers!

Your IP is automatically assigned when you join the game.

Type: ifconfig
You'll see your IP like: 192.168.1.83

Other players can see your IP if you're public, and you can see theirs too!]],
		4
	)
end

function HandbookUI:_loadCommandsContent()
	self:_createSection(
		"📋 Most Important Commands",
		[[These are the commands you'll use most:

NAVIGATION:
• pwd - Shows where you are
• ls - Lists files in current folder
• cd <folder> - Move to a folder
• cd ~ - Go back to your home folder

FILES:
• touch <file> - Create empty file
• nano <file> - Create/edit file (opens editor)
• cat <file> - Read a file
• rm <file> - Delete a file

FOLDERS:
• mkdir <name> - Create folder
• rmdir <name> - Delete empty folder

GETTING HELP:
• help - Shows all commands
• help <command> - Help for specific command]],
		1
	)

	self:_createSection(
		"🔐 Security Commands",
		[[PASSWORD & PROTECTION:
• passwd <password> - Set your password
• snapshot create <name> - Backup your system
• snapshot restore <name> - Restore from backup
• ufw status - Check firewall
• ufw allow <port> - Open a port
• ufw deny <port> - Block a port

MONITORING:
• connections - See who's connecting to you
• authlog - View security events
• monitor - Watch for attacks in real-time
• ps - See running programs
• htop - Fancy process viewer]],
		2
	)

	self:_createSection(
		"🌐 Network Commands",
		[[DISCOVERY:
• players - See who else is online
• whois <ip> - Get info about a player
• ping <ip> - Test connection to someone
• ifconfig - See your own IP address
• netstat - See your open ports

COMMUNICATION:
(Some coming soon!)
• msg <player> <text> - Send a message
• mail <player> - Send an email

CONNECTION:
• scan <ip> - Scan someone's ports
• connect <ip>:<port> - Connect to service]],
		3
	)

	self:_createSection(
		"💻 System Commands",
		[[INFO:
• whoami - Shows your username
• date - Current date and time
• uptime - How long system has been running
• clear - Clear the terminal screen

PROCESSES:
• ps - List running programs
• htop - Interactive process viewer
• kill <pid> - Stop a program

OTHER:
• echo <text> - Print something
• history - See commands you've typed]],
		4
	)
end

function HandbookUI:_loadHackingContent()
	self:_createSection(
		"⚠️ Important: Ethical Hacking Only!",
		[[In RobloxOS, "hacking" is a game mechanic for learning cybersecurity concepts.

✅ ALLOWED (in this game):
• Practicing on other players who consent
• Learning how attacks work
• Testing your own defenses
• Educational experimentation

❌ NOT ALLOWED (ever):
• Real-world hacking
• Attacking real systems
• Using these techniques outside the game
• Harassing other players

This is for LEARNING and FUN only!]],
		1
	)

	self:_createSection(
		"🔍 Phase 1: Reconnaissance (Intel Gathering)",
		[[Before any attack, you need information:

STEP 1: Find targets
• players - See who's online

STEP 2: Gather info
• whois <ip> - Learn about them
• ping <ip> - Test if they're reachable

STEP 3: Scan for weaknesses
• scan <ip> - Find open ports
  (Warning: They'll see you doing this!)

STEP 4: Take notes
• Create a file to track what you learn
• nano targets.txt
• Write down IP, username, what ports are open]],
		2
	)

	self:_createSection(
		"💥 Phase 2: Initial Access",
		[[Ways to try to get in:

METHOD 1: Brute Force (Password Guessing)
• bruteforce <ip> <username>
• Tries common passwords
• Very noisy - target will know!
• Works better on weak passwords

METHOD 2: Social Engineering
• phish <player>
• Send fake messages
• Trick them into giving password
• Requires them to fall for it

METHOD 3: Exploits
• exploit <ip> <exploit_name>
• Use known vulnerabilities
• Only works if they haven't patched
• Less noisy than brute force

METHOD 4: Be Creative!
• Sometimes the best hack is asking nicely
• Or waiting for them to make a mistake]],
		3
	)

	self:_createSection(
		"🦠 Phase 3: Post-Access Actions",
		[[If you successfully get access:

PAYLOADS:
• payload create <name> - Make malware
• payload list - See available payloads
• deploy <payload> <target> - Install it

NETWORK SNIFFING:
• sniff <interface> - Capture network data
• Look for unencrypted passwords

MAINTAINING ACCESS:
• Install backdoors
• Create new user accounts
• Hide your presence

OBJECTIVES:
• Read their files: cat secretfile.txt
• Copy important data
• Plant fake information
• Prove you were there (leave a message!)]],
		4
	)

	self:_createSection(
		"🎯 Pro Hacker Tips",
		[[BEFORE ATTACKING:
1. Make sure you have permission
2. Know your target (recon is key!)
3. Have an escape plan
4. Document what you do

DURING AN ATTACK:
1. Be patient - don't rush
2. Watch for alerts from target
3. Cover your tracks
4. Stay stealthy when possible

AFTER SUCCESS:
1. Document what worked
2. Help the victim fix their security
3. Share techniques (educational!)
4. Level up your reputation]],
		5
	)
end

function HandbookUI:_loadDefenseContent()
	self:_createSection(
		"🛡️ Defense Basics",
		[[The best defense is being prepared!

GOLDEN RULES:
1. Always set a STRONG password
2. Create regular backups
3. Monitor your system
4. Block suspicious IPs
5. Keep your firewall configured

Remember: It's easier to prevent an attack than to recover from one!]],
		1
	)

	self:_createSection(
		"🔐 Password Security",
		[[Your password is your first line of defense!

WEAK Password (DON'T USE):
• password, 123456, admin, root
• Short (less than 8 characters)
• Common words
• Your username

STRONG Password (USE THIS):
• 12+ characters long
• Mix of letters, numbers, symbols
• Example: MyR0blox#Pass2024!
• Not in any dictionary

SET YOUR PASSWORD:
passwd MySecurePassword123!

The stronger your password, the harder it is to crack!]],
		2
	)

	self:_createSection(
		"🔥 Firewall Setup",
		[[Your firewall controls who can connect to you:

CHECK STATUS:
ufw status

BLOCK EVERYTHING (except what you allow):
ufw deny 1-65535

ALLOW SPECIFIC SERVICES:
ufw allow 22    (SSH)
ufw allow 80    (Web server)
ufw allow 443   (Secure web)

BLOCK SPECIFIC PORTS:
ufw deny 1337

Good firewall = Hard to hack!]],
		3
	)

	self:_createSection(
		"👀 Monitoring for Attacks",
		[[Stay alert and watch for attackers:

REAL-TIME MONITORING:
• monitor - Shows live alerts
• connections - See who's connecting
• authlog - View login attempts

WHAT TO LOOK FOR:
• Multiple failed login attempts
• Port scans from same IP
• Unusual connection times
• Unknown processes running

IF UNDER ATTACK:
1. block <attacker_ip>
2. snapshot restore <backup>
3. passwd <new_password>
4. isolate (disconnect from network)]],
		4
	)

	self:_createSection(
		"💾 Backup Strategy",
		[[ALWAYS have backups!

CREATE BACKUPS:
snapshot create daily_backup
snapshot create before_experiment
snapshot create safe_state

LIST BACKUPS:
snapshot list

RESTORE IF NEEDED:
snapshot restore safe_state

BACKUP SCHEDULE:
• Daily: Before you log off
• Before: Trying something risky
• After: Making big changes
• Regular: Every few hours while playing]],
		5
	)

	self:_createSection(
		"🚨 Emergency Response",
		[[If you're being hacked RIGHT NOW:

IMMEDIATE ACTIONS:
1. isolate
   (Disconnects you from network)

2. connections
   (See who's attacking)

3. block <their_ip>
   (Ban the attacker)

4. kill <suspicious_pid>
   (Stop malware)

5. snapshot restore safe_backup
   (Reset to clean state)

6. passwd <new_strong_password>
   (Change compromised password)

7. antivirus scan /
   (Check for remaining threats)

Stay calm and follow these steps!]],
		6
	)
end

function HandbookUI:_loadTipsContent()
	self:_createSection(
		"💡 Terminal Pro Tips",
		[[Make your life easier:

COMMAND HISTORY:
• Press UP ARROW - See previous commands
• Press DOWN ARROW - Go forward
• Type: history - See all past commands

SHORTCUTS:
• cd ~ - Go home quickly
• cd .. - Go up one folder
• pwd - "Where am I?"
• clear - Clean up messy terminal

FILE TIPS:
• Use descriptive names: attack_plan.txt
• Organize with folders
• Backup important files
• Delete old junk with rm]],
		1
	)

	self:_createSection(
		"🎯 Becoming a Better Hacker",
		[[LEARNING PATH:
1. Master basic commands first
2. Practice file organization
3. Learn networking concepts
4. Try defense before offense
5. Experiment with attacks (safely!)
6. Study what works and what doesn't

PRACTICE IDEAS:
• Create a target practice file system
• Try hacking yourself (test your defenses!)
• Document every technique you learn
• Help beginners learn
• Challenge yourself with hard passwords

Remember: Real hackers never stop learning!]],
		2
	)

	self:_createSection(
		"🗂️ File Organization Tips",
		[[Keep your system organized:

SUGGESTED STRUCTURE:
/home/yourname/
  ├── work/
  │   ├── projects/
  │   ├── scripts/
  │   └── logs/
  ├── security/
  │   ├── scans/
  │   ├── exploits/
  │   └── payloads/
  ├── targets/
  │   ├── recon/
  │   ├── access/
  │   └── notes/
  └── backups/

CREATE THIS:
mkdir -p work/{projects,scripts,logs}
mkdir -p security/{scans,exploits,payloads}
mkdir targets

Organization = Efficiency!]],
		3
	)

	self:_createSection(
		"🤝 Multiplayer Etiquette",
		[[Be a good player:

DO:
✅ Ask before attacking
✅ Help beginners learn
✅ Share cool techniques
✅ Report bugs to game devs
✅ Have fun!

DON'T:
❌ Grief or harass players
❌ Spam attacks on same person
❌ Use exploits to cheat
❌ Share real personal info
❌ Be toxic in chat

Good sportsmanship makes the game fun for everyone!]],
		4
	)

	self:_createSection(
		"🎓 Learning Resources",
		[[Want to learn more?

IN-GAME:
• Type: help <command>
• Read the welcome.txt file
• Experiment safely
• Ask other players

COMMAND EXAMPLES:
• help passwd - Learn about passwords
• help scan - Learn about scanning
• help snapshot - Learn about backups

PRACTICE CHALLENGES:
1. Create 10 organized folders
2. Set a super strong password
3. Successfully defend against attack
4. Complete a recon mission
5. Help another player learn

The more you practice, the better you get!]],
		5
	)

	self:_createSection(
		"🏆 Goals & Achievements",
		[[Track your progress:

BEGINNER (Everyone starts here):
□ Set your first password
□ Create a file with nano
□ Make a folder structure
□ Create a backup
□ Block an IP address

INTERMEDIATE:
□ Successfully scan another player
□ Defend against an attack
□ Restore from backup
□ Organize 20+ files
□ Help a beginner

ADVANCED:
□ Successful brute force attack
□ Deploy a payload
□ Maintain good reputation
□ Create complex scripts
□ Master all commands

EXPERT:
□ Hack multiple players
□ Never get hacked
□ Build legendary reputation
□ Teach others
□ Be a RobloxOS master!]],
		6
	)
end

function HandbookUI:_filterContent(searchText: string)
	if searchText == "" then
		-- Show all content
		for _, child in ipairs(self.contentFrame:GetChildren()) do
			if child:IsA("Frame") then
				child.Visible = true
			end
		end
		return
	end

	-- Filter content based on search
	local lowerSearch = string.lower(searchText)

	for _, child in ipairs(self.contentFrame:GetChildren()) do
		if child:IsA("Frame") then
			local titleLabel = child:FindFirstChild("Title")
			local contentLabel = child:FindFirstChild("Content")

			if titleLabel and contentLabel then
				local titleText = string.lower(titleLabel.Text)
				local contentText = string.lower(contentLabel.Text)

				if string.find(titleText, lowerSearch) or string.find(contentText, lowerSearch) then
					child.Visible = true
				else
					child.Visible = false
				end
			end
		end
	end
end

function HandbookUI:show()
	self.handbookFrame.Visible = true
	self.isVisible = true
end

function HandbookUI:hide()
	self.handbookFrame.Visible = false
	self.isVisible = false
end

function HandbookUI:toggle()
	if self.isVisible then
		self:hide()
	else
		self:show()
	end
end

function HandbookUI:destroy()
	if self.screenGui then
		self.screenGui:Destroy()
	end
end

return HandbookUI


