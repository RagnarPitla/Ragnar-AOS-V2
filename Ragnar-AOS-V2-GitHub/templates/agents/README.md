# Specialist Agent Library

Pre-built `.github/agents/` definitions RAOS copies into your project during `/raos` bootstrap, based on the integrations you opt into.

These are the auxiliary agents Ragnar uses to automate his own work. ADO tracking, Power Platform auth, Dataverse ops, Azure deploys, GitHub PRs, Copilot Studio agent authoring. Bundled here so your team doesn't have to write them from scratch.

---

## Catalog

| Agent | What it owns | Depends on | Typical use |
|---|---|---|---|
| [`pac-cli`](pac-cli.agent.md) | Power Platform auth profiles, solution import/export | `pac` CLI installed | Power Platform projects |
| [`dataverse`](dataverse.agent.md) | Table metadata, row CRUD, Niyam policy tables, audit log | `pac-cli` for auth | Dataverse-backed projects, especially D365 and Niyam agents |
| [`azure`](azure.agent.md) | Resource groups, ACA deploys, Key Vault reads, Bicep | `az login` | Azure-hosted projects |
| [`github`](github.agent.md) | PRs, issues, releases, Actions workflows | `gh auth` | Any GitHub-hosted repo |
| [`ado`](ado.agent.md) | Work item sync with Kazuki two-bucket pattern | ADO MCP configured | Projects tracked in Azure DevOps |
| [`copilot-studio`](copilot-studio.agent.md) | Topic YAML, LSP validation, push/pull | `pac-cli` + `dataverse` | Building Copilot Studio agents |

---

## Opt-in during bootstrap

When you run `/raos` in a fresh project, you'll see a checkbox list. Tick each system the project works with:

- [ ] Power Platform → copies `pac-cli.agent.md`
- [ ] Dataverse → copies `dataverse.agent.md` (auto-adds pac-cli)
- [ ] Azure → copies `azure.agent.md`
- [ ] GitHub → copies `github.agent.md`
- [ ] Azure DevOps → copies `ado.agent.md`
- [ ] Copilot Studio agents → auto-bundles pac-cli + dataverse + copilot-studio

You can also add or remove agents later by re-running `/raos` and choosing the edit flow.

---

## Copilot Studio bundle

Checking "Copilot Studio agents" is a shorthand for the common case: you're building a Copilot Studio agent that reads/writes Dataverse data and needs Power Platform auth. It automatically pulls in:

- `pac-cli` (auth)
- `dataverse` (data + Niyam policies if enabled)
- `copilot-studio` (YAML authoring)

This is the minimum viable team for Copilot Studio agent development. Add `ado` if you're tracking work there, `github` if the YAML is in a GitHub repo.

---

## "Other". when you need a different integration

The catalog covers Microsoft's stack (Power Platform, Azure, D365) plus GitHub and ADO. If you need something else. Slack, Jira, Linear, Supabase, Shopify, Stripe. don't try to stretch one of these.

Run the `plugin-dev:agent-creator` subagent and describe what you need. It generates a fresh specialist agent tailored to the service. Faster than adapting a mismatched template.

---

## When NOT to include an agent

Noise hurts. Include only agents whose systems you actually touch in this project.

- Project is a pure React app with no Microsoft stack → skip pac-cli, dataverse, copilot-studio. Maybe include github.
- Personal script with no tracking → skip ado, github. Keep it minimal.
- Research project, read-only ≥ 90% of the work → skip everything except the project specialists.

Every agent in `.github/agents/` is context the Team Lead reads. Fewer agents = tighter context = faster decisions.

---

## Customizing an agent

After `/raos` copies an agent into your project's `.github/agents/`, it's yours. Edit it. Tighten it. Add project-specific MCP tool names. Narrow the bucket lists based on how much you trust the specialist on this codebase.

The templates are starting points, not frozen truth. Every team adapts them. That's the point.
