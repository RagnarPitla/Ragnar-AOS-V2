# Hooks Degraded Mode — GitHub Copilot CLI

GitHub Copilot CLI does **not** support the Claude Code hook system (PreToolUse, PostToolUse, Stop, UserPromptSubmit). This document explains what each hook did and what manual alternatives exist.

## What the Claude Code hooks did

| Hook | File | What it did automatically |
|---|---|---|
| **PreToolUse** | `harness/hooks/pre-tool-use.sh` | Checked for a KILL sentinel file before every tool call (kill switch). Optionally enforced budget caps. Dispatched auth gate checks for production-affecting tools. |
| **PostToolUse** | `harness/hooks/post-tool-use.sh` | Appended a span to `trace.ndjson` after every tool call (automatic tracing). Bumped tool-call counters in the manifest. Triggered the circuit breaker if error rate exceeded threshold. |
| **Stop** | `harness/hooks/stop.sh` | Wrote a checkpoint to `checkpoint.json` on session end. Rolled up costs from the trace into `costs.json`. Updated the manifest with final phase/status. |
| **UserPromptSubmit** | `harness/hooks/user-prompt-submit.sh` | Detected `/raos resume <run_id>` and `/raos kill <run_id>` commands before they reached the agent. Displayed an active-run banner. Marked runs active/killed. |

## What's lost in Copilot CLI

1. **Automatic tracing** — Tool calls are not automatically logged to `trace.ndjson`. The team-lead must manually note key actions in the manifest or trace file.
2. **Kill switch enforcement** — No automatic pre-tool-call check for a KILL sentinel. The user must tell the team-lead to stop, or cancel the session.
3. **Circuit breaker** — No automatic error-rate detection. The team-lead must notice repeated failures and pause.
4. **Automatic checkpointing** — No session-end hook to write `checkpoint.json`. The team-lead prompt includes instructions to write checkpoints at phase boundaries.
5. **Auth gate dispatch** — No automatic routing of production-affecting tool calls through auth checks. The team-lead and specialists must follow the guardrails in `instructions.md` manually.
6. **Budget enforcement** — No automatic blocking when budget caps are hit. Budgets are observability-only; the team-lead tracks them manually.

## Manual alternatives

| Lost capability | Manual alternative |
|---|---|
| Kill switch | Tell the team-lead "stop" or cancel the Copilot session. To pre-set a kill, create `.agentic-os/runs/<run_id>/KILL` manually; the team-lead checks for it at phase boundaries. |
| Tracing | The team-lead writes checkpoint entries at each phase boundary. For full tracing, run `harness/bin/trace-to-sqlite.sh` on any manually-maintained trace file. |
| Checkpointing | The team-lead writes `checkpoint.json` at every phase transition (built into the team-lead prompt). |
| Cost rollup | Run `harness/bin/costs.sh` manually after a run completes. |
| Circuit breaker | The team-lead is instructed to pause after 3 consecutive errors and escalate to the user. |
| Auth gate | Specialists are instructed to verify auth before production writes (same as always; just not auto-enforced). |

## For headless/scheduled runs

Headless mode in Copilot CLI is best achieved through **GitHub Actions** using `harness/schedule/github-actions.yaml.template`. GitHub Actions provides its own job logging, timeout enforcement, and failure notifications — covering most of what the hooks provided.

## The harness/hooks/ folder

The hook scripts in `harness/hooks/` are **Claude Code only**. They remain in the repository as reference implementations. If you migrate to Claude Code, they will work with the `settings.json.fragment` hook registration. On Copilot CLI, they are inert.

## Version

2.0 (2026-04-19). GitHub Copilot CLI degraded-hooks documentation.
