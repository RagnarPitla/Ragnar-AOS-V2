# Upgrading from RAOS V1 (1.09) to V2 (2.0) — The Scaffold

V2 is additive. Every V1 objective still works. What V2 adds is a durable harness called **The Scaffold** so the team can survive crashes, resume across sessions, run headless on a schedule, and self-verify through an independent evaluator subagent.

![From Session to Scaffold](assets/From%20Session%20to%20Scaffold.png)

Nothing you liked about V1 goes away. The two-bucket rule, the 3-phase dispatch, the specialists, the `.agentic-os/` memory folder — all still in V2, unchanged.

## What's new in V2

### 1. Run manifest — durable state for every objective

Every `/raos <objective>` now creates `.agentic-os/runs/<run_id>/` with five files that carry the objective's full state across sessions:

```
manifest.yaml          status, phase, budgets, checkpoints, gates
trace.ndjson           every tool call, one JSON line per span
verification.yaml      criteria + evaluator iterations + evidence
checkpoint.json        latest snapshot (phase + tasks.json version)
costs.json             token/duration/$ rollups (estimates)
```

In V1, close your laptop mid-Synthesis and the team forgets what it was doing. In V2, `/raos resume <run_id>` picks up exactly where the team left off.

### 2. Four Claude Code hooks

V2 ships four pure-bash hooks that wire into Claude Code's native hook system:

| Hook             | File                                  | What it does                                                   |
| ---------------- | ------------------------------------- | -------------------------------------------------------------- |
| PreToolUse       | `harness/hooks/pre-tool-use.sh`       | Kill switch + optional budget enforcement + auth gate dispatch |
| PostToolUse      | `harness/hooks/post-tool-use.sh`      | Append span to trace.ndjson + bump counters + circuit breaker  |
| Stop             | `harness/hooks/stop.sh`               | Write checkpoint + roll up costs + update manifest             |
| UserPromptSubmit | `harness/hooks/user-prompt-submit.sh` | Detect `/raos resume` and `/raos kill`; banner active run      |

Hooks are registered via `harness/settings.json.fragment`, which the installer merges into `~/.claude/settings.json`.

Copilot CLI gets equivalent hooks where the runtime supports them, and logs `degraded` entries where it does not.

### 3. Evaluator subagent

`templates/agents/evaluator.agent.md` is a new subagent that runs with `context: fork` — its reasoning is isolated from the team-lead's. After Synthesis, the team-lead dispatches the evaluator with one parameter: the run directory. The evaluator reads `verification.yaml`, runs each criterion's `how_to_verify`, and returns pass/fail with evidence.

Three iterations max. If the third iteration returns `needs_revision`, team-lead escalates to the user (guidance bucket). Anthropic's research is clear: a builder asked to judge itself writes polite self-praise. A skeptic in a clean context doesn't.

### 4. Scheduler templates

`harness/schedule/` ships three templates, one per platform:

- `launchd.plist.template` — macOS
- `taskscheduler.xml.template` — Windows
- `github-actions.yaml.template` — cross-platform, works with Copilot CLI too

Each one wraps `harness/bin/headless.sh <project> <run_id>`, which is the single entry point for unattended runs.

### 5. New slash subcommands

- `/raos runs` — list all runs in `.agentic-os/runs/` with status and phase
- `/raos resume <run_id>` — continue a paused, verifying, or blocked run
- `/raos kill <run_id>` — drop a KILL sentinel; next tool call halts

### 6. Observability-only budgets (by default)

The run manifest tracks tool-call count, wall-clock seconds, and estimated dollars. **Nothing blocks on these by default** — Ragnar's team has no budget constraints. Counters exist for visibility. Flip `budgets.enforce: true` in a manifest if you want the PreToolUse hook to block on hard caps (useful for scheduled headless runs).

### 7. New reference docs & recipes

- [references/the-scaffold.md](references/the-scaffold.md) — the thesis
- [references/run-lifecycle.md](references/run-lifecycle.md) — the six states and what happens at each
- [references/budgets-and-gates.md](references/budgets-and-gates.md) — observability model, circuit breaker, kill switch
- [references/recipes/headless-scheduled-run.md](references/recipes/headless-scheduled-run.md) — wiring launchd / Task Scheduler / GH Actions
- [references/recipes/resume-after-crash.md](references/recipes/resume-after-crash.md) — recovery playbook

## What stayed the same

- `.claude/agents/` specialist layout
- The two-bucket rule (autonomous vs. guidance)
- Auth gates (pac-cli, Azure, GitHub, Dataverse, ADO, Copilot Studio specialists)
- `.agentic-os/` local memory (`memory.md`, `routines.md`, `os.txt`, `version.txt`)
- The 7-day self-improvement loop
- The factory model — each teammate still names their own OS slug
- Single-file installer distribution — the installer is still self-contained

## Migration from V1

If you're on V1 and want to upgrade to V2:

### Option A — fresh install on a new project

Easiest. Point your teammate at the V2 installer (`Ragnar-AgenticOS-setup.md` in this folder) and have them run it in a new project. They get V2 from day one.

### Option B — upgrade an existing V1 install in-place

The V2 installer detects V1 state and migrates safely. What it does:

1. **Reads** `.agentic-os/version.txt`. If `< 2.0`:
2. **Preserves** every existing file: `memory.md`, `routines.md`, `os.txt`, `tasks.json`. Nothing is deleted.
3. **Creates** `.agentic-os/runs/` (empty). Existing objectives stay in `tasks.json` without a `run_id`; new objectives get one.
4. **Appends** a migration note to `memory.md`: `"Upgraded to RAOS 2.0 (Scaffold) on <date>. Prior observations preserved. Run state from this point lives in .agentic-os/runs/."`
5. **Bumps** `version.txt` to `2.0`.
6. **Replaces** the auto-boot block in `~/.claude/CLAUDE.md` (via its named sentinel markers — same pattern as V1).
7. **Merges** `harness/settings.json.fragment` into `~/.claude/settings.json` so the four hooks are registered.
8. **Writes** the `harness/` folder, new templates (`run.manifest.yaml.template`, `verification.yaml.template`), new evaluator subagent, and new reference docs into the skill folder.

### Option C — run both side-by-side

You can install V2 under a different OS slug (e.g., `kumi-os-v2` next to `kumi-os`). Two auto-boot blocks in `~/.claude/CLAUDE.md`, keyed to different wake phrases. Try V2 on a new project while V1 handles your existing ones. When you're happy, swap the auto-boot blocks.

## In-place migration script (manual fallback)

If you want to migrate without re-running the installer, run these commands in the project root. You still need to copy the V2 files into your skill folder separately.

```bash
# 1. Preserve V1 state
cp -r .agentic-os .agentic-os.v1-backup

# 2. Create the runs folder
mkdir -p .agentic-os/runs

# 3. Bump version
echo "2.0" > .agentic-os/version.txt

# 4. Append migration note
cat >> .agentic-os/memory.md <<EOF

---
Upgraded to RAOS 2.0 (Scaffold) on $(date -u +"%Y-%m-%dT%H:%M:%SZ"). Prior observations preserved. Run state from this point lives in .agentic-os/runs/.
EOF
```

Then copy the V2 `harness/`, `templates/run.manifest.yaml.template`, `templates/verification.yaml.template`, `templates/agents/evaluator.agent.md`, updated `templates/team-lead.agent.md`, updated `commands/raos.md`, and new `references/the-scaffold.md` + `references/run-lifecycle.md` + `references/budgets-and-gates.md` + `references/recipes/headless-scheduled-run.md` + `references/recipes/resume-after-crash.md` into your skill folder, and merge `harness/settings.json.fragment` into `~/.claude/settings.json`.

## Rollback

V1 installs don't go away when V2 is installed. To roll back:

1. Restore `.agentic-os/version.txt` to `1.09`.
2. Remove (or comment out) the four hook entries in `~/.claude/settings.json` that V2 added.
3. Delete the V2-specific files from your skill folder: `harness/`, `templates/run.manifest.yaml.template`, `templates/verification.yaml.template`, `templates/agents/evaluator.agent.md`, and the new references.
4. Restore V1's `templates/team-lead.agent.md` from the V1 source (it still works; V2's edits were additive).
5. Existing runs in `.agentic-os/runs/` stay. V1 ignores them.

## FAQ

**Q: Will my existing V1 `tasks.json` break?**
No. V2 adds optional `run_id` fields to tasks and objectives. V1 tasks without `run_id` are still valid.

**Q: Do I have to use the scheduler?**
No. It's opt-in. Interactive runs work the same as V1, just with a run manifest for durability.

**Q: What if I don't want the evaluator?**
You can't easily turn it off — it's how V2 decides "done" — but you can tune `verification.yaml.max_iterations` or write minimal criteria if you want the evaluator to be fast. The real answer is: the evaluator is the quality lever. If you're skipping it, you're back to V1's "team-lead judges its own work" mode.

**Q: Does V2 work on Windows?**
Yes. Hooks are bash, which means Windows users need Git Bash or WSL. The Task Scheduler template invokes `bash.exe` to run hook scripts.

**Q: What breaks if I close my laptop mid-objective in V2?**
Nothing. The Stop hook writes a checkpoint on session end. Next time you open Claude Code in the same project, `/raos runs` shows the paused run and `/raos resume <run_id>` picks it up.

**Q: Are my V1 observations and routines still used?**
Yes. `memory.md` and `routines.md` are read by the team-lead on boot exactly as in V1. V2 adds a new data source (runs); it doesn't remove any.

## Version history

- **2.0** (2026-04-19) — The Scaffold. Run manifests, 4 hooks, evaluator subagent, scheduler templates, `/raos resume|runs|kill` subcommands, observability-only budgets.
- **1.09** — Factory model. Personalized OS slug + wake phrase. Auto-boot keyed by OS name. (See V1 folder for full 1.x changelog.)
