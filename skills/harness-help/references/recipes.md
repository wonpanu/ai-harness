# Prompts worth copying

Swap in the real paths, skills, and done checks. Informal wording works.

## Understand

- `/harness-mode read <thread>. restate the underlying issue in your own words, in plain english.`
- `/harness-mode investigate why <symptom>. give me what we know, what data you used, and your best hypotheses. don't change any code yet.`
- `use /how to understand <subsystem>. then use /why to find out why it broke recently.`
- `/recall my work on <topic> from last week, then read <issue>.`
- `/teach me why you implemented it this way and not <other way>. what did you trade off?`
- `/harness-mode take over this branch. read the decision log, find what's done, and continue. don't redo finished work.`

## Build

- Bug: `/harness-mode <symptom>. repro first, then fix and verify.`
- Bug in an app: `/harness-mode repro this with /verify-<app>. if it repros on main, fix it and show me a video as proof.`
- Bug with a cheap test: `/harness-mode repro <bug> first. pin it with a failing test at the seam, then fix and rerun.`
- Feature: `/harness-mode add <behavior>. <current output> stays byte-identical. verify both.`
- Refactor: `/harness-mode move <code> into one module, zero behavior change. record the current output first and prove it's unchanged after.`
- Perf: `/harness-mode <operation> takes <time> on <fixture>. trace it, fix the measured cause, show me before and after.`

## Design and plan

- `/harness-mode prototype a few options for <feature>. take screenshots or videos for me to compare.`
- `/harness-mode we need <feature>. /architect it first, and answer open questions with prototypes. let me review before proceeding.`
- `/harness-mode write a tutorial for how i would use <new package> first. then /teach me why it beats the current one.`
- `ask /arena for a second opinion on this thread and our approach.`
- `/harness-mode turn this design into a plan. small verifiable PRs, each with its own verification steps.`
- `/harness-mode plan the migration of <library> to <target>. small verifiable PRs. the result must match the original exactly, bugs included.`

## Review and ship

- `/interrogate the whole branch, but skeptically. don't change anything yet. no nitpicks unless it's a real bug or regression.` Read the dismissals too.
- `/swarm check every package under <dir> against its check script. one worker per package. one report.`
- `/harness-mode open the pr. small ordered commits, evidence in the description.`
- `/harness-mode babysit this pr. get it green.` For status only: `/harness-mode check on pr <number>. anything outstanding?`
- `/harness-mode land the stack.`

## Away and back

- `/harness-mode im going to bed. <goal> in a fresh worktree off <base>. done means <checks>. keep a decision log. don't ask me before committing. /loop until done. if you're truly stuck after a few hours, stop and write up why.`
- `/show-me-your-work catch me up on what you did last night.` Read its Attention section first.
- `/harness-mode full autopilot on this queue. each item is independent.`
- `/harness-mode autopilot these changes but stack them, don't ship. i'll land the stack.`
- `/bro` restates the last reply in plain words.

## Make it stick

- `/reflect capture what we learned so the next run doesn't repeat it.` Approve only edits that change a future decision.
- `/correct agents keep adding comments that restate the code. make it impossible, and show me the check failing on a past commit.`
- `/correct mine the last 60 days of my corrections in this repo and fix the top classes.`
- `/automate-me refresh my mode skill from the last month of work.`
