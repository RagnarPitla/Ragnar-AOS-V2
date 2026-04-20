# Image Prompts for Ragnar-AgenticOS

Two prompts, same visual language as the Stage 3 "Objective" diagram (cream background, monospace, terminal window, robot-icon agent boxes, warm-brown arrows, sticky-note callouts, pill badges, 16:9).

Paste into Lovart.ai, Nano Banana, or any high-fidelity image generator.

---

## Prompt 1. Thumbnail for README (primary)

**Title in image:** Your Agentic Team Builds It

Clean minimalist technical documentation illustration. Warm cream/parchment background (#F3ECD8). Bold black monospace typography throughout. Terminal-view aesthetic. 16:9 aspect ratio.

Visual language (match exactly):

- Rounded-rectangle agent boxes outlined in warm brown (#8B6F47), each with a small robot-head icon in the top-right corner.
- A macOS-style terminal window with red / yellow / green traffic lights, cream-colored content area, monospace text.
- Thin warm-brown arrows connecting elements. Dashed brown lines for "shared task" references.
- Sticky-note callout boxes (slightly off-white, rounded, soft drop shadow).
- Pill-shaped badges in brown for labels like "RAGNAR-AGENTIC-OS" and "STAGE 3".
- Olive-green checkmarks for "done" states. No other bright colors.

Layout (left to right):

1. **Top-left pill badge:** `RAGNAR-AGENTIC-OS`
2. **Timestamp strap just under the pill badge (small caps, warm brown, letter-spaced):** `APRIL 2026. HERE IS WHERE WE SHOULD BE.`
3. **Huge bold title just below:** `Your Agentic Team Builds It`
4. **Sub-tagline (monospace, smaller):** `One objective. End-to-end Copilot Studio agent: research, policies, build, deploy. Delivered by your subagent team.`

5. **Left column (input side):**
   - A circular "You" avatar, labeled `objective setter`.
   - An arrow to a sticky-note:
     ```
     OBJECTIVE: Build a customer-facing
     Copilot Studio agent end-to-end.
     Include customer research, agent
     design, policies, skills, deploy
     to production environment.
     ```

6. **Center top, terminal window** titled `Terminal - Ragnar-AgenticOS`:
   ```
   $ /my-os "build procurement agent end-to-end"
   > parsing objective...
   > composing 6-subagent team
   > research -> challenge -> synthesis
   > tracking via shared_tasks.md
   > team active_
   ```

7. **Center, team of 6 subagent boxes arranged around a central orchestrator:**
   - Center: `team-lead` with a small crown icon, label `orchestrator`
   - Around it (clockwise from top): `customer-research` (label: `interviews + brief`), `copilot-studio-agent` (label: `YAML topics + skills`), `dataverse-agent` (label: `policy tables + metadata`), `pac-cli` (label: `auth + environments`), `azure-agent` (label: `deploy + Key Vault`), `ado-agent` (label: `work items`)
   - Thin warm-brown arrows between every subagent and the team-lead.

8. **Center-bottom sticky-note** labeled `shared_tasks.md`, dashed lines from every subagent to it:
   ```
   [x] customer research
   [x] agent needs brief
   [x] policies in Dataverse
   [x] Copilot Studio topics
   [x] skills + plugins
   [ ] deploy + verify
   ```

9. **Right column (output side):**
   - A verification gate rendered as two warm-brown pillars, labeled `verification`.
   - After the gate, a stack of three output files with checkmarks:
     - `customer_research.md`
     - `agent_policies.yaml`
     - `procurement_agent.deployed`

10. **Environment hint callout** (top-right sticky-note):
   ```
   CLAUDE_CODE=yes
   COPILOT_CLI=yes
   context: fork
   ```

11. **Bottom banner (all caps, centered, spanning full width, small brown letters):**
    `YOU SET THE OBJECTIVE. THE OS COMPOSES THE TEAM. THE TEAM DELIVERS THE RESULT.`

12. **Author signature (bottom-right corner):**
    Render the text `by Ragnar Pitla` in **bold black monospace**, clearly legible (roughly 2x the weight of the bottom banner). Place it in the bottom-right corner with a small amount of padding from the edges. No box, no underline. Treat it like a creator credit, unmistakable but not dominant.

Do NOT include any Mercedes, Angebots-Prüfung, Niyam, or customer-specific references. Keep it generic and aspirational.

---

## Prompt 2. Task vs Objective comparison (optional, for decks or blog)

**Title in image:** From Task to Objective

Same cream + monospace + warm-brown style as Prompt 1. 16:9. Split vertically down the middle with a subtle warm-brown dividing line.

**Top strap across the full width, above the two halves (small caps, warm brown, letter-spaced):** `APRIL 2026. HERE IS WHERE WE SHOULD BE.`

**Author signature (bottom-right corner):** `by Ragnar Pitla` in bold black monospace, roughly 2x the weight of the bottom banner. Bottom-right with small padding. No box, no underline. Clear creator credit.

### Left half - `STAGE 1. Task-based CLI`

- Top pill badge: `STAGE 1`
- Bold title: `Regular CLI`
- Sub-tagline: `You type prompts. One at a time. You hold the plan in your head.`
- Circular "You" avatar with an arrow to a terminal window showing:
  ```
  $ write me a python script
  > here you go...
  $ now add error handling
  > updated...
  $ now write tests
  > updated again...
  $ why is this failing?
  > try this fix...
  ```
- Below the terminal, a trail of small prompt-bubbles labeled `prompt 1 -> prompt 2 -> prompt 3 -> prompt 4 -> ...` trailing off the edge.
- Bottom label in small caps: `YOU DECOMPOSE. YOU QA. YOU INTEGRATE. YOU HOLD STATE.`

### Right half - `STAGE 3. Objective-based Agentic OS`

- Top pill badge: `STAGE 3`
- Bold title: `Ragnar-Agentic-OS`
- Sub-tagline: `You set the outcome. The OS composes the team. The team delivers.`
- Circular "You" avatar with a single sticky-note:
  ```
  OBJECTIVE: Build a Copilot Studio
  agent end-to-end with policies,
  skills, and production deploy.
  ```
- Arrow into a terminal window titled `Ragnar-Agentic-OS` showing:
  ```
  $ /my-os "build it"
  > composing team of 6 subagents...
  > research -> challenge -> synthesis
  > verifying against success criteria
  > done_
  ```
- Below the terminal, a cluster of 6 agent boxes with robot icons: `pac-cli`, `dataverse-agent`, `copilot-studio-agent`, `azure-agent`, `ado-agent`, `customer-research`, all connected to a central `team-lead` with a crown.
- Arrow out of the cluster to a stack of deliverables on the far right: `agent.deployed`, `policies.yaml`, `skills.bundle`, `research.md`, each with an olive-green checkmark.
- Bottom label in small caps: `THE TEAM WRITES THE PLAN. YOU APPROVE GATES, NOT STEPS.`

### Bottom center banner spanning full width

`FROM TASK-BASED PROMPTING TO OBJECTIVE-BASED DELIVERY.`

Same muted palette. No other colors besides cream, black, warm brown, and subtle olive-green checkmarks.

---

## Usage

1. Paste Prompt 1 into Lovart.ai / Nano Banana / preferred generator.
2. Save output as `assets/ragnar-agentic-os-thumbnail.png` in this folder.
3. The README already links to that path, so it will render once the file is there.
4. Prompt 2 is optional. Save as `assets/task-vs-objective.png` if generated.
