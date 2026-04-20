# Hermes Agent — Architecture Analysis for RAOS V2

## 1. OVERALL ARCHITECTURE

Hermes is a Python CLI AI agent (~50k+ LOC, ~3000 tests) with a clean layered design:

```
Entry Points:  hermes_cli/main.py (CLI), gateway/run.py (messaging), ui-tui/ (React TUI)
                    |                        |                           |
Core Agent:    run_agent.py (AIAgent class — synchronous conversation loop)
                    |
Tool Layer:    model_tools.py → tools/registry.py → tools/*.py (self-registering)
                    |
State:         hermes_state.py (SQLite + FTS5), ~/.hermes/config.yaml, ~/.hermes/.env
```

Key files:
- `run_agent.py` — AIAgent class with `chat()` and `run_conversation()` methods
- `model_tools.py` — Tool orchestration, discovery, dispatch
- `tools/registry.py` — Central tool registry (zero-dep, imported by all tools)
- `toolsets.py` — Grouping tools into named sets (research, coding, etc.)
- `cli.py` — HermesCLI class with Rich + prompt_toolkit
- `hermes_state.py` — SessionDB (SQLite WAL mode, FTS5 search)

## 2. SKILLS SYSTEM

Skills are stored in `~/.hermes/skills/` as JSON files. Each skill contains:
- A name and description
- Prompt content injected as a USER message (not system prompt — preserves prompt caching)
- Can be browsed/installed via `/skills` slash command (skills_hub.py)
- Managed via `skill_manage` tool (enable/disable per platform)
- Skills are essentially prompt templates that augment the agent's behavior

Key insight: Skills as user messages rather than system prompt modifications is a deliberate
cache-friendly design — system prompt stays stable across the conversation.

## 3. AGENT ORCHESTRATION / DELEGATION

`tools/delegate_tool.py` (~1200 lines) — sophisticated subagent system:

- **Isolation**: Each child gets fresh conversation, own task_id, own terminal session
- **Restricted toolsets**: Children get configurable tool access, with blocked tools
  (no recursive delegation, no user interaction, no memory writes, no cross-platform messaging)
- **Max depth = 2**: parent(0) → child(1) → grandchild rejected(2)
- **Parallel execution**: ThreadPoolExecutor with configurable max_concurrent_children (default 3)
- **Parent sees only summary**: Never the child's intermediate tool calls or reasoning
- **Global state management**: Saves/restores `_last_resolved_tool_names` around child execution

Pattern for RAOS: The "parent sees only summary" isolation model + blocked tool lists
is a clean delegation pattern.

## 4. MEMORY / PERSISTENCE

Two-tier system:

**Session State (hermes_state.py)**:
- SQLite with WAL mode (concurrent reads + single writer)
- FTS5 full-text search across all session messages
- Schema tracks: sessions, messages, token counts, costs, billing info
- Session splitting via parent_session_id chains (after context compression)
- Source tagging (cli, telegram, discord, etc.) for filtering
- `session_search` tool lets agent search past conversations

**Memory Tool**:
- MEMORY.md file — persistent notes the agent can read/write
- Blocked from subagents (only parent can write)

**Config/State**:
- `~/.hermes/config.yaml` — settings
- `~/.hermes/.env` — API keys
- `~/.hermes/state.db` — session database
- Profile support: fully isolated instances via HERMES_HOME override

## 5. TOOL SYSTEM

**Registration pattern** (tools/registry.py):
- Each tool file calls `registry.register()` at module level
- Auto-discovery: AST-scans `tools/*.py` for top-level `registry.register()` calls
- No manual import list needed
- Each registration includes: name, toolset, schema, handler, check_fn, requires_env

**Core tools** (_HERMES_CORE_TOOLS in toolsets.py):
- terminal, process (background process mgmt)
- read_file, write_file, patch, search_files
- web_search, web_extract
- browser_navigate/snapshot/click/type/scroll/back/press/get_images/vision/console/cdp
- vision_analyze, image_generate
- text_to_speech
- todo, memory
- session_search
- clarify (ask user questions)
- execute_code (sandbox)
- delegate_task (subagents)
- cronjob
- send_message (cross-platform)
- skills_list, skill_view, skill_manage
- MCP client (~1050 lines in mcp_tool.py)

**Terminal environments**: local, docker, ssh, modal, daytona, singularity

**Key pattern**: Tools return JSON strings. All handlers get `task_id` kwarg for session scoping.

## 6. DASHBOARD / UI

Three UI surfaces:

1. **Classic CLI** (cli.py) — Rich panels + prompt_toolkit autocomplete + KawaiiSpinner
2. **TUI** (ui-tui/) — Ink (React) terminal UI via `hermes --tui`
   - TypeScript frontend (Ink components) + Python backend (tui_gateway)
   - JSON-RPC over stdio between Node and Python
   - Full component library: branding, markdown, prompts, session picker, etc.
3. **Gateway** (gateway/) — Messaging platform adapters
   - Telegram, Discord, Slack, WhatsApp, Home Assistant, Signal, QQBot

**Skin engine** (hermes_cli/skin_engine.py):
- Data-driven theming — pure data, no code changes for new skins
- Customizes: banner colors, spinner faces/verbs/wings, tool prefix, branding
- Built-in skins: default, ares, mono, slate
- User skins: YAML files in `~/.hermes/skins/`

## 7. CONFIG MANAGEMENT

- `~/.hermes/config.yaml` — settings (DEFAULT_CONFIG in hermes_cli/config.py)
- `~/.hermes/.env` — API keys (OPTIONAL_ENV_VARS with metadata: description, prompt, url, category)
- Config version migration (currently v5) — auto-migrates on upgrade
- Interactive setup wizard (hermes_cli/setup.py)
- **Profiles**: Fully isolated instances, each with own HERMES_HOME
  - `hermes -p coder` runs with `~/.hermes/profiles/coder/`
  - All code uses `get_hermes_home()` — never hardcoded `~/.hermes`
- Provider credential resolution (hermes_cli/auth.py)

## 8. ERROR HANDLING / RETRIES

- `max_iterations` limit on agent loop (default 90)
- `iteration_budget.remaining` — token/cost budget tracking
- Dangerous command detection (tools/approval.py) — requires user approval
- Callback system for clarify, sudo, approval (hermes_cli/callbacks.py)
- Tool handlers return JSON with error info — agent sees errors as tool results

## 9. LOGGING / TRACING / OBSERVABILITY

- Python logging throughout
- Trajectory saving (agent/trajectory.py) — save full conversation traces
- Token counting per session (input, output, cache_read, cache_write, reasoning)
- Cost estimation and tracking (estimated vs actual USD)
- Session metadata: billing_provider, billing_base_url, billing_mode, cost_source

## 10. PATTERNS VALUABLE FOR RAOS V2

### A. Self-Registering Tool Pattern
Tools register themselves at import time via `registry.register()`. Auto-discovery
uses AST scanning — no manual import lists. This is the cleanest tool registration
pattern I've seen.

### B. Toolset Composition
Named toolsets that can include/exclude tools. Platforms get different toolsets.
`_HERMES_CORE_TOOLS` shared list ensures consistency.

### C. Delegation with Isolation
Subagents get fresh context, restricted tools, own task_id. Parent only sees summary.
Blocked tool list prevents dangerous recursion/side effects.

### D. Context Compression
Auto-compresses middle turns while protecting head+tail. Uses auxiliary (cheap) model.
Structured summary with Resolved/Pending tracking. Iterative updates across multiple
compactions. This is critical for long-running agents.

### E. Prompt Caching Awareness
System prompt stays stable. Skills injected as user messages. No mid-conversation
toolset changes. This saves significant cost on Anthropic.

### F. Profile Isolation
Full multi-instance support via HERMES_HOME override. Every state file, config,
session DB is scoped. Clean pattern for multi-tenant agent systems.

### G. Slash Command Registry
Single source of truth (CommandDef objects) that auto-generates: CLI dispatch,
gateway dispatch, help text, Telegram bot menus, Slack subcommands, autocomplete.

### H. Platform Gateway Pattern
Unified agent core with platform adapters. Same agent logic across CLI, Telegram,
Discord, Slack, WhatsApp, etc. Session store handles cross-platform persistence.

### I. Terminal Environment Abstraction
Same terminal tool works across local, docker, ssh, modal, daytona, singularity.
Clean backend abstraction.

### J. Skin/Theme Engine
Pure data-driven theming with inheritance (missing values fall back to default skin).
YAML-based user customization.

### K. Background Process Management
`process_registry.py` tracks background processes. Notify-on-complete pattern for
long-running tasks. Gateway watches for process completion to trigger new agent turns.

### L. MCP Client Integration
Full MCP (Model Context Protocol) client at ~1050 lines — connects to external tool servers.

---

## MOST INTERESTING/UNIQUE FEATURES

1. **AST-based auto-discovery of tools** — no registration boilerplate
2. **Prompt caching-aware architecture** — skills as user messages, stable system prompt
3. **Context compression with Active Task tracking** — keeps agent on track after compaction
4. **3-surface UI** (CLI + React TUI + messaging gateway) from single agent core
5. **Profile isolation** — multi-instance via HERMES_HOME, 119+ code references all scoped
6. **Skin engine** — data-driven theming with no code changes
7. **6 terminal backends** — local/docker/ssh/modal/daytona/singularity
8. **~3000 tests** with CI-parity wrapper script (hermetic env: unset keys, UTC, 4 workers)
9. **Delegate tool** with parallel execution, depth limits, and blocked tool lists
10. **ACP adapter** for VS Code / Zed / JetBrains integration
