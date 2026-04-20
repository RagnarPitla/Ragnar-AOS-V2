# Recipe: Spec → Critique → Implement

**Pattern:** Write the spec before the code. Critique the spec adversarially. Implement against the final spec. Maps directly onto the 3-phase pattern (Research → Challenge → Synthesis).

**When to use:** Any objective big enough to warrant 15+ minutes of execution. Small mechanical tasks don't need this. but "ship a feature," "fix this class of bug," "make X better" all do.

**Plug into your team lead:** Already baked into the 3-phase pattern. This recipe explains WHY that pattern works, and the sub-pattern that makes the Challenge phase effective.

---

## The three steps

### 1. Spec (Research output reshaped)

A spec is the objective plus enough shared context that any specialist could pick it up cold and know what to do. Written by cli-lead after Research completes.

A good spec answers:
- What's the outcome?
- What's the constraint set (success criteria, must-not-break)?
- What's the current state (from Research)?
- What interfaces change, what stays?
- What's out of scope?
- What's the verification plan?

Bad specs skip "what's the current state" or "what's out of scope" and produce scope creep.

### 2. Critique (Challenge phase)

Before writing code, assume the spec is wrong. Find the failure modes.

Three critique angles:
- **Assumption audit:** List every assumption in the spec. Which are load-bearing? If any one is false, does the spec fall?
- **Cheapest invalidation path:** What's the fastest way to prove this won't work? Check migration history, run a quick prototype, ask the specialist who last touched the area.
- **Skeptic's voice:** Imagine the teammate who always pushes back. What would they flag? What past similar project failed and why?

Critique output: a shortlist of risks + either "spec is good, proceed" or "spec needs changes. here they are."

If critique reveals a problem the spec can't absorb, loop back to Research or surface as guidance.

### 3. Implement (Synthesis phase)

Now, and only now, specialists execute. The spec is a contract. they build to it, not to their own invented interpretation. If a specialist finds something that contradicts the spec mid-run, they stop and escalate (don't silently deviate).

At the end, verification checks the deliverable against the spec. If it passes, report done. If not, targeted fix. don't rewrite.

---

## Why this order matters

Going straight from "build it" to code leads to:
- Scope creep (no explicit out-of-scope).
- Rework (you find mid-build that an assumption was wrong).
- Disagreement on "done" (no shared success criteria).

Spec-Critique-Implement front-loads the thinking. The spec is cheap to iterate; code is expensive. Critique catches the dumb mistake when it's still words. Implement runs smoothly because everyone knows the target.

---

## Example: converting a task into a spec

Raw task: "The React dashboard is slow."

Bad: immediately dispatch a frontend specialist to "fix performance." They'll thrash.

Spec-Critique-Implement:

**Spec** (after Research phase):
```
OUTCOME: Dashboard initial load time under 2s on mid-tier hardware.

CURRENT STATE: Initial load averages 6s. Slowest paths:
  - 3 network calls in serial (2.1s total)
  - Large JSON parse blocking main thread (1.5s)
  - Unoptimized SVG render (0.8s)

CONSTRAINT: Must not break existing tests. Must not require backend API changes.

OUT OF SCOPE: Offline mode. Re-architecting state management.

VERIFICATION: Measure load time against test dataset. Ship if ≤2s, loop if >2s.
```

**Critique** (Challenge phase):
- Assumption "the three network calls are independent" → true (checked React DevTools).
- Assumption "the JSON parse is the bottleneck" → load-bearing. Is the JSON necessarily large? Yes. data shape is fixed by backend. Don't try to shrink it.
- Skeptic: "Have we checked if the SVG is actually slow on target hardware, or just on the dev machine?" → good catch. Add one verification measurement on a slow laptop before optimizing SVG.

**Implement** (Synthesis phase):
- Specialist A: parallelize the three network calls.
- Specialist B: move JSON parse to web worker.
- Specialist C: conditionally optimize SVG only if slow-laptop measurement confirms it matters.
- Review + verify: measure on target hardware. Ship.

Result goes from "make it fast" (vague, high-risk) to three well-scoped changes with verification. Same or less wall-clock time, dramatically higher confidence.

---

## When to skip

Pure mechanical work (rename, format, bump version) doesn't need this. The critique would be theater.

Exploratory work ("I don't know what I want yet") doesn't need this. you don't have a spec to write. Run Stage 1 or Stage 2 mode until the direction clarifies, then promote to a real objective.
