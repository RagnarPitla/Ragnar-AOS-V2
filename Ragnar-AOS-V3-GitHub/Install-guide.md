# Install Guide — Ragnar's Agentic OS V3 for GitHub Copilot CLI

## Prerequisites

```bash
# 1. Install GitHub CLI
brew install gh            # macOS
winget install GitHub.cli  # Windows

# 2. Authenticate
gh auth login

# 3. Install the Copilot extension
gh extension install github/gh-copilot

# 4. Verify it works
gh copilot --version
```

- **Python 3.10+** (for the dashboard)
- **Git** (to clone the repo)

## Option A: Install from GitHub (Recommended)

```bash
# 1. Clone the repo
git clone https://github.com/RagnarPitla/Ragnar-AOS-V2.git
cd Ragnar-AOS-V2

# 2. Copy the installer to your project
cp Ragnar-AOS-V3-GitHub/Ragnar-AgenticOS-setup.md ~/your-project/

# 3. Open Copilot CLI in your project
cd ~/your-project
gh copilot

# 4. Tell Copilot to install
> Install Ragnar-AgenticOS v2 from ./Ragnar-AgenticOS-setup.md
```

## Option B: Install from a shared file

If someone sent you `Ragnar-AgenticOS-setup.md` directly:

```bash
# 1. Drop it in your project folder
cp ~/Downloads/Ragnar-AgenticOS-setup.md ~/your-project/

# 2. Open Copilot CLI
cd ~/your-project
gh copilot

# 3. Tell Copilot to install
> Install Ragnar-AgenticOS v2 from ./Ragnar-AgenticOS-setup.md
```

## Option C: Install as a global skill

```bash
# 1. Copy to your GitHub skills folder (works from any project)
mkdir -p ~/.github/skills
cp Ragnar-AgenticOS-setup.md ~/.github/skills/

# 2. From any project, just say:
gh copilot
> Install Ragnar-AgenticOS
```

## What happens during install

The installer will ask you 3 questions:

1. **OS slug** — a short kebab-case name (e.g., `kumi-os`, `contoso-os`)
2. **Display name** — what the OS calls itself (e.g., "Kumi's Agentic OS")
3. **Wake phrase** — the phrase that boots the team (e.g., "Hey Kumi")

Then it:
- Writes ~79 blueprint files to `~/.github/skills/<your-os-name>/`
- Wires auto-boot in `~/.github/instructions.md`
- Creates `.agentic-os/` and `.agentic-os/runs/` in your project

## Verify the install

```bash
cd ~/your-project
gh copilot

# Boot your OS with your wake phrase
> Hey Kumi

# Or use the slash command
> /raos status
```

## Common commands after install

| Command | What it does |
|---|---|
| `/raos <objective>` | Start a new objective (Research → Challenge → Synthesis → Verify) |
| `/raos status` | Show current run status, phase, and budget usage |
| `/raos runs` | List all runs (active, paused, done, killed) |
| `/raos resume <run_id>` | Resume a paused or crashed run |
| `/raos kill <run_id>` | Kill a running objective immediately |

## Copilot CLI limitations vs Claude Code

GitHub Copilot CLI does not support Claude Code's hook system. This means:
- **No automatic tracing** — the team-lead writes checkpoints at phase boundaries
- **No automatic kill switch** — tell the team-lead "stop" or cancel the session
- **No automatic circuit breaker** — the team-lead pauses after repeated failures

These are observability trade-offs, not functionality losses. See [HOOKS-DEGRADED.md](HOOKS-DEGRADED.md) for details.

**Headless/scheduled runs** work best through GitHub Actions. See `harness/schedule/github-actions.yaml.template`.

## Dashboard (Mission Control)

```bash
python3 dashboard/server.py --project /path/to/your-project
# Opens http://localhost:9200
```

## Upgrading from V1?

See [UPGRADE.md](UPGRADE.md). V2 is additive — your V1 data is preserved.

## Uninstall

In Copilot CLI, say: "Uninstall my Agentic OS". The installer handles cleanup.

## Questions

Ping Ragnar Pitla on LinkedIn: https://www.linkedin.com/in/ragnarpitla/
