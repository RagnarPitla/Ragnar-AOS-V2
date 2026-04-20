# Ragnar's Agentic OS — V2 (The Scaffold)

**By Ragnar Pitla.** For questions: https://www.linkedin.com/in/ragnarpitla/

![Your Agentic Team Builds It](assets/Your%20Agentic%20Team%20Builds%20It.png)

_One objective in. Customer research, agent design, policies, Copilot Studio build, and production deploy out. Delivered by a team of subagents (pac-cli, dataverse, copilot-studio, azure, ado) orchestrated by a team-lead — now durable across sessions, resumable after crash, and runnable headless on a schedule._

This folder is V2 of Ragnar's Agentic OS. It adds **The Scaffold** — a durable harness layer on top of V1. V1 lives intact in the sibling `Ragnar-AOS/` folder; V2 lives here. Everything V1 did still works in V2; V2 is additive.

![The Scaffold Run Folder Anatomy](assets/The%20Scaffold%20Run%20Folder%20Anatomy.png)

For the full list of what's new and how to migrate, see **[UPGRADE.md](UPGRADE.md)**. New here? Start with **[Install-guide.md](Install-guide.md)**. For terminology, see **[GLOSSARY.md](GLOSSARY.md)**.

---

## What's new in V2

1. **Run manifests** — every objective becomes a run in `.agentic-os/runs/<run_id>/` with durable state (manifest, trace, verification, checkpoint, costs).
2. **Four Claude Code hooks** — PreToolUse (kill switch, auth gate), PostToolUse (trace + circuit breaker), Stop (checkpoint + cost rollup), UserPromptSubmit (resume/kill detection).
3. **Evaluator subagent** — an independent judge that runs in a forked context (`context: fork`), verifying deliverables against `verification.yaml` before the team-lead declares done.
4. **Scheduler templates** — macOS launchd, Windows Task Scheduler, and GitHub Actions templates for headless scheduled runs.
5. **New slash subcommands** — `/raos runs`, `/raos resume <run_id>`, `/raos kill <run_id>`.
6. **Observability-only budgets** — trace token/time/$ rollups without enforcement by default. Flip `budgets.enforce: true` in a manifest for hard caps.

---

## The one file they need

**[Ragnar-AgenticOS-setup.md](Ragnar-AgenticOS-setup.md)** is the V2 installer. Self-contained. Every blueprint file in this folder (including the new `harness/` scripts, scheduler templates, and V2 references) is embedded inside it between sentinel markers.

Either distribution works:

- **Share just `Ragnar-AgenticOS-setup.md`** (one file, everything embedded). Simplest.
- **Share the whole `Ragnar-AOS-V2/` folder** (browseable blueprint + the installer). Better for reading the source.

Your teammate invokes the installer once. It asks them three questions, writes their personal V2 OS into their Claude Code / Copilot CLI skill folder, wires auto-boot, registers the four hooks, and sets up a local `.agentic-os/runs/` folder in the current project.

If your teammate was already on V1 (1.09), the installer detects it and migrates in place — preserving every V1 artifact. See [UPGRADE.md](UPGRADE.md) for the migration logic.

---

## What your teammate gets in V2

1. **Their own named OS.** Same factory model as V1 — pick a slug, display name, wake phrase.
2. **Auto-boot.** From any project folder, their wake phrase (or `/<their-os-name>`) boots the team.
3. **Durable runs.** Every objective now survives across sessions. Close the laptop, come back tomorrow, `/raos resume <run_id>`.
4. **Separate evaluator.** The team-lead no longer judges its own work. The evaluator subagent runs in a forked context and verifies against explicit criteria.
5. **Scheduled headless runs.** Optional. Templates for macOS, Windows, and GitHub Actions ship with V2.
6. **Local memory.** Same `.agentic-os/memory.md` + `routines.md` as V1. Now sitting next to `runs/`.
7. **Self-improvement.** Every 7 days, the OS proposes new skills, upgrades, or routines to promote.

---

## How to invoke

**Claude Code:**

```bash
cd path/to/your/project
# Drop Ragnar-AgenticOS-setup.md in the project or in ~/.claude/skills/ and say:
"Install Ragnar-AgenticOS v2 from ./Ragnar-AgenticOS-setup.md"
```

**GitHub Copilot CLI:**

```bash
cd path/to/your/project
gh copilot
> install Ragnar-AgenticOS v2 from ./Ragnar-AgenticOS-setup.md
```

The installer takes it from there.

---

## Folder contents (V2)

```
Ragnar-AOS-V2/
├── README.md                          ← this file
├── UPGRADE.md                         ← what's new in V2, migration from V1
├── Install-guide.md                   ← how to get started in 2 minutes
├── GLOSSARY.md                        ← key terms and definitions
├── .gitignore.template                ← recommended .gitignore additions
├── Ragnar-AgenticOS-setup.md          ← the V2 installer (embeds everything below)
├── SKILL.md                           ← the V2 blueprint skill body
├── commands/
│   └── raos.md                        ← now with /raos resume|runs|kill subcommands
├── references/
│   ├── the-4-stages.md
│   ├── objective-oriented-arch.md
│   ├── 3-phase-execution.md
│   ├── parallel-speed-first.md
│   ├── the-scaffold.md                ← NEW — V2 thesis
│   ├── run-lifecycle.md               ← NEW — the six run states
│   ├── budgets-and-gates.md           ← NEW — observability + kill switch + circuit breaker
│   └── recipes/
│       ├── ado-tracking.md
│       ├── pac-auth-gate.md
│       ├── niyam-policy.md
│       ├── two-bucket-approval.md
│       ├── spec-critique-implement.md
│       ├── headless-scheduled-run.md  ← NEW — launchd / Task Scheduler / GH Actions
│       └── resume-after-crash.md      ← NEW — recovery playbook
├── templates/
│   ├── CLAUDE.md.template
│   ├── objective.template.md
│   ├── specialist.agent.template.md
│   ├── tasks.json.schema              ← + optional run_id fields (additive)
│   ├── team-lead.agent.md             ← updated with run-awareness + evaluator dispatch
│   ├── run.manifest.yaml.template     ← NEW
│   ├── verification.yaml.template     ← NEW
│   └── agents/
│       ├── README.md
│       ├── pac-cli.agent.md
│       ├── dataverse.agent.md
│       ├── azure.agent.md
│       ├── github.agent.md
│       ├── ado.agent.md
│       ├── copilot-studio.agent.md
│       └── evaluator.agent.md         ← NEW — forked-context judge
└── harness/                            ← NEW — The Scaffold itself
    ├── hooks/
    │   ├── pre-tool-use.sh             ← kill switch + auth gate + optional budget enforcement
    │   ├── post-tool-use.sh            ← trace append + circuit breaker
    │   ├── stop.sh                     ← checkpoint + cost rollup
    │   └── user-prompt-submit.sh       ← /raos resume|kill detection + active-run banner
    ├── bin/
    │   ├── manifest.sh                 ← jq-free YAML helper
    │   ├── costs.sh                    ← trace → costs.json rollup
    │   ├── trace-to-sqlite.sh          ← optional NDJSON → SQLite exporter
    │   └── headless.sh                 ← entry point for scheduled runs
    ├── schedule/
    │   ├── launchd.plist.template      ← macOS
    │   ├── taskscheduler.xml.template  ← Windows
    │   └── github-actions.yaml.template ← cross-platform
    └── settings.json.fragment          ← hook registration for ~/.claude/settings.json
```

~40 blueprint files total. All embedded inside the single V2 installer when regenerated via the build script.

---

## Version

**2.0** (2026-04-19). The Scaffold. Durable runs, four hooks, evaluator subagent, scheduler templates, `/raos resume|runs|kill` subcommands, observability-only budgets. See [UPGRADE.md](UPGRADE.md) for migration from V1 (1.09).

---

## Rebuilding the installer

If you edit any blueprint file in this folder (SKILL.md, a reference doc, a template, a hook script, etc.), rebuild the single-file installer so the embedded copy matches.

The installer is pre-built. If you edit blueprint files and need to regenerate, see the `.ragnar/` local backup for the build script.

---

## Uninstall (for teammates)

Same as V1, plus:

1. Delete the skill folder at `~/.claude/skills/<OS_NAME>/` and/or `~/.github/skills/<OS_NAME>/`.
2. Remove the tagged auto-boot block in `~/.claude/CLAUDE.md` (and/or `~/.github/instructions.md`).
3. Remove the four V2 hook entries from `~/.claude/settings.json`.
4. Optionally delete `.agentic-os/` (holds runs + learnings). Keep it if you want the trace history.

---

## Thesis

The mental model behind RAOS is Ragnar's "4 Stages of an Agentic Team":

| Stage                 | You own                         | AI owns                                      |
| --------------------- | ------------------------------- | -------------------------------------------- |
| 1. Task               | Plan, decompose, QA, integrate  | The one prompt you typed                     |
| 2. Project            | The brief + acceptance criteria | Decomposition, parallel execution, synthesis |
| 3. Objective          | The objective + guardrails      | Team composition, plan, execution, iteration |
| 4. Headless (horizon) | Strategy + verification gates   | Everything operational, on a schedule        |

V1 got teams to Stage 2 reliably and Stage 3 in-session. **V2 — The Scaffold — makes Stage 3 reliable across sessions and Stage 4 tractable.** Scheduled headless runs are now a plist file. Resume-after-crash is a single slash command. An independent evaluator judges deliverables against written criteria before the team-lead claims done.

Deeper read: [references/the-4-stages.md](references/the-4-stages.md), then [references/the-scaffold.md](references/the-scaffold.md).

![From Task to Objective Comparison](assets/From%20Task%20to%20Objective%20Comparison.png)

---

## Questions or feedback

Ping Ragnar Pitla on LinkedIn: https://www.linkedin.com/in/ragnarpitla/
