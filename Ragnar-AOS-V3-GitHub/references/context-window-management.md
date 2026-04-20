# Context Window Management

## Problem

Agents lose critical context in long conversations. The context window fills with tool output, intermediate reasoning, and stale information. By the time the agent needs to make a decision, the original task description and key decisions have been pushed out.

## Core Pattern: HEAD | COMPRESSED MIDDLE | TAIL

Structure the context window into three zones:

```
┌─────────────────────────────────┐
│ HEAD (pinned, never compressed) │
│ - System prompt                 │
│ - Active Task block             │
│ - Key constraints/rules         │
├─────────────────────────────────┤
│ COMPRESSED MIDDLE (summaries)   │
│ - Turn summaries (not raw)      │
│ - Decision log                  │
│ - Error log                     │
├─────────────────────────────────┤
│ TAIL (last N turns, verbatim)   │
│ - Recent tool calls + results   │
│ - Current working state         │
│ - Last 3-5 exchanges            │
└─────────────────────────────────┘
```

## Active Task Block

Always maintain this structure at the top of context. Update it every turn.

```
## Active Task
**Objective:** Migrate user auth from JWT to session-based auth
**Current Step:** Updating middleware to check session store
**Blocked On:** Nothing
**Completed:**
- [x] Designed session schema
- [x] Implemented session store (Redis)
- [ ] Updated middleware
- [ ] Updated login/logout endpoints
- [ ] Updated tests
**Key Decisions:**
- Using Redis (not DB) for sessions — latency requirement <5ms
- Session TTL: 24h with sliding expiration
- Keeping JWT for API-to-API calls, sessions for browser only
```

## When to Compress

Trigger compression when token usage exceeds 80% of the context window:

```python
def should_compress(current_tokens, max_tokens):
    return current_tokens > max_tokens * 0.80

# Model-specific thresholds
THRESHOLDS = {
    "claude-sonnet-4-20250514": int(200_000 * 0.80),   # 160K
    "gpt-4o":          int(128_000 * 0.80),   # 102K
    "claude-3-haiku":  int(200_000 * 0.80),   # 160K
}
```

## What to Preserve vs Discard

Priority order (highest first):

| Priority | Category | Action |
|----------|----------|--------|
| 1 | Decisions made | Always preserve with rationale |
| 2 | Errors encountered | Preserve — prevents loops |
| 3 | Current file state | Preserve paths + key content |
| 4 | Constraints/requirements | Keep in Active Task block |
| 5 | Successful tool outputs | Compress to 1-line summary |
| 6 | Raw file contents | Discard — re-read if needed |
| 7 | Intermediate reasoning | Discard entirely |

## Compression Implementation

```python
def compress_turns(turns: list[dict]) -> str:
    """Compress a batch of turns into a summary block."""
    # Group by activity
    decisions = []
    errors = []
    files_modified = set()
    
    for turn in turns:
        if "decided" in turn["content"].lower() or "choosing" in turn["content"].lower():
            decisions.append(extract_decision(turn))
        if turn.get("tool_result", {}).get("exit_code", 0) != 0:
            errors.append(summarize_error(turn))
        files_modified.update(extract_file_paths(turn))
    
    summary = f"""## Compressed: Turns {turns[0]['index']}-{turns[-1]['index']}
**Actions taken:** {len(turns)} turns of work
**Files modified:** {', '.join(files_modified)}
**Decisions:** {'; '.join(decisions) if decisions else 'None'}
**Errors hit:** {'; '.join(errors) if errors else 'None'}
"""
    return summary
```

## Before/After Example

### Before Compression (raw turns eating 40K tokens):

```
Turn 12: [assistant] Let me read the auth middleware file...
Turn 13: [tool_result] <2000 lines of middleware.js>
Turn 14: [assistant] I see the issue. The JWT verification is on line 47...
Turn 15: [tool_call] patch middleware.js ...
Turn 16: [tool_result] File patched successfully
Turn 17: [assistant] Now let me run the tests...
Turn 18: [tool_result] FAIL: 3 tests failed - session not found
Turn 19: [assistant] The Redis connection isn't initialized. Let me fix...
Turn 20: [tool_call] patch redis-client.js ...
Turn 21: [tool_result] File patched successfully
Turn 22: [assistant] Running tests again...
Turn 23: [tool_result] PASS: all 47 tests pass
```

### After Compression (~500 tokens):

```
## Compressed: Turns 12-23
**Actions taken:** 12 turns of middleware migration work
**Files modified:** middleware.js, redis-client.js
**Decisions:** JWT check replaced with session lookup on line 47
**Errors hit:** Redis connection not initialized before middleware runs — fixed by moving init to app startup
**Outcome:** All 47 tests passing
```

## Integration Pattern

```python
class ContextManager:
    def __init__(self, max_tokens: int):
        self.max_tokens = max_tokens
        self.head = []        # Pinned messages
        self.compressed = []  # Summary blocks
        self.tail = []        # Recent verbatim turns
        self.active_task = {} # Current task state
    
    def add_turn(self, turn: dict):
        self.tail.append(turn)
        current = self.count_tokens()
        if current > self.max_tokens * 0.80:
            # Compress oldest half of tail
            to_compress = self.tail[:len(self.tail)//2]
            self.tail = self.tail[len(self.tail)//2:]
            summary = compress_turns(to_compress)
            self.compressed.append(summary)
    
    def build_context(self) -> list[dict]:
        return self.head + self.compressed + self.tail
    
    def update_active_task(self, **kwargs):
        self.active_task.update(kwargs)
        # Active task is always in head[1] (after system prompt)
        self.head[1] = {"role": "system", "content": format_active_task(self.active_task)}
```

## Rules for Agents

1. **Never let the Active Task block go stale.** Update it after every meaningful action.
2. **Re-read files instead of preserving raw content.** File reads are cheap; context space is not.
3. **Log decisions explicitly.** "I chose X because Y" survives compression. Implicit reasoning does not.
4. **Compress proactively.** Don't wait for the context to overflow — compress at 80%.
5. **Errors are more valuable than successes.** A successful `npm install` can be discarded. A failed one with the error message must be preserved.
