# Recipe: Niyam. Policy-as-Dataverse-Rows

**Pattern:** Agent behavior changes by adding a row to a Dataverse table, not by editing a prompt. No code redeploy for rule changes.

**When to use:** Building D365-connected Copilot Studio agents that enforce business rules. Rules change faster than code can ship. Business users want to change agent behavior without engineering.

**Plug into your team lead:** Add to `CLAUDE.md`:

```
- Niyam pattern active. Policies live in Dataverse tables (cr023_policy,
  cr023_process, cr023_audit). Agents read policies at runtime. To change
  agent behavior, add/update a policy row. do NOT edit agent prompts.
  The dataverse specialist owns policy tables and audit log writes.
```

---

## Why policy-as-data

Prompt-as-policy is fragile. Every rule change:
- requires an engineer,
- requires an agent redeploy,
- requires re-testing the whole agent,
- produces a diff that's hard to audit.

Row-as-policy fixes all four. Business adds a row, agent picks it up next invocation, audit log captures the change.

---

## Table skeleton

Minimum set of tables. Prefix convention: `cr023_` (Ragnar's default. pick your own publisher prefix per project).

| Table | Purpose | Key columns |
|---|---|---|
| `cr023_skill` | Agent capabilities | name, description, active, category |
| `cr023_policy` | Rules the agent enforces | name, description, rule_json, applies_to (skill lookup), effective_date, active |
| `cr023_process` | Procedures the agent follows | name, description, steps_json, owner, active |
| `cr023_exception` | Known deviations allowed | name, policy (lookup), reason, approved_by, expires_on |
| `cr023_audit` | Every policy-driven decision | timestamp, policy (lookup), input, decision, reason, user |

---

## The agent's runtime loop

```
1. User asks the Copilot Studio agent: "can I do X?"
2. Parent agent classifies intent → routes to the right child (Smart Matcher, Policy Enforcer, Exception Handler).
3. Policy Enforcer child queries Dataverse:
   - SELECT * FROM cr023_policy WHERE applies_to = <X-relevant skill> AND active = true
4. Evaluates each policy against the user's request.
5. If any policy blocks: check cr023_exception. If exception exists and not expired: allow with audit.
6. Writes cr023_audit row: what was decided, why, which policy applied.
7. Returns decision to user.
```

No prompts changed. Change a row → change the behavior. Disable a row → remove the rule. Add an exception → grant scoped relief.

---

## How RAOS uses this

When a project opts into Dataverse + Copilot Studio at bootstrap:

- The `dataverse` specialist gets a copy of this recipe in `.claude/agents/dataverse.agent.md` (as a reference link).
- CLAUDE.md notes the Niyam pattern is active.
- The `copilot-studio` specialist knows to route policy logic to Dataverse queries, not to topic YAML.

---

## Tools the dataverse specialist uses

Depends on your Dataverse MCP. Common shapes:
- `mcp__dataverse__table_create`. bootstrap the policy tables.
- `mcp__dataverse__row_upsert`. add/update policies and exceptions.
- `mcp__dataverse__row_query`. runtime policy reads from the agent.
- Web API REST. for higher-volume audit writes if MCP is slow.

---

## Anti-pattern

Putting policy logic in the agent's Instructions prompt. Every rule change requires editing the prompt, re-testing the whole agent, redeploying. Also, prompt-based policy can't be audited cleanly. you can't diff who changed what and why.

If the project uses Copilot Studio but NOT Niyam, that's a call. But if the project is going to have > 5 rules that change over time, Niyam pays for itself.

---

## Further reading

For full Niyam skill: `~/.claude/skills/niyam-agent-template/SKILL.md`. RAOS points to it rather than duplicating the contents.
