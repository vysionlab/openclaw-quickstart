#!/usr/bin/env bash
# OpenClaw Quickstart — Simple, clean installer
# https://github.com/vysionlab/openclaw-quickstart
set -euo pipefail

OPENCLAW_VERSION="latest"
NPM_PREFIX="$HOME/.npm-global"

# ── Colors ──────────────────────────────────────────────────
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓ $*${NC}"; }
info() { echo -e "${CYAN}  → $*${NC}"; }
warn() { echo -e "${YELLOW}  ⚠ $*${NC}"; }
die()  { echo -e "${RED}  ✗ $*${NC}"; exit 1; }

echo ""
echo "  🦞 OpenClaw Quickstart"
echo "  ─────────────────────────────"
echo ""

# ── 1. Node.js ──────────────────────────────────────────────
if command -v node &>/dev/null && node -e "process.exit(parseInt(process.version.slice(1)) >= 18 ? 0 : 1)" 2>/dev/null; then
    ok "Node $(node -v) already installed"
else
    info "Installing Node.js 22..."
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        # nvm available
        source "$HOME/.nvm/nvm.sh"
        nvm install 22 && nvm use 22 && nvm alias default 22
        ok "Node $(node -v) installed via nvm"
    elif command -v brew &>/dev/null; then
        brew install node@22 && brew link --overwrite --force node@22
        ok "Node $(node -v) installed via Homebrew"
    elif [[ "$(uname -s)" == "Linux" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - &>/dev/null
        sudo apt-get install -y nodejs &>/dev/null
        ok "Node $(node -v) installed"
    else
        die "Node.js not found. Install it from https://nodejs.org then re-run this script."
    fi
fi

# ── 2. npm global prefix ────────────────────────────────────
mkdir -p "$NPM_PREFIX"
CURRENT_PREFIX=$(npm config get prefix 2>/dev/null || echo "")
if [ "$CURRENT_PREFIX" != "$NPM_PREFIX" ]; then
    npm config set prefix "$NPM_PREFIX"
fi

# Ensure PATH includes npm global bin (for this session)
export PATH="$NPM_PREFIX/bin:$PATH"

# Write to shell RC if not already there
SHELL_RC="$HOME/.zshrc"
[[ "$SHELL" == *"bash"* ]] && SHELL_RC="$HOME/.bash_profile"
if ! grep -q "npm-global/bin" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# OpenClaw / npm global" >> "$SHELL_RC"
    echo "export PATH=\"\$HOME/.npm-global/bin:\$PATH\"" >> "$SHELL_RC"
fi
ok "npm prefix: $NPM_PREFIX"

# ── 3. Install OpenClaw ─────────────────────────────────────
info "Installing OpenClaw (latest)..."
rm -rf "$NPM_PREFIX/lib/node_modules/openclaw" 2>/dev/null || true
npm install -g "openclaw@$OPENCLAW_VERSION" --silent
ok "OpenClaw $(openclaw --version 2>/dev/null) installed"

# ── 4. Python + uv ─────────────────────────────────────────
if command -v uv &>/dev/null; then
    ok "uv already installed"
elif command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh &>/dev/null
    export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
    ok "uv installed"
fi

# ── 5. mcporter ─────────────────────────────────────────────
info "Installing mcporter..."
npm install -g mcporter --silent 2>/dev/null && ok "mcporter installed" || warn "mcporter install failed (optional)"

# ── 6. Excalidraw MCP ───────────────────────────────────────
info "Installing Excalidraw MCP..."
npm install -g excalidraw-mcp --silent 2>/dev/null && ok "excalidraw-mcp installed" || warn "excalidraw-mcp install failed (optional)"

# ── 7. obsidian-cli ─────────────────────────────────────────
info "Installing obsidian-cli..."
npm install -g @davidenke/obsidian-cli --silent 2>/dev/null && ok "obsidian-cli installed" || warn "obsidian-cli install failed (optional)"

# ── 8. Done ─────────────────────────────────────────────────
echo ""
echo -e "  ${GREEN}✅ Installation complete!${NC}"
echo ""
echo "  Installed extras:"
echo -e "  ${CYAN}  • mcporter     — MCP server manager${NC}"
echo -e "  ${CYAN}  • excalidraw-mcp — diagram generation${NC}"
echo -e "  ${CYAN}  • obsidian-cli  — Obsidian vault search${NC}"
echo ""
echo "  Run the setup wizard:"
echo ""
echo -e "  ${CYAN}  openclaw config${NC}"
echo ""
echo "  Then start your agent:"
echo ""
echo -e "  ${CYAN}  openclaw gateway start${NC}"
echo ""
echo "  Docs: https://docs.openclaw.ai"
echo ""
