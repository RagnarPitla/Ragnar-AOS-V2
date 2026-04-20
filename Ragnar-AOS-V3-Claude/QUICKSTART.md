# Ragnar's Agentic OS V2 — Quick Start

## What's New in V3

V3 adds 12 new capabilities inspired by Hermes Agent patterns:

1. **Context Window Management** — auto-summarize conversations, Active Task tracking
2. **Delegation Contracts** — subagent isolation with restricted tools and depth limits
3. **Agent Auto-Discovery** — agents self-register from the `agents/` directory
4. **Background Tasks** — fire-and-forget and notify-on-complete execution
5. **Session Persistence** — SQLite + FTS5 full-text history search
6. **Profile Isolation** — multiple configurations via `RAOS_HOME`
7. **Dashboard Theme Engine** — YAML skins, theme switcher, 2 built-in themes
8. **Cost/Token Tracking** — per-objective budgets with real-time monitoring
9. **MCP Integration** — external tool server connections via Model Context Protocol
10. **Platform Gateway** — multi-platform adapters (Claude, Copilot, etc.)
11. **Terminal Backends** — local/docker/ssh/cloud execution abstraction
12. **Command Registry** — single source of truth for all slash commands

## Prerequisites

- **Claude Code CLI** installed and authenticated (`claude` command available in your terminal)
- **Python 3.10+** installed (required for the dashboard and build scripts)
- A project folder you want to add the Agentic OS to

## Setup (< 2 minutes)

### Step 1: Drop the installer in your project

Copy `Ragnar-AgenticOS-setup.md` into your project root (or into `~/.claude/skills/`).

### Step 2: Tell Claude to install

```
Install Ragnar-AgenticOS
```

(Or: "Install RAOS v2", "set up my Agentic OS", etc.)

### Step 3: Answer the 3 naming questions

The installer asks:
1. **OS slug** — a short kebab-case name (e.g., `contoso-os`)
2. **Display name** — what the OS calls itself (e.g., "Contoso Agentic OS")
3. **Wake phrase** — the phrase that boots the team (e.g., "Hey Contoso")

### Step 4: Use it

Type `/raos` or your wake phrase from any project folder. Done.

## Common commands

| Command | What it does |
|---|---|
| `/raos <objective>` | Start a new objective (Research → Challenge → Synthesis → Verify) |
| `/raos status` | Show current run status, phase, and budget usage |
| `/raos runs` | List all runs (active, paused, done, killed) |
| `/raos resume <run_id>` | Resume a paused or crashed run |
| `/raos kill <run_id>` | Kill a running objective immediately |

## Dashboard (Mission Control)

Run the local dashboard for onboarding and live task monitoring:

    python3 dashboard/server.py --project /path/to/your-project

Opens http://localhost:9200 with:
- **Onboarding Wizard** — name your OS, pick specialists, deploy
- **Task Monitor** — live kanban view of tasks.json

## Upgrading from V1?

See [UPGRADE.md](UPGRADE.md) for the full migration guide. V2 is additive — everything V1 did still works.
