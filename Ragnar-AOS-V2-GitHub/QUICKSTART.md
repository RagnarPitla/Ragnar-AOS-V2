# Quickstart — Ragnar's Agentic OS V2 for GitHub Copilot CLI

Get from zero to a working Agentic OS team in under 5 minutes.

## Prerequisites

1. **GitHub CLI** installed: https://cli.github.com/
2. **GitHub Copilot CLI extension** installed:
   ```bash
   gh extension install github/gh-copilot
   ```
3. **A project folder** you want to work in.

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
