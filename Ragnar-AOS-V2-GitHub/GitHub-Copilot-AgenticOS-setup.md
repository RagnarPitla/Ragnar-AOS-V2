# GitHub Copilot CLI — Ragnar's Agentic OS V2 Setup Guide

This is the setup guide for installing RAOS V2 on **GitHub Copilot CLI** (`gh copilot`).

For Claude Code, use `Ragnar-AgenticOS-setup.md` instead. This file covers the Copilot-specific differences.

## Prerequisites

1. GitHub CLI: https://cli.github.com/
2. GitHub Copilot extension:
   ```bash
   gh extension install github/gh-copilot
   ```

## What gets installed

The installer (`Ragnar-AgenticOS-setup.md`) writes to:

| Item | Location |
|---|---|
| Skill folder | `~/.github/skills/<your-os-name>/` |
| Auto-boot block | `~/.github/instructions.md` |
| Project memory | `.agentic-os/` (in each project) |
| Agent files | `.github/agents/` (in each project, after bootstrap) |
| Task list | `.github/tasks.json` (in each project) |

## What's NOT installed (vs Claude Code)

- **No hook registration.** Claude Code's `settings.json.fragment` is not used. GitHub Copilot CLI does not have a PreToolUse/PostToolUse/Stop/UserPromptSubmit hook system.
- **No automatic tracing, kill switch, circuit breaker, or checkpointing.** These are handled by prompt-level instructions in the team-lead agent instead.

See [HOOKS-DEGRADED.md](HOOKS-DEGRADED.md) for the full breakdown of what's lost and the manual alternatives.

## Installation

```bash
cd path/to/your/project
gh copilot
> Install Ragnar-AgenticOS v2 from ./Ragnar-AgenticOS-setup.md
```

The installer detects that you're on Copilot CLI (by checking for `~/.github/`) and:

1. Asks three naming questions (slug, display name, wake phrase)
2. Writes the skill folder to `~/.github/skills/<slug>/`
3. Appends auto-boot to `~/.github/instructions.md`
4. Creates `.agentic-os/` in the current project
5. Skips hook registration (not applicable)
6. Reports done

## Headless / scheduled runs

GitHub Copilot CLI does not have a headless print mode like `claude -p`. For unattended runs:

- **Use GitHub Actions.** The template at `harness/schedule/github-actions.yaml.template` is the recommended approach. It runs in CI, has built-in logging, timeouts, and failure notifications.
- **Local fallback.** `harness/bin/headless-copilot.sh` exists as a best-effort wrapper but is limited. Prefer GitHub Actions.

## Evaluator subagent

The evaluator runs without `context: fork` (not supported in Copilot CLI). Instead, the team-lead invokes the evaluator with explicit isolation instructions:

> "You are the evaluator. Ignore all prior reasoning about this objective. Read only verification.yaml and the deliverables. Judge fresh."

This is a prompt-level approximation of context isolation. It works well in practice but is not as strong as Claude Code's forked context.

## Uninstall

1. Delete `~/.github/skills/<your-os-name>/`
2. Remove the auto-boot block from `~/.github/instructions.md` (search for your OS name between sentinel markers)
3. Optionally delete `.agentic-os/` from your projects

## Questions

Ping Ragnar Pitla on LinkedIn: https://www.linkedin.com/in/ragnarpitla/
