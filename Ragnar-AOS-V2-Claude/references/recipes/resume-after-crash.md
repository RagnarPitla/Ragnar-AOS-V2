# Recipe: resume after crash

Laptop hibernated. Claude Code froze and you killed it. SSH dropped mid-run. Whatever the reason, the session ended without `status: done`. The Scaffold is designed for this.

## The short version

```bash
cd <project>
/raos resume <run_id>
```

That's it. The team-lead reads the manifest, the latest checkpoint, and the recent trace tail, and continues from `current_phase`.

## What if I don't remember the run_id

```bash
/raos runs
```

Lists every run in `.agentic-os/runs/` with its status, current phase, and last updated timestamp. Most recent first. Pick the one you want.

You can also browse manually:

```bash
ls -lt <project>/.agentic-os/runs/
cat <project>/.agentic-os/runs/<run_id>/manifest.yaml | head -20
```

## What happens inside `/raos resume`

1. UserPromptSubmit hook sees `/raos resume <run_id>`. Writes `<run_id>` to `.agentic-os/runs/.active`. Prints a banner with the run's current phase + status.
2. Team-lead reads:
   - `manifest.yaml` — status, current_phase, budgets, recent gates, recent checkpoints
   - `checkpoint.json` — the latest snapshot (phase + tasks.json version + last trace line)
   - `verification.yaml` — if the run was in `verifying`, this tells team-lead what the evaluator last said
   - `trace.ndjson` tail (~50 lines) — recent tool calls so team-lead knows what just happened
3. Team-lead announces: "Resuming <run_id>. Last phase was <X>. Last evaluator verdict was <Y>. Continuing with <Z>."
4. Work resumes from `current_phase`. No re-decomposition, no re-prompting the user.

## When resume won't work cleanly

### Status is `killed`

Deliberate. Delete the KILL sentinel first, then resume:

```bash
rm <project>/.agentic-os/runs/<run_id>/KILL
/raos resume <run_id>
```

### Status is `blocked`

A guidance-bucket gate is waiting on you. Read the most recent `gates[]` entry with `decision: deferred` to see what the team is asking. Answer it in your next message to the team-lead and work resumes.

### Status is `failed`

The evaluator hit the iteration cap. The run is closed. You have three choices:

1. **Re-scope the objective.** Edit `verification.yaml` to relax the failing criteria, set `status: verifying` back in the manifest, and resume. The evaluator will judge the next Synthesis pass against the new criteria.
2. **Extend the cap.** Edit `verification.yaml` `max_iterations` to 5 or 6, flip `status` back, and resume.
3. **Abandon.** Leave it `failed`. The run record stays as a permanent artifact you can learn from.

### `tasks.json` has advanced since the last checkpoint

Someone (or another session) updated tasks.json. The manifest's `linked_tasks_version` won't match. Team-lead will detect this on resume and pause to reconcile:

> "Resuming <run_id>, but tasks.json has advanced (version N → M). Last known changes: <diff summary>. Should I incorporate these into the current Synthesis or treat them as a separate objective?"

Answer in normal conversation. Team-lead updates `linked_tasks_version` after reconciliation.

### The run folder is missing

Either the folder was deleted, or you're in the wrong project directory. `ls .agentic-os/runs/` in the project root will tell you which.

## Partial-credit recovery

If the laptop died mid-Synthesis and the work-in-progress is genuinely lost (no files written before the crash), the trace still has spans for every tool call that completed. Team-lead can read the trace tail and reconstruct the "what I had just done" picture before crashing. You won't lose the plan. You will lose the half-formed next step.

## The guarantee

As long as:

- The run folder exists (`.agentic-os/runs/<run_id>/`), and
- `manifest.yaml` is readable,

…resume works. No daemon, no database, no network. Files on disk are the whole state.
