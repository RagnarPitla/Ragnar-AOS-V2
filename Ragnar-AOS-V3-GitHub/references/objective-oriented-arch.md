# Objective-Oriented Architecture

**Why the Team Lead owns execution, not the user.**

---

## The shift

Task-oriented systems put the user in the loop of every decision. Objective-oriented systems let the Team Lead run the loop and surface only what matters.

| Task-oriented | Objective-oriented |
|---|---|
| User prompts → AI responds → user integrates | User sets objective → team executes → delivers result |
| User decomposes | Team Lead decomposes |
| User reviews every step | User reviews the final deliverable |
| User re-prompts on miss | Team Lead iterates internally |
| Pace = user's typing speed | Pace = Team Lead's dispatch speed |

The user's attention is the scarcest resource in the system. Objective-oriented architecture protects it.

---

## Three principles

### 1. The Team Lead is the only user-facing surface

The user never talks to the frontend specialist, the pac-cli specialist, the Researcher. They talk to cli-lead. cli-lead translates intent into dispatch, merges results, runs verification, reports.

Why: user mental model stays simple. "I set the goal. The team runs it." If the user ever finds themselves prompting a specialist directly, the architecture has leaked. route through cli-lead.

### 2. The Team Lead auto-approves within the autonomous bucket

The user defines the autonomous and guidance buckets once, in the project instructions file (In Claude Code: `CLAUDE.md` / In GitHub Copilot CLI: `instructions.md`), during bootstrap. After that, cli-lead makes decisions without asking, as long as they're in the autonomous bucket.

- Reading files? Autonomous.
- Running tests? Autonomous.
- Editing code on a feature branch? Autonomous.
- Writing docs? Autonomous.
- Force-pushing? Guidance.
- Spending money? Guidance.
- Changing the objective's scope? Guidance.

Why: if the Team Lead asks the user about every edit, the architecture has collapsed back to task-oriented. The user set the objective. trust the Team Lead to pursue it within the bucket.

### 3. Results, not drafts

A draft is when the Team Lead returns work with "is this what you wanted?" A result is when the Team Lead returns work with "here is what I did, here is the evidence it meets your success criteria, here is what's next."

The difference is verification. Before reporting done, the Team Lead runs each SUCCESS LOOKS LIKE criterion against the deliverable and attaches evidence. If any criterion fails, the Team Lead loops back. internally, without bothering the user. until it passes or until it hits a guidance bucket wall.

Why: the user's job is setting direction, not sanity-checking output. If every objective ends with a back-and-forth cleanup, the architecture hasn't saved the user any time.

---

## What this costs

Objective-oriented architecture has real costs, and you should know them.

- **Front-loaded setup.** Bootstrap takes 5 minutes. The autonomous/guidance bucket question takes real thought. You can't skip it. if you do, the Team Lead will either be paralyzed (ask about everything) or reckless (never ask).
- **Tolerance for Team Lead judgment.** The Team Lead will make calls you wouldn't have. Usually fine. Occasionally wrong. The trade-off is volume: you get 10 objectives done for the price of writing 3 yourself, even if 1 of those 10 needs rework.
- **A short adjustment period.** The first few times, you will want to peek at every intermediate step. That's Stage 2 muscle memory. Let the verification gate do its job. If the result is good, you saved hours. If not, you know to tighten the objective next time.

The payoff: you go from one project at a time to three. From typing every brief to setting a direction and letting the team execute.

---

## What this is NOT

- **Not full autonomy.** Guardrails are sacred. The two-bucket rule is always on. A Team Lead that force-pushes because "it's faster" has failed architecture.
- **Not magic.** The Team Lead is only as good as the objective. Fuzzy objective in, fuzzy result out. If you find results consistently poor, tighten the SUCCESS LOOKS LIKE criteria.
- **Not one-and-done.** Objectives come back with one of three outcomes: delivered, blocked with a clear reason, or surfaced a decision you need to make. The third outcome is a feature, not a bug. some work genuinely needs a human decision, and the Team Lead's job is to identify those cases early, not to guess.

---

## How RAOS implements this

- **SKILL.md** defines the bootstrap flow so every team starts with the autonomous/guidance buckets declared.
- **team-lead.agent.md** codifies the Team Lead's behavior, including the verification gate and the two-bucket rule.
- **objective.template.md** forces every objective into a shape that enables autonomous execution.
- **tasks.json** gives the Team Lead a shared state to coordinate specialists without constantly asking the user.
- **Recipes** (in `references/recipes/`) provide drop-in patterns for specific decision surfaces (ADO tracking, PAC auth, Niyam policies) so the Team Lead has concrete rules to classify with.

Every piece of RAOS serves one goal: move the user up the stack. From task to project to objective.
