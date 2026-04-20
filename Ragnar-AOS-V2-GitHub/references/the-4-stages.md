# The 4 Stages of an Agentic Team

The map from where you are to where you're going.

---

## Where we are today

You open Claude Code, type a task, get an output. You read it, fix it, integrate it, commit it. Then you type the next task.

The AI is fast. The AI is cheap. But the AI is your hammer, and you are still swinging it one nail at a time. You are the planner, the decomposer, the synthesizer, the QA, the integrator. The AI writes the code in between.

That is not a team. That is a tool.

## Where we are going

The future does not look like typing faster. It looks like typing less.

You give the AI an **objective**, not a task. "Make the onboarding flow convert 20% better," not "add a button to the sign-up page." The AI decides what that means. It builds its own team. It assigns roles. It runs the work. It reports back.

You become the objective-setter. The AI becomes the team.

Beyond that, there is a horizon called **Headless**: you set an objective before bed, wake up to a pull request. We are not ready for that yet. But we are heading there.

---

## The 4 Stages

| Stage | You own | AI owns | Signal you are stuck |
|---|---|---|---|
| **1. Task** | Plan, execute, synthesize, QA, integrate | The one task you typed | You are the orchestrator of every prompt |
| **2. Project** | The plan and acceptance criteria | Decomposition, parallel execution, synthesis | You are writing briefs and reviewing every piece |
| **3. Objective** | The objective and the guardrails | Team composition, plan, execution, iteration | Review time drops, output scales without you scaling |
| **4. Headless** (horizon) | Strategy and verification gates | Everything operational, on a schedule | Not here yet. organizational, not technical |

---

## Stage 1: Task

You prompt, AI responds, you integrate.

One window or four. same shape. You pick the task. You write the prompt. You read the output. You glue it in. Repeat.

The AI is a fast pair programmer. Not a teammate. You do all the planning, synthesizing, QA, integration. You are the bottleneck, and you don't know it because typing fast feels productive.

**Signal you are stuck in Stage 1:**
- Every new prompt is a new decision.
- You decide what to build next, and how to cut it up.
- You retype the same setup context over and over.
- You feel busy, producing code. but projects take forever.
- Parallelizing into more chats just multiplies orchestration work on you.

**To move to Stage 2:** Stop prompting task by task. Describe the project. Let the AI decompose.

---

## Stage 2: Project

You give the AI a bigger chunk of work. The AI decomposes it.

Now you say "build the feature," not "write the function." The AI reads your project. It spawns sub-agents. It fans out work in parallel. It synthesizes results.

You still own the plan. You still approve the work. But you stop writing task by task. You describe what you want; the AI figures out how to break it down.

**What makes Stage 2 work:**
- A `CLAUDE.md` at the project root that tells every agent what the project is.
- Sub-agents in `.github/agents/` with clear names and ownership.
- A skills library that encodes how your team actually works.
- Git worktrees for parallel streams.

**This is where RAOS brings you.** You run `/raos` in any project folder. If a team exists, it boots. If not, it reads your project, decides which specialists you need, creates them, and hands you a shared task list. You are no longer setting up a team every time. the OS does it.

**Signal you are ready for Stage 3:** Decomposition works. But you are still writing every brief, still reviewing every piece. You want to go higher.

---

## Stage 3: Objective

You give the AI an outcome, not a work breakdown.

This is the shift. You stop saying "build X." You start saying "achieve Y." The AI builds the team itself. It decides what roles are needed. It writes the plan. It assigns the work. It iterates when the first pass isn't good enough. It comes back with a result, not a draft.

At this stage the agents coordinate with each other, not just with you. They share a task list. They hand off. The frontend agent talks to the backend agent. The tester talks to both. You are not the hub. You are the product owner.

What you own shrinks to two things: **the objective** and **the guardrails**. What does success look like? What is not allowed to break? Everything else is the team's job.

**What makes Stage 3 work:**
- Agent Teams (Claude Code's newest multi-agent capability).
- Evals so the team knows when it's done.
- Verification loops so the team can self-check.
- Guardrails on what the team can touch (tool allowlists, permission gates, two-bucket approval).

**This is where RAOS is going.** Today it brings you to Stage 2 reliably. The design is pointed at Stage 3: receive an objective, compose the team automatically, run with cross-collaboration, and deliver a verified outcome.

**Signal you have reached Stage 3:** Your team writes objectives, not tasks. Your review time drops. Your output scales without you scaling. You trust the team enough not to read every intermediate step.

---

## Stage 4: Headless (the horizon)

You set the objective. You walk away. You come back to the result.

No terminal open. Agents run on a schedule, in a loop, or triggered by an event. They plan. They execute. They self-correct. They report when done, or when blocked.

**We are not ready for Stage 4 yet. The reason is not technical.**

The tech works. The Ralph Loop works. Scheduled headless runs work. The `-p` flag works. You can wire a cron today. That is not the blocker.

The real blocker is two things, and neither are code.

**1. Access to the systems that run unattended work.** Credentials, production data, scheduling. Most orgs require governance review, security signoff, audit trail, compliance. Quarters, not weeks.

**2. The data we feed agents is not objective-oriented yet.** Look at your emails, Teams messages, meeting transcripts. They are full of tasks. "Can you do X." "Please update Y." "Follow up on Z." Fuzzy, ambiguous, context-dependent. A human reads them because a human has context. An agent cannot extract an objective that isn't in the input.

Headless needs objective-oriented inputs. Emails that carry outcomes. Meetings that produce goals. Teams threads that end with a decision, not a task list.

**Here is the beautiful part.** When we get to Stage 3, we start operating objective-first. We write objectives instead of tasks. We talk objectives in meetings. We end emails with outcomes, not asks. We train ourselves and our people to generate objective-oriented data by default.

That is what makes Stage 4 real. Not a new Claude feature. Not a new admin role. Us changing how we communicate, one email and one meeting at a time, until our inputs are clean enough for an agent to act without a human translating first.

**Stage 3 is the training ground for Stage 4.** The way we learn to work in Stage 3 is the way we generate the data that unlocks Stage 4.

---

## Where do you start?

If you are in Stage 1, here is the move.

**This week:** Install RAOS in one project. Let it bootstrap a team. Describe a project, not a task. Let the team decompose it. Review the merged output, not the intermediate steps.

**This month:** Write a `CLAUDE.md` for your main project. Codify one skill you use every day. Create one specialist agent that does work you keep repeating.

**This quarter:** Run a real project through Stage 2 end to end. Measure how much faster. Measure how much less you typed. Then describe the next project as an objective, not a feature list.

We are all in Stage 1 today. RAOS is the bridge to Stage 2. Stage 3 is the destination we are actively building toward. Stage 4 is the horizon.

If you want to go there, this is your way to start here.
