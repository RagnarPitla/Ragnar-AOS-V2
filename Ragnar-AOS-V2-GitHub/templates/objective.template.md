# How to write an objective

The difference between a task and an objective is the difference between Stage 2 and Stage 3.

**Task:** "Add a button to the sign-up page."
**Objective:** "Make the onboarding flow convert 20% better."

A task tells the AI *what to do*. An objective tells the AI *what to achieve*.

---

## The shape of a good objective

Every objective the Team Lead accepts gets parsed into this structure. The user can write it freeform. the Team Lead fills in the rest and confirms before dispatching.

```
OBJECTIVE:
  <one sentence. outcome, not work. Present tense verb preferred.>

SUCCESS LOOKS LIKE:
  - <measurable or observable criterion #1>
  - <measurable or observable criterion #2>
  - <measurable or observable criterion #3>

MUST NOT BREAK:
  - <guardrail. what can't regress>
  - <guardrail. auth, data integrity, SLO, etc.>

OUT OF SCOPE:
  - <what this objective explicitly doesn't address. prevents scope creep>
  - <second out-of-scope item if useful>

PHASE PLAN:
  - Research: <specialists assigned, what they investigate>
  - Challenge: <who does adversarial review, what they attack>
  - Synthesis: <specialists assigned, what they build>

VERIFICATION GATE:
  - Before reporting done, check each SUCCESS LOOKS LIKE criterion. Attach evidence (file, test result, screenshot, measurement).
```

---

## Examples

### Good objective

> Make the README clearer for new contributors so a first-time reader can set up the project locally without asking for help.

```
OBJECTIVE:
  A first-time reader can set up the project locally using only the README.

SUCCESS LOOKS LIKE:
  - README covers install, env vars, first-run, and one common gotcha.
  - Every command in README runs cleanly on a fresh clone (verified).
  - No broken links or stale paths.

MUST NOT BREAK:
  - Existing internal links from other docs into the README.
  - The project's Markdown style conventions.

OUT OF SCOPE:
  - Rewriting the architecture section.
  - Translating the README to other languages.

PHASE PLAN:
  - Research: Explore. read current README, scan docs/ for related docs, survey what's missing.
  - Challenge: Plan. what would a new contributor stumble on? Any assumption of insider knowledge?
  - Synthesis: docs-writer specialist. produce new README; reviewer. run setup on fresh clone.

VERIFICATION GATE:
  - Run through README step by step on a clean git clone. Every step works. Log the run in tasks.json.
```

### Still a task, not an objective

> "Update the README."

This is too thin to be an objective. The Team Lead should push back and ask: "What would a better README achieve for the reader?"

### Objective that's too fuzzy

> "Make the product better."

No success criteria, no guardrails. The Team Lead should ask for specifics before dispatching. "Better for whom, measured how, by when?"

---

## Rewriting tasks as objectives (team coaching)

When a teammate sends a task-shaped request, coach them into objective form. A few moves that work:

- **"What changes after this is done?"**. pushes them from verb-work to outcome-observation.
- **"Who's the reader / user / customer?"**. anchors the objective to a specific human.
- **"How will we know we did it?"**. forces measurable success criteria.
- **"What would fail this objective without our noticing?"**. surfaces guardrails.

The Team Lead's job is not to silently translate tasks into objectives. it's to teach the team to write objectives directly. Every successful objective cycle is one less translation the user has to do themselves.

---

## When NOT to force an objective

Some work really is just a task and doesn't deserve the overhead. Signals:

- Single file, single specialist, under 15 minutes.
- Mechanical. rename, format, bump a dependency.
- Exploratory. user is playing, not building.

In those cases, use Project mode or Ad-hoc mode. Save Objective mode for work worth a 3-phase cycle.
