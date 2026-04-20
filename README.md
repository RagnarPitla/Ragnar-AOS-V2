# Ragnar's Agentic OS V2 — "The Scaffold"

Two ready-to-use versions of RAOS V2:

| Folder | Runtime | Who it's for |
|--------|---------|-------------|
| `Ragnar-AOS-V2-Claude/` | Claude Code CLI | Ragnar (creator) |
| `Ragnar-AOS-V2-GitHub/` | GitHub Copilot CLI | Microsoft team |

## Quick Start

Pick the folder matching your CLI, then follow the `QUICKSTART.md` inside.

## Dashboard

Both versions include a local web dashboard (`dashboard/server.py`) for onboarding and live task monitoring:

```bash
python3 Ragnar-AOS-V2-Claude/dashboard/server.py --project /path/to/project
```

Opens http://localhost:9200.

---

# Ragnar's Agentic OS V3 — "The Hermes Update"

V3 builds on V2's Scaffold with 12 new features borrowed from Hermes Agent patterns and 8 bug fixes.

## V3 Folder Comparison

| Folder | Runtime | Files | Who it's for |
|--------|---------|-------|-------------|
| `Ragnar-AOS-V3-Claude/` | Claude Code CLI | 75 | Ragnar (creator) |
| `Ragnar-AOS-V3-GitHub/` | GitHub Copilot CLI | 79 | Microsoft team |

## What's New in V3

### 12 New Features

1. **Context Window Management** — auto-summarize conversations, Active Task tracking to stay focused
2. **Delegation Contracts** — isolation model for subagents with restricted tools and depth limits
3. **Agent Auto-Discovery** — agents self-register from the `agents/` directory
4. **Background Tasks** — fire-and-forget and notify-on-complete patterns
5. **Session Persistence** — SQLite + FTS5 full-text history search across sessions
6. **Profile Isolation** — multiple configurations via `RAOS_HOME` environment variable
7. **Dashboard Theme Engine** — YAML skins, theme switcher, 2 built-in themes
8. **Cost/Token Tracking** — per-objective budgets with real-time monitoring
9. **MCP Integration** — connect external tool servers via Model Context Protocol
10. **Platform Gateway** — multi-platform adapters (Claude, Copilot, etc.)
11. **Terminal Backends** — local/docker/ssh/cloud execution abstraction
12. **Command Registry** — single source of truth for all slash commands

### 8 Bug Fixes

1. Fixed `detect_runtime` labels (correct platform detection)
2. Added `.github/` path support for Copilot CLI skill installation
3. Fixed installer path resolution for nested project structures
4. Fixed schema paths in manifest and verification templates
5. Fixed hooks docstring formatting (Claude Code hook descriptions)
6. Added reference doc Copilot equivalents (parity across runtimes)
7. Removed redundant template file (dead code cleanup)
8. Documented Python 3.10+ as minimum requirement

## New Reference Docs in V3

Both V3 folders include these new reference documents:

- `references/context-window-management.md`
- `references/delegation-contracts.md`
- `references/background-tasks.md`
- `references/session-persistence.md`
- `references/profile-isolation.md`
- `references/dashboard-themes.md`
- `references/cost-tracking.md`
- `references/mcp-integration.md`
- `references/platform-gateway.md`
- `references/terminal-backends.md`
- `references/command-registry.md`

## Changelog: V2 → V3

- **Added**: Context window management with auto-summarize and active task tracking
- **Added**: Delegation contracts with isolation, restricted tools, depth limits
- **Added**: Agent auto-discovery from `agents/` directory
- **Added**: Background task execution (fire-and-forget + notify-on-complete)
- **Added**: Session persistence via SQLite with FTS5 full-text search
- **Added**: Profile isolation via `RAOS_HOME` for multi-config setups
- **Added**: Dashboard theme engine with YAML skins and 2 built-in themes
- **Added**: Cost/token tracking with per-objective budgets
- **Added**: MCP integration for external tool server connections
- **Added**: Platform gateway with multi-platform adapters
- **Added**: Terminal backend abstraction (local/docker/ssh/cloud)
- **Added**: Command registry as single source of truth
- **Fixed**: `detect_runtime` labels now correctly identify the platform
- **Fixed**: `.github/` path support for Copilot CLI installations
- **Fixed**: Installer path resolution for nested projects
- **Fixed**: Schema paths in manifest and verification templates
- **Fixed**: Hooks docstring formatting
- **Fixed**: Reference doc parity — Copilot equivalents added
- **Removed**: Redundant template file
- **Docs**: Python 3.10+ minimum requirement documented

---

## Author

Ragnar Pitla — [LinkedIn](https://www.linkedin.com/in/ragnarpitla/)
