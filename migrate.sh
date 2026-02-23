#!/usr/bin/env bash
# migrate.sh — Package your OpenClaw workspace for server migration
# Usage: bash migrate.sh [workspace_dir] [output_file]
# Example: bash migrate.sh ~/openclaw openclaw-backup.tar.gz

set -euo pipefail

WORKSPACE="${1:-$HOME/openclaw}"
OUTPUT="${2:-openclaw-migration-$(date +%Y%m%d).tar.gz}"

if [ ! -d "$WORKSPACE" ]; then
  echo "❌ Workspace not found: $WORKSPACE"
  echo "   Usage: bash migrate.sh [workspace_dir] [output_file]"
  exit 1
fi

echo "📦 Packaging OpenClaw workspace: $WORKSPACE"
echo ""

# Files and directories to include
INCLUDES=(
  "AGENTS.md"
  "SOUL.md"
  "IDENTITY.md"
  "USER.md"
  "MEMORY.md"
  "WORKSPACE.md"
  "TOOLS.md"
  "HEARTBEAT.md"
  "memory/"
  "skills/"
  "templates/"
  "assets/"
  "config/"
)

# Build tar args — only include items that exist
TAR_ARGS=()
for item in "${INCLUDES[@]}"; do
  if [ -e "$WORKSPACE/$item" ]; then
    TAR_ARGS+=("$item")
    echo "  ✅ $item"
  else
    echo "  ⏭️  $item (not found, skipping)"
  fi
done

echo ""

# Create the archive from within the workspace
cd "$WORKSPACE"
tar -czf "$OLDPWD/$OUTPUT" "${TAR_ARGS[@]}"
cd "$OLDPWD"

SIZE=$(du -sh "$OUTPUT" | cut -f1)
echo "✅ Archive created: $OUTPUT ($SIZE)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Next steps on your new server:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1. Run the quickstart installer:"
echo "     curl -fsSL https://raw.githubusercontent.com/vysionlab/openclaw-quickstart/main/install.sh | bash"
echo ""
echo "  2. Copy your archive to the new server:"
echo "     scp $OUTPUT user@newserver:~/"
echo ""
echo "  3. On the new server, extract into your workspace:"
echo "     tar -xzf $OUTPUT -C ~/openclaw"
echo ""
echo "  4. Re-pair your Telegram (or other channel):"
echo "     openclaw gateway start"
echo "     openclaw pairing list telegram"
echo "     openclaw pairing approve telegram <CODE>"
echo ""
echo "  5. Recreate your cron jobs:"
echo "     openclaw cron list   # (on old server first — note the jobs)"
echo "     openclaw cron add    # recreate on new server"
echo ""
echo "  ⚠️  config/cron-credentials.md contains API keys — keep the archive secure!"
echo ""
