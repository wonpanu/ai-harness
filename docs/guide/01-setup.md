# Set up ai-harness

In this page you install the harness, see how its models are pinned, and run your first task. Setup is one clone plus one script.

## Install the harness

Clone the repo and run its installer:

```text
git clone https://github.com/wonpanu/ai-harness ~/ai-harness
cd ~/ai-harness && ./install.sh
```

`install.sh` symlinks `AGENTS.md`/`CLAUDE.md`, installs the agents under `agents/` into `~/.claude/agents`, and installs the skills under `skills/` without touching `~/.claude/skills/tdd`, which is unrelated to this harness. See [INSTALL.md](../../INSTALL.md) for the full walkthrough, including connecting Claude, OpenAI, or both.

## Models are already pinned

There's no setup conversation to pick models. Each role's model and reasoning effort live in that agent's own frontmatter:

- `agents/deep-reasoner.md`, `agents/senior-lead-reviewer.md` — Opus 5.5, effort `xhigh`.
- `agents/fast-worker.md` — Sonnet 5, effort `medium`.
- `agents/web-searcher.md`, `agents/code-committer.md` — Haiku 4.5.
- The orchestrator is the session model (Fable 5.1, effort `high`).

Codex CLI gets the same roles from `codex/config.toml`, which points each role at its `codex/agents/<role>.toml` for model and effort. The tier map lives in `AGENTS.md`'s Orchestration workflow section. To change a role's model, edit that agent's frontmatter (or its `codex/agents/<role>.toml` counterpart) directly — there's no interactive model picker, and no per-session reasoning-budget choice.

## Accept the verification offer, or don't

The first time you run a real task, `/harness-mode` looks for a way to prove app behavior in your project, either a `verify-*` skill or an existing harness. If it finds neither, it offers once to generate one with [`/create-verification-skill`](../../skills/create-verification-skill/SKILL.md).

Say yes and it writes `.claude/skills/verify-<app>/`, a project-local skill that teaches agents to drive your app the way a user does. It proves the skill works once before handing it over. Say no and the task moves on. You can run `/create-verification-skill` yourself any time. [Verify and ship](./06-verify-and-ship.md#create-a-project-verification-skill) covers it in depth.

If you're new to this harness, say yes. An agent that can check its own work keeps going until the check passes. An agent that can't hands every result back to you to check by hand. Of everything in this guide, the verification skill pays off the most.

## Keep the cost in check

ai-harness spends extra tokens on subagents and review panels. That's the price of the rigor. To spend fewer:

- Save `/harness-mode` for work that needs rigor. A small, obvious edit doesn't — the orchestrator's default is to do one-turn work itself.
- Shorten a panel, such as an `/arena` candidate count. Each entry runs one subagent.
- Delegate only when a condition in `AGENTS.md`'s "When to delegate" list clearly applies; cold-context agent overhead isn't worth it for 1-2 file edits.

## Run your first task

Pick something real but small, and describe it the way you'd describe it to a colleague:

```text
/harness-mode add a --json flag to this command. text output stays byte-identical. verify both.
```

Watch the todo list. Its first items are the matched playbook's steps copied in, the Feature playbook for this prompt. If `/harness-mode` skips a step, the step stays in the list with `skip: <reason>`, so you can see what it chose not to do.

From here you can type normal follow-ups. `harness-mode` is always on for this repo: `AGENTS.md` tells the orchestrator to apply it at task start, so there's no mode to toggle per message.

Next: [Route work through `/harness-mode`](./02-harness-mode.md).
