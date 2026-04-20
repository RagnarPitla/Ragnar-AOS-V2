# Ragnar's Agentic OS V2 — Quick Start

## Prerequisites

- **Claude Code CLI** installed and authenticated (`claude` command available in your terminal)
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
