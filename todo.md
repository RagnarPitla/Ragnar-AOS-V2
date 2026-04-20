# Ragnar-AOS V2 — Review TODO

Pre-share checklist for the internal Microsoft team.

---

## MUST FIX (before sharing)

### Gap 1: Copilot CLI Runtime Compatibility [SHOWSTOPPER]

The entire system is wired to Claude Code primitives. Your team runs Copilot CLI.

- [ ] Agent dispatch uses Claude Code's "Agent tool" with subagent_type (Explore, Plan, general-purpose). Copilot CLI does NOT have this. The 3-phase parallel execution model breaks.
- [ ] Hooks (PreToolUse, PostToolUse, Stop, UserPromptSubmit) are Claude Code specific. The 4 harness scripts in harness/hooks/ won't fire in Copilot CLI. That means: no tracing, no checkpointing, no kill switch, no circuit breaker, no cost rollup — the entire Scaffold.
- [ ] File paths assume .claude/agents/, ~/.claude/skills/, ~/.claude/settings.json. The installer writes to ~/.github/ too, but SKILL.md, team-lead.agent.md, and every recipe reference .claude/ paths.
- [ ] `context: fork` in SKILL.md frontmatter is a Claude Code feature. Copilot CLI ignores it.

**Options:**
  a) Write a companion doc mapping every Claude Code primitive to its Copilot CLI equivalent (or noting what's missing and the workaround).
  b) Abstract the dispatch mechanism in the team-lead so it works with whatever "run a sub-task" primitive the runtime provides.
  c) At minimum, add a "Runtime Compatibility" section to SKILL.md that tells Copilot CLI users what works, what's degraded, and what's missing.

---

### Gap 2: No Onboarding / Quickstart for Teammates

The installer puts files on disk but there's no "your first 15 minutes" guide.

- [ ] Add QUICKSTART.md with:
  1. A concrete walkthrough: "Say your wake phrase. Answer the 10 questions. Here's what good answers look like. Here's your first objective to try."
  2. A "what just happened" explanation after bootstrap completes.
  3. A "when things go wrong" section (not troubleshooting — more like "your first objective didn't work, here's why and what to adjust").

---

### Gap 3: No Error Recovery Without Hooks

Resume-after-crash and checkpoint logic both live in hooks. Hooks won't fire in Copilot CLI, so crash recovery is broken.

- [ ] Move checkpoint logic into the team-lead agent instructions directly. After each phase completion, the team-lead should write a checkpoint to .agentic-os/runs/<run_id>/ as part of its normal flow — not as a hook side-effect.

---

## SHOULD FIX (before sharing or shortly after)

### Gap 4: tasks.json Has No Conflict Handling

No guidance on what happens when two specialists try to update tasks.json simultaneously during parallel dispatch. JSON is not concurrent.

- [ ] Make team-lead the sole writer to tasks.json (specialists report back, team-lead updates), OR
- [ ] Add a simple locking convention (e.g., .tasks.json.lock), OR
- [ ] Document that tasks.json is team-lead-owned and specialists must not write directly

---

### Gap 5: verification.yaml Is Underspecified

Template has good structure but doesn't show the evaluator HOW to verify.

- [ ] Add 2-3 concrete verification.yaml examples with real verification commands/tools
- [ ] Show the evaluator that it should EXECUTE checks, not just read the builder's self-report
- [ ] Examples: "Tests pass" → which command? "No broken links" → which tool? "Performance within budget" → how to measure?

---

### Gap 8: No .gitignore Guidance

.agentic-os/runs/ will accumulate trace files, checkpoints, cost rollups that should NOT be committed.

- [ ] Add a .gitignore template or installer step that appends:
  ```
  # RAOS — transient run data
  .agentic-os/runs/
  .agentic-os/last-improvement-check.txt
  ```
- [ ] Document what SHOULD be committed:
  ```
  .agentic-os/memory.md
  .agentic-os/routines.md
  .agentic-os/os.txt
  .agentic-os/version.txt
  ```

---

### Style Issue 1: Inconsistent Naming — "cli-lead" vs "team-lead"

- [ ] templates say "team-lead.agent.md" but the file gets written as "cli-lead.md" in .claude/agents/. Pick one. Given the "never call it CLI" rule, "team-lead.md" is more consistent.

---

### Style Issue 2: Version Mismatch

- [ ] SKILL.md frontmatter says version 2.0, but version.txt seeds as "1.09", auto-boot block says "v1.09", README says V2. Pick one scheme and use it everywhere.

---

## NICE TO HAVE (iterate after first team feedback)

### Gap 6: Build Script May Not Handle V2 Harness Correctly

- [ ] Verify build_raos_installer.py works end-to-end: run `python3 build_raos_installer.py` and check that all ~40 files get embedded, shell scripts get the RAOS-EXEC sentinel, and the installer chmod's them on extraction.

---

### Gap 7: Cost Tracking Has No Sizing Guidance

- [ ] Add a "budget sizing" section to budgets-and-gates.md with examples:
  - Small objective (single-file edit): ~$0.50, ~5 min
  - Medium objective (multi-file feature): ~$5, ~30 min
  - Large objective (cross-system): ~$20, ~2 hours
  - Calibrate to actual team usage

---

### Gap 9: Specialist Agent Template Is Too Generic

- [ ] Add 2-3 example specialists showing best practices:
  - Tightly-scoped (e.g., "test-runner" that ONLY runs/interprets tests, never edits code)
  - Broadly-scoped (e.g., "fullstack-dev" with clear file ownership boundaries)
  - Show "owns:" and "coordinates with:" filled in concretely

---

### Gap 10: Self-Improvement Loop Has No Guardrails

- [ ] Add explicit "propose only, never auto-apply" rule
- [ ] Add a changelog in .agentic-os/ so the team can see what changed
- [ ] Add a "revert last improvement" mechanism

---

### Dead References

- [ ] SKILL.md mentions "Rbuild.ai/RAOS/OS-CLI-BUILDER-SKILL.md" and "Rbuild.ai/RAOS/raos-v2-installer.skill.md" — these paths likely don't exist on team machines. Remove or update.
- [ ] Troubleshooting table mentions "plugin-dev:agent-creator" subagent — is this shipped? Not in templates.

---

### Jargon

- [ ] Add one-line explanations for "Kazuki two-bucket", "Niyam", and other RAOS-specific terms on first use, or add a glossary.

---

## WHAT'S EXCELLENT (no changes needed)

- Conceptual framework (4 Stages, 3-phase execution, two-bucket approval, objective-oriented architecture)
- Writing quality — reads like it was written for skeptical engineers
- Recipes are self-contained and modular
- Single-file installer with factory model and idempotent upgrades
- Evaluator subagent (separate builder from judge, forked context)
