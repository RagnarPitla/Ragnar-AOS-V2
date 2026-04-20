# The 3-Phase Execution Pattern

Every objective decomposes into three phases. Skip one only if you can justify it in writing.

```
Objective → Research → Challenge → Synthesis → Verification → Result
```

---

## Phase 1: Research

**Goal:** build shared context. No solutions yet.

The Team Lead dispatches Explore agents (or project specialists in read-only mode) to gather what's actually in the codebase, the docs, and the surrounding systems. Parallel where possible. multiple areas at once, one agent per area.

**Output:** a "what is" brief. Three sections:
- What exists today (files, behaviors, constraints)
- What's unknown or assumed (flagged, to be verified)
- What the objective specifically needs to touch

**What Research is NOT:**
- Proposing solutions ("we should rewrite the auth layer").
- Writing code.
- Deciding scope.

Research is the map. Challenge picks the route. Synthesis walks it.

---

## Phase 2: Challenge

**Goal:** kill the objective before we invest.

The Team Lead dispatches a Plan agent plus one adversarial sweep. The prompt: "assume this objective will fail. what breaks it? What's the cheapest path to invalidate it?"

Three questions the Challenge phase must answer:
1. **What assumptions are we making?** List them. Are they load-bearing? If any one falls, the objective falls.
2. **What's the cheapest way to prove the approach wrong?** (Type-check first. Read the migration history. Ask the specialist who touched this last.)
3. **What would a skeptic on our team say?** Imagine the colleague who pushed back on the last plan. What would they flag?

**Output:** a shortlist of risks and a recommended approach. Not a plan. a plan comes in Synthesis. A direction.

**What Challenge is NOT:**
- Procedural "list all risks" theater. The point is to find the risk that actually matters and either mitigate it or kill the objective.
- Rewriting Research. If Challenge discovers missing context, loop back to Research. don't wing it.

---

## Phase 3: Synthesis

**Goal:** build the deliverable.

Project specialists execute. The Team Lead sequences and merges. Parallel where specialists own disjoint surfaces; sequential where they don't.

Rules during Synthesis:
- **One owner per file.** If two specialists need the same file, cli-lead sequences them.
- **Tasks.json updates in real time.** The user's `/raos status` must reflect reality.
- **Failure is a signal, not a stop.** A specialist hitting a wall escalates to cli-lead. cli-lead decides: loop back to Research, re-Challenge, or surface a guidance-bucket question to the user.

**Output:** a deliverable that the verification gate can check. Not "we've made progress." A thing that can be evaluated against SUCCESS LOOKS LIKE.

---

## The verification gate

Before reporting done, cli-lead runs each success criterion against the deliverable. For each:

- **Evidence attached** (file path, test output, measurement, screenshot).
- **Pass/fail** stated clearly.
- **If fail:** loop back to Synthesis with a targeted fix. Do not hand the user a draft and call it done.

If Synthesis can't close the gap without guidance-bucket decisions, cli-lead surfaces the specific decision to the user. "I can complete this by X or Y. X is faster but has trade-off Z. Which do you want?". this is a feature, not a failure.

---

## When to skip a phase

Each phase has real cost. Sometimes skipping is correct. Write the justification in tasks.json so future-you can audit.

- **Skip Research if:** objective is tightly scoped to a single file you just edited.
- **Skip Challenge if:** the objective is mechanical (rename, format, bump version) with no judgment calls. Note: "mechanical" is a high bar. most work has hidden judgment.
- **Skip Synthesis-as-parallel if:** the objective is small enough for one specialist. Still run the phase; just don't fan out.

The verification gate is never skipped. If you cannot verify it, you have not delivered it.

---

## Example trace

> Objective: Make the README clearer for new contributors so a first-time reader can set up the project locally without asking for help.

**Research** (parallel, 2 agents, ~2 min):
- Agent A: Explore current README, extract every instruction.
- Agent B: Scan docs/, git history, README evolution.
- Output: Current README has 4 install steps, 2 of which assume prior knowledge. Git log shows three recent contributors asked for help.

**Challenge** (1 agent, ~1 min):
- Plan: What would a first-timer stumble on? Answer: the ENV setup step assumes a specific shell config. The first-run command mentions a service that isn't documented elsewhere.
- Output: Two load-bearing assumptions. Recommended approach: rewrite these two sections + add a verification step.

**Synthesis** (sequential, 2 specialists, ~5 min):
- docs-writer: Rewrites README with the two fixes plus a "verify your setup" command.
- reviewer: Runs through the new README on a fresh clone.
- Output: Updated README + clean setup log.

**Verification:**
- Criterion 1 "README covers install + env + first-run + gotcha" → ✅ (new README has all four sections)
- Criterion 2 "Every command runs cleanly on fresh clone" → ✅ (reviewer's log)
- Criterion 3 "No broken links or stale paths" → ✅ (link check passed)
- **Status:** done. Reported to user with the new README diff and the verification log.

Total user interaction: one confirmation at the parsed objective, one review of the final diff. The user did not prompt anything during the run.

That is the 3-phase pattern working.
