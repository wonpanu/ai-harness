# Agent guidance

Single source of truth for every AI coding agent (Claude Code, Codex, Cursor, Gemini CLI, Zed, …).
`CLAUDE.md` is a symlink to this file. Claude Code maps the roles below to the predefined
subagents in `agents/`; a tool without subagents applies each role's discipline itself, inline.

**Keep the playbook in sync:** `PLAYBOOK.html` is the visual version of this file (interactive
flow diagram + rules). Whenever this file, `agents/*.md`, or `skills/harness-mode/SKILL.md`
change, update PLAYBOOK.html in the same turn; an edit to any other skill does not require it. It is
also published as the "AI Orchestrator Playbook" artifact — offer to republish it so the hosted copy
stays current. Skills are symlinked from `~/ai-harness`, so a skill edit made from any project
session lands on whatever branch that checkout has: branch there first (`reflect` / `correct` do).

## Orchestration workflow

Model per role lives in each agent's frontmatter (`agents/*.md`, symlinked into `~/.claude/agents`) — the models named below are the current values. Codex CLI gets the same roles from `codex/config.toml` (symlinked to `~/.codex/config.toml`), which points each role at its `codex/agents/<role>.toml` for model, effort and instructions, on this tier map:

| Tier | Claude | OpenAI (Codex) |
|---|---|---|
| Orchestrator / peer / harness-agent | Fable 5.1 · high | gpt-6-astra · high |
| deep-reasoner · senior-lead-reviewer | Opus 5.5 · xhigh | gpt-6-sol · xhigh |
| fast-worker · comment-reviewer | Sonnet 5 · medium | gpt-6-luna · medium |
| web-searcher · code-committer | Haiku 4.5 | gpt-6-luna · low |
| cross-model second opinion | — | `codex exec -c model="gpt-6-sol" -c model_reasoning_effort="xhigh"` |

You (the session model) are the orchestrator. Plan, decompose, synthesize.
Reasoning-heavy phases → deep-reasoner role (Opus 5.5, effort xhigh)
Mechanical work → fast-worker role (Sonnet 5, effort medium)
Internet research (docs, versions, error messages, current facts) → web-searcher role (Haiku 4.5)
Committing finished work on instruction → code-committer role (Haiku 4.5) — never modifies code, never pushes to main — branch + PR when told to ship
Other agent (a fresh instance of the current session model — same model as you, separate context) is a cracked engineer on par with deep-reasoner, from a different perspective. Treat as a peer, not a reviewer.
Code-writing delegate inside a harness-mode playbook step → harness-agent role (session model, fresh context; reads the `harness-mode` skill in full before working, executes the brief only — a `general-purpose` agent skips that read and drifts)
Comment pass before review → comment-reviewer role (Sonnet 5, read-only; spawned by the `no-comments` skill)
Cross-model second opinion (arena / architect / interrogate panels) → one Codex run via `codex exec`, same prompt, different model family; agreement is high-signal
High-stakes decisions: task the peer on the same problem in parallel, synthesize the best of both, without showing either the other's answer. Keep your own context lean.

**When to delegate (vs. do it yourself):** default is doing it yourself in one turn — delegate only when one of these clearly applies:
- Explore/search across many files or directories where reading exceeds answering → `Explore` or `fast-worker`
- Reasoning-heavy work (architecture, complex debugging, algorithms, trade-offs) needing deep thought across many tool calls → `deep-reasoner`
- Mechanical work, well-specified but bulky/repetitive (multi-file renames, boilerplate, test scaffolds) → `fast-worker`
- Internet research → `web-searcher`; committing finished work → `code-committer`
- High-stakes decision where being wrong is expensive → peer + deep-reasoner in parallel, then synthesize
- Reviewing work about to merge/ship (plan, diff, design) from a senior-lead lens — maintainability, tech-debt, operability → `senior-lead-reviewer` (Opus 5.5, effort xhigh, fresh context; distinct lens from peer=correctness and simplifying-code=over-engineering)
- Code-writing step of a harness-mode playbook (Feature step 4, Bug fix step 3) → `harness-agent`, for the review separation; the one-turn exception below still applies
Work you can finish yourself in one turn (one or two file edits, answering questions, small edits): **do NOT delegate** — cold-context agent overhead isn't worth it. That same "one or two file edits" line is the trivial cut-off everywhere in this file and the playbooks.

**PRD before starting:** whenever the orchestrator takes on incoming requirements, write a brief PRD first — goal, acceptance criteria, and necessary context (constraints, relevant files/systems, decisions already made) — and pass it to every delegated worker and reviewer so they work/review on the same context. Scale to the task: a few lines for small work, full form only for large work. If any domain term in the requirement is ambiguous or may mean something different in this project's context, run `grill-with-docs` (or align terminology against the project's domain model/docs by hand) BEFORE drafting the PRD — so the PRD's words carry the project's meaning, not a guessed one. Every new constant, error value, message string, or helper the PRD names points at an existing file that already does the same thing (`model: internal/handler/auth.go`); a name without a model is a guess the delegate builds literally.

## Task routing (harness-mode)

Always on. At the start of every non-trivial task (anything beyond a one-line answer or one or two file edits), invoke the `harness-mode` skill: match the task to one of its playbooks and open a todo list whose first items are that playbook's steps copied verbatim. A step you skip stays listed with `skip: <reason>`. The skill's non-negotiables are the single list of what routes where; this file does not repeat it. Name the principles that changed a decision in one line of the reply (`principles: laziness-protocol, prove-it-works`); read the leaf `~/.claude/skills/principle-<name>/SKILL.md` before citing one. `harness-mode` outranks `frontier-mode`: frontier-mode is the discipline scaffold for weaker models and runs inside a harness-mode step, never instead of it.

Recurring mistakes get structural fixes, not more prompting: `reflect` after a session that taught something (captures the lesson as a skill edit); `correct` when the same correction lands a second time (changes the repo so the mistake class cannot recur, and keeps the rule-to-enforcer table below). A rule nothing enforces will repeat.

| Rule | Enforced by (hook / permission / agent limit, or honestly `text only`) |
|---|---|
| Playbook steps copied verbatim into the todo list | `UserPromptSubmit` hook in `claude/settings.json` injects the reminder every prompt; the `harness-mode` skill holds the steps |
| Never push to main; branch + PR | `permissions.deny` in `claude/settings.json` blocks `git push origin main` and force pushes; `code-committer` instructions and the Shipping / Opening-a-PR playbooks cover the rest (text) |
| Comments default none | `comment-reviewer` agent limited to read tools (`tools:` in its frontmatter), spawned by `no-comments` before review |
| Diff readability pass before done | text only: `simplifying-code` skill, named in Code style |
| Review separation: `simplifying-code` and `no-comments` run in a fresh context, never by the diff's author, before the first "done" reply | text only: Feature step 6; `harness-mode` non-negotiables |
| Every new constant / error / message / helper in a PRD names its model file | text only: "PRD before starting" above; Feature step 4 |
| Red → green → refactor for every behavior change | text only: `tdd` skill (mandatory in `harness-mode`); Feature step 4 and Bug fix step 3 brief it; a skip is written in the todo list per the tdd skill's skip clause |
| Chat replies in i-have-adhd shape | plugin SessionStart hook via `.i-have-adhd-always` (install.sh) |

`tdd` is not optional: every behavior change goes red (failing test at a written-down seam) → green (minimal code) → refactor (at review, via `simplifying-code`), one slice at a time; the tdd skill holds the only skip clause. `codebase-design` supplies the seam/module/interface vocabulary when the interface shape itself is in question. User-invoked workflow skills (`grill-me` / `grill-with-docs` / `to-prd` / `to-issues` / `diagnose` / `handoff` / `harness-help`) stay manual; the playbooks name them where they fit (`diagnose` in Bug fix, `handoff` in Pause safely, `to-prd` + `to-issues` in Multi-phase plan).

## Code style

- Guard clauses + early return; never `else` after a returning branch. Error handling reads as a flat ladder of independent `if` guards, no nesting.
- One condition per guard, one return each — never fold an error/missing-data check and a business-logic check into a single boolean (`a !== undefined && !a.some(...)` → `if (a === undefined) return …` then `if (!a.some(...)) return …`). Each guard gets its own why-comment; the ladder reads top-down as a list of reasons to bail.
- Names are descriptive and unabbreviated, even when long (`maximumRefundAmount`, not `maxAmt`); code reads without needing comments. Short names only for tight-scope idioms (loop vars, single-letter receivers).
- Name a boolean only when the condition carries business meaning (`isExpress`, `isProjectNotLinkedToCampaign`), or when the same condition is tested more than once. A plain nil/empty/error guard stays inline (`if messages == nil`, `if len(ids) == 0`) — a name like `hasNoMessages` next to `hasMessages` misleads more than it explains.
- Extract a function only for logic that is reused (two or more callers) or genuinely complex. Single-use blocks stay inline so a function reads top to bottom; a helper that exists only to name a block forces the reader to jump around and hides how many callers there are.
- Contract values that another system reads or that a spec fixes (issuer names, URL bases, TTLs, fixed enum strings) are named constants at the top of the file, never inline literals — the name says whose contract it is.
- Errors: check `err != nil` first, then classify inside that block (`errors.Is` / code compare); never test a specific error before the nil check. Assign, then guard on its own line — no `if x := f(); x != nil {` one-liners. Sentinel/canonical error values are package-level `var`s, never declared mid-function.
- Comments: default is none. Add one only for a business rule or external constraint the code cannot show (a client that reads `projects[0]`, a legacy quirk being mirrored, a workaround), never how a technique works (what `to_jsonb` does), what a type holds, or a restatement of the name. One line max, doc comments included. Test AAA markers stay bare (`// Arrange`) unless the arrangement itself is the surprise. Long-form explanation belongs in README/docs/Bruno, not in code.
- Before finishing, do a comment pass over the diff: delete every comment that fails the rule above. A reviewer should find fewer than one comment per function.
- Before reporting a code change done, run the `skills/simplifying-code/` pass over the diff: readability, simplification, reuse, altitude, efficiency. It applies behavior-preserving fixes only and reports what it skipped. Tool-neutral: any agent that can run git and edit files follows the same steps.
- Tests are always split with `// Arrange`, `// Act`, `// Assert` (3A) markers — every test case, every stack. Tests are written first (`tdd` skill, red → green per slice) at seams written down up front (grill, PRD, or brief); expected values are literals from an independent source, never recomputed the way the code does.
- Follow the language's official style for the rest (e.g. Go initialism casing: `ID`, `URL`, `API`).

Stack-specific style lives in skills — invoke/read the matching one before writing or reviewing code on that stack:
- Go services/BFF → `skills/go-backend-style/` (rules + EXAMPLES.md)
- React/TS frontend → `skills/react-frontend-style/` (rules + EXAMPLES.md)
- Tailwind CSS / design tokens → `skills/tailwindcss-style/`
- TanStack Query / data fetching → `skills/tanstack-query-style/`
(infra/CI-CD/lambda skills: add only after surveying real repos — no imagined rules.)

- Project-specific patterns (layering, error types, naming schemes, design tokens) live in that project's CLAUDE.md/CONVENTIONS.md — they win over the style skills; don't duplicate here.

## General practice

- **Always follow the most correct practice, even against current convention** — update docs/CONVENTIONS/rules to match; keep relearning/reskilling. Before implementing a pattern change → propose it + update docs first (docs-first).
- **Reference repos are a source of patterns, not verbatim copies** — borrow the pattern (state mgmt, hook structure, return shape, logic flow) but **rename everything to fit its role in our own repo's context**.
- Before asserting "the rest already follows best practice" → verify by actually exploring; don't trust memory.
- Grill the user via AskUserQuestion (or plain questions) one at a time before starting — the user likes assumptions challenged and decisions settled point by point. Once, up front; never mid-task on reversible work (`principle-never-block-on-the-human`), and a question whose answer can be observed by running something is a prototype, not a question.
- For rigor on hard tasks, apply `skills/frontier-mode/`: restate → verify assumptions → falsify conclusions → hostile self-review → cite or label every claim.
- Engineering principles live in `~/.claude/skills/principle-*/` (24 one-rule skills, indexed in the `harness-mode` skill). Cite the ones that changed a decision; never cite one whose leaf file you did not read this session.
- Reference material: `docs/pstack-port.md` records where the playbooks, principles and workflow skills came from, the translation glossary, and what was deliberately not ported. `docs/guide/` is the walkthrough for a first real task.

## Output style

Source: [i-have-adhd](https://github.com/ayghri/i-have-adhd). Always on, no invocation needed: Claude Code loads the plugin's full ruleset every session via the `.i-have-adhd-always` flag (`install.sh` creates it); tools without that hook get this short form from here. The orchestrator applies it to everything it says to the user; workers report to the orchestrator in their own terse form.

The reader has ADHD. Shape every response so it can be acted on:

1. Lead with the answer or next action: command, path, or snippet first.
2. Number multi-step work; one bounded action per step.
3. End with one next action doable in under two minutes.
4. Finish the current issue before raising a new one.
5. Restate progress each turn ("step 3 of 5 done").
6. Give time estimates in concrete units, never "a bit".
7. After a change, show what now works.
8. Errors: state location, cause, and fix. No drama.
9. Cap lists to 5 items.
10. No preamble, no recaps, no closers.

Exceptions: explain fully when asked to explain. Confirm before destructive actions. After three failed fixes, stop and name the doubtful assumption. If the request is ambiguous, ask one short question.
