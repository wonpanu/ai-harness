---
name: simplifying-code
description: Behavior-preserving readability and simplification pass over changed code. Reviews the diff from five angles (readability, simplification, reuse, altitude, efficiency), applies the fixes that keep behavior identical, and reports what it skipped. Tool-neutral - works with any AI coding agent or model that can run git and edit files. Use after writing or changing code and before reporting it done, or when the user says "simplify this", "make this readable", "clean up the diff", "is this over-engineered", "what can we delete", or invokes /simplifying-code. Does not hunt correctness bugs.
---

# Simplifying code

Make the changed code easy for the next reader to follow, without changing what it does.

Quality only. A suspected correctness bug is out of lane: report it in one line, do not fix it here.

**Mode:** apply by default. If the user asked for a review, report, or audit, run steps 1-3, print the report, and change nothing.

Copy this checklist into your response and tick each item as you complete it:

```
Simplifying pass:
- [ ] 1. Scope: diff gathered, changed files listed
- [ ] 2. Baseline check run, result recorded
- [ ] 3. Five angles reviewed; every finding has file:line and a concrete cost
- [ ] 4. Fixes applied one at a time; check re-run, edge inputs compared, behavior identical
- [ ] 5. Report printed: fixed / skipped / out of lane
```

## 1. Scope

Get the diff under review:

1. A target was given (path, branch, commit) → review that.
2. Otherwise run `git diff @{upstream}...HEAD`. No upstream → `git diff main...HEAD`.
3. Also run `git diff HEAD`, so uncommitted work is included.
4. Run `git status --short`. Untracked files never appear in a diff: they are new code, so read each one in full.

In scope: changed lines, plus the full function around each change. Read the whole function, not only the hunk. Everything else is out of scope.

Rules come from these sources, highest priority first. When a source disagrees with this skill, the source wins.

1. The project's own conventions file (`CLAUDE.md`, `AGENTS.md`, `CONVENTIONS.md`).
2. The "Code style" section of the harness `AGENTS.md`.
3. The style skill for the stack being edited, if one exists.

## 2. Baseline

Before editing anything, find the cheapest check that exercises the changed code: a targeted test, a typecheck, a build. Run it and record the result.

- Check already fails → record which failures exist. Your fixes must not add new ones.
- No check exists → say so, and limit step 4 to fixes you can verify by reading: renaming a local, flattening a guard, deleting dead code.

## 3. Review from five angles

Take the angles one at a time, in this order. For each angle, and for each bullet under Readability, write down its findings or the word `none` before moving on. A tool with subagents may run one agent per angle in parallel, giving each the diff and this file. Without subagents, work inline. The output is the same either way.

### Readability

The reader should follow each changed function top to bottom without jumping between files. Look at:

- **Control flow:** nesting that guard clauses would flatten, `else` after a branch that returns, one condition that mixes two unrelated reasons.
- **Names:** abbreviations, generic names (`data`, `tmp`, `flag`, `handle`), names that promise something different from what the value holds.
- **Indirection:** a helper with one caller that exists only to name a block.
- **Comments:** a comment that restates the code, or a business rule with no comment explaining why.
- **Literals:** a value another system reads, written inline instead of as a named constant.

### Simplification

Flag complexity the change adds: state that can be derived from other state, copy-paste with slight variation, dead code, an abstraction with one implementation, an option for a value that never changes, a new dependency for something the standard library already does. Name the simpler form.

### Reuse

Flag new code that re-implements something the codebase already has. Search the shared and utility modules and the files next to the change. Name the existing function to call.

### Altitude

Check that each change fixes the cause at the right depth. A special case added to shared code for one caller is a symptom patch. Name the more general change to the underlying mechanism. Renaming the special case does not remove it: a flag that says who is calling is still a special case. The general form takes the value that varies as its parameter.

### Efficiency

Flag wasted work the change adds: repeated computation or I/O inside a loop, independent operations run one after another, blocking work on a startup or hot path. Name the cheaper form. Skip costs that cannot matter at the code's real scale.

### Writing a finding

Every finding uses this shape:

```
file:line | angle | what to change, and what replaces it | Cost: what the reader or the system pays today
```

A finding without a nameable cost is a preference. Drop it.

| Noise, drop it | Signal, keep it |
|---|---|
| "I would rename `flag`." | "`flag` holds whether the campaign is archived. A reader has to open `campaign.ts` to learn that. Rename to `isCampaignArchived`." |
| "This function is long." | "Lines 40-72 nest four levels to reach the success path. Three guard clauses make the success path the last line." |
| "Could use a helper here." | "Lines 18-21 re-implement `formatPhoneNumber` from `shared/format`. Two formatting rules will drift apart. Call `formatPhoneNumber`." |

If the code is already clean, report no findings. Never invent findings to fill the report.

## 4. Apply

1. Merge findings that point at the same line or the same mechanism.
2. Apply one fix.
3. Re-run the baseline check.
4. The fix touched a computation, a return value, or swapped in an existing helper → run the old code and the new code on edge inputs (zero, negative, boundary, empty) and compare the printed output, not only equality. A passing check proves only what it covers. Keep the inputs and both outputs: the report must show them.
5. Any difference in value, type, or printed format → undo that fix and record it as skipped, naming the input that differed.
6. Repeat from 2.

Skip a finding, and record why, when the fix would:

- **Change behavior.** This includes return values for empty or error input, error messages, log text, ordering, and any name another system reads.
- **Reach outside the diff,** such as renaming an exported symbol or editing callers that were not part of the change. A symbol the change itself introduced may be renamed or removed once a search shows nothing outside the diff uses it.
- **Not be verifiable** with the check you have.

Never edit a test's assertions to make a fix pass. Never reformat lines you did not otherwise change. Never add features.

## 5. Report

Use this exact structure:

```
Simplifying pass: <n> fixed, <n> skipped
Check: <command> | before: <result> | after: <result>
Findings per angle: readability <n> | simplification <n> | reuse <n> | altitude <n> | efficiency <n>

Fixed:
- file:line | angle | what changed
  compared: <edge input> | old: <printed output> | new: <printed output>

Skipped:
- file:line | angle | finding | reason skipped

Out of lane, not fixed:
- file:line | suspected correctness bug, one line
```

The counts in the first line must equal the number of entries listed under each heading.

The `compared:` line is required for every fix covered by step 4.4, and its two outputs must be character-for-character identical. A fix without that evidence belongs under `Skipped`.

In report-only mode, replace the `Fixed` heading with `Findings` and list every finding in the shape from step 3.
