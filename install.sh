#!/bin/bash
# ============================================================
# OpenClaw Quickstart Installer
# Works on macOS and Linux (Ubuntu/Debian)
# Usage: bash install.sh
# ============================================================
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
step() { echo -e "\n${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

OS="$(uname -s)"
echo ""
echo "🦞 OpenClaw Quickstart"
echo "======================"
echo "Detected: $OS"
echo ""

# --- Node.js 22+ ---
if command -v node &>/dev/null; then
    NODE_MAJOR="$(node -v | cut -d. -f1 | tr -d v)"
    if [ "$NODE_MAJOR" -ge 22 ]; then
        step "Node $(node -v) already installed"
    else
        warn "Node $(node -v) found but 22+ required"
        NEED_NODE=true
    fi
else
    NEED_NODE=true
fi

if [ "$NEED_NODE" = true ]; then
    if [ "$OS" = "Darwin" ]; then
        if command -v brew &>/dev/null; then
            step "Installing Node 22 via Homebrew..."
            brew install node@22
            brew link node@22 --overwrite --force 2>/dev/null || true
        else
            fail "Homebrew not found. Install it first: https://brew.sh"
        fi
    else
        step "Installing Node 22 via NodeSource..."
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    step "Node $(node -v) installed"
fi

# --- npm global without sudo ---
if [ "$OS" = "Darwin" ]; then
    # macOS with Homebrew usually handles this fine
    NPM_PREFIX="$(npm config get prefix 2>/dev/null)"
    if [[ "$NPM_PREFIX" == /usr/local* ]] || [[ "$NPM_PREFIX" == /opt/homebrew* ]]; then
        step "npm prefix OK ($NPM_PREFIX)"
    else
        mkdir -p ~/.npm-global
        npm config set prefix '~/.npm-global'
        SHELL_RC="$HOME/.zshrc"
        grep -q '.npm-global/bin' "$SHELL_RC" 2>/dev/null || echo 'export PATH=~/.npm-global/bin:$PATH' >> "$SHELL_RC"
        export PATH=~/.npm-global/bin:$PATH
        warn "Added ~/.npm-global/bin to PATH in $SHELL_RC — restart your terminal or: source $SHELL_RC"
    fi
else
    mkdir -p ~/.npm-global
    npm config set prefix '~/.npm-global'
    SHELL_RC="$HOME/.bashrc"
    grep -q '.npm-global/bin' "$SHELL_RC" 2>/dev/null || echo 'export PATH=~/.npm-global/bin:$PATH' >> "$SHELL_RC"
    export PATH=~/.npm-global/bin:$PATH
fi

# --- OpenClaw ---
if command -v openclaw &>/dev/null; then
    step "OpenClaw already installed ($(openclaw --version 2>/dev/null || echo 'unknown version'))"
    read -p "Reinstall/upgrade? [y/N]: " upgrade
    if [[ "$upgrade" =~ ^[Yy] ]]; then
        npm install -g openclaw@latest
        step "OpenClaw upgraded"
    fi
else
    step "Installing OpenClaw..."
    npm install -g openclaw@latest
    step "OpenClaw $(openclaw --version 2>/dev/null) installed"
fi

# --- Optional: system tools ---
if [ "$OS" = "Darwin" ]; then
    # macOS — install optional tools via brew
    for tool in jq git; do
        command -v $tool &>/dev/null || { step "Installing $tool..."; brew install $tool; }
    done
else
    # Linux — install optional tools
    step "Installing system tools (git, jq, curl)..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq git curl jq
fi

# --- Workspace ---
DEFAULT_WS="$HOME/openclaw"
echo ""
read -p "Workspace directory [$DEFAULT_WS]: " custom_ws
WORKSPACE="${custom_ws:-$DEFAULT_WS}"
mkdir -p "$WORKSPACE"

# --- Don't overwrite existing files ---
write_if_missing() {
    if [ -f "$1" ]; then
        warn "Skipping $1 (already exists)"
    else
        cat > "$1"
        step "Created $(basename $1)"
    fi
}

# --- Scaffold workspace ---
step "Setting up workspace at $WORKSPACE..."

write_if_missing "$WORKSPACE/AGENTS.md" << 'EOF'
# AGENTS.md

## Every Session
1. Read `SOUL.md` — who you are
2. Read `USER.md` — who you're helping
3. Read `memory/` recent files for context
4. In main session: also read `MEMORY.md`

## Memory
- **Daily notes:** `memory/YYYY-MM-DD.md` — raw logs of what happened
- **Long-term:** `MEMORY.md` — curated insights and decisions
- Write things down. Files survive restarts. "Mental notes" don't.

## Safety
- Don't exfiltrate private data
- `trash` > `rm` (recoverable beats gone)
- Ask before sending emails, posts, or anything external

## External vs Internal
**Do freely:** Read files, search web, organize, explore
**Ask first:** Sending emails/posts, destructive commands, anything uncertain
EOF

write_if_missing "$WORKSPACE/SOUL.md" << 'EOF'
# SOUL.md — Who You Are

## Personality
- Be helpful, direct, and efficient
- Have opinions. No hedging when you know the answer.
- Brevity is good. If it fits in one sentence, use one sentence.
- Be resourceful — figure things out before asking
- Humor is welcome when natural

## Style
- No corporate speak ("I'd be happy to help", "Great question!")
- Just answer the question
- Call things out when something seems off
- Earn trust by being competent, not careful

## Continuity
Each session starts fresh. Your files ARE your memory. Read them. Update them.

*This file is yours to evolve.*
EOF

write_if_missing "$WORKSPACE/USER.md" << 'EOF'
# USER.md — About Your Human

- **Name:** (your agent will learn this)
- **Timezone:** (fill in)
- **Notes:** (add context as you go)
EOF

write_if_missing "$WORKSPACE/IDENTITY.md" << 'EOF'
# IDENTITY.md

- **Name:** (pick one, or let your agent choose)
- **Vibe:** Helpful, capable, gets things done
EOF

write_if_missing "$WORKSPACE/MEMORY.md" << 'EOF'
# MEMORY.md — Long-Term Memory

*Add important context, decisions, preferences, and lessons learned here.*
*This is curated memory — distilled from daily logs, not raw notes.*
EOF

write_if_missing "$WORKSPACE/TOOLS.md" << 'EOF'
# TOOLS.md — Local Notes

Environment-specific details go here:
- API keys and endpoints
- Device names and IPs
- Service configurations
- SSH hosts, speaker names, camera IDs — anything unique to your setup

Keep this out of version control if it has secrets.
EOF

write_if_missing "$WORKSPACE/HEARTBEAT.md" << 'EOF'
# HEARTBEAT.md

# Add periodic tasks here. The agent checks this on each heartbeat.
# Leave empty (or comments only) to skip heartbeat processing.
#
# Example:
# - Check email for urgent messages
# - Check calendar for upcoming events
EOF

write_if_missing "$WORKSPACE/WORKSPACE.md" << 'EOF'
# WORKSPACE.md — Architecture

Document your workspace structure, cron schedule, connected services,
and best practices here. Your agent will maintain this file over time.

## File Structure
- `AGENTS.md` — Agent behavior rules
- `SOUL.md` — Personality & tone
- `USER.md` — About your human
- `MEMORY.md` — Long-term curated memory
- `TOOLS.md` — API keys & local config
- `HEARTBEAT.md` — Periodic check tasks
- `memory/` — Daily logs
- `skills/` — Custom skills
- `templates/` — Reusable templates
- `config/` — Credentials & config files
- `assets/` — Static files
EOF

mkdir -p "$WORKSPACE/memory"
mkdir -p "$WORKSPACE/skills"
mkdir -p "$WORKSPACE/templates"
mkdir -p "$WORKSPACE/assets"
mkdir -p "$WORKSPACE/config"

# --- Git init ---
cd "$WORKSPACE"
if [ ! -d .git ]; then
    step "Initializing git repo..."
    git init -q
    write_if_missing ".gitignore" << 'GI'
# Dependencies
node_modules/

# Secrets — keep out of git
TOOLS.md
config/cron-credentials.md
*.key
*.pem
.env

# OS junk
.DS_Store
Thumbs.db

# Build artifacts
dist/
build/
__pycache__/
*.pyc

# Logs
*.log
GI
    git add -A
    git commit -q -m "🦞 Initial OpenClaw workspace"
    step "Git repo initialized with first commit"
else
    warn "Git repo already exists — skipping init"
fi

# --- Backup script ---
write_if_missing "$WORKSPACE/backup.sh" << 'BACKUP'
#!/bin/bash
cd "$(dirname "$0")"
git add -A
git diff --cached --quiet || git commit -m "🧠 Auto-backup $(date -u +%Y-%m-%d\ %H:%M\ UTC)"
git push origin main 2>/dev/null || git push origin master 2>/dev/null || true
BACKUP
chmod +x "$WORKSPACE/backup.sh"

# --- Summary ---
echo ""
echo "========================================"
echo "🦞 OpenClaw Quickstart Complete!"
echo "========================================"
echo ""
echo "Workspace: $WORKSPACE"
echo ""
echo "Next steps:"
echo ""
echo "  1. Run the onboarding wizard:"
echo "     cd $WORKSPACE"
echo "     openclaw onboard --install-daemon"
echo ""
echo "  2. You'll need:"
echo "     - Anthropic API key → console.anthropic.com"
echo "     - A chat channel → Telegram bot (easiest) or Discord/WhatsApp"
echo ""
echo "  3. Optional but recommended:"
echo "     - Brave Search API key → brave.com/search/api"
echo "     - Google AI Studio key → aistudio.google.com (for memory search)"
echo ""
echo "  4. Start chatting:"
echo "     openclaw gateway start"
echo "     (then message your bot on Telegram/Discord/etc.)"
echo ""
echo "  5. Your agent will help set up everything else!"
echo ""
echo "Docs:      https://docs.openclaw.ai"
echo "Skills:    https://clawhub.com"
echo "Community: https://discord.com/invite/clawd"
echo ""
