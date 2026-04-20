# The Scaffold

RAOS V1 got you to Stage 2 reliably. Stage 3 worked if you never closed your laptop. Stage 4 was always the stated horizon but never the everyday reality.

The Scaffold is the missing piece. It's the thin OS layer around the agent loop that makes Stage 3 survive across sessions and makes Stage 4 tractable on a cron.

![Separate the Builder from the Judge](../assets/Separate%20the%20Builder%20from%20the%20Judge.png)

## What it is

A directory. That's it. The Scaffold lives at `.agentic-os/runs/<run_id>/` inside your project. Every objective you accept gets its own run folder. Inside, five small files carry all the state an agent needs to pick up where it left off:

```
.agentic-os/runs/<run_id>/
├── manifest.yaml          the run's brain: status, phase, budgets, checkpoints, gates
├── trace.ndjson           append-only log of every tool call, one JSON line per span
├── verification.yaml      the contract: criteria, evaluator iterations, evidence
├── checkpoint.json        the latest snapshot (phase + tasks.json version)
├── costs.json             token/duration/$ rollups (estimates only)
└── gates/                 pending auth or approval sentinels
```

Four Claude Code hooks keep those files current:

- `PreToolUse` — kill switch, optional budget enforcement, auth gate dispatch
- `PostToolUse` — append to trace.ndjson, increment counters, circuit breaker
- `Stop` — write checkpoint, update manifest, roll up costs
- `UserPromptSubmit` — detect `/raos resume` and `/raos kill`, banner the active run

One new subagent, `evaluator`, runs in a forked context and judges whether the work met the verification contract. It is separated from the team-lead on purpose: a builder asked to critique itself writes polite self-praise. A skeptic in a clean context doesn't.

That's the whole Scaffold. No daemons. No databases. No new dependencies.

## Why it belongs here

The 4-Stages model already named the gap. Stage 3 asked the team to own the whole objective. The team did, within one session. Across sessions, the state evaporated. Across days, the team couldn't resume. The team-lead had no durable memory of what the objective was, what phase it was in, or what the evaluator had already rejected.

The Scaffold doesn't change the team's shape. cli-lead still orchestrates. Specialists still do the work. The two-bucket rule still gates destructive actions. What changes is that the team now has a clipboard. The clipboard survives. You can walk away, come back tomorrow, and say `/raos resume niyam-returns-20260419-1432` and the team picks up inside Synthesis, not from scratch.

Stage 4 follows for free. Once state is durable, the difference between "I'll run this again after lunch" and "launchd will run this every hour" is a plist file. The same resume command. No new runtime.

## What it is not

- **Not a framework.** It composes Claude Code's existing primitives (subagents, skills, hooks, `context: fork`, `/loop`). It replaces nothing.
- **Not an enforcer.** Budgets are observability-only by default. The Scaffold watches. It doesn't interrupt unless you flip `budgets.enforce: true` in a manifest.
- **Not a dashboard.** NDJSON traces are grep-able by humans and by Claude. If you want a UI, `harness/bin/trace-to-sqlite.sh` gets you one query away.
- **Not a scheduler.** It ships schedule templates (launchd, Windows Task Scheduler, GitHub Actions) but does not install them. You decide when headless runs happen.

## The contract the Scaffold enforces

One rule: **every objective becomes a run.**

The team-lead writes a manifest when it accepts an objective. From that moment, every tool call the team makes is traced, every phase transition is checkpointed, every gate decision is recorded, and every verification pass is judged by the evaluator against a written contract. When the team-lead reports "done," there is evidence, timestamped, in the run folder. When the team-lead reports "blocked," there is a gate entry explaining what it's blocked on.

Stage 2 worked because you could see the team think. Stage 3 works because the team's thinking outlives the session. That's the whole Scaffold.

## How to read the rest of V2

- [run-lifecycle.md](run-lifecycle.md) — the precise sequence: accept → research → challenge → synthesis → evaluate → done, with what each hook writes at each step.
- [budgets-and-gates.md](budgets-and-gates.md) — the observability model, the kill switch, the circuit breaker, and when to flip enforcement on.
- [recipes/headless-scheduled-run.md](recipes/headless-scheduled-run.md) — wiring a launchd, Task Scheduler, or GitHub Actions job to resume a run without a human in the room.
- [recipes/resume-after-crash.md](recipes/resume-after-crash.md) — what to do when your laptop dies mid-Synthesis.

## One-line mental model

The Scaffold is the clipboard your team never had. Everything else is a file.
