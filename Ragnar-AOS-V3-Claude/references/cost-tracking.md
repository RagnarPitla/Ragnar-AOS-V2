# Cost Tracking

## Problem

Agent work costs real money. Without tracking, a single runaway objective can burn through $50 before anyone notices. Teams need visibility into what agents cost, per-session and per-objective, with hard budget limits.

## Core Pattern: Per-Message Token Tracking + Cost Estimation

Track token counts on every message, multiply by model-specific pricing, enforce budget limits.

```
Message → Count Tokens → Store in DB → Estimate Cost → Check Budget
                                                          │
                                              ┌───────────┴───────────┐
                                              │ Under 80%: continue   │
                                              │ At 80%: warn          │
                                              │ At 100%: hard stop    │
                                              └───────────────────────┘
```

## Token Tracking Schema

```sql
-- Extend the messages table (see session-persistence.md)
ALTER TABLE messages ADD COLUMN tokens_input INTEGER DEFAULT 0;
ALTER TABLE messages ADD COLUMN tokens_output INTEGER DEFAULT 0;
ALTER TABLE messages ADD COLUMN tokens_cache_read INTEGER DEFAULT 0;
ALTER TABLE messages ADD COLUMN tokens_cache_write INTEGER DEFAULT 0;
ALTER TABLE messages ADD COLUMN model TEXT;

-- Cost tracking table
CREATE TABLE cost_ledger (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id),
    message_id INTEGER REFERENCES messages(id),
    model TEXT NOT NULL,
    tokens_input INTEGER DEFAULT 0,
    tokens_output INTEGER DEFAULT 0,
    tokens_cache_read INTEGER DEFAULT 0,
    tokens_cache_write INTEGER DEFAULT 0,
    cost_usd REAL NOT NULL,
    created_at TEXT DEFAULT (datetime('now'))
);

-- Budget tracking
CREATE TABLE budgets (
    id TEXT PRIMARY KEY,           -- objective_id or session_id
    budget_type TEXT NOT NULL,     -- 'session' or 'objective'
    max_cost_usd REAL NOT NULL,
    current_cost_usd REAL DEFAULT 0.0,
    status TEXT DEFAULT 'active'   -- active, warning, exceeded
);

CREATE INDEX idx_cost_session ON cost_ledger(session_id);
CREATE INDEX idx_cost_model ON cost_ledger(model);
```

## Model Pricing Tables

```python
# Prices per 1M tokens (USD) — update as pricing changes
MODEL_PRICING = {
    "claude-sonnet-4-20250514": {
        "input": 3.00,
        "output": 15.00,
        "cache_read": 0.30,
        "cache_write": 3.75,
    },
    "claude-3-haiku": {
        "input": 0.25,
        "output": 1.25,
        "cache_read": 0.03,
        "cache_write": 0.30,
    },
    "gpt-4o": {
        "input": 2.50,
        "output": 10.00,
        "cache_read": 1.25,
        "cache_write": 2.50,
    },
    "gpt-4o-mini": {
        "input": 0.15,
        "output": 0.60,
        "cache_read": 0.075,
        "cache_write": 0.15,
    },
}

def estimate_cost(model: str, tokens: dict) -> float:
    """Calculate cost in USD for a single message."""
    pricing = MODEL_PRICING.get(model, MODEL_PRICING["claude-sonnet-4-20250514"])
    cost = (
        tokens.get("input", 0) * pricing["input"] / 1_000_000
        + tokens.get("output", 0) * pricing["output"] / 1_000_000
        + tokens.get("cache_read", 0) * pricing["cache_read"] / 1_000_000
        + tokens.get("cache_write", 0) * pricing["cache_write"] / 1_000_000
    )
    return round(cost, 6)
```

## Budget Enforcement

```python
class BudgetManager:
    def __init__(self, db):
        self.db = db
    
    def check_budget(self, budget_id: str) -> dict:
        """Check budget status before making an API call."""
        budget = self.db.execute(
            "SELECT max_cost_usd, current_cost_usd, status FROM budgets WHERE id = ?",
            (budget_id,)
        ).fetchone()
        
        if not budget:
            return {"allowed": True, "status": "no_budget"}
        
        ratio = budget["current_cost_usd"] / budget["max_cost_usd"]
        
        if ratio >= 1.0:
            return {
                "allowed": False,
                "status": "exceeded",
                "current": budget["current_cost_usd"],
                "max": budget["max_cost_usd"]
            }
        elif ratio >= 0.8:
            return {
                "allowed": True,
                "status": "warning",
                "current": budget["current_cost_usd"],
                "max": budget["max_cost_usd"],
                "remaining": budget["max_cost_usd"] - budget["current_cost_usd"]
            }
        else:
            return {"allowed": True, "status": "ok"}
    
    def record_cost(self, budget_id: str, session_id: str, model: str, tokens: dict):
        """Record a cost entry and update budget."""
        cost = estimate_cost(model, tokens)
        
        self.db.execute(
            "INSERT INTO cost_ledger (session_id, model, tokens_input, tokens_output, "
            "tokens_cache_read, tokens_cache_write, cost_usd) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (session_id, model, tokens.get("input", 0), tokens.get("output", 0),
             tokens.get("cache_read", 0), tokens.get("cache_write", 0), cost)
        )
        
        self.db.execute(
            "UPDATE budgets SET current_cost_usd = current_cost_usd + ? WHERE id = ?",
            (cost, budget_id)
        )
        
        # Check if we crossed a threshold
        status = self.check_budget(budget_id)
        if status["status"] == "warning":
            notify_agent(f"Budget warning: ${status['current']:.2f} / ${status['max']:.2f}")
        elif status["status"] == "exceeded":
            notify_agent(f"BUDGET EXCEEDED: ${status['current']:.2f} / ${status['max']:.2f}")
            raise BudgetExceededError(budget_id)
```

## Reporting

### Per-Session Cost

```python
def session_cost_report(session_id: str) -> dict:
    result = db.execute("""
        SELECT 
            model,
            COUNT(*) as messages,
            SUM(tokens_input) as total_input,
            SUM(tokens_output) as total_output,
            SUM(cost_usd) as total_cost
        FROM cost_ledger
        WHERE session_id = ?
        GROUP BY model
    """, (session_id,)).fetchall()
    
    return {
        "session_id": session_id,
        "by_model": [dict(r) for r in result],
        "total_cost": sum(r["total_cost"] for r in result)
    }
```

### Per-Objective Cost (across multiple agents)

```python
def objective_cost_report(objective_id: str) -> dict:
    """Cost across all sessions tied to an objective."""
    result = db.execute("""
        SELECT 
            s.title as session_title,
            cl.model,
            COUNT(*) as messages,
            SUM(cl.cost_usd) as cost
        FROM cost_ledger cl
        JOIN sessions s ON s.id = cl.session_id
        WHERE s.objective = ? OR s.id IN (
            SELECT session_id FROM objective_sessions WHERE objective_id = ?
        )
        GROUP BY s.id, cl.model
        ORDER BY cost DESC
    """, (objective_id, objective_id)).fetchall()
    
    total = sum(r["cost"] for r in result)
    return {
        "objective_id": objective_id,
        "breakdown": [dict(r) for r in result],
        "total_cost": total,
        "total_messages": sum(r["messages"] for r in result)
    }
```

## Example Output

```
=== Objective Cost Report ===
Objective: "Implement user authentication system"
Total Cost: $2.47 across 14 agent turns (3 agents)

  Architect Agent (session abc123):
    claude-sonnet-4-20250514: 4 turns, 12K input, 3K output = $0.08
  
  Builder Agent 1 (session def456):
    claude-sonnet-4-20250514: 6 turns, 89K input, 18K output = $0.54
  
  Builder Agent 2 (session ghi789):
    claude-sonnet-4-20250514: 4 turns, 62K input, 41K output = $0.80
  
  Test Agent (session jkl012):
    claude-sonnet-4-20250514: 8 turns, 45K input, 22K output = $1.05

Budget: $2.47 / $5.00 (49.4%)
```

## Integration with Agent Loop

```python
def agent_turn(message: str, budget_id: str, session_id: str):
    """Wrap each agent turn with cost tracking."""
    # Pre-check
    budget_status = budget_manager.check_budget(budget_id)
    if not budget_status["allowed"]:
        return {"error": "Budget exceeded", "details": budget_status}
    
    # Make API call
    response = call_model(message)
    
    # Record cost
    budget_manager.record_cost(
        budget_id=budget_id,
        session_id=session_id,
        model=response.model,
        tokens={
            "input": response.usage.input_tokens,
            "output": response.usage.output_tokens,
            "cache_read": response.usage.cache_read_tokens,
            "cache_write": response.usage.cache_creation_tokens,
        }
    )
    
    return response
```

## Rules for Agents

1. **Track every API call.** No exceptions. Even retries and failed calls cost money.
2. **Check budget before each turn.** Don't make the call if you're over budget.
3. **Warn at 80%.** Give the agent a chance to wrap up efficiently.
4. **Hard stop at 100%.** Save state, summarize progress, exit cleanly.
5. **Use cheaper models for simple tasks.** Haiku for file reads, Sonnet for reasoning.
6. **Cache aggressively.** Cache reads cost 10x less than fresh input tokens.
7. **Report costs in summaries.** Every delegation result should include cost.
