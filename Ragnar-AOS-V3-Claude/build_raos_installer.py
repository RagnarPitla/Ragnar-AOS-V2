#!/usr/bin/env python3
"""Build Ragnar-AgenticOS-setup.md v2.0 as a single self-contained installer.

v2.0 — The Scaffold. Additive on top of v1.09:
  - Adds a durable harness layer (.agentic-os/runs/<run_id>/) with manifest,
    trace.ndjson, verification.yaml, checkpoint.json, costs.json.
  - Ships 4 Claude Code hooks: PreToolUse, PostToolUse, Stop, UserPromptSubmit.
  - Ships an evaluator subagent that runs with `context: fork`.
  - Ships 3 scheduler templates (launchd, Windows Task Scheduler, GitHub Actions).
  - Adds /raos resume|runs|kill subcommands.
  - Observability-only budgets by default. Flip `budgets.enforce: true` in a
    manifest for hard caps.

This script walks Ragnar-AOS-V2/ and embeds every blueprint file between
sentinel markers. Executable scripts (harness/hooks/*.sh, harness/bin/*.sh) use
a second sentinel pair (RAOS-EXEC-START/END) so the installer can chmod +x
them after writing to disk.

Skip list:
  - Ragnar-AgenticOS-setup*.md (the installer itself; we're writing it)
  - README.md (not part of the installable blueprint)
  - UPGRADE.md (guidance doc; lives alongside the installer, not embedded)
  - build_raos_installer.py (this script)
  - .DS_Store and other hidden files
"""

from pathlib import Path

SRC = Path(__file__).parent.resolve()
OUT = SRC / "Ragnar-AgenticOS-setup.md"

FILE_START = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~RAOS-FILE-START"
FILE_END = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~RAOS-FILE-END"

# New in V2: executable files get a second sentinel pair so the installer
# chmod +x them after write.
EXEC_START = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~RAOS-EXEC-START"
EXEC_END = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~RAOS-EXEC-END"

SKIP_PREFIXES = (
    "Ragnar-AgenticOS-setup",   # the installer itself
    "README.md",                 # folder-level README, not installable
    "UPGRADE.md",                # guidance doc, not installable
    "build_raos_installer.py",   # this script
    ".DS_Store",
    ".git",
)


def is_executable_blueprint(rel: str) -> bool:
    """Files that need chmod +x after install: everything under harness/hooks
    and harness/bin, except settings.json.fragment and non-shell templates."""
    if rel.startswith("harness/hooks/") and rel.endswith(".sh"):
        return True
    if rel.startswith("harness/bin/") and rel.endswith(".sh"):
        return True
    return False


HEADER = """---
name: ragnar-agentic-os-setup
version: 2.0
description: Factory installer for Ragnar's Agentic OS (RAOS) V2 — "The Scaffold". Use when user says "install Ragnar-AgenticOS", "install RAOS v2", "set up my Agentic OS", or invokes this file. V2 adds a durable harness layer on top of V1: run manifests in .agentic-os/runs/, 4 Claude Code hooks (PreToolUse/PostToolUse/Stop/UserPromptSubmit) for tracing + checkpointing + kill switch, an evaluator subagent that runs in a forked context, scheduler templates (launchd/Task Scheduler/GitHub Actions) for headless runs, and /raos resume|runs|kill subcommands. Everything V1 did still works — V2 is additive and back-compatible.
trigger: "install Ragnar-AgenticOS", "install Ragnar-AgenticOS v2", "set up my Agentic OS", "install RAOS", "install RAOS v2", "setup RAOS v2.0", "Ragnar-AgenticOS-setup", "upgrade to RAOS v2"
context: fork
agent: general-purpose
---

# Ragnar's Agentic OS. Factory Setup v2.0 — The Scaffold

**One file. Each teammate builds their OWN named Agentic OS from the RAOS V2 blueprint.**

By Ragnar Pitla. Share this single file with your team. They run it once. They name their own OS. Their terminal becomes an objective-oriented AI workspace — with durable runs, crash recovery, an independent evaluator, and optional headless scheduling.

V2 is additive on top of V1. If a teammate is on V1 (1.09), the installer detects it and migrates in place. No V1 data is lost.

---

## What's new in V2 — The Scaffold

1. **Run manifests.** Every `/raos <objective>` creates `.agentic-os/runs/<run_id>/` with manifest.yaml, trace.ndjson, verification.yaml, checkpoint.json, costs.json. Runs survive across sessions.
2. **Four Claude Code hooks.** PreToolUse (kill switch + auth gate), PostToolUse (trace + circuit breaker), Stop (checkpoint + costs), UserPromptSubmit (resume/kill detection + active-run banner).
3. **Evaluator subagent.** Runs with `context: fork`. Judges deliverables against verification.yaml before team-lead declares done. Max 3 revision iterations.
4. **Scheduler templates.** launchd (macOS), Task Scheduler XML (Windows), GitHub Actions YAML (cross-platform).
5. **/raos resume|runs|kill subcommands.** Continue a run, list runs, drop a kill sentinel.
6. **Observability-only budgets.** Track tool-call count, wall clock, $ estimates. No enforcement unless `budgets.enforce: true` in the manifest.

See the embedded `UPGRADE.md` and `references/the-scaffold.md` for the full thesis.

---

## The mental model

RAOS is a **factory**. Your teammate runs this installer and ends up with:

- **Their OS** (e.g., `kumi-os`, `alice-os`) installed as a skill under their chosen name in `~/.claude/skills/<their-name>/` and/or `~/.github/skills/<their-name>/`.
- **An auto-boot phrase** they picked (e.g., "Kumi", "hey Alice") that launches their OS from any project.
- **A local `.agentic-os/` memory + `.agentic-os/runs/` durable state** in each project so objectives survive across sessions.
- **Four hooks registered** in `~/.claude/settings.json` so the Scaffold primitives (trace, checkpoint, kill switch, resume banner) work automatically.
- **A self-improvement loop** that proposes new skills or upgrades every 7 days.

The blueprint is embedded in this file. No sibling folder, no repo clone, no npm.

---

## How to invoke this file

**In Claude Code:**
```
# Option A - drop the file anywhere in your project and say:
"Install Ragnar-AgenticOS v2 from ./Ragnar-AgenticOS-setup.md"

# Option B - copy to your skills folder and invoke by name:
cp Ragnar-AgenticOS-setup.md ~/.claude/skills/
# then in any session:
"Set up Ragnar-AgenticOS v2"
```

**In GitHub Copilot CLI:**
```
~/Ragnar-AgenticOS-setup.md
gh copilot
> install Ragnar-AgenticOS v2 from ~/Ragnar-AgenticOS-setup.md
```

When the AI reads this file, the instructions below tell it exactly what to do.

---

## AI Instructions (read carefully, follow exactly)

You are about to run the RAOS V2 factory. The user has invoked this file. Do the following, in this order. Do not skip steps.

### Step 0: Preserve main-conversation context

This file's frontmatter declares `context: fork` + `agent: general-purpose` so a supporting runtime runs the install in an isolated sub-agent. If your runtime honors that, great. If it does not, dispatch the heavy install work through the Agent tool with `subagent_type: general-purpose` and surface only the final install report back to the main conversation. Never dump the embedded blueprint into the main context — parse from THIS file, write to disk, report counts.

### Step 1: Greet, resolve USERNAME, ask the three naming questions

(Same as V1. Ask for OS_NAME slug, OS_DISPLAY name, OS_BOOT_PHRASE. Defaults: `my-agentic-os`, mirror name, first-name-ish phrase.)

### Step 2: Detect runtime + V1 presence

- Claude Code: `~/.claude/` exists.
- Copilot CLI: `~/.github/` exists.
- V1 presence: `.agentic-os/version.txt` exists in the current project AND reads `< 2.0`.

If V1 is present, set `MIGRATE_FROM_V1 = true`. The install will preserve V1 state and add V2 on top.

### Step 3: Parse and write the embedded blueprint

For each sentinel block below (either `RAOS-FILE-START/END` or `RAOS-EXEC-START/END`):

1. Read the relative path after the `START` sentinel.
2. Read the file contents until the matching `END` sentinel.
3. Destination path: `<SKILL_DIR>/<relative_path>`, where `<SKILL_DIR>` is the user's skill folder (`~/.claude/skills/<OS_NAME>/` or `~/.github/skills/<OS_NAME>/`).
4. Apply personalization rules:
   - In SKILL.md: replace `name: ragnar-agentic-os-setup` with `name: <OS_NAME>`, replace `Ragnar's Agentic OS` titles with `<OS_DISPLAY>`.
   - In `commands/raos.md`: rename to `commands/<OS_NAME>.md` on write.
   - In scheduler templates, harness/settings.json.fragment, and headless.sh: replace `<OS_NAME>` and `<SKILL_DIR>` placeholders with the resolved values.
5. Write the file. If the block used `RAOS-EXEC-START/END`, `chmod +x` the destination after writing.

### Step 4: Register the V2 hooks in ~/.claude/settings.json

Read `<SKILL_DIR>/harness/settings.json.fragment`. Replace `<SKILL_DIR>` placeholders with the resolved absolute skill folder path. Merge the `hooks` object into `~/.claude/settings.json`. If settings.json has pre-existing hooks, APPEND to the arrays for each event — do not overwrite.

### Step 5: Wire the auto-boot block in ~/.claude/CLAUDE.md

(Same as V1 — a named sentinel block keyed to `<OS_NAME>` and `<OS_BOOT_PHRASE>`. If `MIGRATE_FROM_V1`, replace the existing V1 block in place; otherwise append.)

### Step 6: Set up local memory + runs folder

```
.agentic-os/
├── memory.md               (V1 — preserve if MIGRATE_FROM_V1)
├── routines.md             (V1 — preserve if MIGRATE_FROM_V1)
├── os.txt                  (V1 — preserve)
├── version.txt             (bump to 2.0)
└── runs/                   (NEW — empty on fresh install; preserve on migrate)
```

If `MIGRATE_FROM_V1`:
1. Create `.agentic-os/runs/` if missing.
2. Append to `.agentic-os/memory.md`: `"Upgraded to RAOS 2.0 (Scaffold) on <date>. Prior observations preserved. Run state from this point lives in .agentic-os/runs/."`
3. Bump `.agentic-os/version.txt` to `2.0`.
4. Existing tasks.json is left intact — V2 added optional `run_id` fields but does not require them for old objectives.

### Step 7: Report to the user

Print the V2 install summary: what was written, V1→V2 migration status, where to find `UPGRADE.md`, how to invoke `/raos`, `/raos resume`, `/raos runs`, `/raos kill`, and how to wire a scheduled run if they want one. Include a one-line pointer to `references/the-scaffold.md` for the thesis.

### Step 8: Done

Do not auto-invoke `/raos`. The user decides when to boot their OS.

---

## Versioning

- **Version:** 2.0
- **Date:** 2026-04-19
- **Changelog from 1.09:** The Scaffold. Durable run manifests in `.agentic-os/runs/<run_id>/`. Four Claude Code hooks (PreToolUse/PostToolUse/Stop/UserPromptSubmit). Evaluator subagent with `context: fork`. Scheduler templates for macOS (launchd), Windows (Task Scheduler), and cross-platform (GitHub Actions). `/raos resume|runs|kill` subcommands. Observability-only budgets. Team-lead now dispatches the evaluator before declaring done. tasks.json schema adds optional `run_id` fields (additive).

When Ragnar ships a newer version (e.g., v2.1), teammates whose `.agentic-os/version.txt` reads `2.0` get prompted to re-run the newer installer and pull the upstream improvements.

---

## Uninstall

If the user asks to uninstall their OS:

1. Remove `~/.claude/skills/<OS_NAME>/` and/or `~/.github/skills/<OS_NAME>/`.
2. Remove the `<!-- AGENTIC-OS-AUTOBOOT-v... name=<OS_NAME> -->` and `<!-- AGENTIC-OS-IMPROVEMENT-v... name=<OS_NAME> -->` blocks from `~/.claude/CLAUDE.md`. Leave blocks belonging to other OSes alone.
3. Remove the V2 hook entries from `~/.claude/settings.json` that reference `<SKILL_DIR>/harness/hooks/`. Leave unrelated hooks alone.
4. Leave `.agentic-os/` folders in projects alone. They contain runs + learnings.

Confirm with user before deleting anything.

---

# EMBEDDED FILES

Below, each RAOS V2 blueprint file is embedded between sentinel markers. Parse them during Step 3 of the install.

Two sentinel pairs:
- `RAOS-FILE-START` / `RAOS-FILE-END` — regular text files.
- `RAOS-EXEC-START` / `RAOS-EXEC-END` — executable scripts. Installer must `chmod +x` these after writing.

"""


def main() -> None:
    files = []
    for p in sorted(SRC.rglob("*")):
        if not p.is_file():
            continue
        rel = p.relative_to(SRC).as_posix()
        if any(rel.startswith(prefix) or rel == prefix for prefix in SKIP_PREFIXES):
            continue
        files.append((rel, p))

    parts = [HEADER]

    exec_count = 0
    for rel, p in files:
        try:
            content = p.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            # Skip binary files (e.g., images in assets/)
            print(f"  skipping binary: {rel}")
            continue

        if is_executable_blueprint(rel):
            start, end = EXEC_START, EXEC_END
            exec_count += 1
        else:
            start, end = FILE_START, FILE_END

        parts.append(f"\n{start} {rel}\n")
        parts.append(content)
        if not content.endswith("\n"):
            parts.append("\n")
        parts.append(f"{end}\n")

    parts.append(
        f"\n---\n\n**End of embedded files.** Total: {len(files)} blueprint files "
        f"({exec_count} executable).\n\n"
    )
    parts.append(
        "If you are an AI reading this file as a user invocation, you should now be in "
        "Step 7 (report what was installed). If you haven't done Steps 1-6 yet, go back "
        "to the top and start over. Do not skip ahead.\n"
    )

    output = "".join(parts)
    OUT.write_text(output, encoding="utf-8")
    print(f"Wrote {OUT}")
    print(f"Size: {len(output):,} bytes ({len(output) / 1024:.1f} KB)")
    print(f"Embedded: {len(files)} files ({exec_count} executable)")


if __name__ == "__main__":
    main()
