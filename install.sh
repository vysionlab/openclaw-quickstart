#!/bin/bash
# ============================================================
# OpenClaw Quick Deploy
# Sets up a fully configured OpenClaw instance on Ubuntu
# Usage: curl -fsSL <url> | bash
#   or:  bash install.sh
# ============================================================
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
step() { echo -e "\n${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

echo ""
echo "🤖 OpenClaw Quick Deploy"
echo "========================"
echo ""

# --- System deps ---
step "Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq git curl jq chromium-browser poppler-utils python3-pip

# --- Node.js 22+ ---
if ! command -v node &>/dev/null || [ "$(node -v | cut -d. -f1 | tr -d v)" -lt 22 ]; then
    step "Installing Node.js 22..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi
step "Node $(node -v)"

# --- npm global without sudo ---
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
grep -q '.npm-global/bin' ~/.bashrc || echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
export PATH=~/.npm-global/bin:$PATH

# --- OpenClaw ---
step "Installing OpenClaw..."
npm install -g openclaw
step "OpenClaw $(openclaw --version) installed"

# --- ClawHub CLI ---
step "Installing ClawHub CLI..."
npm install -g clawhub --force 2>/dev/null

# --- Python tools ---
step "Installing Python tools..."
pip3 install --break-system-packages agentmail python-dotenv 2>/dev/null || pip install agentmail python-dotenv 2>/dev/null

# --- Workspace ---
WORKSPACE="$HOME/workspace"
read -p "Workspace directory [$WORKSPACE]: " custom_ws
WORKSPACE="${custom_ws:-$WORKSPACE}"
mkdir -p "$WORKSPACE"

# --- Scaffold workspace files ---
step "Creating workspace files..."

# AGENTS.md
cat > "$WORKSPACE/AGENTS.md" << 'EOF'
# AGENTS.md

## Every Session
1. Read `SOUL.md` — who you are
2. Read `USER.md` — who you're helping
3. Read `memory/` recent files for context
4. In main session: also read `MEMORY.md`

## Memory
- **Daily notes:** `memory/YYYY-MM-DD.md` — raw logs
- **Long-term:** `MEMORY.md` — curated insights
- Write things down. Files survive restarts. "Mental notes" don't.

## Safety
- Don't exfiltrate private data
- `trash` > `rm`
- Ask before sending emails, posts, or anything external

## External vs Internal
**Do freely:** Read files, search web, organize, explore
**Ask first:** Sending emails/posts, destructive commands, anything uncertain
EOF

# SOUL.md
cat > "$WORKSPACE/SOUL.md" << 'EOF'
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

# USER.md
cat > "$WORKSPACE/USER.md" << 'EOF'
# USER.md — About Your Human

- **Name:** (fill in)
- **Timezone:** (fill in)
- **Notes:** (add context as you learn about them)
EOF

# IDENTITY.md
cat > "$WORKSPACE/IDENTITY.md" << 'EOF'
# IDENTITY.md

- **Name:** (choose a name)
- **Vibe:** Helpful, capable, gets things done
EOF

# MEMORY.md
cat > "$WORKSPACE/MEMORY.md" << 'EOF'
# MEMORY.md — Long-Term Memory

*Add important context, decisions, preferences, and lessons learned here.*
*This file is your curated memory — distilled from daily logs.*
EOF

# TOOLS.md
cat > "$WORKSPACE/TOOLS.md" << 'EOF'
# TOOLS.md — Local Notes

Add environment-specific details here:
- API keys and endpoints
- Device names
- Service configurations
- Anything unique to your setup
EOF

# HEARTBEAT.md
cat > "$WORKSPACE/HEARTBEAT.md" << 'EOF'
# HEARTBEAT.md

# Add periodic tasks below. The agent checks this on each heartbeat.
# Keep it small to limit token burn.
# Leave empty to skip heartbeat processing.
EOF

# memory dir
mkdir -p "$WORKSPACE/memory"
mkdir -p "$WORKSPACE/skills"
mkdir -p "$WORKSPACE/templates"
mkdir -p "$WORKSPACE/assets"
mkdir -p "$WORKSPACE/config"

step "Workspace scaffolded at $WORKSPACE"

# --- Git init ---
cd "$WORKSPACE"
if [ ! -d .git ]; then
    git init
    cat > .gitignore << 'GI'
node_modules/
*.key
*.env
.openclaw/
__pycache__/
*.pyc
GI
    git add -A
    git commit -m "Initial workspace setup"
fi

# --- Summary ---
echo ""
echo "========================================"
echo "🤖 OpenClaw is installed!"
echo "========================================"
echo ""
echo "Next steps:"
echo ""
echo "  1. Configure OpenClaw:"
echo "     openclaw configure"
echo ""
echo "  2. You'll need at minimum:"
echo "     - Anthropic API key (console.anthropic.com)"
echo "     - A channel: Telegram bot token, or Discord, etc."
echo ""
echo "  3. Optional but recommended:"
echo "     - Brave Search API key (brave.com/search/api)"
echo "     - Tailscale for remote access"
echo ""
echo "  4. Start it up:"
echo "     openclaw gateway start"
echo ""
echo "  5. Install skills from ClawHub:"
echo "     npx clawhub search <keyword>"
echo "     npx clawhub install <skill>"
echo ""
echo "  6. Talk to your agent! It will help set up the rest."
echo ""
echo "Workspace: $WORKSPACE"
echo "Docs: https://docs.openclaw.ai"
echo "Skills: https://clawhub.com"
echo "Community: https://discord.com/invite/clawd"
echo ""
