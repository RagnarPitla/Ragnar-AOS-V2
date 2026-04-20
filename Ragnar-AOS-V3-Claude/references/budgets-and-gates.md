# Budgets, gates, and the kill switch

The Scaffold is conservative by default. It watches. It doesn't interrupt unless you ask it to.

![The Hook Path](../assets/The%20Hook%20Path.png)

## Budgets: observability first

Every run manifest has a `budgets` block:

```yaml
budgets:
  enforce: false
  tool_calls:   { soft: 150,  hard: 300,   used: 0 }
  wall_clock_s: { soft: 1800, hard: 7200,  used: 0 }
  dollars:      { soft: 5.00, hard: 20.00, used: 0.00 }
```

The PostToolUse hook bumps `used` after every tool call. That's the observability loop. The counters tell you how much the team is spending, without stopping the team.

Set `enforce: true` in the manifest and the PreToolUse hook flips into enforcer mode: it reads `tool_calls.used` before each call and exits 2 if it's at or above `hard`. The tool call fails with a clear message pointing at the manifest.

### When to flip enforcement on

Most of the time: don't. Ragnar's team doesn't have a budget problem. Observability is enough — you read `manifest.yaml` or `costs.json` and see how much the run is spending.

Flip enforcement on when:

- You're running **headless on a schedule** and want a circuit breaker of last resort. A bad run won't turn into a $500 surprise.
- You're **handing the skill to a new teammate** and want guardrails while they learn what "normal" spend looks like for their objectives.
- You're **benchmarking** two approaches and want hard stops to make them comparable.

### Soft vs. hard

Soft caps are advisory. The Scaffold doesn't block on them. The team-lead can read soft caps and decide to surface a warning to the user, but it's not wired to a hook by default. Hard caps are the enforcement line when `enforce: true`.

## Gates: the two-bucket rule, now durable

V1's two-bucket rule lived in the team-lead's prompt. V2 keeps it there, and adds a durable record: every gate decision lands in `manifest.gates[]`:

```yaml
gates:
  - { ts: "2026-04-19T14:30:00Z", kind: "auth",         bucket: "autonomous", decision: "pass",     note: "pac auth verified for env contoso-dev" }
  - { ts: "2026-04-19T15:02:00Z", kind: "approval",     bucket: "guidance",   decision: "deferred", note: "user asked about destructive PR merge" }
  - { ts: "2026-04-19T15:05:00Z", kind: "approval",     bucket: "guidance",   decision: "pass",     note: "user approved merge" }
  - { ts: "2026-04-19T15:40:00Z", kind: "verification", bucket: "autonomous", decision: "pass",     note: "evaluator iteration 2 passed all criteria" }
```

Four gate kinds:

- **auth** — an integration specialist (pac-cli, azure, github, ado) verified environment or credentials before a destructive action.
- **approval** — a guidance-bucket action was escalated to the user. `decision: deferred` means waiting; `pass` or `fail` means answered.
- **verification** — evaluator returned a verdict on an iteration.
- **kill** — user dropped a KILL sentinel; team-lead halted.
- **circuit_breaker** — post-tool-use.sh detected 3 consecutive failures of the same tool; run auto-paused.

Why durable gates matter: when you resume a run three days later, the gates tell you what the team stopped for and what it promised the user. You don't have to reread the conversation.

## Auth gates: fail-closed, by file

Auth gates are gate files, not prompts. When an integration specialist starts work, it drops a pending sentinel:

```
.agentic-os/runs/<run_id>/gates/auth-pac.pending
.agentic-os/runs/<run_id>/gates/auth-az.pending
```

The PreToolUse hook checks these files when it sees `pac ` or `az ` in the tool input. If the sentinel exists, the tool call is blocked until the specialist verifies the environment and deletes the file. This is V1's pattern — made durable by living in the run folder instead of the team-lead's prompt.

## Circuit breaker: automatic pause on repeated failures

`post-tool-use.sh` tails the last 3 spans in `trace.ndjson`. If all three are the same tool and all three have non-zero exit codes, it sets `status: paused` in the manifest and writes a `circuit_breaker` entry to the trace.

The team-lead sees `status: paused` on its next turn (via the UserPromptSubmit hook's banner) and surfaces to the user: "I've tripped the circuit breaker on <tool>. Three failures in a row. Here's what I was trying: <excerpt from trace>. Should I change approach, escalate, or retry?"

The user's answer is recorded as a guidance gate. On `pass`, team-lead flips status back to `running` and continues.

## Kill switch: the override

A KILL sentinel is the atomic bomb. If you want to stop a run immediately — including a scheduled headless run — drop a file:

```bash
echo "stopping at $(date)" > .agentic-os/runs/<run_id>/KILL
# or use the command:
/raos kill <run_id>
```

The next tool call the PreToolUse hook sees will exit 2 with a clear message. No cleanup is attempted. No graceful shutdown. The run enters `killed` state and stays there until you delete the KILL sentinel. Resuming a killed run requires removing the file first — that's intentional friction so "I told it to die" can't be accidentally undone.

## What this doesn't protect against

- **Prompt injection.** If a tool returns output that tells the team-lead to ignore the verification.yaml, the Scaffold doesn't catch that. Your prompts are still your own problem.
- **Bad criteria.** If `verification.yaml` doesn't include a criterion that matters, the evaluator can't judge it. Garbage in, confident pass out.
- **A truly broken tool.** If `pac ` crashes cleanly with exit 0, none of the gates will trigger. The tool must actually return non-zero for the circuit breaker to fire.

The Scaffold is a safety net. The team-lead and the specialists are still the pilots.

---

## Budget sizing guidance

Use these as starting points when setting soft/hard caps. Actual costs depend on model, context length, and tool density.

| Objective size | Example | Tool calls (soft/hard) | Estimated cost |
|---|---|---|---|
| **Small** | README rewrite, single-file refactor | 30 / 50 | ~$1 |
| **Medium** | Feature build, API endpoint + tests | 100 / 150 | ~$3–5 |
| **Large** | Multi-specialist objective, full module | 200 / 300 | ~$5–15 |

**Headless runs:** Always set `enforce: true` with conservative hard caps. A runaway headless objective has no human watching — the hard cap is your only circuit breaker. Start with the "Medium" numbers and adjust after your first few runs.
