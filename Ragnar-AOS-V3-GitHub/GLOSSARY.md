# GLOSSARY — Ragnar's Agentic OS V2

Key terms used throughout the RAOS documentation and templates.

| Term | Definition |
|---|---|
| **RAOS** | Ragnar's Agentic OS. The framework described in this repository. |
| **The Scaffold** | The V2 durable harness layer: run manifests, checkpoints, tracing, evaluator, scheduler templates. |
| **Team Lead** | The orchestrator agent (`cli-lead`). The only agent the user speaks to directly. Decomposes objectives, dispatches specialists, enforces guardrails. |
| **Specialist** | A domain-specific agent (e.g., `pac-cli`, `dataverse`, `azure`) that reports to the team-lead. |
| **Evaluator** | An independent judge agent that verifies deliverables against `verification.yaml` before the team-lead declares done. Runs with explicit isolation from the team-lead's reasoning. |
| **Objective** | A user-stated outcome (Stage 3). The team-lead decomposes it into phases and delegates to specialists. |
| **Project** | A user-stated feature or chunk of work (Stage 2). Lighter than an objective — no full 4-phase cycle. |
| **Run** | A durable execution of an objective. Lives in `.agentic-os/runs/<run_id>/` with manifest, trace, verification, checkpoint, and costs. |
| **Run manifest** | `manifest.yaml` — the durable state file for a run. Tracks status, phase, budgets, checkpoints, gates. |
| **Verification** | `verification.yaml` — criteria the evaluator checks against. Each criterion has a `how_to_verify` field. |
| **Checkpoint** | A snapshot of the run's state at a phase boundary. Written to `checkpoint.json`. Enables resume after crash. |
| **Two-bucket rule** | Every action is classified as **autonomous** (reversible, cheap — just do it) or **guidance** (destructive, judgment — ask user first). |
| **Kill switch** | A mechanism to halt a run. In Claude Code, enforced by hooks. In Copilot CLI, the team-lead checks for a KILL sentinel file at phase boundaries. |
| **Circuit breaker** | Automatic pause after repeated errors. In Claude Code, enforced by PostToolUse hook. In Copilot CLI, the team-lead pauses after 3 consecutive failures. |
| **Gate** | A decision point recorded in the manifest's `gates[]` array. Types: `auth`, `guidance`, `verification`, `budget`. |
| **Phase** | One of the four execution stages: Research, Challenge, Synthesis, Verify. |
| **Auto-boot** | A block in `~/.github/instructions.md` that activates the OS when the user's wake phrase is detected. |
| **Factory model** | Each teammate names and installs their own OS instance from the shared blueprint. |
| **Headless run** | An unattended scheduled run. Best achieved via GitHub Actions on Copilot CLI. |
| **Observability-only budgets** | Token/time/cost counters that track but don't enforce limits by default. |
| **Self-improvement loop** | Every 7 days, the OS proposes new skills, routines, or upgrades based on observed patterns. |

## Copilot CLI-specific terms

| Term | Definition |
|---|---|
| **Degraded hooks** | The Claude Code hook system (PreToolUse, PostToolUse, Stop, UserPromptSubmit) is not available in Copilot CLI. The team-lead compensates with prompt-level instructions. See [HOOKS-DEGRADED.md](HOOKS-DEGRADED.md). |
| **Manual isolation** | The evaluator cannot run in a forked context on Copilot CLI. The team-lead invokes it with explicit instructions to ignore prior reasoning. |

## V3 Terms

| Term | Definition |
|---|---|
| **Context Compression** | Automatic summarization of conversation history when the context window approaches its limit. Preserves key decisions and active task state while freeing token budget. |
| **Delegation Contract** | A structured agreement passed to a subagent specifying allowed tools, depth limits, timeout, and expected output format. Enforces isolation between agents. |
| **Session Persistence** | Durable storage of conversation history and run state in SQLite with FTS5 full-text search. Enables cross-session resume and history queries. |
| **Profile Isolation** | Running multiple independent RAOS configurations on the same machine by setting the `RAOS_HOME` environment variable to different directories. |
| **MCP (Model Context Protocol)** | A protocol for connecting external tool servers to the Agentic OS. Enables third-party integrations without modifying core agent prompts. |
| **Platform Gateway** | An adapter layer that normalizes differences between CLI runtimes (Claude Code, GitHub Copilot, etc.) so the same agent logic runs on any platform. |
| **Terminal Backend** | An abstraction over execution environments: local shell, Docker container, SSH remote, or cloud instance. Agents request terminal access without knowing the underlying transport. |
| **Command Registry** | A single YAML/JSON file that defines all available slash commands, their arguments, and help text. The source of truth for `/raos` command routing. |
| **Cost Tracking** | Per-run and per-objective accounting of token usage, API costs, and wall-clock time. Logged in the run manifest for budget monitoring. |
| **Background Task** | An agent-initiated task that runs asynchronously. Two modes: fire-and-forget (no result needed) and notify-on-complete (agent is notified when done). |
| **Agent Discovery** | Automatic registration of agents by scanning the `agents/` directory at boot. New `.md` agent files are picked up without manual wiring. |
| **Theme Engine** | A dashboard subsystem that loads visual themes from YAML skin files. Supports a theme switcher and ships with 2 built-in themes. |
