# Profile Isolation

## Problem

One agent configuration doesn't fit all contexts. A code reviewer agent needs different tools, memory, and rules than a DevOps agent. A production environment needs different guardrails than development. Without isolation, agents share state and config in ways that cause conflicts.

## Core Pattern: Home Directory Override

A single environment variable — `RAOS_HOME` — controls where all agent state lives. Every profile gets its own fully isolated directory tree.

```
~/.raos/                          # Default profile
~/.raos-profiles/
  ├── coder/                      # Coder profile
  │   ├── config.yaml
  │   ├── state/
  │   │   └── sessions.db
  │   ├── skills/
  │   └── memory/
  ├── reviewer/                   # Reviewer profile
  │   ├── config.yaml
  │   ├── state/
  │   │   └── sessions.db
  │   ├── skills/
  │   └── memory/
  └── devops/                     # DevOps profile
      ├── config.yaml
      ├── state/
      │   └── sessions.db
      ├── skills/
      └── memory/
```

## Implementation

### The Golden Rule: `get_raos_home()`

Every piece of code that touches the filesystem MUST use this function. Never hardcode paths.

```python
import os

def get_raos_home() -> str:
    """Get the RAOS home directory. All paths derive from this."""
    return os.environ.get("RAOS_HOME", os.path.expanduser("~/.raos"))

def get_config_path() -> str:
    return os.path.join(get_raos_home(), "config.yaml")

def get_state_db_path() -> str:
    return os.path.join(get_raos_home(), "state", "sessions.db")

def get_skills_dir() -> str:
    return os.path.join(get_raos_home(), "skills")

def get_memory_dir() -> str:
    return os.path.join(get_raos_home(), "memory")
```

### Profile Switching via CLI

```bash
# Use a specific profile
raos -p coder "Write the auth module"
raos -p reviewer "Review PR #42"
raos -p devops "Deploy to staging"

# Under the hood, -p sets RAOS_HOME:
# raos -p coder → RAOS_HOME=~/.raos-profiles/coder raos "..."
```

### Profile Initialization

```python
def init_profile(name: str) -> str:
    """Create a new isolated profile."""
    base = os.path.expanduser("~/.raos-profiles")
    profile_dir = os.path.join(base, name)
    
    # Create directory structure
    os.makedirs(os.path.join(profile_dir, "state"), exist_ok=True)
    os.makedirs(os.path.join(profile_dir, "skills"), exist_ok=True)
    os.makedirs(os.path.join(profile_dir, "memory"), exist_ok=True)
    
    # Create default config
    default_config = {
        "profile_name": name,
        "model": "claude-sonnet-4-20250514",
        "max_iterations": 50,
        "allowed_tools": ["all"],
        "system_prompt_additions": "",
    }
    
    config_path = os.path.join(profile_dir, "config.yaml")
    with open(config_path, "w") as f:
        yaml.dump(default_config, f)
    
    return profile_dir
```

## What Each Profile Isolates

| Component | What's Isolated | Why |
|-----------|----------------|-----|
| `config.yaml` | Model, tools, limits, prompts | Different agents need different capabilities |
| `state/sessions.db` | Conversation history | Reviewer shouldn't see coder's debug sessions |
| `skills/` | Learned procedures/scripts | DevOps skills ≠ coding skills |
| `memory/` | Persistent knowledge store | Project-specific institutional knowledge |

## Use Cases

### 1. Role-Based Profiles

```yaml
# ~/.raos-profiles/coder/config.yaml
profile_name: coder
model: claude-sonnet-4-20250514
max_iterations: 100
allowed_tools: [read_file, write_file, patch, search_files, terminal]
system_prompt_additions: |
  You are a senior software engineer. Write clean, tested code.
  Always run tests after changes. Follow existing code patterns.

# ~/.raos-profiles/reviewer/config.yaml
profile_name: reviewer
model: claude-sonnet-4-20250514
max_iterations: 30
allowed_tools: [read_file, search_files, terminal]  # No write access
system_prompt_additions: |
  You are a code reviewer. Read code, find bugs, suggest improvements.
  Never modify files directly. Output review comments only.
```

### 2. Environment-Based Profiles

```yaml
# ~/.raos-profiles/dev/config.yaml
profile_name: dev
max_cost_per_session: 5.00
allowed_tools: [all]
dangerous_tool_confirmation: false

# ~/.raos-profiles/prod/config.yaml
profile_name: prod
max_cost_per_session: 1.00
allowed_tools: [read_file, search_files, terminal]  # No write in prod
dangerous_tool_confirmation: true
required_approval: [terminal]  # Human approval for shell commands
```

### 3. Project-Specific Profiles

```yaml
# ~/.raos-profiles/project-alpha/config.yaml
profile_name: project-alpha
model: claude-sonnet-4-20250514
system_prompt_additions: |
  Project Alpha uses:
  - TypeScript + Next.js 14
  - PostgreSQL + Prisma ORM
  - pnpm for package management
  - Vitest for testing
  Always use these technologies. Check prisma schema before DB work.
```

## Profile Composition

For advanced setups, profiles can inherit from a base:

```yaml
# ~/.raos-profiles/base/config.yaml
model: claude-sonnet-4-20250514
max_iterations: 50

# ~/.raos-profiles/coder/config.yaml
inherits: base
max_iterations: 100  # Override
allowed_tools: [all]  # Add
```

```python
def load_config(profile_dir: str) -> dict:
    config_path = os.path.join(profile_dir, "config.yaml")
    with open(config_path) as f:
        config = yaml.safe_load(f)
    
    if "inherits" in config:
        base_dir = os.path.join(os.path.dirname(profile_dir), config["inherits"])
        base_config = load_config(base_dir)
        base_config.update(config)
        return base_config
    
    return config
```

## Rules for Agents

1. **Always use `get_raos_home()`.** Never write `~/.raos` directly in code.
2. **Check `RAOS_HOME` at startup.** Log which profile is active.
3. **Don't cross profile boundaries.** A coder profile must never read reviewer's state.
4. **Initialize on first use.** If the profile directory doesn't exist, create it.
5. **Profiles are disposable.** Delete a profile directory to reset completely.
6. **Default is default.** If no `-p` flag, use `~/.raos` as the default profile.
