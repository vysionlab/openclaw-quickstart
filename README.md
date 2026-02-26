# 🦞 OpenClaw Quickstart

The fastest way to get a personal AI agent running on your Mac.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/vysionlab/openclaw-quickstart/main/install.sh | bash
```

Then run the setup wizard:

```bash
openclaw config
```

That's it. The wizard walks you through:
- Picking a model (Claude, GPT-4o, Gemini, Ollama, etc.)
- Connecting a channel (Telegram, Discord, WhatsApp, etc.)
- Setting up your workspace
- Installing skills
- Starting your agent

## What Gets Installed

| Tool | Purpose |
|------|---------|
| Node.js 22 | Runtime |
| OpenClaw (latest) | AI agent platform |
| mcporter | MCP server manager (HubSpot, n8n, etc.) |
| excalidraw-mcp | Diagram generation — agent draws `.excalidraw` files |
| obsidian-cli | Obsidian vault search from the terminal |
| uv | Fast Python package runner for skills |

Installed to `~/.npm-global` — no sudo required.

## Requirements

- macOS (Apple Silicon or Intel) — Linux also supported
- Internet connection

Node.js will be installed automatically if missing (via nvm, Homebrew, or NodeSource).

## After Setup

```bash
openclaw gateway start     # Start your agent
openclaw status            # Health check
openclaw cron list         # View scheduled tasks
openclaw gateway logs      # View live logs
```

## Docs

Full documentation: [docs.openclaw.ai](https://docs.openclaw.ai)

## Moving to a New Server

See [migrate.sh](./migrate.sh) to package your existing workspace for server migration.
