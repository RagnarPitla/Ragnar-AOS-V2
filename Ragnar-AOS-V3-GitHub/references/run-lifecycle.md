# Run lifecycle

Every objective in V2 becomes a run. A run has six states. The team-lead drives the transitions. The hooks record them. The evaluator decides when synthesis is actually done.

![Run Lifecycle](../assets/Run%20Lifecycle.png)

## The six states

```
accepted → running → verifying → done
                   ↘           ↗
                    paused ───┘
                        ↘
                       killed / blocked / failed
```

| Status     | Meaning |
|------------|---------|
| accepted   | Team-lead has parsed the objective and written the manifest. No work done yet. |
| running    | A phase is active (Research, Challenge, or Synthesis). Trace is filling. |
| verifying  | Synthesis has stopped claiming done. The evaluator is judging against verification.yaml. |
| paused     | A circuit breaker tripped, or the user closed the session mid-Synthesis. Resumable. |
| done       | Evaluator returned `pass`. Team-lead reported to the user. Manifest is closed. |
| killed     | User dropped a KILL sentinel. Not resumable without removing it. |
| blocked    | A guidance-bucket gate is waiting on the user. Resumable once answered. |
| failed     | Evaluator returned `needs_revision` three times. Team-lead escalated to user. |

## What happens at each step

### 1. Accept

User says `/raos <objective>`. Team-lead parses into the structured objective shape and, with the user's nod, writes:

- `.agentic-os/runs/<run_id>/manifest.yaml` (from `templates/run.manifest.yaml.template`)
- `.agentic-os/runs/<run_id>/verification.yaml` (from `templates/verification.yaml.template`, populated with SUCCESS LOOKS LIKE)
- `.agentic-os/runs/.active` pointing to `<run_id>`
- Creates `.agentic-os/runs/<run_id>/gates/` directory

Manifest `status: accepted`, `current_phase: research`.

### 2. Research → Challenge → Synthesis

Same 3-phase loop as V1. Team-lead updates `current_phase` in the manifest as it transitions. Every tool call any agent makes lands as a NDJSON line in `trace.ndjson`. Every failure triggers the circuit breaker check in `post-tool-use.sh`.

On phase transition, team-lead appends a named checkpoint to `manifest.checkpoints[]`:

```yaml
checkpoints:
  - { ts: "2026-04-19T14:30:00Z", phase: "research",  note: "phase complete" }
  - { ts: "2026-04-19T15:10:00Z", phase: "challenge", note: "phase complete" }
```

The Stop hook also appends an auto checkpoint whenever the session stops (In Claude Code this fires automatically via hooks / In GitHub Copilot CLI the team-lead writes checkpoints at phase boundaries — see [HOOKS-DEGRADED.md](../HOOKS-DEGRADED.md)). That's why a crashed session still has a recent checkpoint to resume from.

### 3. Verify

When Synthesis believes it's done, team-lead does NOT declare done. It:

1. Sets `status: verifying`.
2. Dispatches the `evaluator` subagent in a forked context.
3. Hands the evaluator one instruction and one parameter: `RUN_DIR=<absolute path>`.

The evaluator reads `verification.yaml`, runs each criterion's `how_to_verify`, records verdicts + evidence, appends an iteration entry, and returns a one-line verdict.

If the evaluator returns `pass`, team-lead sets `status: done`, appends a final gate entry (`kind: verification, decision: pass`), and reports to the user with the evidence summary.

If the evaluator returns `needs_revision`, team-lead reads the failing criteria, re-enters Synthesis with a targeted brief (only the failing ids, with their evidence), and dispatches the evaluator again when done.

### 4. Iterate (up to 3 times)

Each evaluator pass is one iteration. The max is 3, set in `verification.yaml.max_iterations`. On iteration 3 returning `needs_revision`, team-lead stops iterating and escalates to the user: a guidance-bucket action. The user decides whether to extend the cap, re-scope the objective, or accept partial delivery.

### 5. Resume

User runs `/raos resume <run_id>`. The UserPromptSubmit hook marks the run active and banners the manifest path, current phase, and status to the team-lead. Team-lead reads the manifest, the latest checkpoint, and the recent trace tail, then continues from `current_phase`.

No special logic for "recovered vs. fresh" — the team-lead is stateless; the files are the state.

### 6. Close

A closed run (done, killed, failed) stays in `.agentic-os/runs/`. Nothing auto-deletes. Each run is a permanent record you can read, grep, replay, or feed back into `memory.md` as a learned pattern. This is why traces are NDJSON: you can grep across every run the team has ever completed.

## What each hook writes, at what step

| Hook | Step | File it touches |
|------|------|-----------------|
| UserPromptSubmit | on `/raos resume` | `.agentic-os/runs/.active` |
| UserPromptSubmit | on `/raos kill`   | `<run_dir>/KILL` |
| PreToolUse       | before every tool call | reads `KILL`, reads manifest (budget check if enforced) |
| PostToolUse      | after every tool call | appends to `trace.ndjson`, bumps counters, may flip `status: paused` |
| Stop             | on session stop (Claude Code: automatic hook / GitHub Copilot CLI: team-lead driven) | writes `checkpoint.json`, appends to `manifest.checkpoints[]`, runs `costs.sh` |

## The one invariant

**If an objective is active, a run folder exists.** No orphan objectives. No in-memory state. Kill the laptop at any moment and `/raos resume` works. The Scaffold has no state that isn't in a file.
