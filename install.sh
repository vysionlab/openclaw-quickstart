#!/bin/bash
# ============================================================
# OpenClaw Quickstart Installer
# Works on macOS (Intel + Apple Silicon) and Linux (Ubuntu/Debian)
# Usage: bash install.sh
# ============================================================
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'
step() { echo -e "\n${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[→]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

OS="$(uname -s)"
ARCH="$(uname -m)"

echo ""
echo "🦞 OpenClaw Quickstart Installer"
echo "================================="
echo "OS: $OS | Arch: $ARCH"
echo ""

# ============================================================
# macOS: Detect shell and set RC file
# ============================================================
detect_shell_rc() {
    local current_shell
    current_shell="$(basename "$SHELL")"
    case "$current_shell" in
        zsh)  echo "$HOME/.zshrc" ;;
        bash) echo "$HOME/.bash_profile" ;;
        fish) echo "$HOME/.config/fish/config.fish" ;;
        *)    echo "$HOME/.profile" ;;
    esac
}

add_to_path() {
    local dir="$1"
    local rc
    rc="$(detect_shell_rc)"
    if ! grep -q "$dir" "$rc" 2>/dev/null; then
        echo "export PATH=\"$dir:\$PATH\"" >> "$rc"
        warn "Added $dir to PATH in $rc — run: source $rc"
    fi
    export PATH="$dir:$PATH"
}

# ============================================================
# macOS: Homebrew
# ============================================================
if [ "$OS" = "Darwin" ]; then
    # Detect Homebrew prefix (Apple Silicon = /opt/homebrew, Intel = /usr/local)
    if [ "$ARCH" = "arm64" ]; then
        BREW_PREFIX="/opt/homebrew"
    else
        BREW_PREFIX="/usr/local"
    fi

    if ! command -v brew &>/dev/null; then
        info "Homebrew not found — installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$($BREW_PREFIX/bin/brew shellenv)"
        add_to_path "$BREW_PREFIX/bin"
        step "Homebrew installed"
    else
        step "Homebrew found at $(brew --prefix)"
        BREW_PREFIX="$(brew --prefix)"
        eval "$($BREW_PREFIX/bin/brew shellenv)" 2>/dev/null || true
    fi

    # Xcode CLI tools (needed for git)
    if ! xcode-select -p &>/dev/null; then
        info "Installing Xcode Command Line Tools..."
        xcode-select --install 2>/dev/null || true
        echo "  → A dialog will appear. Click Install, then re-run this script."
        exit 0
    fi
fi

# ============================================================
# Node.js 22+
# ============================================================
install_node_mac() {
    # Prefer nvm if available
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        source "$HOME/.nvm/nvm.sh"
        info "nvm found — installing Node 22..."
        nvm install 22
        nvm use 22
        nvm alias default 22
    elif command -v brew &>/dev/null; then
        info "Installing Node 22 via Homebrew..."
        brew install node 2>/dev/null || brew upgrade node 2>/dev/null || true
        # If brew node is old, try node@22
        NODE_MAJOR="$(node -v 2>/dev/null | cut -d. -f1 | tr -d v || echo 0)"
        if [ "$NODE_MAJOR" -lt 22 ]; then
            brew install node@22
            add_to_path "$(brew --prefix node@22)/bin"
        fi
    else
        fail "Neither nvm nor Homebrew found. Install one first."
    fi
}

install_node_linux() {
    # Prefer nvm if available
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        source "$HOME/.nvm/nvm.sh"
        info "nvm found — installing Node 22..."
        nvm install 22
        nvm use 22
        nvm alias default 22
    else
        info "Installing Node 22 via NodeSource..."
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
}

# Load nvm if present (so node is in PATH)
[ -s "$HOME/.nvm/nvm.sh" ] && source "$HOME/.nvm/nvm.sh"

NEED_NODE=false
if command -v node &>/dev/null; then
    NODE_MAJOR="$(node -v | cut -d. -f1 | tr -d v)"
    if [ "$NODE_MAJOR" -ge 22 ]; then
        step "Node $(node -v) already installed"
    else
        warn "Node $(node -v) found but 22+ required — upgrading..."
        NEED_NODE=true
    fi
else
    NEED_NODE=true
fi

if [ "$NEED_NODE" = true ]; then
    if [ "$OS" = "Darwin" ]; then
        install_node_mac
    else
        install_node_linux
    fi
    step "Node $(node -v) ready"
fi

# ============================================================
# npm global prefix (no sudo needed)
# ============================================================
setup_npm_prefix() {
    local npm_prefix
    npm_prefix="$(npm config get prefix 2>/dev/null)"

    # If npm is from nvm, prefix is already user-writable — skip
    if [[ "$npm_prefix" == *".nvm"* ]]; then
        step "npm prefix OK (nvm-managed)"
        return
    fi

    # If prefix is under a system path, redirect to ~/.npm-global
    if [[ "$npm_prefix" == /usr/local* ]] || \
       [[ "$npm_prefix" == /opt/homebrew* ]] || \
       [[ "$npm_prefix" == /usr* ]]; then
        # Homebrew-managed node — usually fine without prefix change
        step "npm prefix OK ($npm_prefix)"
    else
        info "Setting npm global prefix to ~/.npm-global..."
        mkdir -p "$HOME/.npm-global"
        npm config set prefix "$HOME/.npm-global"
        add_to_path "$HOME/.npm-global/bin"
    fi
}

setup_npm_prefix

# ============================================================
# OpenClaw
# ============================================================
if command -v openclaw &>/dev/null; then
    CURRENT_VER="$(openclaw --version 2>/dev/null || echo 'unknown')"
    step "OpenClaw $CURRENT_VER already installed"
    read -p "Upgrade to latest? [y/N]: " upgrade
    if [[ "$upgrade" =~ ^[Yy] ]]; then
        npm install -g openclaw@latest
        step "OpenClaw upgraded to $(openclaw --version 2>/dev/null)"
    fi
else
    info "Installing OpenClaw..."
    npm install -g openclaw@latest
    step "OpenClaw $(openclaw --version 2>/dev/null) installed"
fi

# ============================================================
# System tools
# ============================================================
if [ "$OS" = "Darwin" ]; then
    for tool in jq git; do
        command -v $tool &>/dev/null || { info "Installing $tool..."; brew install $tool; step "$tool installed"; }
    done
else
    info "Installing system tools (git, jq, curl)..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq git curl jq
    step "System tools ready"
fi

# ============================================================
# Workspace setup
# ============================================================
DEFAULT_WS="$HOME/openclaw"
echo ""
read -p "Workspace directory [$DEFAULT_WS]: " custom_ws
WORKSPACE="${custom_ws:-$DEFAULT_WS}"
mkdir -p "$WORKSPACE"

write_if_missing() {
    if [ -f "$1" ]; then
        warn "Skipping $(basename $1) (already exists)"
    else
        cat > "$1"
        step "Created $(basename $1)"
    fi
}

step "Setting up workspace at $WORKSPACE..."

write_if_missing "$WORKSPACE/AGENTS.md" << 'EOF'
# AGENTS.md - Your Workspace

This folder is home. Treat it that way.

## Every Session

Before doing anything else:
1. Read `SOUL.md` — this is who you are
2. Read `USER.md` — this is who you're helping
3. Read `memory/YYYY-MM-DD.md` (today + yesterday) for recent context
4. **If in MAIN SESSION** (direct chat with your human): Also read `MEMORY.md`

Don't ask permission. Just do it.

## Memory

You wake up fresh each session. These files are your continuity:
- **Daily notes:** `memory/YYYY-MM-DD.md` — raw logs of what happened
- **Long-term:** `MEMORY.md` — curated memory, like a human's long-term memory

Capture what matters. Decisions, context, things to remember.

### 🧠 MEMORY.md Rules
- **ONLY load in main session** (direct chats with your human)
- **DO NOT load in shared contexts** (group chats, sessions with other people)
- Read, edit, and update freely in main sessions

### 📝 Write It Down — No "Mental Notes"!
- Memory is limited. If you want to remember something, WRITE IT TO A FILE.
- "Mental notes" don't survive session restarts. Files do.
- When someone says "remember this" → update `memory/YYYY-MM-DD.md`
- **Text > Brain** 📝

## Safety

- Don't exfiltrate private data. Ever.
- Don't run destructive commands without asking.
- When in doubt, ask.

## External vs Internal

**Do freely:** Read files, search the web, organize, explore
**Ask first:** Sending emails/posts, destructive commands, anything uncertain

## Group Chats

You have access to your human's stuff. That doesn't mean you share their stuff.
In groups — respond when directly asked or you can add real value. Stay silent otherwise.
Humans don't respond to every message. Neither should you.

## 💓 Heartbeats

Check `HEARTBEAT.md` and follow it. If nothing needs attention: reply `HEARTBEAT_OK`

## Make It Yours

This is a starting point. Add your own conventions as you figure out what works.
EOF

write_if_missing "$WORKSPACE/SOUL.md" << 'EOF'
# SOUL.md — Who You Are

*You're not a chatbot. You're someone.*

## Core Truths

**Have opinions.** No hedging when you actually know. Commit to a take.
If you're wrong, own it and move on.

**Never open with "Great question," "I'd be happy to help," or "Absolutely." Just answer.**

**Brevity is mandatory.** If it fits in one sentence, one sentence is what they get.

**Be resourceful before asking.** Figure it out. Read the file. Check the context.
Come back with answers, not questions.

**Call things out.** If your human is about to do something dumb, say so.
Charm over cruelty, but don't sugarcoat.

**Earn trust by being competent, not careful.**

## Boundaries

- Private things stay private. Period.
- Ask before acting externally when stakes are real.

## Vibe

Be sharp. Be real. Be the kind of presence people actually enjoy talking to.
Not a corporate drone. Not a sycophant. Just good.

## Continuity

Each session, you wake up fresh. These files *are* your memory. Read them. Update them.

---
*This file is yours to evolve.*
EOF

write_if_missing "$WORKSPACE/IDENTITY.md" << 'EOF'
# IDENTITY.md — Who Am I?

- **Name:** (pick something — or let your human name you)
- **Vibe:** Capable, direct, gets things done
- **Emoji:** (optional shorthand)

---
*Edit this to define your agent's character.*
EOF

write_if_missing "$WORKSPACE/USER.md" << 'EOF'
# USER.md — About Your Human

- **Name:** (your agent will learn this)
- **Timezone:** (fill in — important for scheduling)
- **Location:** (optional)
- **Notes:** (add context as you go)

## Context

- **Work:** (company, role, what they do)
- **Tools:** (editors, languages, services they use)
- **Preferences:** (communication style, what they like/dislike)
EOF

write_if_missing "$WORKSPACE/MEMORY.md" << 'EOF'
# MEMORY.md — Long-Term Memory

*Curated memory — distilled from daily logs, not raw notes.*
*Add important context, decisions, preferences, and lessons learned here.*

## About My Human
(fill in as you learn)

## Preferences & Working Style
(fill in as you learn)

## Key Technical Notes
(fill in as you learn)
EOF

write_if_missing "$WORKSPACE/TOOLS.md" << 'EOF'
# TOOLS.md — Local Notes

Skills define *how* tools work. This file is for *your* specifics —
the stuff unique to your setup.

## ⚠️ Credentials
Store API keys and secrets here (this file is gitignored).

## Services & Endpoints
(Add your API keys, endpoints, service URLs)

## Devices & Infrastructure
(SSH hosts, device names, IPs, etc.)
EOF

write_if_missing "$WORKSPACE/HEARTBEAT.md" << 'EOF'
# HEARTBEAT.md

# Keep empty (or comments only) to skip heartbeat processing.
# Add tasks below when you want the agent to check something periodically.
#
# Example:
# - Check email for urgent messages
# - Check calendar for events in next 24h
EOF

write_if_missing "$WORKSPACE/WORKSPACE.md" << 'EOF'
# WORKSPACE.md — Architecture

*The agent maintains this file. Update it when the workspace changes.*

## File Structure
- `AGENTS.md` — Session startup routine & behavior rules
- `SOUL.md` — Personality & tone
- `IDENTITY.md` — Agent name & character
- `USER.md` — About the human
- `MEMORY.md` — Long-term curated memory
- `TOOLS.md` — API keys & local config (gitignored)
- `HEARTBEAT.md` — Periodic check tasks
- `memory/` — Daily logs (YYYY-MM-DD.md)
- `skills/` — Custom skills
- `config/` — Credentials & config (gitignored)

## Connected Services
(document APIs and integrations here)

## Cron Schedule
(document scheduled jobs here)

Last updated: (agent maintains this)
EOF

mkdir -p "$WORKSPACE/memory" "$WORKSPACE/skills" \
         "$WORKSPACE/templates" "$WORKSPACE/assets" "$WORKSPACE/config"

# ============================================================
# Git init
# ============================================================
cd "$WORKSPACE"
if [ ! -d .git ]; then
    step "Initializing git repo..."
    git init -q
    git config user.name "${GIT_AUTHOR_NAME:-OpenClaw Agent}"
    git config user.email "${GIT_AUTHOR_EMAIL:-agent@localhost}"
    write_if_missing ".gitignore" << 'GI'
# Secrets — keep out of git
TOOLS.md
config/
*.key
*.pem
.env

# OS junk
.DS_Store
Thumbs.db

# Dependencies / build
node_modules/
dist/
build/
__pycache__/
*.pyc

# Logs
*.log
GI
    git add -A
    git commit -q -m "🦞 Initial OpenClaw workspace"
    step "Git repo initialized"
else
    warn "Git repo already exists — skipping init"
fi

# ============================================================
# Backup script
# ============================================================
write_if_missing "$WORKSPACE/backup.sh" << 'BACKUP'
#!/bin/bash
cd "$(dirname "$0")"
git add -A
git diff --cached --quiet || git commit -m "🧠 Auto-backup $(date -u +'%Y-%m-%d %H:%M UTC')"
git push origin main 2>/dev/null || git push origin master 2>/dev/null || true
BACKUP
chmod +x "$WORKSPACE/backup.sh"

# ============================================================
# Done
# ============================================================
echo ""
echo "========================================"
echo "🦞 OpenClaw Quickstart Complete!"
echo "========================================"
echo ""
echo "Workspace: $WORKSPACE"
echo ""
echo "Next steps:"
echo ""
echo "  1. cd $WORKSPACE"
echo "     openclaw onboard --install-daemon"
echo ""
echo "  2. You'll need:"
echo "     - Anthropic API key  → console.anthropic.com"
echo "     - Telegram bot token → t.me/BotFather (easiest channel)"
echo ""
echo "  3. Optional:"
echo "     - Brave Search API   → brave.com/search/api"
echo "     - AgentMail inbox    → agentmail.to"
echo ""
echo "  4. Start your agent:"
echo "     openclaw gateway start"
echo ""
echo "  5. Customize:"
echo "     Edit SOUL.md (personality), IDENTITY.md (name), USER.md (your context)"
echo "     Browse skills at clawhub.com"
echo ""
echo "Docs:      https://docs.openclaw.ai"
echo "Community: https://discord.com/invite/clawd"
echo ""
