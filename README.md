# OpenClaw Quick Deploy

One script to go from bare Ubuntu to a running OpenClaw agent.

## Install

```bash
# On a fresh Ubuntu server (22.04+):
bash install.sh
```

## What it does

1. Installs Node.js 22, OpenClaw, ClawHub CLI, Python tools
2. Creates a workspace with scaffolded files:
   - `AGENTS.md` — agent behavior rules
   - `SOUL.md` — personality (customizable)
   - `USER.md` — about the human (fill in)
   - `IDENTITY.md` — agent identity
   - `MEMORY.md` — long-term memory
   - `TOOLS.md` — API keys & config
   - `HEARTBEAT.md` — periodic tasks
   - `memory/`, `skills/`, `templates/`, `assets/`, `config/`
3. Initializes git for version control
4. Prints next steps

## After install

1. `openclaw configure` — interactive setup (API keys, channel)
2. `openclaw gateway start` — start the agent
3. Talk to it — it handles the rest

## Requirements

- Ubuntu 22.04+ (or similar Linux/macOS)
- 2GB+ RAM
- 20GB+ disk

## Minimum API keys needed

| Key | Required | Where |
|-----|----------|-------|
| Anthropic | Yes | console.anthropic.com |
| Chat channel (Telegram/Discord/etc) | Yes | Depends on platform |
| Brave Search | Recommended | brave.com/search/api |

Everything else (Google APIs, email, social, etc.) can be added later as needed.
