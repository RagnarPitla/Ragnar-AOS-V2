# MCP Integration — Model Context Protocol

> Connect external tool servers to extend agent capabilities without modifying core code.

## What is MCP?

MCP (Model Context Protocol) is a standard for connecting AI agents to external tool servers. Instead of hardcoding tool implementations, agents discover and call tools served by separate processes over stdio or HTTP.

**Key benefits:**
- Tools are language-agnostic (server in Python, agent in JS — doesn't matter)
- Hot-swappable: add/remove tool servers without restarting the agent
- Isolation: tool crashes don't crash the agent
- Reusable: one MCP server serves multiple agents

## Architecture

```
Agent Core
  ├── Built-in tools (read_file, terminal, etc.)
  └── MCP Client
        ├── Database Server (stdio) → query, insert, schema tools
        ├── Jira Server (stdio)     → create_issue, search, transition tools
        └── Custom Server (HTTP)    → domain-specific tools
```

## Configuration Format

MCP servers are configured in the project config:

```json
{
  "mcpServers": {
    "database": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "postgresql://user:pass@localhost:5432/mydb"
      }
    },
    "jira": {
      "command": "python",
      "args": ["-m", "mcp_jira_server"],
      "env": {
        "JIRA_URL": "https://myorg.atlassian.net",
        "JIRA_TOKEN": "${JIRA_API_TOKEN}"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/allowed/path"]
    }
  }
}
```

### Config Fields

| Field     | Type     | Description                                    |
|-----------|----------|------------------------------------------------|
| `command` | string   | Executable to launch the server                |
| `args`    | list     | Command-line arguments                         |
| `env`     | object   | Environment variables (supports `${VAR}` refs) |
| `timeout` | int      | Startup timeout in seconds (default: 30)       |
| `enabled` | bool     | Toggle server on/off (default: true)           |

## Tool Discovery

On startup, the MCP client connects to each server and lists available tools:

```python
async def discover_tools(server_name: str, config: dict) -> list[Tool]:
    """Connect to MCP server, return available tools."""
    client = MCPClient()
    await client.connect(config["command"], config["args"], config.get("env", {}))
    
    tools = await client.list_tools()
    # Each tool has: name, description, input_schema (JSON Schema)
    
    # Namespace tools to avoid collisions
    for tool in tools:
        tool.namespaced_name = f"{server_name}.{tool.name}"
    
    return tools
```

## Mapping Tools to Agents

Once discovered, MCP tools are added to the agent's toolset:

```python
# In agent configuration
allowed_tools:
  - read_file
  - write_file
  - terminal
  - database.query          # MCP tool: run SQL queries
  - database.schema         # MCP tool: get table schemas
  - jira.create_issue       # MCP tool: create Jira tickets
  - jira.search             # MCP tool: search issues
```

## Authentication Patterns

### API Keys via Environment

```json
{
  "env": {
    "API_KEY": "${MY_SERVICE_API_KEY}"
  }
}
```

The `${VAR}` syntax references the host machine's environment variables. Never hardcode secrets in config.

### OAuth Tokens

For OAuth-based services, use a token refresh wrapper:

```json
{
  "command": "python",
  "args": ["-m", "mcp_oauth_wrapper", "--service", "github"],
  "env": {
    "OAUTH_CLIENT_ID": "${GH_CLIENT_ID}",
    "OAUTH_CLIENT_SECRET": "${GH_CLIENT_SECRET}",
    "OAUTH_TOKEN_FILE": ".tokens/github.json"
  }
}
```

## Example: Database MCP Server

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    }
  }
}
```

**Discovered tools:**
- `postgres.query` — Execute read-only SQL
- `postgres.schema` — List tables and columns
- `postgres.explain` — Get query execution plan

**Agent usage:**
```
Agent: I need to check the user table structure.
→ calls postgres.schema(table="users")
← Returns column definitions, types, constraints
```

## Example: Jira MCP Server

```json
{
  "mcpServers": {
    "jira": {
      "command": "uvx",
      "args": ["mcp-server-jira"],
      "env": {
        "JIRA_URL": "${JIRA_URL}",
        "JIRA_EMAIL": "${JIRA_EMAIL}",
        "JIRA_TOKEN": "${JIRA_API_TOKEN}"
      }
    }
  }
}
```

**Discovered tools:**
- `jira.search` — JQL search
- `jira.create_issue` — Create ticket
- `jira.transition` — Move issue status
- `jira.add_comment` — Comment on issue

## Failure Handling

### Server Won't Start

```python
try:
    await client.connect(command, args, env, timeout=30)
except MCPStartupError:
    logger.warning(f"MCP server '{name}' failed to start — skipping")
    # Agent continues without these tools
    # Tools from this server return "unavailable" if called
```

### Tool Timeout

```python
try:
    result = await asyncio.wait_for(client.call_tool(name, args), timeout=60)
except asyncio.TimeoutError:
    return ToolResult(error=f"Tool {name} timed out after 60s")
```

### Retry Logic

```python
MAX_RETRIES = 3
RETRY_DELAY = [1, 5, 15]  # exponential-ish backoff

async def call_with_retry(client, tool_name, args):
    for attempt in range(MAX_RETRIES):
        try:
            return await client.call_tool(tool_name, args)
        except MCPConnectionError:
            if attempt < MAX_RETRIES - 1:
                await asyncio.sleep(RETRY_DELAY[attempt])
                await client.reconnect()
            else:
                raise
```

### Server Crash Recovery

```python
async def ensure_connected(server_name):
    """Reconnect to MCP server if connection dropped."""
    client = connections[server_name]
    if not client.is_connected():
        logger.info(f"Reconnecting to MCP server: {server_name}")
        config = mcp_config[server_name]
        await client.connect(config["command"], config["args"], config.get("env", {}))
```

## Security Considerations

1. **Least privilege**: Only give agents access to the MCP tools they need
2. **Read-only by default**: Prefer read-only database connections
3. **Env var secrets**: Never commit tokens to config files
4. **Network isolation**: Run MCP servers in containers if they access external services
5. **Audit logging**: Log all MCP tool calls for traceability
