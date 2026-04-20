# Agent Discovery — Self-Registering Agent Pattern

> Drop a YAML or Markdown file in the agents directory and it's auto-discovered at boot.

## How It Works

1. On startup, the OS scans `.claude/agents/` (or `.github/agents/`) for `*.md` and `*.yaml` files
2. Each file is parsed into an agent definition
3. All discovered agents are registered in an in-memory registry
4. The team-lead agent can assign tasks to any registered agent

No code changes needed. No config file to update. Just drop a file.

## Agent Definition Format (YAML)

### Required Fields

| Field           | Type       | Description                                    |
|-----------------|------------|------------------------------------------------|
| `name`          | string     | Unique agent identifier (e.g. `frontend-dev`)  |
| `role`          | string     | One-line role description                      |
| `description`   | string     | What this agent does, when to use it           |
| `allowed_tools` | list[str]  | Tools this agent can use                       |
| `triggers`      | list[str]  | Keywords/patterns that route tasks to this agent |

### Optional Fields

| Field              | Type   | Default   | Description                          |
|--------------------|--------|-----------|--------------------------------------|
| `max_iterations`   | int    | 10        | Max tool-call loops per task         |
| `model_preference` | string | (default) | Preferred model (e.g. `claude-opus`) |
| `cost_limit`       | float  | 5.00      | Max $ spend per invocation           |
| `timeout_minutes`  | int    | 30        | Hard timeout per task                |
| `dependencies`     | list   | []        | Other agents this one can delegate to |

## Example: YAML Agent Definition

```yaml
# .claude/agents/frontend-dev.yaml
name: frontend-dev
role: Frontend specialist
description: |
  Handles React/Vue/Svelte components, CSS, responsive design,
  accessibility audits, and frontend build pipelines.
allowed_tools:
  - read_file
  - write_file
  - terminal
  - search_files
  - browser
triggers:
  - frontend
  - react
  - css
  - component
  - UI
  - responsive
max_iterations: 15
model_preference: claude-sonnet
cost_limit: 3.00
```

## Example: Markdown Agent Definition

```markdown
# .claude/agents/devops.md
---
name: devops
role: DevOps and infrastructure specialist
allowed_tools: [terminal, read_file, write_file, search_files]
triggers: [deploy, docker, ci, pipeline, kubernetes, terraform]
max_iterations: 20
cost_limit: 5.00
---

You are a DevOps specialist. You handle:
- CI/CD pipeline configuration
- Docker and container orchestration
- Infrastructure as Code (Terraform, Pulumi)
- Cloud deployment (AWS, Azure, GCP)
- Monitoring and alerting setup

Always validate configs before applying. Never deploy to production without confirmation.
```

## Discovery Implementation

```python
import yaml
from pathlib import Path

def discover_agents(project_root: Path) -> dict:
    """Scan agents directory, return {name: AgentDef} registry."""
    registry = {}
    for agents_dir in [
        project_root / ".claude" / "agents",
        project_root / ".github" / "agents",
    ]:
        if not agents_dir.is_dir():
            continue
        for f in agents_dir.iterdir():
            if f.suffix == ".yaml":
                agent = yaml.safe_load(f.read_text())
            elif f.suffix == ".md":
                agent = parse_md_frontmatter(f.read_text())
            else:
                continue
            if agent and "name" in agent:
                registry[agent["name"]] = agent
    return registry
```

## Discovery Directory Structure

```
.claude/
  agents/
    team-lead.md          # orchestrator
    frontend-dev.yaml     # auto-discovered
    backend-dev.yaml      # auto-discovered
    devops.md             # auto-discovered
    qa-tester.yaml        # auto-discovered
```

## Agent Registry API

Once discovered, agents are queryable:

```python
registry = discover_agents(project_root)

# List all agents
names = list(registry.keys())

# Find agent by trigger keyword
def find_agent(keyword: str) -> str | None:
    for name, defn in registry.items():
        if keyword.lower() in [t.lower() for t in defn.get("triggers", [])]:
            return name
    return None

# Route a task
agent = find_agent("react")  # -> "frontend-dev"
```

## Validation

On discovery, validate each agent definition:

1. `name` must be unique across all discovered agents
2. `allowed_tools` must reference valid tool names
3. `triggers` must be non-empty (otherwise agent is never routed to)
4. `cost_limit` must be positive if set
5. Log warnings for malformed files, skip them, don't crash

## Hot Reload

For development, watch the agents directory:

```python
# Re-scan every N seconds or on file change
import time
last_scan = 0
SCAN_INTERVAL = 30  # seconds

def get_registry(project_root):
    global last_scan, _registry
    if time.time() - last_scan > SCAN_INTERVAL:
        _registry = discover_agents(project_root)
        last_scan = time.time()
    return _registry
```

## Best Practices

- One agent per file — keeps definitions atomic and diffable
- Use YAML for pure config, Markdown for agents with system prompts
- Keep trigger lists specific — avoid generic words like "code" or "help"
- Set conservative cost_limit defaults, raise per-agent as needed
- Version control your agents/ directory — it's your team definition
