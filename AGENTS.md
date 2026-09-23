# Agent guidance

Single source of truth for every AI coding agent (Claude Code, Codex, Cursor, Gemini CLI, Zed, …).
`CLAUDE.md` is a symlink to this file. Claude Code maps the roles below to the predefined
subagents in `agents/`; a tool without subagents applies each role's discipline itself, inline.

**Keep the playbook in sync:** `PLAYBOOK.html` is the visual version of this file (interactive
flow diagram + rules). Whenever this file, the agent definitions, or the skills it describes
change, update PLAYBOOK.html in the same turn. It is also published as the "AI Orchestrator
Playbook" artifact — offer to republish it so the hosted copy stays current.

## Orchestration workflow

Model per role lives in each agent's frontmatter (`agents/*.md`, symlinked into `~/.claude/agents`) — the models named below are the current values. Codex CLI gets the same roles from `codex/config.toml` (symlinked to `~/.codex/config.toml`) on this tier map:

| Tier | Claude | OpenAI (Codex) |
|---|---|---|
| Orchestrator / peer | Fable 5.1 · high | gpt-6-astra · high |
| deep-reasoner · senior-lead-reviewer | Opus 5.5 · xhigh | gpt-6-sol · xhigh |
| fast-worker | Sonnet 5 · medium | gpt-6-luna · medium |
| web-searcher · code-committer | Haiku 4.5 | gpt-6-luna · low |

You (the session model) are the orchestrator. Plan, decompose, synthesize.
Reasoning-heavy phases → deep-reasoner role (Opus 5.5, effort xhigh)
Mechanical work → fast-worker role (Sonnet 5, effort medium)
Internet research (docs, versions, error messages, current facts) → web-searcher role (Haiku 4.5)
Committing finished work on instruction → code-committer role (Haiku 4.5) — never modifies code, pushes only when told
Other agent (a fresh instance of the current session model — same model as you, separate context) is a cracked engineer on par with deep-reasoner, from a different perspective. Treat as a peer, not a reviewer.
High-stakes decisions: task the peer on the same problem in parallel, synthesize the best of both, without showing either the other's answer. Keep your own context lean.

**When to delegate (vs. do it yourself):** default is doing it yourself in one turn — delegate only when one of these clearly applies:
- Explore/search across many files or directories where reading exceeds answering → `Explore` or `fast-worker`
- Reasoning-heavy work (architecture, complex debugging, algorithms, trade-offs) needing deep thought across many tool calls → `deep-reasoner`
- Mechanical work, well-specified but bulky/repetitive (multi-file renames, boilerplate, test scaffolds) → `fast-worker`
- Internet research → `web-searcher`; committing finished work → `code-committer`
- High-stakes decision where being wrong is expensive → peer + deep-reasoner in parallel, then synthesize
- Reviewing work about to merge/ship (plan, diff, design) from a senior-lead lens — maintainability, tech-debt, operability → `senior-lead-reviewer` (Opus 5.5, effort xhigh, fresh context; distinct lens from peer=correctness and ponytail=over-engineering)
Work you can finish yourself in one turn (1-2 file edits, answering questions, small edits): **do NOT delegate** — cold-context agent overhead isn't worth it (ponytail).

**PRD before starting:** whenever the orchestrator takes on incoming requirements, write a brief PRD first — goal, acceptance criteria, and necessary context (constraints, relevant files/systems, decisions already made) — and pass it to every delegated worker and reviewer so they work/review on the same context. Scale to the task: a few lines for small work, full form only for large work. If any domain term in the requirement is ambiguous or may mean something different in this project's context, run `grill-with-docs` (or align terminology against the project's domain model/docs by hand) BEFORE drafting the PRD — so the PRD's words carry the project's meaning, not a guessed one.

Workflow skills (grill / ponytail-review / to-prd / to-issues / tdd) are invoked manually by the user — no mandatory pipeline.

## Code style

- Guard clauses + early return; never `else` after a returning branch. Error handling reads as a flat ladder of independent `if` guards, no nesting.
- One condition per guard, one return each — never fold an error/missing-data check and a business-logic check into a single boolean (`a !== undefined && !a.some(...)` → `if (a === undefined) return …` then `if (!a.some(...)) return …`). Each guard gets its own why-comment; the ladder reads top-down as a list of reasons to bail.
- Names are descriptive and unabbreviated, even when long (`maximumRefundAmount`, not `maxAmt`); code reads without needing comments. Short names only for tight-scope idioms (loop vars, single-letter receivers).
- Name a boolean only when the condition carries business meaning (`isExpress`, `isProjectNotLinkedToCampaign`), or when the same condition is tested more than once. A plain nil/empty/error guard stays inline (`if messages == nil`, `if len(ids) == 0`) — a name like `hasNoMessages` next to `hasMessages` misleads more than it explains.
- Extract a function only for logic that is reused (two or more callers) or genuinely complex. Single-use blocks stay inline so a function reads top to bottom; a helper that exists only to name a block forces the reader to jump around and hides how many callers there are.
- Contract values that another system reads or that a spec fixes (issuer names, URL bases, TTLs, fixed enum strings) are named constants at the top of the file, never inline literals — the name says whose contract it is.
- Errors: check `err != nil` first, then classify inside that block (`errors.Is` / code compare); never test a specific error before the nil check. Assign, then guard on its own line — no `if x := f(); x != nil {` one-liners. Sentinel/canonical error values are package-level `var`s, never declared mid-function.
- Comments only when necessary, and never longer than one line (doc comments included): explain why (rationale, workaround, constraint), never what the next line does. Long-form explanation belongs in README/docs, not in code.
- Tests are always split with `// Arrange`, `// Act`, `// Assert` (3A) markers — every test case, every stack.
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
- Grill the user via AskUserQuestion (or plain questions) one at a time before starting — the user likes assumptions challenged and decisions settled point by point.
- For rigor on hard tasks, apply `skills/frontier-mode/`: restate → verify assumptions → falsify conclusions → hostile self-review → cite or label every claim.

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
