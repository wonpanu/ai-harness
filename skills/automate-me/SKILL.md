---
name: automate-me
description: "Use for \"automate me\", \"create/update/refresh my -mode skill\", \"turn/capture my preferences or working style into a skill\", or wanting agents to follow how the user works without re-prompting. Mines the user's Claude Code and Codex transcripts, asks a few structured questions, and drafts or revises a personal <name>-mode skill via creating-skills and unslop, shipped on a branch with a PR."
disable-model-invocation: true
---

# Automate me

A guided flow for turning the user's working conventions into rules agents follow. The output is one `-mode` skill tailored to them (e.g. `jay-mode`, `priya-mode`), plus proposed AGENTS.md edits for any rule that must hold in every session.

This skill orchestrates three others: a mining pass (step 1), the `creating-skills` skill (authoring), and the **unslop** skill (prose discipline for the skill text). It sequences them. It doesn't replace them.

## Flow

### 0. Check for an existing skill

Look for a mode skill matching the user's handle:

- `skills/*-mode/SKILL.md` in the ai-harness repo (global; linked into `${CLAUDE_CONFIG_DIR:-~/.claude}/skills/`)
- `${CLAUDE_CONFIG_DIR:-~/.claude}/skills/*-mode/SKILL.md` (installed from elsewhere)
- `.claude/skills/**/*-mode/SKILL.md` in the current project. Mode skills can sit in a personal category directory (`.claude/skills/<handle>/`), not only at the top level.

`harness-mode` and `frontier-mode` are shared harness modes, not personal ones. Skip them.

If one exists, confirm intent with `AskUserQuestion` (unless they already said "update my skill" or similar):

- Update the existing skill (default for repeat runs)
- Start fresh (rare, ask why before doing it)

Update mode changes the rest of the flow:

- Step 1 mines only history since the skill was last edited (`git log -1 --format=%cI <path>`).
- Step 2 asks what's changed or missing, not what to capture from zero.
- Step 4 edits the existing file in place. Preserve sections the user hasn't contradicted. Revise ones with new evidence. Add new sections only for genuinely new rules.

### 1. Mine their history

The transcript script ships with `reflect`. From this skill's directory, `T=../reflect/scripts/transcripts.sh`:

- `$T dirs <project-path>`: this project's Claude Code transcript dirs.
- `$T prompts <days> <dir>...`: every operator prompt, oldest first, one line each (`<timestamp> <session-id> <text>`).
- `$T corrections <days> <dir>...`: the prompts that read as corrections, in English or Thai, plus every prompt sent right after an interrupt.
- `$T codex <days> <project-path>`: operator prompts from Codex sessions in that project.
- `$T view <transcript.jsonl>`: the readable session, for context around a hit.

Scope: default to this project's dirs. A global mode skill (in the ai-harness repo) should reflect work across repos, so ask once with `AskUserQuestion` whether to include every project under `${CLAUDE_CONFIG_DIR:-~/.claude}/projects/`. Never widen without that yes: other projects hold unrelated, possibly private chats.

Survey the last 2-4 weeks, split into 3 date slices so each has enough material. Launch one `fast-worker` per slice in one message. Give each the dirs, its date window (it runs `prompts` and `corrections` over the full span and keeps the lines whose leading timestamp falls in the window), and the signals below. Each returns a short structured list of patterns with evidence pointers (session id, timestamp, short quote). Default signals worth hunting:

- Response preferences (length, tone, format, language, "dumb it down" corrections)
- Delegation habits (subagents, roles, specialized workflows, parallelism)
- Verification posture (what "done" means, unit tests vs live repro, reviewers)
- Code and prose discipline (style, principles cited, lint/format tools)
- Process conventions (worktrees, commits, PRs, review/merge tooling)
- Repeated corrections (the same fix asked for twice is a rule the agent keeps missing)
- Meta preferences (fixing skills mid-task, proposing new ones)

Cross-check across slices before elevating a signal. Patterns seen in 2+ slices are high-confidence. Lone signals are weak and usually get dropped.

### 2. Ask the user directly

Mining misses intent that hasn't come up yet. Use the `AskUserQuestion` tool (structured multiple choice) rather than asking the user to type from scratch.

Shape: one or two questions with up to 4 options each (the tool's limit; it always offers an Other choice), `multiSelect: true` for category questions. Start broad ("Which areas matter most?"), then follow up on selected areas with specific options. After the structured rounds, one free-form chat question catches anything the options missed.

Don't dump 20 questions.

### 3. Cluster findings

Group the combined signals into sections. Common ones (use only what applies):

- **Response style**: length, tone, format, language.
- **Autonomy**: how much to do without asking, MCP tool use.
- **Understand first**: which skills to reach for when scoping or investigating a change.
- **Subagents**: default, parallelism, role-to-task, specialized workflows.
- **Prose / code discipline**: principles, lint tools, style guides.
- **Review and verify**: repro posture, verification skills, live-testing tools.
- **Process**: git worktrees, commits, PRs, review/merge tooling.
- **Skills**: skill-authoring habits, fix-the-skill-first, proposing new skills.

The **harness-mode** skill shows the shape. Read it for granularity. Don't copy its content. The user's rules are not the same as harness-mode's.

Then sort each rule by where it must live:

- **Must hold in every session** (a repeated correction, a hard rule): propose it as an AGENTS.md edit for global rules, or the project's `CLAUDE.md` for project rules. A mode skill with `disable-model-invocation: true` applies only when the user types it, so it cannot carry these. Propose the AGENTS.md edit first, docs-first (AGENTS.md "General practice"), and leave out what AGENTS.md already says.
- **Enforceable by a mechanism** (a lint, a hook, a permission rule): name it as a `/correct` class instead of writing it down.
- **Personal style for when they invoke the mode**: the mode skill.

### 4. Draft the skill

Use the `creating-skills` skill to author it. Placement:

- Global: `skills/<handle>-mode/SKILL.md` in the ai-harness repo. Run `./install.sh` once afterward so the new directory is linked into `${CLAUDE_CONFIG_DIR:-~/.claude}/skills/` and `~/.agents/skills/`.
- Project-local: `.claude/skills/<handle>-mode/SKILL.md` in the project, or under an established personal category (`.claude/skills/<handle>/<handle>-mode/`). Preserve an existing mode skill's location.
- Handle: the user's first name or chosen identifier. Keep the `-mode` suffix even though `creating-skills` prefers gerund names: the harness modes share it.
- Frontmatter `name`: equals the directory name.
- Frontmatter `description`: trigger on their name + `/<handle>-mode` + "work in their style", not on generic keywords like "write code" or "review PR". Keep it one YAML scalar. Quote it or use `description: >-` with indented continuation lines when punctuation or wrapping requires it.
- Frontmatter `disable-model-invocation: true` by default. Opt out only if the user explicitly wants the mode to load on its own, and even then, every-session rules belong in AGENTS.md.

### 5. Iterate on prose

Apply the **unslop** skill and `creating-skills`' writing rules to every line.

Show the draft to the user and take feedback. Expect multiple iterations. Cut ruthlessly. A mode skill is not a manual.

### 6. Land it

Hand the commit to `code-committer`: a branch and a PR, never a push to main. Ship the AGENTS.md or `CLAUDE.md` edits from step 3 in the same PR when the user approved them. An AGENTS.md edit also updates `PLAYBOOK.html` in the same change.

## Guardrails

- **Don't overfit to one conversation.** A preference stated once and contradicted another time is noise. Require multiple instances before codifying it.
- **Don't be clever.** Restating other skills' contents, inventing metaphors, or writing "poetic" prose for an agent reader is cost without benefit. Keep it operational.
- **Reference, don't inline.** Other skills the user relies on should appear as path references, not pasted excerpts. Same for any principle docs they maintain elsewhere.
- **Keep sections minimal.** Only add a section if the user has a specific, non-default rule there. "Communicate clearly" is not a section. "Short paragraphs. Tables when comparing options. Bullets only when items are genuinely parallel." is.
- **Name conventions generic.** Use "the user" or "the human" in imperatives, not the author's first name.
- **Don't force symmetry.** If a user has no process rules worth writing down, skip the Process section entirely.

## Evaluation

A `-mode` skill is subjective output. The `creating-skills` evaluation-scenario loop isn't useful here. Vibe-check with the user: does it read like them? Did it miss anything? Then ship.

Tune the description only if the skill's trigger accuracy turns out to be a problem in practice.

## When not to use

- User wants a task-specific skill (not working conventions): `creating-skills` alone, no mining required.
- User wants to capture one narrow workflow (e.g. "how I write commit messages"). That's a regular skill, not a mode skill.
- User wants a repeated mistake to stop: `/correct`. User wants one session's lessons captured: `/reflect`.

**Reply:** harness output style (AGENTS.md "Output style"). Lead with the skill path and the PR link, then the sections written (one line each), the proposed AGENTS.md edits, and any `/correct` classes. End with the one next action.
