# Upgrading from RAOS V1 (1.09) to V2 (2.0) — The Scaffold (GitHub Copilot CLI)

V2 is additive. Every V1 objective still works. What V2 adds is a durable harness called **The Scaffold** so the team can survive crashes, resume across sessions, run headless on a schedule, and self-verify through an independent evaluator agent.

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

### 2. Scaffold harness (hooks degraded on Copilot CLI)

The V2 design includes four hook scripts (PreToolUse, PostToolUse, Stop, UserPromptSubmit) for automatic tracing, checkpointing, kill switch, and circuit breaker. **GitHub Copilot CLI does not support these hooks.** Instead:

- The **team-lead prompt** includes explicit instructions to write checkpoints at phase boundaries
- The **kill switch** works via a KILL sentinel file the team-lead checks at phase boundaries
- The **circuit breaker** is a prompt-level instruction (pause after 3 consecutive errors)
- **Tracing** is manual — the team-lead notes key actions in the manifest

See [HOOKS-DEGRADED.md](HOOKS-DEGRADED.md) for the full breakdown.

For Claude Code users, the hooks work automatically via `harness/settings.json.fragment`.

### 3. Evaluator agent

`templates/agents/evaluator.agent.md` is a new agent that verifies deliverables independently. On Copilot CLI, it runs with explicit isolation instructions ("ignore all prior reasoning") rather than Claude Code's `context: fork`. After Synthesis, the team-lead invokes the evaluator with one parameter: the run directory. The evaluator reads `verification.yaml`, runs each criterion's `how_to_verify`, and returns pass/fail with evidence.

Three iterations max. If the third iteration returns `needs_revision`, team-lead escalates to the user (guidance bucket).

### 4. Scheduler templates

`harness/schedule/` ships three templates:

- `launchd.plist.template` — macOS
- `taskscheduler.xml.template` — Windows
- `github-actions.yaml.template` — cross-platform (**recommended for Copilot CLI**)

For Copilot CLI, GitHub Actions is the recommended approach for headless runs. See `harness/bin/headless-copilot.sh` for a best-effort local alternative.

### 5. New slash subcommands

- `/raos runs` — list all runs in `.agentic-os/runs/` with status and phase
- `/raos resume <run_id>` — continue a paused, verifying, or blocked run
- `/raos kill <run_id>` — drop a KILL sentinel; team-lead halts at next phase boundary

### 6. Observability-only budgets (by default)

The run manifest tracks tool-call count, wall-clock seconds, and estimated dollars. **Nothing blocks on these by default.** Counters exist for visibility. Flip `budgets.enforce: true` in a manifest if you want the team-lead to check caps before major actions.

Budget sizing guide:
- **Small** (single-specialist, < 1 hour): tool_calls ~50, wall_clock ~3600s
- **Medium** (multi-specialist, < 4 hours): tool_calls ~200, wall_clock ~14400s
- **Large** (full team, multi-day): tool_calls ~500, wall_clock ~86400s

### 7. New reference docs & recipes

- [references/the-scaffold.md](references/the-scaffold.md) — the thesis
- [references/run-lifecycle.md](references/run-lifecycle.md) — the six states and what happens at each
- [references/budgets-and-gates.md](references/budgets-and-gates.md) — observability model, circuit breaker, kill switch
- [references/recipes/headless-scheduled-run.md](references/recipes/headless-scheduled-run.md) — wiring launchd / Task Scheduler / GH Actions
- [references/recipes/resume-after-crash.md](references/recipes/resume-after-crash.md) — recovery playbook

## What stayed the same

- `.github/agents/` specialist layout
- The two-bucket rule (autonomous vs. guidance)
- Auth gates (pac-cli, Azure, GitHub, Dataverse, ADO, Copilot Studio specialists)
- `.agentic-os/` local memory (`memory.md`, `routines.md`, `os.txt`, `version.txt`)
- The 7-day self-improvement loop (now with explicit user-approval guardrails)
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
6. **Replaces** the auto-boot block in `~/.github/instructions.md` (via its named sentinel markers — same pattern as V1).
7. **Writes** the `harness/` folder, new templates, new evaluator agent, and new reference docs into the skill folder.

### Option C — run both side-by-side

You can install V2 under a different OS slug (e.g., `kumi-os-v2` next to `kumi-os`). Two auto-boot blocks in `~/.github/instructions.md`, keyed to different wake phrases.

## In-place migration script (manual fallback)

If you want to migrate without re-running the installer:

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

Then copy the V2 files into your skill folder at `~/.github/skills/<your-os-name>/`.

## Rollback

V1 installs don't go away when V2 is installed. To roll back:

1. Restore `.agentic-os/version.txt` to `1.09`.
2. Delete the V2-specific files from your skill folder: `harness/`, `templates/run.manifest.yaml.template`, `templates/verification.yaml.template`, `templates/agents/evaluator.agent.md`, and the new references.
3. Restore V1's `templates/team-lead.agent.md` from the V1 source.
4. Existing runs in `.agentic-os/runs/` stay. V1 ignores them.

## FAQ

**Q: Will my existing V1 `tasks.json` break?**
No. V2 adds optional `run_id` fields to tasks and objectives. V1 tasks without `run_id` are still valid.

**Q: Do I have to use the scheduler?**
No. It's opt-in. Interactive runs work the same as V1, just with a run manifest for durability.

**Q: What if I don't want the evaluator?**
You can't easily turn it off — it's how V2 decides "done" — but you can write minimal criteria if you want the evaluator to be fast.

**Q: Does V2 work on Windows?**
Yes. The Copilot CLI works on all platforms. For headless runs, GitHub Actions is cross-platform.

**Q: What breaks if I close my laptop mid-objective in V2?**
Nothing, if the team-lead wrote a checkpoint at the last phase boundary (which it's instructed to do). `/raos runs` shows the paused run and `/raos resume <run_id>` picks it up.

**Q: Are my V1 observations and routines still used?**
Yes. `memory.md` and `routines.md` are read by the team-lead on boot exactly as in V1.

**Q: What about the Claude Code hooks?**
They exist in `harness/hooks/` as reference implementations. On Copilot CLI they are inert. See [HOOKS-DEGRADED.md](HOOKS-DEGRADED.md).

## Version history

- **2.0** (2026-04-19) — The Scaffold (GitHub Copilot CLI Edition). Run manifests, evaluator agent, scheduler templates, `/raos resume|runs|kill` subcommands, observability-only budgets.
- **1.09** — Factory model. Personalized OS slug + wake phrase. Auto-boot keyed by OS name. (See V1 folder for full 1.x changelog.)
