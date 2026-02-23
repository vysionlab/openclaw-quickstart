# 🦞 OpenClaw Quickstart

Get a fully configured OpenClaw agent running in under 5 minutes. Works on **macOS** (Intel + Apple Silicon) and **Linux**.

## What You Get

A guided setup wizard that walks you through:

- 🤖 **Model selection** — Anthropic, OpenAI, Google, Ollama, OpenRouter
- 💬 **Channel setup** — Telegram, Discord, Signal, WhatsApp, or local
- 🧠 **Agent identity** — name, personality, workspace location
- 🔑 **API key configuration** — masked input, auto-detects existing env vars
- 🛠️ **Skills install** — pick from popular skills via clawhub
- ⚙️ **Config written for you** — `openclaw.json`, workspace files, git repo, shell RC

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

The installer handles system dependencies (Node.js 22+, Homebrew on Mac, git, jq), installs OpenClaw, then launches the interactive wizard automatically.

## Requirements

- **macOS**: Xcode CLI tools + Homebrew (installed automatically if missing)
- **Linux**: Ubuntu/Debian with apt
- **Node.js 22+** — installed automatically if missing
- **nvm** — used automatically if present

## The Setup Wizard

After dependencies are ready, you'll be walked through 7 steps:

| Step | What happens |
|------|-------------|
| 1 | Welcome |
| 2 | Choose your workspace directory |
| 3 | Name your agent + pick a personality vibe |
| 4 | Pick your AI provider + model, enter API key |
| 5 | Connect a chat channel (Telegram is easiest) |
| 6 | Optional add-ons: Brave Search, AgentMail |
| 7 | Install skills from clawhub |

At the end, your `~/.openclaw/openclaw.json` is written, workspace files are scaffolded, git is initialized, and you get exact commands to pair your channel and start chatting.

## After Setup

```bash
# Start your agent
openclaw gateway start

# Approve Telegram pairing (if you chose Telegram)
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>

# Or chat in the terminal
openclaw chat
```

## Workspace File Structure

```
~/openclaw/
├── AGENTS.md          # Session startup routine & behavior rules
├── SOUL.md            # Agent personality & tone (shaped by your vibe choice)
├── IDENTITY.md        # Agent's name & character
├── USER.md            # About you
├── MEMORY.md          # Curated long-term memory
├── WORKSPACE.md       # Architecture docs (agent maintains this)
├── TOOLS.md           # API keys & local config (gitignored)
├── HEARTBEAT.md       # Periodic check tasks
├── memory/            # Daily logs (YYYY-MM-DD.md)
├── skills/            # Installed skills
├── templates/         # Reusable templates
├── config/            # Credentials & config (gitignored)
└── assets/            # Static files
```

## How Memory Works

Your agent wakes up fresh each session. The file system is its memory:

- **`memory/YYYY-MM-DD.md`** — Daily raw logs. What happened, decisions made, follow-ups.
- **`MEMORY.md`** — Curated long-term memory. The agent distills daily logs into this over time.
- **`TOOLS.md`** — Setup-specific details: API endpoints, device names, anything unique to your environment.

The agent reads recent `memory/` files and `MEMORY.md` on startup. Write things down — mental notes don't survive restarts.

## Optional Add-ons

| Service | Why | Get it |
|---------|-----|--------|
| Brave Search API | Web search from chat | [brave.com/search/api](https://brave.com/search/api/) |
| AgentMail | Dedicated agent email inbox | [agentmail.to](https://agentmail.to) |
| Tailscale | Access your agent from anywhere | [tailscale.com](https://tailscale.com/) |

## Adding More Skills

```bash
npm install -g clawhub
clawhub search <topic>
clawhub install <skill-name>
```

Browse the full catalog at [clawhub.com](https://clawhub.com).

## Best Practices Built In

- ✅ **Secrets excluded from git** — TOOLS.md and config/ are gitignored
- ✅ **Memory system** — daily logs + curated long-term memory
- ✅ **Agent reads context on startup** — AGENTS.md defines the routine
- ✅ **Personality shaped by you** — wizard writes the right SOUL.md for your vibe
- ✅ **Skills on demand** — descriptions route, full instructions load only when needed
- ✅ **Config written automatically** — no manual JSON editing

## Links

- [OpenClaw Docs](https://docs.openclaw.ai)
- [ClawHub Skills](https://clawhub.com)
- [Discord Community](https://discord.com/invite/clawd)
- [GitHub](https://github.com/openclaw/openclaw)

---

Made with 🦞 by the community. Contributions welcome.
