# Recipe: Azure DevOps Work-Item Tracking

**Pattern:** Kazuki two-bucket. Autonomous closures with code evidence. Guidance on priority or scope changes.

**When to use:** Project has an Azure DevOps backlog. Agents need to sync work items with code state (close items, update status, link commits).

**Plug into your team lead:** Add to `CLAUDE.md`:

```
- Azure DevOps integration active. The `ado` specialist owns work item sync.
  Autonomous: close items with unambiguous code evidence, update titles for clarity,
  add comments tying work to commits. Guidance: priority changes, scope shifts,
  bulk re-triage, moving items between Epics.
```

---

## The two-bucket split (for ADO)

**Autonomous (the `ado` specialist does without asking):**
- Close a work item when:
  - Code search finds the matching change on the target branch.
  - Tests for the change pass.
  - Commit message references the work item ID.
- Update a work item's title/description to match the shipped reality.
- Post a closure comment with: link to commit, link to PR, Epic rollup reference.
- Link related items (parent/child, blocks, blocked by) when the relationship is unambiguous.

**Guidance (specialist surfaces to cli-lead, who asks the user):**
- Change priority (Low → High is a judgment call).
- Move between iterations.
- Reassign to a different owner.
- Move between Epics or Features.
- Bulk operations (>5 items at once).
- Close without code evidence ("seems done" is not evidence).

---

## Tools the ado specialist uses

Depends on your ADO MCP setup. Typical toolset:

- `mcp__ado-<org>__wit_get_work_item`. read a work item.
- `mcp__ado-<org>__wit_list_my_work_items`. get what's on your plate.
- `mcp__ado-<org>__wit_update_work_item`. state/title/comment changes.
- `mcp__ado-<org>__wit_link_work_items`. parent/child/related links.

Replace `<org>` with your ADO org name. each org gets its own MCP server (see [ado-mcp-setup](~/.github/skills/ado-mcp-setup/SKILL.md)).

---

## Closure comment template

Every autonomous closure posts this comment:

```
Closed based on code evidence:
- Branch: <branch name>
- Commit: <short SHA with link>
- PR: <PR number/link if applicable>
- Tests: <status>
- Epic rollup: #<epic number>

Closure performed autonomously per CLAUDE.md. Flag via /raos if incorrect.
```

Why the "flag via /raos" line: gives the user a one-command escape if the specialist got it wrong. Preserves two-bucket trust.

---

## When the ado specialist is unsure

If code evidence is partial ("this PR touches the area but the work item says 'update the docs too' and docs weren't touched"), the specialist does NOT close. It:
1. Posts a comment on the work item: "Partial evidence found. Code change at <link>. Open question: docs update mentioned in description. confirm if in scope."
2. Returns to cli-lead: "Work item #1234 is partially ambiguous. Recommend: close this scope, open new item for docs. Awaiting guidance."
3. cli-lead surfaces the decision to the user.

This is the two-bucket rule working. Evidence-backed = autonomous. Ambiguous = guidance.
