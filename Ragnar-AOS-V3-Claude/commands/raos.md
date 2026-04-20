---
description: Ragnar's Agentic OS V2 (Scaffold). Bootstrap a team, check status, accept an objective, or resume/kill a run. /raos (no args) auto-detects. /raos <sentence> runs an objective. /raos status shows the dashboard. /raos runs lists all runs. /raos resume <run_id> continues a paused run. /raos kill <run_id> halts a run. /raos reset wipes the team.
---

Invoke the `raos` skill. Follow the flow in [~/.claude/skills/raos/SKILL.md](~/.claude/skills/raos/SKILL.md).

Arguments: `$ARGUMENTS`

Detection logic (before doing anything else):

1. Read the current working directory.
2. Check for `.claude/agents/cli-lead.md`. this is the signal that a team exists.
3. Branch on `$ARGUMENTS`:

   - **Empty + no team** → run the **Bootstrap protocol** from SKILL.md. Discover (10 questions + integrations checkbox), Compose, Write, Report.
   - **Empty + team exists** → show **Status**: list agents in `.claude/agents/`, summarize `tasks.json` (open/in-progress/done counts), list active runs from `.agentic-os/runs/` with their phase/status, last activity time. Offer next actions.
   - **`status`** → same as status above.
   - **`runs`** → list every run in `.agentic-os/runs/`: run_id, objective_statement (truncated), status, current_phase, updated_at. Sorted by updated_at, newest first. Tell the user how to resume or kill each one.
   - **`resume <run_id>`** → the UserPromptSubmit hook has already marked the run active. Read `.agentic-os/runs/<run_id>/manifest.yaml`, `checkpoint.json`, `verification.yaml`, and the tail of `trace.ndjson`. Announce: "Resuming <run_id>. Last phase: <phase>. Status: <status>. Continuing with <next step>." Then pick up where the team left off. No re-decomposition. See [references/recipes/resume-after-crash.md](~/.claude/skills/raos/references/recipes/resume-after-crash.md).
   - **`kill <run_id>`** → the UserPromptSubmit hook has already dropped the KILL sentinel. Acknowledge to the user: "Run <run_id> marked killed. Drop the KILL file at <path> to resume." Then stop.
   - **`reset`** → confirm with the user ("this will delete `.claude/agents/`, `tasks.json`, and `.agentic-os/runs/`. git-tracked? type YES to proceed"). Only on explicit YES, wipe.
   - **Any other text + team exists** → treat as an **objective**. Reformat into the shape from [templates/objective.template.md](~/.claude/skills/raos/templates/objective.template.md), confirm with user, then create the run folder and dispatch via the 4-phase pattern (Research → Challenge → Synthesis → Verify via evaluator). See [references/run-lifecycle.md](~/.claude/skills/raos/references/run-lifecycle.md).
   - **Any other text + no team** → bootstrap first, then take the objective.

Always:
- Never call it "CLI" in user-facing copy. Say "Agentic OS" or "your AI team."
- Respect the guardrails in SKILL.md §Guardrails for every action.
- Every objective becomes a run. Write `.agentic-os/runs/<run_id>/manifest.yaml` on accept. No exceptions.
- Update both `tasks.json` (for the dashboard) and the run's `manifest.yaml` (for durable state) as phases complete.
- Use the Agent tool to dispatch parallel work (subagent_type: Explore for Research, Plan for Challenge, project specialists for Synthesis, `evaluator` for Verify).
