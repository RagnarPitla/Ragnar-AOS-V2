# Recipe: Power Platform Auth Gate

**Pattern:** Before any Power Platform write, verify the active pac auth profile is the one you expect. Fail closed.

**When to use:** Project touches Power Platform environments (Dataverse tables, Copilot Studio agents, Power Automate flows, solution imports). You care about not writing to the wrong tenant.

**Plug into your team lead:** Add to your project instructions file (In Claude Code: `CLAUDE.md` / In GitHub Copilot CLI: `instructions.md`):

```
- Power Platform integration active. The `pac-cli` specialist owns auth.
  No Power Platform write runs without pac-cli verifying the active profile
  matches the expected environment. Auth mismatches halt work and surface
  to the user. never silently switch profiles.
```

---

## The gate

Every Power Platform write goes through these steps:

1. **Declare the expected environment.** In your project instructions file (In Claude Code: `CLAUDE.md` / In GitHub Copilot CLI: `instructions.md`), name it: `Expected PP environment: <env name or URL>`. Or the user confirms during objective parsing.
2. **Check the active profile.** `pac-cli` calls `mcp__pac-cli__auth_who` (or `pac auth who`).
3. **Compare.** If active profile's environment == expected → proceed. If not → halt.
4. **On mismatch:** do NOT call `pac auth select` automatically. Surface to cli-lead: "Active environment is X, expected Y. Proceed with X? Select profile for Y? Abort?" cli-lead asks the user.

---

## Tools

- `mcp__pac-cli__auth_who`. current active profile.
- `mcp__pac-cli__auth_list`. all profiles.
- `mcp__pac-cli__auth_create`. add a new profile (guidance bucket. auth creation is judgment).
- `pac auth select --index <n>`. switch profile (guidance bucket).

---

## Why fail closed

Power Platform environments look alike. Dev and Prod URLs differ by one word. Silent profile switches have deleted customer data. Fail-closed is cheap insurance.

If the user finds the halt annoying, they can codify "for this project, always work in env X" in their project instructions file (In Claude Code: `CLAUDE.md` / In GitHub Copilot CLI: `instructions.md`) and then the pac-cli specialist can auto-switch to X at session start. but even then, only to the ONE declared env, never to something else.

---

## What this protects

- Wrong-tenant writes (catastrophic).
- "Dev" imports going to "Prod" (common).
- Running destructive solution ops on unexpected envs.

What this does NOT protect:
- Bad credentials with the right tenant (pac-cli assumes the user's `pac auth` is trustworthy).
- Permission errors (the write will fail at the API level, which is also fine).

---

## Typical pattern in a specialist's workflow

```
# pac-cli specialist, asked to import a solution into env "contoso-dev"

1. mcp__pac-cli__auth_who → returns { environment: "contoso-prod" }
2. Compare: expected "contoso-dev" ≠ active "contoso-prod"
3. HALT. Return to cli-lead: "Env mismatch. Active: contoso-prod. Expected: contoso-dev. Abort or switch?"
4. cli-lead surfaces to user. User says "switch."
5. pac-cli specialist: pac auth select --index <contoso-dev index>
6. Verify again: mcp__pac-cli__auth_who → "contoso-dev" ✅
7. Proceed with solution import.
```

This flow adds 2 seconds of latency and prevents 1 catastrophic mistake per year. Non-negotiable in real use.
