# Glossary — Ragnar's Agentic OS V2

| Term | Definition |
|---|---|
| **Scaffold** | The durable harness layer added in V2. Hooks, run folders, manifests, and the evaluator — everything that makes objectives survive across sessions. |
| **Run** | A single objective execution. Lives in `.agentic-os/runs/<run_id>/` with manifest, trace, verification, checkpoint, and costs files. |
| **Manifest** | `manifest.yaml` — the durable state file for a run. Contains status, phase, budgets, gates, and checkpoints. The source of truth for where an objective stands. |
| **Gate** | A recorded decision point: auth check, user approval, verification verdict, kill, or circuit breaker. Stored in `manifest.gates[]` so resumed runs know what was promised. |
| **Circuit Breaker** | Auto-pause triggered when the same tool fails 3 times in a row. The PostToolUse hook detects this and sets `status: paused` in the manifest. |
| **Evaluator** | An independent subagent that runs in a forked context (`context: fork`). It reads `verification.yaml`, runs each criterion's `how_to_verify`, and returns a verdict. The team-lead never judges its own work. |
| **Two-Bucket Rule** | Every action is classified as **autonomous** (reversible, cheap — just do it) or **guidance** (destructive, judgment-heavy — ask the user first). When uncertain, default to guidance. |
| **Phase** | One stage of objective execution. The four phases are: **Research** (explore), **Challenge** (adversarial review), **Synthesis** (build), **Verify** (evaluator judges). |
| **Checkpoint** | A snapshot of run state (current phase + tasks.json version) written at phase transitions and session end. Enables resume after crash or session close. |
| **Team Lead (cli-lead)** | The orchestrator agent. The only agent the user talks to. In Claude Code, the file lives at `.claude/agents/cli-lead.md`. |
| **Specialist** | A subagent that owns a specific surface (pac-cli, dataverse, azure, etc.). Receives briefs from the team-lead, does the work, reports results. |
| **Wake Phrase** | The user-chosen phrase that boots the Agentic OS from any project folder (e.g., "Hey Contoso" or `/raos`). |
