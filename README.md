# 🦞 OpenClaw Quickstart

Get a fully configured OpenClaw workspace running in under 5 minutes. Works on **macOS** and **Linux**.

## What You Get

- **OpenClaw** installed and ready to run
- **Pre-built workspace** with best-practice file structure:
  - `AGENTS.md` — Agent behavior rules
  - `SOUL.md` — Personality (editable)
  - `USER.md` — Info about you (agent learns over time)
  - `MEMORY.md` — Long-term memory
  - `TOOLS.md` — Your API keys & local config
  - `HEARTBEAT.md` — Periodic task checklist
  - `WORKSPACE.md` — Architecture documentation
- **Git repo** initialized with sensible `.gitignore` (secrets excluded)
- **Backup script** ready for hourly cron
- Folder structure for `memory/`, `skills/`, `templates/`, `config/`, `assets/`

## Quick Start

```bash
git clone https://github.com/vysionlab/openclaw-quickstart.git
cd openclaw-quickstart
bash install.sh
```

Or one-liner:
```bash
curl -fsSL https://raw.githubusercontent.com/vysionlab/openclaw-quickstart/main/install.sh | bash
```

## Requirements

- **macOS**: Homebrew (`brew.sh`) — the script uses it to install Node if needed
- **Linux**: apt-based distro (Ubuntu, Debian, WSL)
- **Node.js 22+** — installed automatically if missing

## After Install

1. **Run the wizard**: `openclaw onboard --install-daemon`
2. **Add your API key**: You'll need an Anthropic key from [console.anthropic.com](https://console.anthropic.com)
3. **Connect a channel**: Telegram is easiest — create a bot via [@BotFather](https://t.me/BotFather)
4. **Start it**: `openclaw gateway start`
5. **Talk to your agent** — it'll help configure everything else

## Optional (Recommended)

| Service | Why | Get it |
|---------|-----|--------|
| Brave Search API | Web search from chat | [brave.com/search/api](https://brave.com/search/api/) |
| Google AI Studio key | Memory search (semantic) | [aistudio.google.com](https://aistudio.google.com/apikey) |
| Tailscale | Access from anywhere | [tailscale.com](https://tailscale.com/) |

## Hourly Backup

The installer creates `backup.sh`. To auto-backup hourly:

```bash
# Add a GitHub remote first:
cd ~/openclaw
git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git

# Then add to cron:
crontab -e
# Add this line:
0 * * * * cd ~/openclaw && ./backup.sh >> backup.log 2>&1
```

## File Structure

```
~/openclaw/
├── AGENTS.md          # How the agent should behave
├── SOUL.md            # Agent personality & tone
├── USER.md            # About you
├── IDENTITY.md        # Agent's name & identity
├── MEMORY.md          # Curated long-term memory
├── WORKSPACE.md       # Architecture docs (agent maintains)
├── TOOLS.md           # API keys & local config (gitignored)
├── HEARTBEAT.md       # Periodic check tasks
├── backup.sh          # Git backup script
├── memory/            # Daily logs (memory/YYYY-MM-DD.md)
├── skills/            # Custom skills
├── templates/         # Reusable templates
├── config/            # Credentials & config
└── assets/            # Static files
```

## Best Practices Built In

- ✅ **Secrets excluded from git** — TOOLS.md and config/cron-credentials.md are gitignored
- ✅ **Memory system** — daily logs + curated long-term memory
- ✅ **Agent reads context on startup** — AGENTS.md tells it what to load
- ✅ **Personality is editable** — SOUL.md is yours to shape
- ✅ **Skills load on demand** — descriptions route, full instructions load only when triggered
- ✅ **Backup-ready** — git initialized, backup script included

## Links

- [OpenClaw Docs](https://docs.openclaw.ai)
- [ClawHub Skills](https://clawhub.com)
- [Discord Community](https://discord.com/invite/clawd)
- [GitHub](https://github.com/openclaw/openclaw)

---

Made with 🦞 by the community. Contributions welcome.
