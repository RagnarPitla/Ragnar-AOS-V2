# Install Guide — Ragnar's Agentic OS V3

## Prerequisites

- **Claude Code CLI** installed and authenticated
  ```bash
  # Verify Claude Code is working:
  claude --version
  ```
- **Python 3.10+** (for the dashboard)
- **Git** (to clone the repo)

## Option A: Install from GitHub (Recommended)

```bash
# 1. Clone the repo
git clone https://github.com/RagnarPitla/Ragnar-AOS-V2.git
cd Ragnar-AOS-V2

# 2. Copy the installer to your project
cp Ragnar-AOS-V3-Claude/Ragnar-AgenticOS-setup.md ~/your-project/

# 3. Open Claude Code in your project
cd ~/your-project
claude

# 4. Tell Claude to install
> Install Ragnar-AgenticOS from ./Ragnar-AgenticOS-setup.md
```

## Option B: Install from a shared file

If someone sent you `Ragnar-AgenticOS-setup.md` directly:

```bash
# 1. Drop it in your project folder
cp ~/Downloads/Ragnar-AgenticOS-setup.md ~/your-project/

# 2. Open Claude Code
cd ~/your-project
claude

# 3. Tell Claude to install
> Install Ragnar-AgenticOS from ./Ragnar-AgenticOS-setup.md
```

## Option C: Install as a global skill

```bash
# 1. Copy to your Claude skills folder (works from any project)
cp Ragnar-AgenticOS-setup.md ~/.claude/skills/

# 2. From any project, just say:
claude
> Install Ragnar-AgenticOS
```

## What happens during install

The installer will ask you 3 questions:

1. **OS slug** — a short kebab-case name (e.g., `kumi-os`, `contoso-os`)
2. **Display name** — what the OS calls itself (e.g., "Kumi's Agentic OS")
3. **Wake phrase** — the phrase that boots the team (e.g., "Hey Kumi")

Then it:
- Writes ~70 blueprint files to `~/.claude/skills/<your-os-name>/`
- Registers 4 hooks in `~/.claude/settings.json`
- Wires auto-boot in `~/.claude/CLAUDE.md`
- Creates `.agentic-os/` and `.agentic-os/runs/` in your project

## Verify the install

```bash
# Open Claude Code in your project
cd ~/your-project
claude

# Boot your OS with your wake phrase
> Hey Kumi

# Or use the slash command
> /raos status
```

You should see your OS boot up, introduce itself, and be ready for objectives.

## Common commands after install

| Command | What it does |
|---|---|
| `/raos <objective>` | Start a new objective (Research → Challenge → Synthesis → Verify) |
| `/raos status` | Show current run status, phase, and budget usage |
| `/raos runs` | List all runs (active, paused, done, killed) |
| `/raos resume <run_id>` | Resume a paused or crashed run |
| `/raos kill <run_id>` | Kill a running objective immediately |

## Dashboard (Mission Control)

```bash
python3 dashboard/server.py --project /path/to/your-project
# Opens http://localhost:9200
```

## Upgrading from V1?

See [UPGRADE.md](UPGRADE.md). V2 is additive — your V1 data is preserved.

## Uninstall

In Claude Code, say: "Uninstall my Agentic OS". The installer handles cleanup.

## Questions

Ping Ragnar Pitla on LinkedIn: https://www.linkedin.com/in/ragnarpitla/
