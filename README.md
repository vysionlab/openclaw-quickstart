# 🦞 OpenClaw Quickstart

Get a fully configured OpenClaw workspace running in under 5 minutes. Works on **macOS** and **Linux**.

## What You Get

- **OpenClaw** installed and ready to run
- **Pre-built workspace** with best-practice file structure:
  - `AGENTS.md` — Agent behavior rules and session startup routine
  - `SOUL.md` — Personality (editable — make it yours)
  - `IDENTITY.md` — Agent's name and character
  - `USER.md` — Info about you (agent learns over time)
  - `MEMORY.md` — Long-term curated memory
  - `TOOLS.md` — Your API keys & local config (gitignored)
  - `HEARTBEAT.md` — Periodic task checklist
  - `WORKSPACE.md` — Architecture documentation (agent maintains)
- **Git repo** initialized with sensible `.gitignore` (secrets excluded)
- **Backup script** ready for cron
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
| AgentMail | Dedicated agent email inbox | [agentmail.to](https://agentmail.to) |
| Tailscale | Access from anywhere | [tailscale.com](https://tailscale.com/) |
| Google AI Studio | Gemini API access | [aistudio.google.com](https://aistudio.google.com/apikey) |

## Backup to GitHub

The installer creates `backup.sh`. To auto-backup daily:

```bash
# Add a GitHub remote first:
cd ~/openclaw
git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git

# Then add to cron (daily at 6am UTC):
crontab -e
# Add:
0 6 * * * cd ~/openclaw && ./backup.sh >> backup.log 2>&1
```

Or set up OpenClaw's built-in cron to handle it from within the agent.

## File Structure

```
~/openclaw/
├── AGENTS.md          # Session startup routine & behavior rules
├── SOUL.md            # Agent personality & tone
├── IDENTITY.md        # Agent's name & character
├── USER.md            # About you
├── MEMORY.md          # Curated long-term memory (main session only)
├── WORKSPACE.md       # Architecture docs (agent maintains this)
├── TOOLS.md           # API keys & local config (gitignored)
├── HEARTBEAT.md       # Periodic check tasks
├── backup.sh          # Git backup script
├── memory/            # Daily logs (memory/YYYY-MM-DD.md)
├── skills/            # Custom skills (from clawhub.com or hand-rolled)
├── templates/         # Reusable templates
├── config/            # Credentials & config (gitignored)
└── assets/            # Static files
```

## How Memory Works

Your agent wakes up fresh each session. The file system is its memory:

- **`memory/YYYY-MM-DD.md`** — Daily raw logs. What happened, decisions made, things to follow up on.
- **`MEMORY.md`** — Curated long-term memory. The agent distills daily logs into this over time. Think of it as the agent's "brain" — not raw notes, but the things worth keeping.
- **`TOOLS.md`** — Setup-specific details: device names, API endpoints, SSH hosts, anything unique to your environment.

The agent reads recent `memory/` files and `MEMORY.md` on startup. Write things down — mental notes don't survive restarts.

## Best Practices Built In

- ✅ **Secrets excluded from git** — TOOLS.md and config/ are gitignored
- ✅ **Memory system** — daily logs + curated long-term memory
- ✅ **Agent reads context on startup** — AGENTS.md defines the startup routine
- ✅ **Personality is editable** — SOUL.md is yours to shape
- ✅ **Skills load on demand** — descriptions route, full instructions load only when needed
- ✅ **Backup-ready** — git initialized, backup script included

## Links

- [OpenClaw Docs](https://docs.openclaw.ai)
- [ClawHub Skills](https://clawhub.com)
- [Discord Community](https://discord.com/invite/clawd)
- [GitHub](https://github.com/openclaw/openclaw)

---

Made with 🦞 by the community. Contributions welcome.
