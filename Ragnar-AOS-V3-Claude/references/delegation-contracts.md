# Delegation Contracts

## Problem

Complex tasks require decomposition. A single agent trying to do everything loses focus, fills its context, and makes compounding errors. Delegation lets a parent agent break work into isolated subtasks.

## Core Pattern: Parent → Contract → Child → Summary

```
Parent Agent
  ├── defines contract
  ├── spawns child with fresh context
  ├── child executes in isolation
  ├── child returns structured summary
  └── parent integrates result (never sees child's reasoning)
```

## The Delegation Contract

Every delegation is defined by a contract object:

```python
contract = {
    "task": "Write unit tests for the UserService class",
    "context": {
        "file_paths": ["src/services/user-service.ts"],
        "test_framework": "vitest",
        "coverage_target": "all public methods",
        "existing_patterns": "see src/services/__tests__/auth-service.test.ts"
    },
    "allowed_tools": [
        "read_file",
        "write_file",
        "patch",
        "search_files",
        "terminal"  # for running tests
    ],
    "blocked_tools": [
        "dispatch_agent",   # no further delegation
        "memory_write",     # no modifying shared memory
        "message_user"      # no direct user communication
    ],
    "max_iterations": 25,
    "max_cost": 0.50,       # USD budget limit
    "expected_output": {
        "format": "summary",
        "fields": ["files_created", "files_modified", "test_count", "all_passing", "issues"]
    },
    "timeout_seconds": 300
}
```

## Isolation Model

Children operate in complete isolation:

| Property | Parent | Child |
|----------|--------|-------|
| Context | Full conversation history | Only contract + task context |
| Session | Main session | Fresh ephemeral session |
| Tools | All tools | Only allowed_tools |
| Memory | Read + write | Read only (or none) |
| Delegation | Can delegate | Cannot delegate (depth=0) |
| User comms | Can message user | Cannot message user |
| State DB | Shared | Own temporary state |

### Why Isolation Matters

- **Fresh context:** Child gets 100% of its context window for the task.
- **No contamination:** Child's failed attempts don't pollute parent's reasoning.
- **Predictable cost:** Budget cap prevents runaway spending.
- **Clean interface:** Parent integrates a summary, not 50 turns of trial and error.

## Depth Limits

```
Orchestrator (depth=2)
  └── Architect (depth=1)
        ├── Builder A (depth=0) — cannot delegate
        ├── Builder B (depth=0) — cannot delegate
        └── Builder C (depth=0) — cannot delegate
```

**Hard rule:** `max_depth = 2`. Children at depth 0 cannot call `dispatch_agent`. This prevents:
- Infinite delegation chains
- Cost explosion from recursive spawning
- Debugging nightmares

## Parent-Child Communication

The parent NEVER sees:
- The child's intermediate reasoning
- Tool call details or raw outputs
- Failed attempts or retries

The parent ONLY sees the structured summary:

```json
{
    "status": "completed",
    "files_created": ["src/services/__tests__/user-service.test.ts"],
    "files_modified": [],
    "test_count": 12,
    "all_passing": true,
    "issues": [],
    "tokens_used": {"input": 45000, "output": 8200},
    "cost_usd": 0.31,
    "iterations": 8
}
```

## Failure Modes and Handling

```python
def handle_child_result(result: dict) -> str:
    match result["status"]:
        case "completed":
            return integrate_result(result)
        
        case "timeout":
            # Child exceeded timeout_seconds
            # Partial work may exist on disk
            return "Child timed out. Check partial output, retry with simpler scope."
        
        case "budget_exceeded":
            # Hit max_cost before finishing
            return "Budget exceeded. Review partial work, consider breaking task further."
        
        case "max_iterations":
            # Likely stuck in a loop
            return "Child hit iteration limit. Task may be too complex or ambiguous."
        
        case "error":
            # Unrecoverable error
            return f"Child failed: {result['error']}. Retry or reassign."
```

## Example: Architect Delegates to 3 Parallel Builders

```python
# Parent: Architect agent planning a feature

# Step 1: Plan the decomposition
subtasks = [
    {
        "task": "Implement database migration for orders table",
        "context": {"schema_design": "...", "db": "postgresql"},
        "allowed_tools": ["read_file", "write_file", "terminal"],
        "max_iterations": 15,
        "max_cost": 0.30
    },
    {
        "task": "Implement OrderService with CRUD operations",
        "context": {"interface": "...", "depends_on": "orders table migration"},
        "allowed_tools": ["read_file", "write_file", "patch", "search_files", "terminal"],
        "max_iterations": 20,
        "max_cost": 0.40
    },
    {
        "task": "Implement REST endpoints for /api/orders",
        "context": {"service_interface": "...", "auth": "session-based", "framework": "express"},
        "allowed_tools": ["read_file", "write_file", "patch", "search_files", "terminal"],
        "max_iterations": 20,
        "max_cost": 0.40
    }
]

# Step 2: Dispatch (can be parallel if no dependencies)
results = []
# Task 1 must complete before 2 and 3 (they depend on the schema)
result_1 = dispatch_agent(subtasks[0])
assert result_1["status"] == "completed"

# Tasks 2 and 3 can run in parallel
result_2, result_3 = dispatch_parallel([subtasks[1], subtasks[2]])

# Step 3: Integrate
for r in [result_1, result_2, result_3]:
    if r["status"] != "completed":
        handle_failure(r)

# Step 4: Run integration tests (parent does this, not children)
run_integration_tests()
```

## Contract Design Rules

1. **Be specific about scope.** "Write tests" is bad. "Write unit tests for UserService covering all public methods" is good.
2. **Provide file paths.** Don't make the child search for things the parent already knows.
3. **Set realistic iteration limits.** Simple tasks: 10-15. Complex tasks: 20-30. Never >50.
4. **Include existing patterns.** Point to a reference file the child can follow.
5. **Define success criteria.** "all_passing: true" is a verifiable exit condition.
6. **Budget conservatively.** If you think it costs $0.30, set limit at $0.50.

## Anti-Patterns

- **Over-delegation:** Don't delegate a 2-minute task. The contract overhead isn't worth it.
- **Vague contracts:** "Make it work" leads to confused children and wasted budget.
- **No allowed_tools list:** Always be explicit. Default-open is dangerous.
- **Reading child reasoning:** If you're parsing child intermediate output, your contract is wrong.
- **Deep chains:** If you need depth > 2, redesign the decomposition to be flatter.
