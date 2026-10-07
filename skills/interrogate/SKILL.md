---
name: interrogate
description: "Use for \"interrogate\", \"adversarial review\", \"multi-model review\", \"challenge this\", \"stress test this code\", \"find blind spots\", or \"tear this apart\". A panel on three model families (deep-reasoner, harness-agent, a Codex gpt-6-sol run) plus the senior-lead-reviewer lens challenges a change independently, and the orchestrator filters their findings into one verdict."
---

# Interrogate

Spawn a panel to adversarially review a change. Three model reviewers get the same prompt and rubric. The adversarial signal comes from model diversity, not assigned personas. A fourth reviewer, `senior-lead-reviewer`, adds the lead lens (maintainability, tech-debt, operability) that its own agent definition carries.

The deliverable is a synthesized verdict. Do NOT auto-apply changes.

## Step 1. Determine scope

Identify what to review from context:

- If the user points at specific files or a diff, use that.
- If on a feature branch, run `git diff main...HEAD` (or the right base branch) for the full changeset. Add `git diff HEAD` for uncommitted work.
- If the user's message references recent work, gather the relevant files.

Package the diff (or file contents) plus any surrounding context files the reviewers need to understand the code.

## Step 2. State the intent

Before spawning reviewers, state the intent in one clear paragraph. Derive it from:

- The task's PRD, when one exists (AGENTS.md "PRD before starting"): its goal and acceptance criteria
- The user's message
- Commit messages
- The PR description, if one exists
- The code itself

If you're unsure about the intent, ask one short question with `AskUserQuestion` before proceeding.

## Step 3. Build the reviewer prompt

Read `references/reviewer-prompt.md` and fill in the template with:

1. The stated intent
2. The diff or file contents
3. The review rubric from `references/rubric.md`
4. The code-quality lens from `references/code-quality-review.md`
5. The conventions to check: paths to the project's `CLAUDE.md` / `AGENTS.md` / `CONVENTIONS.md`, the harness `AGENTS.md` "Code style" section, and the style skill matching the diff's stack (`go-backend-style`, `react-frontend-style`, `tailwindcss-style`, `tanstack-query-style`, `typescript-best-practices`)

Write the filled prompt to the scratchpad, for example `<scratchpad>/interrogate-prompt.md`. The same file goes to all three model reviewers, so every model applies the code-quality lens and the conventions check.

## Step 4. Spawn the panel

Launch all four reviewers in one message so they run in parallel.

| Reviewer | Launch | Model | Prompt |
|---|---|---|---|
| A | `Agent`, `subagent_type: "deep-reasoner"` | Opus 5.5, xhigh | the filled reviewer prompt |
| B | `Agent`, `subagent_type: "harness-agent"` | session model, fresh context | the filled reviewer prompt |
| C | `Bash` with `run_in_background: true`, command below | Codex gpt-6-sol, xhigh | the filled reviewer prompt on stdin |
| Lead | `Agent`, `subagent_type: "senior-lead-reviewer"` | Opus 5.5, xhigh | intent, diff, and the conventions paths only |

Reviewer C:

```bash
codex exec -c model="gpt-6-sol" -c model_reasoning_effort="xhigh" \
  --sandbox read-only --ephemeral -C "<repo root>" \
  -o "<scratchpad>/interrogate-codex.md" - < "<scratchpad>/interrogate-prompt.md"
```

- `--sandbox read-only` keeps it a reviewer.
- `--ephemeral` keeps the run out of `~/.codex/sessions`, so later history mining (`reflect`, `correct`, `automate-me`) does not read it as operator work.
- Read its findings from the `-o` file when the background task completes.
- If `codex` is missing or not logged in, run the panel without Reviewer C and say so under Reviewers.

The lead reviewer does not get the rubric or the code-quality lens. Its agent definition keeps it off correctness bugs and over-engineering, which Reviewers A to C and the `simplifying-code` pass own. Tell it this is a review only.

Every reviewer is read-only. Each prompt says so: no file edits, no commits.

## Step 5. Synthesize

As results come back, build a unified picture:

1. **Parse all findings.** Convert the lead reviewer's verdict into findings: each blocking item becomes a `warning` (or `critical` when it names production breakage), each non-blocking note a `nit`. Keep the label `Lead`.
2. **Identify consensus.** Findings raised by 2+ reviewers independently are highest signal. Reviewer A and Lead both run on Opus 5.5, so their agreement is lens agreement. Agreement across model families (A or Lead with B or C) is the strongest signal.
3. **Identify lone-reviewer findings.** Still worth reading, but weight accordingly.
4. **Deduplicate.** Different reviewers describe the same issue differently. Merge these and note who raised it.
5. **Note disagreements.** If one reviewer flags something and another explicitly says the opposite, that is useful context for the verdict.

## Step 6. Lead judgment

You are the lead judge, a pragmatic senior engineer, not a neutral aggregator. Do this step yourself: the reviewers saw a slice, and you hold the conversation context they lack.

Read `references/lead-judgment.md` for the full framework.

Categorize every finding:

- **Act on.** Real issues affecting correctness, security, or maintainability given the actual goals. These would block a real PR.
- **Consider.** Legitimate points, but you're not sure they outweigh the cost of addressing them right now. Worth the user's attention.
- **Noted.** Technically valid but not actionable. Context-dependent, premature optimization, or low-impact given the current stage.
- **Dismissed.** Wrong, nitpicky, or missing context. Brief explanation why.

For each finding, include:

- Which reviewer(s) raised it
- The category
- A one-line rationale for the categorization

A finding that cites a written rule the diff breaks, where a lint, type, or check could have caught it, gets `correct candidate` in its rationale. Those feed `/correct`.

## Output format

The chat reply follows the harness output style (AGENTS.md "Output style"). Use this order:

1. **Verdict.** One line: `Act on N · Consider N · Noted N · Dismissed N`, then one sentence: ship, fix first, or rethink.
2. **Act on.** For each: description, who raised it, why it matters. More than 5 means you are not filtering hard enough.
3. **Consider.** For each: description, who raised it, the trade-off.
4. **Noted.** One line each.
5. **Dismissed.** One line each with the reason. This is the trust mechanism: the user overrides your judgment here.
6. **Agreement map.** Where reviewers agreed, where they diverged, and what that pattern says.
7. **Intent.** The Step 2 paragraph, quoted.
8. **Reviewers.** One line per reviewer: label, agent or model, number of findings, or `skipped: <reason>`.

Cap each list at 5. When Noted or Dismissed run longer, show the 5 most consequential and give the count of the rest, which the user can ask for.

End with the one next action, for example: fix Act on #1 at `file:line`, about 10 minutes.
