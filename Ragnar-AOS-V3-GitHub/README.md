# Ragnar's Agentic OS — V2 (The Scaffold) — GitHub Copilot CLI Edition

**By Ragnar Pitla.** For questions: https://www.linkedin.com/in/ragnarpitla/

![Your Agentic Team Builds It](assets/Your%20Agentic%20Team%20Builds%20It.png)

_One objective in. Customer research, agent design, policies, Copilot Studio build, and production deploy out. Delivered by a team of specialists (pac-cli, dataverse, copilot-studio, azure, ado) orchestrated by a team-lead — now durable across sessions, resumable after crash, and runnable headless on a schedule._

This folder is V2 of Ragnar's Agentic OS, adapted for **GitHub Copilot CLI** (`gh copilot`). It adds **The Scaffold** — a durable harness layer on top of V1. Everything V1 did still works in V2; V2 is additive.

![The Scaffold Run Folder Anatomy](assets/The%20Scaffold%20Run%20Folder%20Anatomy.png)

For the full list of what's new and how to migrate, see **[UPGRADE.md](UPGRADE.md)**.

---

## What's new in V2

1. **Run manifests** — every objective becomes a run in `.agentic-os/runs/<run_id>/` with durable state (manifest, trace, verification, checkpoint, costs).
2. **Evaluator agent** — an independent judge that verifies deliverables against `verification.yaml` before the team-lead declares done. Invoked with explicit isolation instructions (Copilot CLI does not support forked context).
3. **Scheduler templates** — macOS launchd, Windows Task Scheduler, and GitHub Actions templates for headless scheduled runs. GitHub Actions is the recommended approach for Copilot CLI.
4. **New slash subcommands** — `/raos runs`, `/raos resume <run_id>`, `/raos kill <run_id>`.
5. **Observability-only budgets** — trace token/time/$ rollups without enforcement by default. Flip `budgets.enforce: true` in a manifest for hard caps.

---

## Differences from the Claude Code version

| Feature | Claude Code | GitHub Copilot CLI |
|---|---|---|
| **Hooks** | 4 automatic hooks (PreToolUse, PostToolUse, Stop, UserPromptSubmit) | Not supported. Team-lead handles checkpoints/tracing at phase boundaries. See [HOOKS-DEGRADED.md](HOOKS-DEGRADED.md). |
| **Evaluator isolation** | Runs in `context: fork` (hard isolation) | Invoked with explicit "ignore prior reasoning" instructions (soft isolation) |
| **Subagent dispatch** | Via Agent tool with `subagent_type` | By reading specialist agent files and following their instructions |
| **Config directory** | `~/.claude/` | `~/.github/` |
| **Project instructions** | `.claude/CLAUDE.md` | `.github/instructions.md` |
| **Agent files** | `.claude/agents/` | `.github/agents/` |
| **Task list** | `.claude/tasks.json` | `.github/tasks.json` |
| **Headless mode** | `claude -p` (native) | GitHub Actions (recommended) or `headless-copilot.sh` (best-effort) |
| **Settings** | `~/.claude/settings.json` (hook registration) | Not applicable |
| **Kill switch** | Automatic via PreToolUse hook | Team-lead checks KILL sentinel at phase boundaries |
| **Tracing** | Automatic via PostToolUse hook | Manual checkpoints by team-lead |

---

## The one file they need

**[Ragnar-AgenticOS-setup.md](Ragnar-AgenticOS-setup.md)** is the V2 installer. Self-contained. Every blueprint file in this folder is embedded inside it between sentinel markers.

For Copilot CLI-specific setup guidance, also see **[GitHub-Copilot-AgenticOS-setup.md](GitHub-Copilot-AgenticOS-setup.md)**.

Either distribution works:

- **Share just `Ragnar-AgenticOS-setup.md`** (one file, everything embedded). Simplest.
- **Share the whole folder** (browseable blueprint + the installer). Better for reading the source.

Your teammate invokes the installer once. It asks them three questions, writes their personal V2 OS into their `~/.github/skills/` folder, wires auto-boot, and sets up a local `.agentic-os/runs/` folder in the current project.

If your teammate was already on V1 (1.09), the installer detects it and migrates in place — preserving every V1 artifact. See [UPGRADE.md](UPGRADE.md) for the migration logic.

---

## What your teammate gets in V2

1. **Their own named OS.** Same factory model as V1 — pick a slug, display name, wake phrase.
2. **Auto-boot.** From any project folder, their wake phrase (or `/<their-os-name>`) boots the team.
3. **Durable runs.** Every objective now survives across sessions. Close the laptop, come back tomorrow, `/raos resume <run_id>`.
4. **Separate evaluator.** The team-lead no longer judges its own work. The evaluator agent verifies against explicit criteria.
5. **Scheduled headless runs.** Optional. GitHub Actions template recommended for Copilot CLI.
6. **Local memory.** Same `.agentic-os/memory.md` + `routines.md` as V1. Now sitting next to `runs/`.
7. **Self-improvement.** Every 7 days, the OS proposes new skills, upgrades, or routines to promote. Always requires user approval.

---

## How to invoke

**GitHub Copilot CLI:**

```bash
cd path/to/your/project
gh copilot
> install Ragnar-AgenticOS v2 from ./Ragnar-AgenticOS-setup.md
```

The installer takes it from there. See [QUICKSTART.md](QUICKSTART.md) for the full step-by-step.

---

## Folder contents (V2)

```
Ragnar-AOS-V2-GitHub/
├── README.md                          ← this file
├── UPGRADE.md                         ← what's new in V2, migration from V1
├── QUICKSTART.md                      ← GitHub Copilot CLI quickstart guide
├── GLOSSARY.md                        ← key terms and definitions
├── HOOKS-DEGRADED.md                  ← what's lost without Claude Code hooks
├── Ragnar-AgenticOS-setup.md          ← the V2 installer (embeds everything below)
├── GitHub-Copilot-AgenticOS-setup.md  ← Copilot CLI-specific setup guide
├── SKILL.md                           ← the V2 blueprint skill body
├── commands/
│   └── raos.md                        ← with /raos resume|runs|kill subcommands
├── references/
│   ├── the-4-stages.md
│   ├── objective-oriented-arch.md
│   ├── 3-phase-execution.md
│   ├── parallel-speed-first.md
│   ├── the-scaffold.md                ← V2 thesis
│   ├── run-lifecycle.md               ← the six run states
│   ├── budgets-and-gates.md           ← observability + kill switch + circuit breaker
│   └── recipes/
│       ├── ado-tracking.md
│       ├── pac-auth-gate.md
│       ├── niyam-policy.md
│       ├── two-bucket-approval.md
│       ├── spec-critique-implement.md
│       ├── headless-scheduled-run.md  ← launchd / Task Scheduler / GH Actions
│       └── resume-after-crash.md      ← recovery playbook
├── templates/
│   ├── instructions.md.template       ← project instructions (was CLAUDE.md.template)
│   ├── CLAUDE.md.template             ← kept for Claude Code compatibility
│   ├── objective.template.md
│   ├── specialist.agent.template.md
│   ├── tasks.json.schema              ← + optional run_id fields (additive)
│   ├── team-lead.agent.md             ← updated for Copilot CLI dispatch model
│   ├── run.manifest.yaml.template
│   ├── verification.yaml.template
│   ├── gitignore.template             ← .gitignore entries for RAOS projects
│   └── agents/
│       ├── README.md
│       ├── pac-cli.agent.md
│       ├── dataverse.agent.md
│       ├── azure.agent.md
│       ├── github.agent.md
│       ├── ado.agent.md
│       ├── copilot-studio.agent.md
│       └── evaluator.agent.md         ← judge agent (manual isolation on Copilot CLI)
└── harness/                            ← The Scaffold itself
    ├── hooks/
    │   ├── README.md                   ← explains hooks are Claude Code only
    │   ├── pre-tool-use.sh             ← Claude Code only
    │   ├── post-tool-use.sh            ← Claude Code only
    │   ├── stop.sh                     ← Claude Code only
    │   └── user-prompt-submit.sh       ← Claude Code only
    ├── bin/
    │   ├── manifest.sh                 ← jq-free YAML helper
    │   ├── costs.sh                    ← trace → costs.json rollup
    │   ├── trace-to-sqlite.sh          ← optional NDJSON → SQLite exporter
    │   ├── headless.sh                 ← Claude Code headless entry point
    │   └── headless-copilot.sh         ← Copilot CLI best-effort headless wrapper
    ├── schedule/
    │   ├── launchd.plist.template      ← macOS
    │   ├── taskscheduler.xml.template  ← Windows
    │   └── github-actions.yaml.template ← cross-platform (recommended for Copilot CLI)
    └── settings.json.fragment          ← Claude Code only — hook registration
```

~45 blueprint files total. All embedded inside the single V2 installer when regenerated via the build script.

---

## Version

**2.0** (2026-04-19). The Scaffold — GitHub Copilot CLI Edition. Durable runs, evaluator agent, scheduler templates, `/raos resume|runs|kill` subcommands, observability-only budgets. See [UPGRADE.md](UPGRADE.md) for migration from V1 (1.09).

---

## Rebuilding the installer

If you edit any blueprint file in this folder, rebuild the single-file installer so the embedded copy matches:

```bash
python3 build_raos_installer.py
```

---

## Uninstall (for teammates)

1. Delete the skill folder at `~/.github/skills/<OS_NAME>/`.
2. Remove the tagged auto-boot block in `~/.github/instructions.md`.
3. Optionally delete `.agentic-os/` (holds runs + learnings). Keep it if you want the trace history.

---

## Thesis

The mental model behind RAOS is Ragnar's "4 Stages of an Agentic Team":

| Stage                 | You own                         | AI owns                                      |
| --------------------- | ------------------------------- | -------------------------------------------- |
| 1. Task               | Plan, decompose, QA, integrate  | The one prompt you typed                     |
| 2. Project            | The brief + acceptance criteria | Decomposition, parallel execution, synthesis |
| 3. Objective          | The objective + guardrails      | Team composition, plan, execution, iteration |
| 4. Headless (horizon) | Strategy + verification gates   | Everything operational, on a schedule        |

V1 got teams to Stage 2 reliably and Stage 3 in-session. **V2 — The Scaffold — makes Stage 3 reliable across sessions and Stage 4 tractable.** Scheduled headless runs are now a GitHub Actions workflow. Resume-after-crash is a single slash command. An independent evaluator judges deliverables against written criteria before the team-lead claims done.

Deeper read: [references/the-4-stages.md](references/the-4-stages.md), then [references/the-scaffold.md](references/the-scaffold.md).

![From Task to Objective Comparison](assets/From%20Task%20to%20Objective%20Comparison.png)

---

## Questions or feedback

Ping Ragnar Pitla on LinkedIn: https://www.linkedin.com/in/ragnarpitla/
