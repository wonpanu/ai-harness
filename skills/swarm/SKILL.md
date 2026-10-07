---
name: swarm
description: "Fan out N parallel workers, drain them, and return one report. Use for /swarm, 'swarm this', or parallel coverage, races, gauntlets, and exploration."
---

# Swarm

Fan out N parallel workers. They may cover separate slices, race the same brief, or mix both. The parent waits, aggregates, and returns one report.

## Start

Open a todo list with one entry per phase before launching anything.

1. Frame
2. Fan out
3. Aggregate
4. Report

## Phase A: Frame

1. State the done predicate and the artifact or report the swarm must return.
2. Choose the shape. Partition into slices, race N workers on identical briefs, or mix both. For a race or mixed shape, declare `first pass`, `rank all`, or `best-of` before spawning.
3. Set N from the user or derive it from the shape. N is total workers, not a concurrency limit.
4. Pick the worker role per slice. Roles and models are pinned in `agents/*.md`, so name the agent and never pass a model slug.
   - `fast-worker` for mechanical sweeps: coverage slices, gauntlet runs, measurements, bulk edits.
   - `Explore` for read-only code search slices that only need to locate things.
   - `harness-agent` when a slice needs judgment: exploration, a fix, a design call.

   For a model race, name each arm's role up front. The arms can be `deep-reasoner`, `harness-agent`, `fast-worker`, and one Codex run (`codex exec -c model="gpt-6-sol" -c model_reasoning_effort="xhigh"`, prompt piped on stdin from a file, launched with the Bash tool's `run_in_background: true`).
5. Give each worker its own writable output when it writes. When workers verify or measure commits, each brief names the exact SHAs. A measurement brief also names the method (sample count, what one sample is, order). The worker records both in its result.

## Phase B: Fan out

Spawn all N workers in one message, one `Agent` call each with the step 4 `subagent_type`. Give every worker that writes `isolation: "worktree"` so writers never share a checkout. Use `isolation: "remote"` only when the user asks for cloud workers and the `Agent` tool offers it.

When a worker must start from a non-default branch, name the branch in its brief and have the worker check it out in its worktree before anything else.

Every brief stands alone. Include the goal, scope, exact slice or race arm, how to verify, and what to report. Reports use `PASS`, `ISSUES`, or `BLOCKED` with evidence. A worker that can prove a defect reports `ISSUES` and lists every issue it can prove, not only the first.

If a worker drops out, proceed with N-1 and note it.

## Phase C: Aggregate

Read the terminal results. Drop a result that does not record the SHAs and method its brief names, and respawn that worker once as a fresh subagent with the same brief. After a second miss, record a gap. A gap does not count as a pass. For coverage, every required slice needs a result. For a race, apply the selection rule declared up front. Use first pass, rank all, or best-of. Do not paste raw worker dumps.

Keep a compact result table, one-line evidenced issues, and explicit gaps or dropouts.

## Phase D: Report

Return one consolidated in-chat report with the table, issue one-liners, gaps or dropouts, and the race rule when used.

**Reply:** in the harness output style (AGENTS.md Output style). Lead with the verdict (counts of `PASS` / `ISSUES` / `BLOCKED`, or the race winner), then the table, issues, and gaps. End with the next action.
