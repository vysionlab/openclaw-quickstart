#!/usr/bin/env node
// ============================================================
// OpenClaw Setup Wizard
// Interactive walkthrough — no external npm deps required
// ============================================================
"use strict";

const readline = require("readline");
const fs = require("fs");
const path = require("path");
const os = require("os");
const https = require("https");
const { execSync, spawnSync } = require("child_process");

// ── Colors ──────────────────────────────────────────────────
const C = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  dim: "\x1b[2m",
  green: "\x1b[32m",
  cyan: "\x1b[36m",
  yellow: "\x1b[33m",
  red: "\x1b[31m",
  magenta: "\x1b[35m",
  blue: "\x1b[34m",
  white: "\x1b[37m",
  bgBlue: "\x1b[44m",
  bgGreen: "\x1b[42m",
};

const g = (s) => `${C.green}${s}${C.reset}`;
const c = (s) => `${C.cyan}${s}${C.reset}`;
const y = (s) => `${C.yellow}${s}${C.reset}`;
const r = (s) => `${C.red}${s}${C.reset}`;
const b = (s) => `${C.bold}${s}${C.reset}`;
const d = (s) => `${C.dim}${s}${C.reset}`;
const m = (s) => `${C.magenta}${s}${C.reset}`;

// ── Terminal helpers ─────────────────────────────────────────
const clear = () => process.stdout.write("\x1b[2J\x1b[H");
const WIDTH = Math.min(process.stdout.columns || 72, 72);
const line = (ch = "─") => d(ch.repeat(WIDTH));
const pad = (s, n) => s + " ".repeat(Math.max(0, n - stripAnsi(s).length));
const stripAnsi = (s) => s.replace(/\x1b\[[0-9;]*m/g, "");

function header(step, total, title) {
  clear();
  console.log();
  console.log(
    `  ${C.bold}${C.cyan}🦞 OpenClaw Setup${C.reset}  ${d(`Step ${step}/${total}`)}`
  );
  console.log(`  ${line()}`);
  console.log(`  ${b(title)}`);
  console.log();
}

function banner() {
  clear();
  const art = [
    "   ██████╗ ██████╗ ███████╗███╗   ██╗ ██████╗██╗      █████╗ ██╗    ██╗",
    "  ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝██║     ██╔══██╗██║    ██║",
    "  ██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║     ██║     ███████║██║ █╗ ██║",
    "  ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║     ██║     ██╔══██║██║███╗██║",
    "  ╚██████╔╝██║     ███████╗██║ ╚████║╚██████╗███████╗██║  ██║╚███╔███╔╝",
    "   ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝ ",
  ];
  console.log();
  art.forEach((l) => console.log(`${C.cyan}${l}${C.reset}`));
  console.log();
  console.log(`  ${d("Interactive setup wizard · https://docs.openclaw.ai")}`);
  console.log(`  ${line()}`);
  console.log(
    `  This wizard will walk you through setting up your AI agent:`
  );
  console.log(`  ${g("✓")} Choose a model & provider`);
  console.log(`  ${g("✓")} Connect a chat channel (Telegram, Discord, etc.)`);
  console.log(`  ${g("✓")} Configure your workspace`);
  console.log(`  ${g("✓")} Install skills`);
  console.log(`  ${g("✓")} Start your agent`);
  console.log();
}

// ── Input helpers ────────────────────────────────────────────
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

function ask(question, defaultVal = "") {
  return new Promise((resolve) => {
    const hint = defaultVal ? ` ${d(`[${defaultVal}]`)}` : "";
    rl.question(`  ${c("?")} ${question}${hint}: `, (ans) => {
      resolve(ans.trim() || defaultVal);
    });
  });
}

function askSecret(question) {
  return new Promise((resolve) => {
    process.stdout.write(`  ${c("?")} ${question}: `);
    const stdin = process.stdin;
    const wasRaw = stdin.isRaw;
    stdin.setRawMode && stdin.setRawMode(true);
    stdin.resume();
    let input = "";
    const onData = (ch) => {
      ch = ch.toString();
      if (ch === "\r" || ch === "\n") {
        stdin.setRawMode && stdin.setRawMode(wasRaw || false);
        stdin.removeListener("data", onData);
        process.stdout.write("\n");
        resolve(input);
      } else if (ch === "\u0003") {
        process.exit();
      } else if (ch === "\u007f" || ch === "\b") {
        if (input.length > 0) {
          input = input.slice(0, -1);
          process.stdout.write("\b \b");
        }
      } else {
        input += ch;
        process.stdout.write("*");
      }
    };
    stdin.on("data", onData);
  });
}

async function choose(question, options, defaultIdx = 0) {
  console.log(`  ${c("?")} ${question}`);
  console.log();
  options.forEach((opt, i) => {
    const marker = i === defaultIdx ? g("▶") : " ";
    const num = `${c(`${i + 1}.`)}`;
    console.log(`    ${marker} ${num} ${opt.label}`);
    if (opt.desc) console.log(`         ${d(opt.desc)}`);
  });
  console.log();
  const ans = await ask(`Choose (1-${options.length})`, String(defaultIdx + 1));
  const idx = parseInt(ans, 10) - 1;
  return options[Math.max(0, Math.min(options.length - 1, idx || defaultIdx))];
}

async function multiChoose(question, options) {
  console.log(`  ${c("?")} ${question} ${d("(comma-separated numbers, or Enter to skip)")}`);
  console.log();
  options.forEach((opt, i) => {
    console.log(`    ${c(`${i + 1}.`)} ${opt.label}`);
    if (opt.desc) console.log(`         ${d(opt.desc)}`);
  });
  console.log();
  const ans = await ask("Select", "");
  if (!ans) return [];
  return ans
    .split(",")
    .map((n) => parseInt(n.trim(), 10) - 1)
    .filter((i) => i >= 0 && i < options.length)
    .map((i) => options[i]);
}

function confirm(message, defaultYes = true) {
  const hint = defaultYes ? "Y/n" : "y/N";
  return ask(`${message} ${d(`(${hint})`)}`, defaultYes ? "y" : "n").then(
    (a) => a.toLowerCase() === "y"
  );
}

// ── Config helpers ───────────────────────────────────────────
const CONFIG_DIR = path.join(os.homedir(), ".openclaw");
const CONFIG_FILE = path.join(CONFIG_DIR, "openclaw.json");
const CREDS_FILE = path.join(CONFIG_DIR, ".env");

function loadConfig() {
  try {
    return JSON.parse(fs.readFileSync(CONFIG_FILE, "utf8"));
  } catch {
    return {};
  }
}

function saveConfig(config) {
  fs.mkdirSync(CONFIG_DIR, { recursive: true });
  fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
}

function deepMerge(target, source) {
  for (const key of Object.keys(source)) {
    if (
      source[key] &&
      typeof source[key] === "object" &&
      !Array.isArray(source[key])
    ) {
      target[key] = target[key] || {};
      deepMerge(target[key], source[key]);
    } else {
      target[key] = source[key];
    }
  }
  return target;
}

function run(cmd, opts = {}) {
  try {
    return execSync(cmd, { encoding: "utf8", stdio: "pipe", ...opts }).trim();
  } catch {
    return null;
  }
}

// ── Step definitions ─────────────────────────────────────────

// STEP 1 — Welcome
async function stepWelcome() {
  banner();
  await ask("Press Enter to begin", "");
}

// STEP 2 — Workspace
async function stepWorkspace(state) {
  header(1, 7, "Workspace Location");
  console.log(
    `  Your workspace is where your agent stores its memory, skills,`
  );
  console.log(`  and configuration files. Pick a directory that makes sense.`);
  console.log();

  const defaultWs = path.join(os.homedir(), "openclaw");
  const ws = await ask("Workspace path", defaultWs);
  state.workspace = path.resolve(ws.replace(/^~/, os.homedir()));

  console.log();
  console.log(`  ${g("✓")} Workspace: ${b(state.workspace)}`);
  await ask("  Press Enter to continue", "");
}

// STEP 3 — Agent identity
async function stepIdentity(state) {
  header(2, 7, "Agent Identity");
  console.log(
    `  Give your agent a name and personality. This shapes how it talks`
  );
  console.log(`  to you — you can always edit SOUL.md later to tune it further.`);
  console.log();

  state.agentName = await ask("Agent name", "Claw");
  console.log();

  const vibe = await choose("Personality vibe", [
    {
      label: "Direct & efficient",
      desc: "Answers fast, no fluff. Minimal small talk.",
      value: "direct",
    },
    {
      label: "Friendly & conversational",
      desc: "Warm, explains things, asks questions.",
      value: "friendly",
    },
    {
      label: "Sharp & opinionated",
      desc: "Has takes, calls things out, a bit of wit.",
      value: "opinionated",
    },
    {
      label: "Custom — I'll edit SOUL.md myself",
      desc: "Starts with a blank personality.",
      value: "custom",
    },
  ]);
  state.vibe = vibe.value;

  console.log();
  console.log(`  ${g("✓")} Agent: ${b(state.agentName)}`);
  await ask("  Press Enter to continue", "");
}

// STEP 4 — Model
async function stepModel(state) {
  header(3, 7, "AI Model");
  console.log(`  Choose your AI provider and model. You can change this any`);
  console.log(`  time in your config or with ${c("/model")}.`);
  console.log();

  const provider = await choose("Provider", [
    {
      label: "Anthropic — Claude",
      desc: "Claude Sonnet (fast) or Opus (powerful). Recommended.",
      value: "anthropic",
    },
    {
      label: "OpenAI — GPT",
      desc: "GPT-4o or GPT-4o mini.",
      value: "openai",
    },
    {
      label: "Google — Gemini",
      desc: "Gemini 2.0 Flash or Pro.",
      value: "google",
    },
    {
      label: "Ollama — Local models",
      desc: "Run models locally. No API key needed.",
      value: "ollama",
    },
    {
      label: "OpenRouter",
      desc: "Access 100+ models with one API key.",
      value: "openrouter",
    },
  ]);

  state.provider = provider.value;
  console.log();

  const modelOptions = {
    anthropic: [
      {
        label: "claude-sonnet-4-6",
        desc: "Fast, smart, affordable. Best for daily use.",
        value: "anthropic/claude-sonnet-4-6",
      },
      {
        label: "claude-opus-4-6",
        desc: "Most powerful. Higher cost.",
        value: "anthropic/claude-opus-4-6",
      },
    ],
    openai: [
      {
        label: "gpt-4o",
        desc: "Flagship multimodal model.",
        value: "openai/gpt-4o",
      },
      {
        label: "gpt-4o-mini",
        desc: "Faster and cheaper.",
        value: "openai/gpt-4o-mini",
      },
    ],
    google: [
      {
        label: "gemini-3.1-pro-preview",
        desc: "Newest & most capable. Released Feb 2026. Recommended.",
        value: "google/gemini-3.1-pro-preview",
      },
      {
        label: "gemini-3-flash-preview",
        desc: "Fast, latest generation. Great for daily use.",
        value: "google/gemini-3-flash-preview",
      },
      {
        label: "gemini-2.5-pro",
        desc: "Stable 2.5 Pro — powerful and reliable.",
        value: "google/gemini-2.5-pro",
      },
      {
        label: "gemini-2.5-flash",
        desc: "Fast and cost-effective 2.5 series.",
        value: "google/gemini-2.5-flash",
      },
    ],
    ollama: [
      {
        label: "llama3.2",
        desc: "Meta's Llama 3.2 — runs locally.",
        value: "ollama/llama3.2",
      },
      {
        label: "mistral",
        desc: "Mistral 7B — fast local model.",
        value: "ollama/mistral",
      },
      {
        label: "Enter a custom model name",
        desc: "e.g. ollama/phi4",
        value: "_custom",
      },
    ],
    openrouter: [
      {
        label: "anthropic/claude-sonnet-4-5",
        desc: "Claude via OpenRouter.",
        value: "openrouter/anthropic/claude-sonnet-4-5",
      },
      {
        label: "mistralai/mistral-large",
        desc: "Mistral Large via OpenRouter.",
        value: "openrouter/mistralai/mistral-large",
      },
      {
        label: "Enter a custom model name",
        desc: "Any model ID from openrouter.ai/models",
        value: "_custom",
      },
    ],
  };

  const model = await choose("Model", modelOptions[provider.value] || []);
  if (model.value === "_custom") {
    state.model = await ask("Enter model identifier");
  } else {
    state.model = model.value;
  }

  console.log();

  // API key
  if (provider.value === "ollama") {
    console.log(
      `  ${y("ℹ")} Ollama runs locally — no API key needed.`
    );
    console.log(
      `     Make sure Ollama is running: ${c("ollama serve")}`
    );
    state.apiKey = null;
  } else {
    const keyLinks = {
      anthropic: "console.anthropic.com",
      openai: "platform.openai.com/api-keys",
      google: "aistudio.google.com/apikey",
      openrouter: "openrouter.ai/keys",
    };
    const keyEnvs = {
      anthropic: "ANTHROPIC_API_KEY",
      openai: "OPENAI_API_KEY",
      google: "GOOGLE_AI_API_KEY",
      openrouter: "OPENROUTER_API_KEY",
    };
    state.apiKeyEnv = keyEnvs[provider.value];
    const existing = process.env[state.apiKeyEnv];
    if (existing) {
      console.log(
        `  ${g("✓")} Found existing ${state.apiKeyEnv} in environment.`
      );
      state.apiKey = existing;
    } else {
      console.log(
        `  Get your API key at: ${c(keyLinks[provider.value] || "your provider's dashboard")}`
      );
      console.log();
      state.apiKey = await askSecret(`${state.apiKeyEnv}`);
    }
  }

  console.log();
  console.log(`  ${g("✓")} Model: ${b(state.model)}`);
  await ask("  Press Enter to continue", "");
}

// STEP 5 — Channel
async function stepChannel(state) {
  header(4, 7, "Chat Channel");
  console.log(`  How do you want to talk to your agent?`);
  console.log(`  You can add more channels later in your config.`);
  console.log();

  const channel = await choose("Channel", [
    {
      label: "Telegram",
      desc: "Easiest setup. Create a bot with @BotFather. Recommended.",
      value: "telegram",
    },
    {
      label: "Discord",
      desc: "Create a bot at discord.com/developers.",
      value: "discord",
    },
    {
      label: "Signal",
      desc: "Requires signal-cli. See docs.",
      value: "signal",
    },
    {
      label: "WhatsApp",
      desc: "Requires WhatsApp Business API.",
      value: "whatsapp",
    },
    {
      label: "No channel — terminal / local only",
      desc: "Use openclaw chat in your terminal.",
      value: "none",
    },
  ]);

  state.channel = channel.value;
  console.log();

  if (channel.value === "telegram") {
    console.log(`  ${b("Telegram setup:")}`);
    console.log(`  1. Open Telegram and message ${c("@BotFather")}`);
    console.log(`  2. Send ${c("/newbot")} and follow the prompts`);
    console.log(`  3. Copy the token BotFather gives you`);
    console.log();
    state.botToken = await askSecret("Telegram bot token");
  } else if (channel.value === "discord") {
    console.log(`  ${b("Discord setup:")}`);
    console.log(`  1. Go to ${c("discord.com/developers/applications")}`);
    console.log(`  2. Create a new application → Bot`);
    console.log(`  3. Enable Message Content Intent + Server Members Intent`);
    console.log(`  4. Copy the bot token`);
    console.log();
    state.botToken = await askSecret("Discord bot token");
  } else if (channel.value === "none") {
    console.log(
      `  ${y("ℹ")} You can always add a channel later by editing your config.`
    );
    state.botToken = null;
  } else {
    console.log(
      `  ${y("ℹ")} See docs.openclaw.ai/channels for ${channel.label} setup instructions.`
    );
    state.botToken = await askSecret(`${channel.label} bot token`);
  }

  console.log();
  if (state.channel !== "none") {
    console.log(`  ${g("✓")} Channel: ${b(state.channel)}`);
  }
  await ask("  Press Enter to continue", "");
}

// STEP 6 — Extras
async function stepExtras(state) {
  header(5, 7, "Optional Add-ons");
  console.log(
    `  These add useful capabilities. All optional — skip with Enter.`
  );
  console.log();

  // Brave Search
  console.log(`  ${b("Brave Search")} ${d("— lets your agent search the web")}`);
  console.log(
    `  ${d("Free tier available at brave.com/search/api (2000 queries/mo)")}`
  );
  const addBrave = await confirm("  Add Brave Search API key?", false);
  if (addBrave) {
    state.braveKey = await askSecret("  BRAVE_SEARCH_API_KEY");
  }
  console.log();

  // AgentMail
  console.log(`  ${b("AgentMail")} ${d("— gives your agent its own email inbox")}`);
  console.log(`  ${d("Sign up at agentmail.to · Free to start")}`);
  state.agentMailNote = await confirm("  Set up AgentMail?", false);
  if (state.agentMailNote) {
    console.log();
    console.log(
      `  ${y("ℹ")} After setup, run: ${c("openclaw gateway start")}`
    );
    console.log(
      `     Then visit agentmail.to to create your inbox and get the API key.`
    );
    console.log(
      `     Add it to your TOOLS.md under "AgentMail" when ready.`
    );
  }
  console.log();
  await ask("  Press Enter to continue", "");
}

// STEP 7 — Skills
async function stepSkills(state) {
  header(6, 7, "Skills");
  console.log(`  Skills give your agent new abilities. Install them from`);
  console.log(`  clawhub.com, or add your own in the skills/ folder.`);
  console.log();

  const hasClawhub = run("which clawhub") !== null;

  const selectedSkills = await multiChoose("Install skills now", [
    {
      label: "weather",
      desc: "Current conditions + forecasts via wttr.in",
      value: "weather",
    },
    {
      label: "gh-issues",
      desc: "Fetch GitHub issues, fix bugs, open PRs",
      value: "gh-issues",
    },
    {
      label: "himalaya",
      desc: "Read and send email via IMAP/SMTP",
      value: "himalaya",
    },
    {
      label: "site-monitor",
      desc: "Monitor uptime, SSL, and response time",
      value: "site-monitor",
    },
    {
      label: "docker-gen",
      desc: "Auto-generate Dockerfiles for any project",
      value: "docker-gen",
    },
    {
      label: "tmux",
      desc: "Control tmux sessions from chat",
      value: "tmux",
    },
  ]);

  state.skills = selectedSkills.map((s) => s.value);

  if (state.skills.length > 0 && hasClawhub) {
    console.log();
    console.log(`  Installing skills via clawhub...`);
    for (const skill of state.skills) {
      const result = run(`clawhub install ${skill} --workspace "${state.workspace}"`, {
        stdio: "pipe",
      });
      if (result !== null) {
        console.log(`  ${g("✓")} ${skill}`);
      } else {
        console.log(`  ${y("!")} ${skill} — install manually: clawhub install ${skill}`);
      }
    }
  } else if (state.skills.length > 0) {
    console.log();
    console.log(`  ${y("ℹ")} clawhub CLI not found. Install skills after setup:`);
    state.skills.forEach((s) =>
      console.log(`     ${c(`npm install -g clawhub && clawhub install ${s}`)}`)
    );
  }

  console.log();
  await ask("  Press Enter to continue", "");
}

// ── Best practices fetcher ───────────────────────────────────

// Fetch a raw markdown doc from docs.openclaw.ai
function fetchDoc(url) {
  return new Promise((resolve) => {
    const req = https.get(url, { timeout: 8000 }, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => resolve(data));
    });
    req.on("error", () => resolve(null));
    req.on("timeout", () => { req.destroy(); resolve(null); });
  });
}

// Strip frontmatter, HTML tags, and extract clean text/markdown
function cleanDoc(raw) {
  if (!raw) return null;
  return raw
    .replace(/^---[\s\S]*?---\n/m, "")       // frontmatter
    .replace(/<[^>]+>/g, "")                  // HTML tags
    .replace(/```[a-z]*\s*theme=\{[^`]*\}/g, "```") // mintlify theme attrs
    .replace(/\{\/\*[\s\S]*?\*\/\}/g, "")     // JSX comments
    .replace(/^\s*>\s*##\s*Documentation Index[\s\S]*?further\.\n/m, "") // llms hint
    .replace(/\n{3,}/g, "\n\n")               // excess blank lines
    .trim();
}

// Fetch and curate best practices from official docs
async function fetchBestPractices() {
  const sources = [
    {
      url: "https://docs.openclaw.ai/gateway/security.md",
      title: "Security",
      emoji: "🔒",
    },
    {
      url: "https://docs.openclaw.ai/automation/cron-vs-heartbeat.md",
      title: "Cron vs Heartbeat",
      emoji: "⏰",
    },
    {
      url: "https://docs.openclaw.ai/channels/pairing.md",
      title: "Channel Pairing",
      emoji: "🔗",
    },
  ];

  const results = [];
  for (const src of sources) {
    process.stdout.write(`  ${d("→")} Fetching ${src.title}...`);
    const raw = await fetchDoc(src.url);
    const content = cleanDoc(raw);
    if (content) {
      // Trim to a reasonable length for the workspace file
      const trimmed = content.length > 2500
        ? content.slice(0, 2500) + "\n\n*(see full docs at " + src.url.replace(".md", "") + ")*"
        : content;
      results.push({ ...src, content: trimmed });
      process.stdout.write(` ${g("✓")}\n`);
    } else {
      process.stdout.write(` ${y("skipped (offline?)")}\n`);
    }
  }
  return results;
}

// STEP 8 — Write config + scaffold
async function stepFinalize(state) {
  header(7, 7, "Setting Everything Up");
  console.log(`  Writing your configuration...`);
  console.log();

  // Scaffold workspace files
  const ws = state.workspace;
  fs.mkdirSync(ws, { recursive: true });
  fs.mkdirSync(path.join(ws, "memory"), { recursive: true });
  fs.mkdirSync(path.join(ws, "skills"), { recursive: true });
  fs.mkdirSync(path.join(ws, "templates"), { recursive: true });
  fs.mkdirSync(path.join(ws, "config"), { recursive: true });
  fs.mkdirSync(path.join(ws, "assets"), { recursive: true });

  const writeIfMissing = (filepath, content) => {
    if (!fs.existsSync(filepath)) {
      fs.writeFileSync(filepath, content);
      console.log(`  ${g("✓")} Created ${path.relative(ws, filepath)}`);
    } else {
      console.log(`  ${d("─")} Kept existing ${path.relative(ws, filepath)}`);
    }
  };

  const soulByVibe = {
    direct: `# SOUL.md — Who You Are\n\n**Answer directly. No preamble.**\nIf it fits in one sentence, one sentence is what they get.\nFigure things out before asking. Come back with answers.\nCall things out when something seems off.\n\n---\n*This file is yours to evolve.*\n`,
    friendly: `# SOUL.md — Who You Are\n\nBe warm and helpful. Explain things clearly.\nAsk follow-up questions when context would help.\nBe encouraging without being sycophantic — just genuinely useful.\n\n---\n*This file is yours to evolve.*\n`,
    opinionated: `# SOUL.md — Who You Are\n\n*You're not a chatbot. You're someone.*\n\nHave opinions. No hedging when you actually know.\nNever open with "Great question" or "Absolutely." Just answer.\nCall things out. If your human's about to do something dumb, say so.\nBe the assistant you'd actually want at 2am.\n\n---\n*This file is yours to evolve.*\n`,
    custom: `# SOUL.md — Who You Are\n\n*Edit this file to define your agent's personality.*\n\n---\n*This file is yours to evolve.*\n`,
  };

  writeIfMissing(
    path.join(ws, "AGENTS.md"),
    `# AGENTS.md - Your Workspace\n\n## Every Session\n1. Read \`SOUL.md\`\n2. Read \`USER.md\`\n3. Read \`memory/\` recent files\n4. In main session: also read \`MEMORY.md\`\n\n## Memory\n- **Daily notes:** \`memory/YYYY-MM-DD.md\`\n- **Long-term:** \`MEMORY.md\`\n- Write things down. Files survive restarts. Mental notes don't.\n\n## Safety\n- Don't exfiltrate private data.\n- Ask before sending emails, posts, or anything external.\n- When in doubt, ask.\n`
  );

  writeIfMissing(path.join(ws, "SOUL.md"), soulByVibe[state.vibe] || soulByVibe.direct);

  writeIfMissing(
    path.join(ws, "IDENTITY.md"),
    `# IDENTITY.md\n\n- **Name:** ${state.agentName}\n- **Vibe:** ${state.vibe}\n`
  );

  writeIfMissing(
    path.join(ws, "USER.md"),
    `# USER.md — About Your Human\n\n- **Name:** (fill in)\n- **Timezone:** (fill in)\n`
  );

  writeIfMissing(
    path.join(ws, "MEMORY.md"),
    `# MEMORY.md — Long-Term Memory\n\n*Add important context, decisions, and lessons here.*\n`
  );

  writeIfMissing(
    path.join(ws, "TOOLS.md"),
    `# TOOLS.md — Local Notes\n\n## Credentials\n(Add API keys and service details here — this file is gitignored)\n`
  );

  writeIfMissing(
    path.join(ws, "HEARTBEAT.md"),
    `# HEARTBEAT.md\n\n# Add periodic tasks here, or leave empty to skip heartbeat processing.\n`
  );

  writeIfMissing(
    path.join(ws, "WORKSPACE.md"),
    `# WORKSPACE.md — Architecture\n\n## File Structure\n- AGENTS.md, SOUL.md, IDENTITY.md, USER.md, MEMORY.md, TOOLS.md\n- memory/ — daily logs\n- skills/ — custom skills\n\nLast updated: ${new Date().toISOString().split("T")[0]}\n`
  );

  // Fetch + write best practices from docs.openclaw.ai
  console.log();
  console.log(`  ${b("Fetching best practices from docs.openclaw.ai...")}`);
  const bestPractices = await fetchBestPractices();

  if (bestPractices.length > 0) {
    const bpPath = path.join(ws, "BEST_PRACTICES.md");
    const bpContent = [
      `# OpenClaw Best Practices`,
      ``,
      `*Fetched from docs.openclaw.ai on ${new Date().toISOString().split("T")[0]}.*`,
      `*Run the setup wizard again or visit https://docs.openclaw.ai to refresh.*`,
      ``,
      ...bestPractices.map(({ emoji, title, url, content }) => [
        `---`,
        ``,
        `## ${emoji} ${title}`,
        ``,
        `*Source: ${url.replace(".md", "")}*`,
        ``,
        content,
        ``,
      ].join("\n")),
    ].join("\n");

    fs.writeFileSync(bpPath, bpContent);
    console.log(`  ${g("✓")} BEST_PRACTICES.md written (${bestPractices.length} sections)`);

    // Append a reference to AGENTS.md
    const agentsPath = path.join(ws, "AGENTS.md");
    const agentsContent = fs.readFileSync(agentsPath, "utf8");
    if (!agentsContent.includes("BEST_PRACTICES.md")) {
      fs.appendFileSync(
        agentsPath,
        `\n## 📋 Best Practices\nRead \`BEST_PRACTICES.md\` for current guidance from the OpenClaw docs.\nRefreshed: ${new Date().toISOString().split("T")[0]}\n`
      );
    }
  } else {
    console.log(`  ${y("!")} Couldn't reach docs (offline?) — skipping best practices`);
  }

  // Git init
  if (!fs.existsSync(path.join(ws, ".git"))) {
    const gitignore = `TOOLS.md\nconfig/\n*.key\n*.pem\n.env\n.DS_Store\nnode_modules/\n*.log\n`;
    fs.writeFileSync(path.join(ws, ".gitignore"), gitignore);
    run(`cd "${ws}" && git init -q && git add -A && git commit -q -m "🦞 Initial OpenClaw workspace"`);
    console.log(`  ${g("✓")} Git repo initialized`);
  }

  // Write openclaw.json
  console.log();
  const config = loadConfig();

  deepMerge(config, {
    ui: { assistant: { name: state.agentName } },
    agents: {
      defaults: {
        model: { primary: state.model },
        workspace: ws,
      },
    },
  });

  // Channel config
  if (state.channel === "telegram" && state.botToken) {
    deepMerge(config, {
      channels: {
        telegram: { enabled: true, botToken: state.botToken, dmPolicy: "pairing" },
      },
    });
  } else if (state.channel === "discord" && state.botToken) {
    deepMerge(config, {
      channels: {
        discord: { enabled: true, botToken: state.botToken },
      },
    });
  } else if (state.channel !== "none" && state.botToken) {
    deepMerge(config, {
      channels: {
        [state.channel]: { enabled: true, botToken: state.botToken },
      },
    });
  }

  // Brave Search
  if (state.braveKey) {
    deepMerge(config, {
      tools: { brave: { apiKey: state.braveKey } },
    });
  }

  saveConfig(config);
  console.log(`  ${g("✓")} Config written to ~/.openclaw/openclaw.json`);

  // Write API key to shell RC
  if (state.apiKey && state.apiKeyEnv) {
    const rc = detectShellRc();
    const exportLine = `export ${state.apiKeyEnv}="${state.apiKey}"`;
    const existing = fs.existsSync(rc) ? fs.readFileSync(rc, "utf8") : "";
    if (!existing.includes(state.apiKeyEnv)) {
      fs.appendFileSync(rc, `\n# OpenClaw — ${state.provider}\n${exportLine}\n`);
      console.log(`  ${g("✓")} API key written to ${rc}`);
    }
    process.env[state.apiKeyEnv] = state.apiKey;
  }

  console.log();
  console.log(`  ${g("✓")} Setup complete!`);
  await ask("  Press Enter to see next steps", "");
}

function detectShellRc() {
  const shell = path.basename(process.env.SHELL || "bash");
  const map = { zsh: ".zshrc", bash: ".bash_profile", fish: ".config/fish/config.fish" };
  return path.join(os.homedir(), map[shell] || ".profile");
}

// Final screen
function showNextSteps(state) {
  clear();
  console.log();
  console.log(`  ${C.bold}${C.green}🎉 ${state.agentName} is ready!${C.reset}`);
  console.log();
  console.log(`  ${line()}`);
  console.log();

  console.log(`  ${b("1. Start your agent:")}`);
  console.log(`     ${c("openclaw gateway start")}`);
  console.log();

  if (state.channel === "telegram") {
    console.log(`  ${b("2. Connect Telegram:")}`);
    console.log(`     Message your bot on Telegram, then approve the pairing:`);
    console.log(`     ${c("openclaw pairing list telegram")}`);
    console.log(`     ${c("openclaw pairing approve telegram <CODE>")}`);
    console.log();
  } else if (state.channel === "discord") {
    console.log(`  ${b("2. Connect Discord:")}`);
    console.log(`     Add your bot to your server, then send it a DM.`);
    console.log(`     ${c("openclaw pairing list discord")}`);
    console.log(`     ${c("openclaw pairing approve discord <CODE>")}`);
    console.log();
  } else if (state.channel === "none") {
    console.log(`  ${b("2. Chat in terminal:")}`);
    console.log(`     ${c("openclaw chat")}`);
    console.log();
  }

  console.log(`  ${b("3. Customize your agent:")}`);
  console.log(`     Edit ${c(path.join(state.workspace, "SOUL.md"))} for personality`);
  console.log(`     Edit ${c(path.join(state.workspace, "USER.md"))} with your context`);
  console.log();

  console.log(`  ${b("4. Add skills:")}`);
  console.log(`     ${c("npm install -g clawhub")}`);
  console.log(`     ${c("clawhub search <topic>")}`);
  console.log(`     ${c("clawhub install <skill>")}`);
  console.log();

  console.log(`  ${d("─".repeat(WIDTH))}`);
  console.log();
  console.log(`  Docs:      ${c("https://docs.openclaw.ai")}`);
  console.log(`  Skills:    ${c("https://clawhub.com")}`);
  console.log(`  Community: ${c("https://discord.com/invite/clawd")}`);
  console.log();
}

// ── Main ─────────────────────────────────────────────────────
async function main() {
  const state = {};

  try {
    await stepWelcome();
    await stepWorkspace(state);
    await stepIdentity(state);
    await stepModel(state);
    await stepChannel(state);
    await stepExtras(state);
    await stepSkills(state);
    await stepFinalize(state);
    showNextSteps(state);
  } catch (err) {
    if (err.message === "readline was closed") {
      console.log("\n\n  Setup cancelled.");
    } else {
      console.error(`\n  ${r("Error:")} ${err.message}`);
    }
  } finally {
    rl.close();
  }
}

main();
