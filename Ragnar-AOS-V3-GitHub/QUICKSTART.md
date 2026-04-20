# Quickstart — Ragnar's Agentic OS V2 for GitHub Copilot CLI

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

Get from zero to a working Agentic OS team in under 5 minutes.

## Prerequisites

1. **GitHub CLI** installed: https://cli.github.com/
2. **GitHub Copilot CLI extension** installed:
   ```bash
   gh extension install github/gh-copilot
   ```
3. **Python 3.10+** installed (required for the dashboard and build scripts).
4. **A project folder** you want to work in.

## Step 1: Get the installer

Download or copy `Ragnar-AgenticOS-setup.md` (the single-file installer) into your project folder or home directory.

## Step 2: Run the installer

```bash
cd path/to/your/project
gh copilot
> Install Ragnar-AgenticOS v2 from ./Ragnar-AgenticOS-setup.md
```

The installer will:
- Ask you to name your OS (slug, display name, wake phrase)
- Write ~23 blueprint files to `~/.github/skills/<your-os-name>/`
- Create `.agentic-os/` in your project for local memory and runs
- Wire auto-boot in `~/.github/instructions.md`

## Step 3: Use your team

From any project folder:

```bash
gh copilot
> <your wake phrase>
```

Or use the slash command:

```
/raos                          # status / bootstrap
/raos <objective sentence>     # start a new objective
/raos status                   # dashboard
/raos runs                     # list all runs
/raos resume <run_id>          # continue a paused run
/raos kill <run_id>            # halt a run
```

## What's different from Claude Code

GitHub Copilot CLI does not support Claude Code's hook system. This means:

- **No automatic tracing** — the team-lead writes checkpoints at phase boundaries instead
- **No automatic kill switch** — tell the team-lead "stop" or cancel the session
- **No automatic circuit breaker** — the team-lead pauses after repeated failures

These are observability trade-offs, not functionality losses. The team-lead prompt compensates by including explicit checkpoint and error-handling instructions. For full details, see [HOOKS-DEGRADED.md](HOOKS-DEGRADED.md).

**Headless/scheduled runs** work best through GitHub Actions. See `harness/schedule/github-actions.yaml.template`.

## Dashboard (Mission Control)

Run the local dashboard for onboarding and live task monitoring:

    python3 dashboard/server.py --project /path/to/your-project

Opens http://localhost:9200 with:
- **Onboarding Wizard** — name your OS, pick specialists, deploy
- **Task Monitor** — live kanban view of tasks.json

## Next steps

- Read [UPGRADE.md](UPGRADE.md) if migrating from V1
- Read [references/the-scaffold.md](references/the-scaffold.md) for the V2 thesis
- Read [references/the-4-stages.md](references/the-4-stages.md) for the mental model

## Questions

Ping Ragnar Pitla on LinkedIn: https://www.linkedin.com/in/ragnarpitla/
