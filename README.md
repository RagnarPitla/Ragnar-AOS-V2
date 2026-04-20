# Ragnar's Agentic OS — V3

One file. Each teammate builds their OWN named Agentic OS. Their terminal becomes an objective-oriented AI workspace — with durable runs, crash recovery, an independent evaluator, and optional headless scheduling.

## Get Started

| Folder | Runtime | Install Guide |
|--------|---------|---------------|
| `Ragnar-AOS-V3-Claude/` | Claude Code CLI | [Install-guide.md](Ragnar-AOS-V3-Claude/Install-guide.md) |
| `Ragnar-AOS-V3-GitHub/` | GitHub Copilot CLI | [Install-guide.md](Ragnar-AOS-V3-GitHub/Install-guide.md) |

Pick the folder matching your CLI and follow the Install Guide.

## What V3 includes

### The Scaffold (from V2)

- **Run manifests** — every objective creates `.agentic-os/runs/<run_id>/` with manifest, trace, verification, checkpoint, costs
- **4 Claude Code hooks** — PreToolUse (kill switch), PostToolUse (trace), Stop (checkpoint), UserPromptSubmit (resume detection)
- **Evaluator subagent** — judges deliverables before the team-lead declares done (max 3 revisions)
- **Scheduler templates** — launchd (macOS), Task Scheduler (Windows), GitHub Actions (cross-platform)
- **/raos commands** — `resume`, `runs`, `kill`, `status`
- **Observability-only budgets** — track tool calls, wall clock, $ estimates

### 12 New Features (V3)

1. **Context Window Management** — auto-summarize, Active Task tracking
2. **Delegation Contracts** — subagent isolation with restricted tools and depth limits
3. **Agent Auto-Discovery** — agents self-register from the `agents/` directory
4. **Background Tasks** — fire-and-forget and notify-on-complete patterns
5. **Session Persistence** — SQLite + FTS5 full-text history search
6. **Profile Isolation** — multiple configs via `RAOS_HOME`
7. **Dashboard Theme Engine** — JSON skins, theme switcher, 2 built-in themes
8. **Cost/Token Tracking** — per-objective budgets with real-time monitoring
9. **MCP Integration** — external tool servers via Model Context Protocol
10. **Platform Gateway** — multi-platform adapters (Claude, Copilot, etc.)
11. **Terminal Backends** — local/docker/ssh/cloud execution abstraction
12. **Command Registry** — single source of truth for all slash commands

### 8 Bug Fixes (V3)

1. Fixed `detect_runtime` labels (correct platform detection)
2. Added `.github/` path support for Copilot CLI
3. Fixed installer path resolution for nested projects
4. Fixed schema paths in manifest and verification templates
5. Fixed hooks docstring formatting
6. Added reference doc Copilot equivalents (runtime parity)
7. Removed redundant template file
8. Documented Python 3.10+ minimum requirement

## Dashboard (Mission Control)

```bash
python3 dashboard/server.py --project /path/to/your-project
# Opens http://localhost:9200
```

Onboarding wizard + live task kanban. Supports theme switching (default + dark).

## V2 Archive

V2 folders are preserved for reference:

| Folder | Runtime |
|--------|---------|
| `Ragnar-AOS-V2-Claude/` | Claude Code CLI |
| `Ragnar-AOS-V2-GitHub/` | GitHub Copilot CLI |

V3 is a superset of V2. Use V3.

---

**Author:** Ragnar Pitla — [LinkedIn](https://www.linkedin.com/in/ragnarpitla/)
