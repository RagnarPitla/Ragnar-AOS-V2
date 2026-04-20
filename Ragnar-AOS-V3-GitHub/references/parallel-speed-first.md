# Parallel & Speed-First

Speed is a feature. Objective-oriented execution only pays off if it's dramatically faster than sequential task prompting.

---

## The rule: parallel by default

When a task has no dependency on another, dispatch both at the same time.

In Claude Code (and similarly in GitHub Copilot CLI): multiple Agent tool calls in a single message run concurrently. Use that. The Team Lead should favor breadth over depth whenever the work is parallelizable.

Examples of work that is usually parallelizable:
- Research across different areas of a codebase (one Explore agent per area).
- Multiple independent file edits (one specialist per file scope).
- Simultaneous read and verify (Explore + reviewer) during Research.
- Adversarial review while Synthesis runs (if the reviewer can work on a preview branch).

Examples that are NOT parallelizable:
- Two specialists editing the same file.
- Build → test → deploy (sequential by nature).
- Synthesis that depends on Challenge output (Challenge must complete first).

---

## Pick the right dispatch pattern

- **Explore (read-only research):** fast, cheap, parallel by default. Use for Phase 1 Research.
- **Plan (architectural analysis):** slower, higher-quality output. Use for Phase 2 Challenge. Rarely parallel. usually one Plan agent with full context.
- **Project specialists (your own .github/agents/):** whatever they're scoped to. Parallel if they own disjoint surfaces.
- **general-purpose:** fallback when you need implementation and don't have a specialist. Avoid overuse. it doesn't carry project context as well as a dedicated specialist.

---

## The 5-minute test

If an objective is going to take longer than 5 minutes of wall-clock time, the Team Lead should show the user a progress update once per minute. not continuously, and not nothing.

Good updates:
- "Research phase dispatched 3 agents, waiting on 2."
- "Challenge identified one load-bearing assumption: [X]. Proceeding."
- "Synthesis blocked on auth. classified as guidance, asking user."

Bad updates:
- Silent 8-minute run with no signal.
- Over-chatty narration of every tool call.
- Asking the user questions they already answered.

---

## Optional: tmux visualization

If the teammate has tmux and wants to see parallel execution live, they can split the terminal into panes. one per specialist. and tail their logs. Not required. The native task list (`/raos status` → `.github/tasks.json`) carries the same information.

This is power-user territory. Default RAOS experience does not require tmux.

---

## Cost awareness

Parallel dispatch burns tokens faster. Usually worth it. user attention is more expensive than tokens. But the Team Lead should:

- Not re-dispatch Research agents for the same area twice in one objective.
- Not dispatch specialists whose output is redundant ("get three opinions" is rarely worth 3x the cost).
- Reuse Explore output from Research in Synthesis rather than re-reading.

If the user is on a tight budget (noted in the project instructions — In Claude Code: `CLAUDE.md` / In GitHub Copilot CLI: `instructions.md`), the Team Lead can downgrade to sequential dispatch. That's a user preference, not a default.

---

## The anti-pattern: fake parallelism

A Team Lead that "dispatches" three agents one after the other in separate messages is not running in parallel. it's just adding overhead. Parallel means one message, multiple tool calls, concurrent execution.

If you catch yourself doing it sequentially when the tasks are independent, stop. Batch them.
