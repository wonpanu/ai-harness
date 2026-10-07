---
name: correct
description: "Find the mistakes agents keep repeating in this repo and make each one impossible. Mines git history, PR review comments (gh), and Claude Code / Codex transcripts for repeated operator corrections, then fixes each class at the highest level that works: architecture, then types, then a lint whose error names the fix, then a test, and docs last. Proves each check fails on a real past mistake and keeps the rule-to-enforcer table in AGENTS.md or the project's CLAUDE.md. Use for /correct, or when the operator corrects the same thing a second time."
---

# Correct

The operator keeps correcting agents in this repo for the same mistakes. Change the repo so the next agent can't make them.

Assume every contributor is an agent that sees only the files it opened, copies the nearest example, and takes the shortest path that compiles. Design the repo so a change that looks right from one file is right for the whole repo.

## Find the mistake classes

First, read the evidence. Then group the mistakes into classes. A class counts once it has happened twice.

1. **Agent instruction files.** The project's `CLAUDE.md` / `AGENTS.md` / `CONVENTIONS.md`, the harness `AGENTS.md`, and the rule table (last section). A rule that is written down and still broken is the strongest signal: the prose is not holding.
2. **Operator corrections in transcripts.** The script ships with `reflect`. From this skill's directory:

   ```bash
   T=../reflect/scripts/transcripts.sh
   $T dirs <project-path>                 # this project's Claude Code transcript dirs
   $T corrections 60 <dir>...             # prompts that read as corrections, oldest first
   $T codex 60 <project-path>             # operator prompts from Codex sessions here
   $T view <dir>/<session-id>.jsonl       # the turns around a hit
   ```

   `corrections` matches English and Thai correction phrasing (no, don't, again, ไม่ใช่, เคยบอก, อย่า, ...) and every prompt sent right after an interrupt. Hits are candidates. Read the turn before each one to see what the agent did. Mine only this project's dirs. Sessions launched from a parent directory such as `~` sit in that parent's dir with unrelated chats: read them only after the operator says yes.
3. **Git history.** Reverts, and fix-ups that land within days of the change they fix, are mistakes that shipped.

   ```bash
   git log --since=90.days --oneline -i -E --grep='revert|fix|oops|again|lint|review'
   git log --since=90.days --oneline --diff-filter=D --name-only
   ```

4. **PR review comments.** Inline comments that repeat across PRs are classes.

   ```bash
   gh api 'repos/{owner}/{repo}/pulls/comments?sort=created&direction=desc&per_page=100' \
     --jq '.[] | [.created_at[0:10], (.pull_request_url | split("/") | last), .path, (.body | gsub("\\s+"; " ") | .[0:200])] | @tsv'
   gh pr list --state merged --limit 30 --json number,reviews \
     --jq '.[] | .number as $number | .reviews[] | select(.body != "") | "#\($number) \(.author.login): \(.body | gsub("\\s+"; " ") | .[0:200])"'
   ```

5. **Comments that explain workarounds.** `git grep -n -E 'HACK|WORKAROUND|FIXME|XXX|do not use'`.

With more than a handful of sources, mining is bulk reading. Fan out one `fast-worker` per source (transcripts, git, PR comments) in one message. Each returns candidate classes with evidence pointers: session id and timestamp, commit SHA, or PR number with `path:line`. Keep the grouping and the level choice in the main thread.

## Fix each class at the highest level that works

1. **Eliminate it with architecture.** Give each piece of state one owner and each task one supported way. Hide internals so the wrong import fails. Replace hand-synced lists with one source of truth. Delete old ways and dead code an agent would copy.
2. **Enforce it with types so the bad state can't be written.** If bad code still compiles, add a lint or CI check whose error names the file, type, or function to use instead. Go: `golangci-lint` linters such as `forbidigo` take a custom message. TypeScript: ESLint `no-restricted-syntax` and `no-restricted-imports` take a `message` that names the replacement. If the pattern is already common, fail only when a change adds more (`golangci-lint run --new-from-rev=origin/main`, or a baseline file).
3. **Test the behavior.** Fix or delete any test that would still pass if every function it calls returned nothing.
4. **Write docs or agent rules last, only for judgment calls.** Nothing fails when an agent skips them.

Some classes are agent behavior, not code: committing without being asked, pushing to main, skipping the `simplifying-code` pass. Same ladder, different rungs:

1. A permission rule or hook that blocks it (`settings.json`, via the `update-config` skill).
2. A role that owns it (an `agents/*.md` definition, as `code-committer` owns commits).
3. A `harness-mode` trigger or playbook step that names it at the moment it applies.
4. AGENTS.md prose, last.

## Fix and prove

Then fix the most frequent classes now, one commit per class through `code-committer`, shipped on a branch with a PR. Never push to main.

Prove each new check fails on a real past mistake: replay the reverted commit, the PR snippet a reviewer flagged, or the code from the transcript the operator corrected, and show the failing output. Run the same command locally and in CI. Exceptions go on the offending line with a reason, an expiry date, and a human's approval.

## Keep the rule table

Last, keep a table in the agent instruction file that pairs each rule with what enforces it, columns `Rule | Enforced by`:

- In this harness, that file is `AGENTS.md` (`CLAUDE.md` is a symlink to it). The table sits in its harness-mode routing section, after the paragraph on recurring mistakes. An AGENTS.md edit also updates `PLAYBOOK.html` in the same change.
- For a project, it is the project's `CLAUDE.md`. Add the table if it is missing.

When the operator corrects you, fix the mistake and add the rule. If the rule was already there and its `Enforced by` cell names only prose, that's a repeat, so fix it at the highest level in the same change. Drop a rule once its mistake can't happen.

**Reply:** harness output style (AGENTS.md "Output style"). Lead with the classes fixed. For each: the evidence (two pointers at most), the level you picked, why a higher level didn't work, and the proof (the check failing on the past mistake). Cap at 5 classes and give the count of the rest. End with the one next action.
