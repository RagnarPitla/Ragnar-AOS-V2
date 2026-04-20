# Recipe: The Two-Bucket Rule

**Pattern:** Every action is either autonomous (do it, report after) or guidance (explain, propose, wait for user). Classify BEFORE acting.

**When to use:** Every project. This is the core safety + autonomy trade-off that makes objective-oriented execution possible without destroying anything.

**Plug into your team lead:** RAOS bakes this into every bootstrapped project instructions file automatically (In Claude Code: `CLAUDE.md` / In GitHub Copilot CLI: `instructions.md`). You don't have to add it. but you can customize the buckets.

---

## The two buckets

**Autonomous bucket:** the agent does the thing. Reports after.

Characteristics:
- **Reversible**. if wrong, we can undo without lasting damage.
- **Cheap**. low cost to redo (time, money, relationships).
- **Evidence-backed**. there's a clear signal the action is correct.
- **Scope-aligned**. within the current objective's declared scope.

Examples:
- Reading any file.
- Running tests.
- Editing code on a feature branch.
- Writing/updating docs.
- Committing to a feature branch (not main).
- Running non-destructive CLI queries (status, list, show).
- Searching external docs.
- Creating new files in the project.

**Guidance bucket:** the agent explains, proposes, waits.

Characteristics:
- **Hard to reverse**. undoing requires meaningful effort or cannot fully undo.
- **Expensive**. time, money, reputation on the line.
- **Judgment-dependent**. the right answer requires context the agent doesn't have.
- **Scope-shifting**. would change what the objective is about.

Examples:
- Force-pushing anything.
- `git reset --hard`, branch deletion, checkout --.
- Merging to main / production branch.
- Writing to production databases or services.
- Spending money (API calls to paid services beyond declared scope, etc.).
- Sending external messages (Slack, email, Telegram, PRs).
- Adding/removing team members from `.github/agents/`.
- Changing the objective's scope mid-run.

---

## How cli-lead classifies

For every proposed action, cli-lead asks three questions:

1. **If this is wrong, can I undo it cheaply?** → Yes = lean autonomous. No = lean guidance.
2. **Does this affect shared or external state?** → No = lean autonomous. Yes = lean guidance.
3. **Could a reasonable person disagree with this call?** → No = lean autonomous. Yes = lean guidance.

When two or more answers point toward guidance, it's guidance.

When uncertain, default to guidance. The cost of a one-line "proceed?" is low. The cost of an unwanted action is high.

---

## Customizing per project

In your project instructions file (In Claude Code: `CLAUDE.md` / In GitHub Copilot CLI: `instructions.md`), you can expand or tighten the buckets:

```
## Autonomous bucket. AI can do without asking
- Everything in the default list
- Also: deploy to staging (we have a rollback button)
- Also: post status updates to #eng channel (the channel is low-stakes)

## Guidance bucket. AI must confirm before acting
- Everything in the default list
- Also: any change touching files in /legal or /compliance (always review)
- Also: any PR that adds a new npm dependency (we track bundle size)
```

This customization is one of the highest-leverage moves in RAOS. Get the buckets right and the Team Lead runs smoothly. Get them wrong and you're either micromanaged (too conservative) or nervous (too aggressive).

---

## The escalation pattern

When a specialist hits a guidance-bucket action:
1. Specialist pauses. Does NOT attempt the action.
2. Writes a tasks.json entry: bucket=guidance, status=blocked.
3. Returns to cli-lead: "Action X needs guidance. Proposal: Y. Alternatives: Z1, Z2. Impact if wrong: W."
4. cli-lead surfaces to the user: one question, clear options, no narration.
5. User answers. cli-lead tells the specialist. Work resumes.

The whole loop should take under 30 seconds when the user is available. If the user is away, the specialist returns up the stack and cli-lead queues the question for when the user is back.

---

## Anti-patterns

- **Asking about every action** ("should I run the tests?" "should I read the file?"). Exhausting. The user set the objective. trust the team to research.
- **Never asking** ("the tests passed so I force-pushed to main"). Catastrophic. Evidence of passing tests doesn't make destructive ops autonomous.
- **Asking in narration form** ("I was thinking about maybe updating the schema if that's okay with you?"). Clear classification: is this guidance? Then ask. Is it autonomous? Then do it. Don't hedge.

The two-bucket rule is how the Team Lead earns trust. Apply it relentlessly.
