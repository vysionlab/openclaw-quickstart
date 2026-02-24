#!/bin/bash
# ============================================================
# OpenClaw Quickstart — System Dependency Installer
# Works on macOS (Intel + Apple Silicon) and Linux (Ubuntu/Debian)
# After dependencies are ready, launches the interactive setup wizard.
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "🦞 OpenClaw Quickstart"
echo "======================"
echo "OS: $OS | Arch: $ARCH"
echo ""

# ============================================================
# Helpers
# ============================================================
detect_shell_rc() {
    case "$(basename "$SHELL")" in
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
# macOS: Homebrew + Xcode CLI tools
# ============================================================
if [ "$OS" = "Darwin" ]; then
    # Detect Homebrew prefix (Apple Silicon = /opt/homebrew, Intel = /usr/local)
    if [ "$ARCH" = "arm64" ]; then
        BREW_PREFIX="/opt/homebrew"
    else
        BREW_PREFIX="/usr/local"
    fi

    # Xcode CLI tools (required for git)
    if ! xcode-select -p &>/dev/null; then
        info "Installing Xcode Command Line Tools..."
        xcode-select --install 2>/dev/null || true
        echo ""
        echo "  A dialog box should appear. Click Install, wait for it to finish,"
        echo "  then re-run this script."
        exit 0
    fi

    # Homebrew
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$($BREW_PREFIX/bin/brew shellenv)"
        add_to_path "$BREW_PREFIX/bin"
        step "Homebrew installed"
    else
        step "Homebrew found ($(brew --prefix))"
        eval "$($(brew --prefix)/bin/brew shellenv)" 2>/dev/null || true
        BREW_PREFIX="$(brew --prefix)"
    fi
fi

# ============================================================
# Node.js 22+
# ============================================================

# Load nvm if present
[ -s "$HOME/.nvm/nvm.sh" ] && source "$HOME/.nvm/nvm.sh"

install_node_mac() {
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        info "Installing Node 22 via nvm..."
        nvm install 22 && nvm use 22 && nvm alias default 22
    elif command -v brew &>/dev/null; then
        info "Installing Node via Homebrew..."
        brew install node 2>/dev/null || brew upgrade node 2>/dev/null || true
        # Fallback: if still too old, get node@22 explicitly
        NODE_MAJOR="$(node -v 2>/dev/null | cut -d. -f1 | tr -d v || echo 0)"
        if [ "$NODE_MAJOR" -lt 22 ]; then
            brew install node@22
            add_to_path "$(brew --prefix node@22)/bin"
        fi
    else
        fail "Neither nvm nor Homebrew found. Install Homebrew first: https://brew.sh"
    fi
}

install_node_linux() {
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        info "Installing Node 22 via nvm..."
        nvm install 22 && nvm use 22 && nvm alias default 22
    else
        info "Installing Node 22 via NodeSource..."
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
}

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
    if [ "$OS" = "Darwin" ]; then install_node_mac; else install_node_linux; fi
    step "Node $(node -v) ready"
fi

# ============================================================
# npm global prefix (no sudo needed)
# ============================================================
NPM_PREFIX="$(npm config get prefix 2>/dev/null)"

if [[ "$NPM_PREFIX" == *".nvm"* ]]; then
    step "npm prefix OK (nvm-managed)"
elif [[ "$NPM_PREFIX" == /usr/local* ]] || [[ "$NPM_PREFIX" == /opt/homebrew* ]]; then
    step "npm prefix OK ($NPM_PREFIX)"
elif [[ "$NPM_PREFIX" == /usr* ]]; then
    # System Node without write access — redirect to user dir
    info "Setting npm global prefix to ~/.npm-global..."
    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global"
    add_to_path "$HOME/.npm-global/bin"
else
    step "npm prefix OK ($NPM_PREFIX)"
fi

# ============================================================
# Swap (Linux only — prevents OOM kills during npm install)
# ============================================================
if [ "$OS" = "Linux" ]; then
    TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_MEM_MB=$((TOTAL_MEM_KB / 1024))
    SWAP_KB=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
    if [ "$SWAP_KB" -eq 0 ] && [ "$TOTAL_MEM_MB" -lt 2048 ]; then
        info "Low RAM detected (${TOTAL_MEM_MB}MB, no swap) — adding 2GB swap to prevent OOM kills..."
        sudo fallocate -l 2G /swapfile 2>/dev/null || sudo dd if=/dev/zero of=/swapfile bs=1M count=2048 2>/dev/null
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        step "2GB swap enabled"
    fi
fi

# ============================================================
# OpenClaw
# ============================================================
if command -v openclaw &>/dev/null; then
    CURRENT_VER="$(openclaw --version 2>/dev/null || echo 'unknown')"
    step "OpenClaw $CURRENT_VER already installed"
    read -p "Upgrade to latest? [y/N]: " upgrade
    if [[ "$upgrade" =~ ^[Yy] ]]; then
        rm -rf "$NPM_PREFIX/lib/node_modules/openclaw" 2>/dev/null || true
        npm install -g openclaw@latest
        step "OpenClaw upgraded to $(openclaw --version 2>/dev/null)"
    fi
else
    info "Installing OpenClaw..."
    # Clean up any partial install that would cause ENOTEMPTY
    rm -rf "$NPM_PREFIX/lib/node_modules/openclaw" 2>/dev/null || true
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
# Launch interactive setup wizard
# ============================================================
WIZARD="$SCRIPT_DIR/wizard.js"

if [ ! -f "$WIZARD" ]; then
    info "Downloading setup wizard..."
    curl -fsSL https://raw.githubusercontent.com/vysionlab/openclaw-quickstart/main/wizard.js \
        -o "$SCRIPT_DIR/wizard.js"
    step "Wizard downloaded"
fi

chmod +x "$WIZARD"

echo ""
echo "========================================"
echo "🦞 Dependencies ready — starting setup"
echo "========================================"
echo ""

exec node "$WIZARD"
