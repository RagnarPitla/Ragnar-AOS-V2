# Session Persistence

## Problem

Agents start every conversation from zero. They repeat mistakes, re-discover solutions, and lose all institutional knowledge between sessions. A human developer remembers "we tried approach X last week and it failed because Y." Agents don't — unless you build persistence.

## Core Pattern: SQLite + FTS5

Use SQLite with full-text search to store conversation history, decisions, and learnings across sessions.

```
┌──────────────┐     ┌──────────────────┐
│   sessions   │────→│    messages       │
│ id           │     │ session_id (FK)   │
│ title        │     │ role              │
│ created_at   │     │ content           │
│ parent_id    │     │ tokens            │
│ status       │     │ created_at        │
│ summary      │     └──────────────────┘
└──────────────┘              │
                              ▼
                    ┌──────────────────┐
                    │ messages_fts     │
                    │ (FTS5 virtual)   │
                    │ content indexed  │
                    └──────────────────┘
```

## Schema

```sql
CREATE TABLE sessions (
    id TEXT PRIMARY KEY,           -- UUID
    title TEXT NOT NULL,           -- Human-readable description
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    parent_id TEXT REFERENCES sessions(id),  -- For session chaining
    status TEXT DEFAULT 'active',  -- active, completed, abandoned
    summary TEXT,                  -- Post-session summary
    objective TEXT,                -- What this session aimed to do
    tags TEXT                      -- Comma-separated tags for filtering
);

CREATE TABLE messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id),
    role TEXT NOT NULL,            -- user, assistant, system, tool
    content TEXT NOT NULL,
    tokens_input INTEGER DEFAULT 0,
    tokens_output INTEGER DEFAULT 0,
    tool_name TEXT,                -- If role=tool, which tool
    created_at TEXT DEFAULT (datetime('now'))
);

-- Full-text search index
CREATE VIRTUAL TABLE messages_fts USING fts5(
    content,
    content='messages',
    content_rowid='id'
);

-- Triggers to keep FTS in sync
CREATE TRIGGER messages_ai AFTER INSERT ON messages BEGIN
    INSERT INTO messages_fts(rowid, content) VALUES (new.id, new.content);
END;

CREATE TRIGGER messages_ad AFTER DELETE ON messages BEGIN
    INSERT INTO messages_fts(messages_fts, rowid, content) VALUES('delete', old.id, old.content);
END;

-- Indexes
CREATE INDEX idx_sessions_parent ON sessions(parent_id);
CREATE INDEX idx_messages_session ON messages(session_id);
CREATE INDEX idx_sessions_tags ON sessions(tags);
```

## Session Chaining

When continuing previous work, link sessions:

```python
def continue_session(previous_session_id: str, new_objective: str) -> str:
    """Create a new session that continues from a previous one."""
    # Get the previous session's summary
    prev = db.execute(
        "SELECT summary, objective FROM sessions WHERE id = ?",
        (previous_session_id,)
    ).fetchone()
    
    new_id = str(uuid4())
    db.execute(
        "INSERT INTO sessions (id, title, parent_id, objective) VALUES (?, ?, ?, ?)",
        (new_id, new_objective, previous_session_id, new_objective)
    )
    
    # Inject previous context into new session's system prompt
    context = f"""Continuing from previous session: {prev['objective']}
Previous summary: {prev['summary']}
New objective: {new_objective}"""
    
    return new_id, context
```

### Chain traversal:

```python
def get_session_chain(session_id: str) -> list[dict]:
    """Walk back through parent sessions to build full history."""
    chain = []
    current = session_id
    while current:
        session = db.execute(
            "SELECT id, objective, summary, parent_id FROM sessions WHERE id = ?",
            (current,)
        ).fetchone()
        if not session:
            break
        chain.append(session)
        current = session['parent_id']
    return list(reversed(chain))  # Oldest first
```

## Searching Past Sessions

The killer feature: agents can search before starting work.

```python
def search_history(query: str, limit: int = 10) -> list[dict]:
    """Full-text search across all past session messages."""
    results = db.execute("""
        SELECT m.content, m.role, s.title, s.objective, s.id as session_id,
               rank
        FROM messages_fts AS fts
        JOIN messages AS m ON m.id = fts.rowid
        JOIN sessions AS s ON s.id = m.session_id
        WHERE messages_fts MATCH ?
        ORDER BY rank
        LIMIT ?
    """, (query, limit)).fetchall()
    return results

# Example: before debugging a Redis issue
results = search_history("Redis connection timeout")
# Returns past messages where Redis timeouts were discussed/solved
```

## What to Persist

### Always persist:
- **Decisions with rationale:** "Chose Redis over Memcached because we need pub/sub"
- **Errors and their solutions:** "Got ECONNREFUSED — fixed by starting Redis before the app"
- **Architecture choices:** "Using event sourcing for order state management"
- **Configuration discoveries:** "Need to set `max_old_space_size=4096` for this build"

### Persist as summary only:
- Long tool outputs (just the outcome: "47 tests passed" not the full output)
- File contents (just the path and what was changed)

### Don't persist:
- Raw file reads (re-read when needed)
- Intermediate reasoning that led nowhere
- Verbose build/install logs

## Session Summary Generation

At session end, generate a structured summary:

```python
def summarize_session(session_id: str) -> str:
    """Generate a summary when a session completes."""
    messages = db.execute(
        "SELECT role, content FROM messages WHERE session_id = ? ORDER BY id",
        (session_id,)
    ).fetchall()
    
    # Extract key information
    summary = {
        "objective": get_objective(session_id),
        "outcome": "completed" | "blocked" | "abandoned",
        "what_was_done": [...],      # List of actions taken
        "decisions_made": [...],      # Key choices
        "errors_encountered": [...],  # Problems and solutions
        "files_modified": [...],      # Changed files
        "open_questions": [...]       # Unresolved items
    }
    
    db.execute(
        "UPDATE sessions SET summary = ?, status = 'completed' WHERE id = ?",
        (json.dumps(summary), session_id)
    )
    return summary
```

## Integration: Pre-Work Search

Before starting any task, search for relevant history:

```python
def pre_work_check(task_description: str) -> str:
    """Search for past sessions relevant to current task."""
    # Search for related work
    results = search_history(task_description, limit=5)
    
    if results:
        context = "## Relevant Past Sessions\n"
        for r in results:
            context += f"- **{r['title']}** (session {r['session_id'][:8]}): {r['content'][:200]}\n"
        return context
    
    return "No relevant past sessions found."

# Usage in agent loop
task = "Fix the Redis connection pooling issue"
past_context = pre_work_check(task)
# Agent now knows what was tried before
```

## Database Location

```python
import os

def get_db_path() -> str:
    raos_home = os.environ.get("RAOS_HOME", os.path.expanduser("~/.raos"))
    return os.path.join(raos_home, "state", "sessions.db")
```

The database lives under the RAOS home directory, making it profile-aware (see profile-isolation.md).

## Rules for Agents

1. **Search before you start.** Always check if this problem was solved before.
2. **Log decisions explicitly.** Don't just make a choice — record it with the "why."
3. **Summarize on exit.** Every session gets a summary, even abandoned ones.
4. **Chain related sessions.** Use `parent_id` to link continued work.
5. **Tag sessions.** Tags like "redis", "auth", "migration" make future search easier.
6. **Don't store raw outputs.** Summaries are searchable; 5000-line logs are not.
