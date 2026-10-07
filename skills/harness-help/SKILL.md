---
name: harness-help
description: Guides users through ai-harness setup, /harness-mode, its playbooks and principles, and picking the skill or agent for a task. Type /harness-help with a question.
disable-model-invocation: true
---

# Harness help

Answer the user's question about ai-harness, hand them a prompt they can send, and link the file the answer came from. For a help question, don't start the work. The user asked how, and a harness run spends real tokens on subagents and review panels, so let them send the prompt.

A message that asks for work, such as "use the harness to fix this bug", is not a help question. Read [`harness-mode`](../harness-mode/SKILL.md) and do the work under it.

This file maps questions to the skills, agents, and guide pages that hold the answers. Those files own the details. Read the file you route to before you quote it, and trust it when it disagrees with this map. Give the user repo-relative paths (`skills/<name>/SKILL.md`, `docs/guide/<page>.md`); the public copy is `https://github.com/wonpanu/ai-harness/blob/main/` followed by that path. Skills installed outside the repo (marked "installed" below) live in `${CLAUDE_CONFIG_DIR:-~/.claude}/skills/<name>/`.

## Find out what they need

Infer the need from the message and the conversation. A named situation, such as "which skill reviews a PR?", goes straight to its section. If the need is still unclear, ask one `AskUserQuestion` with these options, then answer only the section they pick:

- Set up or customize the harness
- Start a task with `/harness-mode`
- Pick a skill, agent, or principle
- Fix a run that went wrong

Check the state that changes the answer, and mention it only when it does:

- No `harness-mode` link in `${CLAUDE_CONFIG_DIR:-~/.claude}/skills/` means `./install.sh` hasn't run since these skills landed (with `CLAUDE_DIR=<that dir>` when Claude Code uses a non-default config dir). Nothing below works until it does.
- No `verify-*` skill or other app harness in the project means agents have no scripted way to drive the app. Mention `/create-verification-skill` when the question is about proving a change works.
- No `codex` on the PATH, or not logged in, means the review panels (`interrogate`, `arena`, `architect`) run without their cross-model reviewer. Mention it when the question is about reviews or cost.

## Set up or customize

1. Clone the repo and run `./install.sh`. [INSTALL.md](../../INSTALL.md) walks through it, including connecting Claude, OpenAI, or both. The [README](../../README.md) has a one-line prompt that does it for you.
2. Models are already pinned. Each role's model and effort live in its `agents/*.md` frontmatter (Claude Code) and `codex/agents/<role>.toml` (Codex). The tier table is in AGENTS.md "Orchestration workflow". To change a role's model, edit its file. There is no picker and no per-session budget.
3. Start a real task with `/harness-mode`, a goal, and a check that can pass or fail.

[Guide page 1](../../docs/guide/01-setup.md) has the details. Offer to word their first prompt with them, per [`references/prompting.md`](references/prompting.md).

If cost is the worry, say where the tokens go and how to spend fewer. The harness spends extra tokens on subagents and review panels: `interrogate` runs four reviewers including an xhigh Codex run, `reflect` runs three plus a synthesizer, `arena` and `architect` run panels. AGENTS.md "When to delegate" keeps one-turn work solo. Save the panels for contested or one-way-door work.

The harness is built for Claude Code. AGENTS.md is read by Codex, Gemini CLI, Zed, and other tools that follow the AGENTS.md convention, and `install.sh` links every skill into `~/.agents/skills/` for tools that read that directory. Skills that spawn agents by role (`harness-agent`, `deep-reasoner`, `fast-worker`, ...) need Claude Code's `Agent` tool or Codex's roles from `codex/config.toml`. Elsewhere, the agent applies each role's discipline inline (AGENTS.md, top).

Customizing is under [Make it my own](#make-it-my-own).

## Start a task with `/harness-mode`

`/harness-mode` matches the task to a playbook, copies the playbook's steps into the todo list, and runs the other skills as the steps need them. A step it skips stays in the list as `skip: <reason>`. A good prompt states the goal and how to tell it's done. It doesn't list skills, because a hand-written sequence tends to drop or reorder steps the playbook would keep. Read [`references/prompting.md`](references/prompting.md) before you help word one. [Guide page 2](../../docs/guide/02-harness-mode.md) has examples.

It is always on. The harness-mode routing section of AGENTS.md tells the orchestrator to read it at the start of every non-trivial task, and AGENTS.md loads every session as `CLAUDE.md`. Typing `/harness-mode` makes it explicit. Mid-chat, "new task" makes the mode match a fresh playbook. Playbook steps spawn `harness-agent` for code-writing subagents. To get the same style from a subagent of your own, spawn it with `subagent_type: "harness-agent"`.

## Pick a skill, agent, or principle

The default answer is `/harness-mode`, which runs most of the others when its steps need them. Name a skill directly when the user wants more or less of something than the playbook gives. Read the skill before you recommend it, and give one example prompt.

| The user wants to | Skill |
|---|---|
| Do any non-trivial task with rigor | [`/harness-mode`](../harness-mode/SKILL.md) |
| Know how code works now, or where new code should live | [`/how`](../how/SKILL.md) |
| Know why code is shaped this way, or where a number came from | [`/why`](../why/SKILL.md) |
| Understand a change or subsystem, explained plainly | [`/teach`](../teach/SKILL.md) |
| Catch up on their own recent work on a topic | [`/recall`](../recall/SKILL.md) |
| Know what a small diff could break outside itself | [`/blast-radius`](../blast-radius/SKILL.md) |
| Settle types and module shape before code that crosses a function boundary | [`/architect`](../architect/SKILL.md) |
| Get several attempts at one brief, merged into the best one | [`/arena`](../arena/SKILL.md) |
| Run parallel checks over slices, or race workers | [`/swarm`](../swarm/SKILL.md) |
| Have a multi-model panel review a diff and try to break it | [`/interrogate`](../interrogate/SKILL.md) |
| Stress-test a plan by being grilled on it | `/grill-me` (installed) |
| Grill a plan against the project's docs and terms before writing a PRD | `/grill-with-docs` (installed) |
| Turn the conversation into a PRD, or a PRD into tracker issues | `/to-prd`, `/to-issues` (installed) |
| Fix a bug or build a feature test-first (mandatory for every behavior change; `/harness-mode` runs it) | [`/tdd`](../tdd/SKILL.md) |
| Decide where a seam goes, or deepen a module's interface | [`codebase-design`](../codebase-design/SKILL.md) |
| Run the reproduce, minimise, hypothesise loop on a hard bug | `/diagnose` (installed) |
| Write a handoff doc so another agent can pick up the work | `/handoff` (installed) |
| Make changed code readable without changing behavior | [`/simplifying-code`](../simplifying-code/SKILL.md) |
| Strip comments before review, using a reviewer that didn't write them | [`/no-comments`](../no-comments/SKILL.md) |
| Apply stack style rules: Go, React, Tailwind, TanStack Query, TypeScript | [`go-backend-style`](../go-backend-style/SKILL.md), [`react-frontend-style`](../react-frontend-style/SKILL.md), [`tailwindcss-style`](../tailwindcss-style/SKILL.md), [`tanstack-query-style`](../tanstack-query-style/SKILL.md), [`/typescript-best-practices`](../typescript-best-practices/SKILL.md) |
| Give a cheaper model frontier-level rigor | [`/frontier-mode`](../frontier-mode/SKILL.md) |
| Clean AI tells out of prose | [`/unslop`](../unslop/SKILL.md) |
| Write docs, an RFC, a README, a PR description, or a commit message to a standard | [`/technical-writing`](../technical-writing/SKILL.md) |
| Hear the last reply again in plain words | [`/bro`](../bro/SKILL.md) |
| Give agents a scripted way to drive the app and prove behavior | [`/create-verification-skill`](../create-verification-skill/SKILL.md) |
| Bring a verification skill and its feature map back in line with the app | [`/maintain-verification-skill`](../maintain-verification-skill/SKILL.md) |
| Vet a performance number before reporting or acting on it | [`/benchmark-checklist`](../benchmark-checklist/SKILL.md) |
| Run a large or cross-cutting change, or one to review after stepping away | [`/figure-it-out`](../figure-it-out/SKILL.md) |
| Keep a decision log during a run, and review it afterward | [`/show-me-your-work`](../show-me-your-work/SKILL.md) |
| Write or restructure a skill | [`creating-skills`](../creating-skills/SKILL.md) |
| Turn their own working habits into a personal mode skill | [`/automate-me`](../automate-me/SKILL.md) |
| Turn what a finished task taught into skill edits | [`/reflect`](../reflect/SKILL.md) |
| Stop agents from repeating the same mistakes in this repo | [`/correct`](../correct/SKILL.md) |
| Find their way around the harness | `/harness-help` |

If a skill directory next to this one is missing from the table, read its frontmatter and route by its description. The `principle-*` directories are covered under principles below.

Agents are roles, not commands. AGENTS.md "Orchestration workflow" routes them: `deep-reasoner` for reasoning-heavy work, `fast-worker` for mechanical bulk, `harness-agent` for code inside a playbook step, `senior-lead-reviewer` for the maintainability lens before merge, `comment-reviewer` for the comment pass, `web-searcher` for internet research, `code-committer` for commits. A user steers one by asking for it ("have senior-lead-reviewer look at this before I merge").

Close calls:

- `/how` explains what the code does. `/why` explains the reasons. `/teach` runs one or both and explains the result plainly.
- `/diagnose` finds the cause of a hard bug. `/tdd` pins the fix with a failing test first. The Bug fix playbook runs both.
- `/simplifying-code` makes a diff readable without changing behavior. `/interrogate` hunts bugs and design flaws with a panel. `senior-lead-reviewer` judges whether the team can live with it.
- `/reflect` turns one session's lessons into skill edits. `/correct` makes a repeated mistake class impossible in a repo. `/automate-me` captures the user's own working style.
- `/arena` gives every worker the same brief and merges the best parts. `/swarm` splits work into slices or a race and returns one report.
- `/figure-it-out` designs one rigorous run. The Orchestrate playbook runs a program that spans days and many PRs. The Autonomous run playbook drives one task to a finish condition.

Not in the harness:

- `/code-review`, `/security-review`, `/simplify`, `/loop`, `run`, and `claude-in-chrome` are Claude Code built-ins. The playbooks call them where they fit.
- There is no `/orchestrate` skill. Orchestrate is a `/harness-mode` playbook.
- What was deliberately left out, and why, is in the port record that AGENTS.md "General practice" links.

## Playbooks and principles

Playbooks are step lists inside `/harness-mode` (`skills/harness-mode/playbooks/`), not skills, so they have no slash command. Describing the task picks one, and these phrases name one directly:

- "babysit this pr" or "check on pr 123" runs Babysit. It drives the PR to merge-ready and stops there. It doesn't merge unless the user asks to merge, land, or ship.
- "land the stack" runs Shipping.
- "take over this branch" runs Session pickup.
- "pause safely" runs Pause safely. `/handoff` writes the handoff doc.
- "full autopilot on this queue" runs Autopilot-full. "stack them, don't ship" runs Autopilot-stack.
- "run the eval playbook" runs Eval.

The Playbooks section of [`harness-mode`](../harness-mode/SKILL.md) lists every playbook and when it applies. [Guide page 6](../../docs/guide/06-verify-and-ship.md) covers opening, babysitting, and landing a PR.

The harness has no planning skill. Claude Code's plan mode works alongside it. For work that spans phases or stacked PRs, asking `/harness-mode` for a plan runs the [Multi-phase plan playbook](../harness-mode/playbooks/multi-phase-plan.md), which writes the plan and doesn't implement it. `/to-prd` and `/to-issues` turn it into tracker items. For a design question, the Prototype playbook or `/architect` settles it in code first.

Principles are one-rule skills (`skills/principle-*/`, 24 of them) that `/harness-mode` reads and cites in one line of its reply, as in `principles: laziness-protocol, prove-it-works`. The user rarely invokes one. They steer with the names instead, as in "apply prove it works. show me the real output." Typing `/principle-<name>` still loads one on demand. [Guide page 8](../../docs/guide/08-principles.md) lists them.

## Fix a run that went wrong

| Symptom | Fix |
|---|---|
| No playbook todo list on a real task | Say "new task" or type `/harness-mode`. If it never applies, check that `${CLAUDE_CONFIG_DIR:-~/.claude}/CLAUDE.md` links to AGENTS.md (`./install.sh`, with `CLAUDE_DIR` set for a non-default config dir). |
| A question got treated as the next step of the last task | Say "new task", or say the turn doesn't need the mode. |
| A model change had no effect | Models live in `agents/*.md` frontmatter and `codex/agents/*.toml`. Edit there, then start a new session. |
| Runs cost more than expected | See the cost paragraph under Set up or customize. |
| A skill didn't load on its own | Most workflow skills are user-invoked (`disable-model-invocation: true`). They run when typed, or when a `/harness-mode` step calls them. The style skills, `simplifying-code`, `creating-skills`, `tdd`, and `codebase-design` load from the user's words. |
| The agent keeps making the same mistake | `/correct` makes the class impossible and records what enforces the rule. `/reflect` turns one session's lesson into a skill edit. |
| Parallel agents overwrote each other | Give each agent its own worktree (`Agent` with `isolation: "worktree"`). |
| An overnight run moved but finished nothing | `/loop` needs a check that can pass or fail, not a duration. See [guide page 7](../../docs/guide/07-overnight.md). |
| The reply claims success from a green build | Ask for the real command, flow, stored value, or profile. That's the prove-it-works principle. |
| A review panel ran without its Codex reviewer | `codex` is missing or logged out. Run `codex login` (INSTALL.md). |

For a run that drifts, [`references/prompting.md`](references/prompting.md) has one-line steers. [Guide page 10](../../docs/guide/10-recipes-and-pitfalls.md) has more pitfalls and the recipes worth copying.

## Make it my own

- [`/automate-me`](../automate-me/SKILL.md) drafts a personal mode skill from the user's own history, and proposes AGENTS.md edits for rules that must hold every session.
- [`/reflect`](../reflect/SKILL.md) after a session turns its lessons into skill edits the user approves.
- [`/correct`](../correct/SKILL.md) turns a repeated correction into a lint, type, test, or hook, and keeps the rule-to-enforcer table in AGENTS.md or the project's `CLAUDE.md`.
- `/harness-mode write a skill for <workflow>` runs the authoring playbook, which follows [`creating-skills`](../creating-skills/SKILL.md). The eval playbook tests a skill change blind.
- Always-on rules go in AGENTS.md. An AGENTS.md change also updates `PLAYBOOK.html` in the same change. Fix a misbehaving skill in its own PR, not inside the feature work where it went wrong.

[Guide page 9](../../docs/guide/09-make-it-yours.md) covers each of these.

## Reply

Harness output style (AGENTS.md "Output style"). Lead with the answer. Give at most one example prompt in a code block, adapted from [`references/recipes.md`](references/recipes.md) when one fits, then the link to the file the answer came from. Keep it short unless the user asked for the whole map. End with the one next action, usually: send the prompt.
