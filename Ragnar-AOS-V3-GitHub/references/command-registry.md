# Command Registry — Single Source of Truth for All Commands

> Define a command once. It works everywhere: CLI, Telegram, Discord, Slack.

## The Problem

Without a registry, commands are duplicated:
- CLI handler in `cli.py`
- Telegram handler in `telegram_bot.py`
- Slash command in `discord_bot.py`
- Each with different argument parsing, help text, error handling

## Core Pattern

One `CommandDef` defines everything. The registry auto-generates platform-specific dispatchers.

```python
@dataclass
class CommandArg:
    name: str
    type: str              # "string", "int", "bool", "choice"
    description: str
    required: bool = True
    default: Any = None
    choices: list = None   # for type="choice"

@dataclass
class CommandDef:
    name: str                    # "/status"
    description: str             # "Show system status"
    handler: Callable            # async function to execute
    aliases: list[str] = None   # ["/s", "/stat"]
    platforms: list[str] = None # None = all platforms
    args: list[CommandArg] = None
    hidden: bool = False         # hide from help/menus
    admin_only: bool = False
```

## Registry

```python
class CommandRegistry:
    def __init__(self):
        self._commands: dict[str, CommandDef] = {}
    
    def register(self, cmd: CommandDef):
        self._commands[cmd.name] = cmd
        for alias in (cmd.aliases or []):
            self._commands[alias] = cmd
    
    def get(self, name: str) -> CommandDef | None:
        return self._commands.get(name)
    
    def list_for_platform(self, platform: str) -> list[CommandDef]:
        seen = set()
        result = []
        for cmd in self._commands.values():
            if cmd.name in seen or cmd.hidden:
                continue
            if cmd.platforms is None or platform in cmd.platforms:
                result.append(cmd)
                seen.add(cmd.name)
        return sorted(result, key=lambda c: c.name)
    
    def dispatch(self, text: str, platform: str) -> tuple[CommandDef, dict] | None:
        """Parse command + args from text, return (cmd, parsed_args)."""
        parts = text.strip().split()
        if not parts:
            return None
        cmd = self.get(parts[0])
        if not cmd:
            return None
        if cmd.platforms and platform not in cmd.platforms:
            return None
        args = self._parse_args(cmd, parts[1:])
        return cmd, args
```

## Defining Commands

```python
registry = CommandRegistry()

# /status — works everywhere
registry.register(CommandDef(
    name="/status",
    description="Show system status and uptime",
    handler=handle_status,
    aliases=["/s", "/stat"],
))

# /deploy — CLI and Slack only
registry.register(CommandDef(
    name="/deploy",
    description="Deploy to environment",
    handler=handle_deploy,
    aliases=["/d"],
    platforms=["cli", "slack"],
    args=[
        CommandArg("env", "choice", "Target environment", choices=["staging", "production"]),
        CommandArg("force", "bool", "Skip confirmation", required=False, default=False),
    ],
))

# /tasks — universal
registry.register(CommandDef(
    name="/tasks",
    description="List current tasks and their status",
    handler=handle_tasks,
    aliases=["/t"],
))
```

## Auto-Generated Outputs

### CLI Help Text

```python
def generate_help(registry: CommandRegistry) -> str:
    lines = ["Available commands:\n"]
    for cmd in registry.list_for_platform("cli"):
        aliases = f" ({', '.join(cmd.aliases)})" if cmd.aliases else ""
        lines.append(f"  {cmd.name:<16}{cmd.description}{aliases}")
        if cmd.args:
            for arg in cmd.args:
                req = "required" if arg.required else f"default: {arg.default}"
                lines.append(f"    --{arg.name:<12} {arg.description} [{req}]")
    return "\n".join(lines)
```

Output:
```
Available commands:

  /status         Show system status and uptime (/s, /stat)
  /deploy         Deploy to environment (/d)
    --env          Target environment [required]
    --force        Skip confirmation [default: False]
  /tasks          List current tasks and their status (/t)
```

### CLI Autocomplete

```python
def generate_completions(registry: CommandRegistry) -> list[str]:
    completions = []
    for cmd in registry.list_for_platform("cli"):
        completions.append(cmd.name)
        completions.extend(cmd.aliases or [])
    return completions

# For bash/zsh completion scripts
def generate_bash_completions(registry):
    cmds = generate_completions(registry)
    return f'complete -W "{" ".join(cmds)}" raos'
```

### Telegram Bot Menu

```python
async def set_telegram_commands(bot, registry: CommandRegistry):
    """Register commands with Telegram's BotFather menu."""
    commands = []
    for cmd in registry.list_for_platform("telegram"):
        # Telegram commands don't have leading /
        name = cmd.name.lstrip("/")
        commands.append(BotCommand(name, cmd.description[:256]))
    await bot.set_my_commands(commands)

# Result: Telegram shows command autocomplete in chat
```

### Discord Slash Commands

```python
async def register_discord_commands(client, registry: CommandRegistry):
    for cmd in registry.list_for_platform("discord"):
        options = []
        for arg in (cmd.args or []):
            opt_type = {"string": 3, "int": 4, "bool": 5, "choice": 3}[arg.type]
            opt = {"name": arg.name, "description": arg.description,
                   "type": opt_type, "required": arg.required}
            if arg.choices:
                opt["choices"] = [{"name": c, "value": c} for c in arg.choices]
            options.append(opt)
        await client.create_global_command(
            name=cmd.name.lstrip("/"),
            description=cmd.description,
            options=options
        )
```

### Slack Interactive Menus

```python
def generate_slack_blocks(registry: CommandRegistry) -> list:
    """Generate Slack Block Kit command menu."""
    actions = []
    for cmd in registry.list_for_platform("slack"):
        actions.append({
            "type": "button",
            "text": {"type": "plain_text", "text": cmd.name},
            "action_id": f"cmd_{cmd.name.lstrip('/')}",
            "value": cmd.name
        })
    return [{"type": "actions", "elements": actions}]
```

## Platform-Specific Response Rendering

```python
async def execute_and_respond(cmd, args, platform):
    result = await cmd.handler(**args)
    
    if platform == "cli":
        # Rich terminal output with colors
        return format_cli(result)
    elif platform == "telegram":
        # Markdown with inline keyboards for actions
        return format_telegram(result)
    elif platform == "discord":
        # Embed with fields
        return format_discord_embed(result)
    elif platform == "slack":
        # Block Kit with sections
        return format_slack_blocks(result)
```

## Plugin Extensibility

Plugins register commands at startup:

```python
# plugins/monitoring.py
def register(registry: CommandRegistry):
    registry.register(CommandDef(
        name="/health",
        description="Run health checks on all services",
        handler=health_check,
        aliases=["/hc"],
    ))
    registry.register(CommandDef(
        name="/metrics",
        description="Show system metrics",
        handler=show_metrics,
    ))

# main.py — load plugins
for plugin in discover_plugins():
    plugin.register(registry)
```

## Example: /status End-to-End

Define once:
```python
registry.register(CommandDef(
    name="/status",
    description="Show system status",
    handler=handle_status,
))

async def handle_status() -> dict:
    return {
        "uptime": get_uptime(),
        "tasks": {"total": 12, "done": 8, "active": 3, "blocked": 1},
        "agents": ["frontend", "backend", "devops"],
        "health": "operational"
    }
```

CLI sees:
```
⚡ System Status
  Uptime:  2h 34m
  Tasks:   12 total (8 done, 3 active, 1 blocked)
  Agents:  frontend, backend, devops
  Health:  ✅ Operational
```

Telegram sees:
```
🤖 *System Status*
⏱ Uptime: 2h 34m
📋 Tasks: 12 total
  ✅ 8 done | 🔄 3 active | 🚫 1 blocked
👥 Agents: frontend, backend, devops
💚 Health: Operational

[Refresh] [View Tasks] [Settings]  ← inline keyboard
```

Slack sees: Block Kit sections with action buttons.

**One handler. Every platform. Zero duplication.**
