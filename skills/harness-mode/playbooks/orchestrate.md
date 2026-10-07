### Orchestrate

**You own the program, never the code. Author briefs, drain the queue, keep the frontier green, decide.** For a whole project handed to one standing coordinator session: multi-day, many stacked PRs, dozens to hundreds of subagents, the human checking in twice a day instead of every five minutes. One task taken to a predicate is Autonomous run. One ambitious run needing a bespoke workflow is figure-it-out. Route here when the work outlives any single agent. Work one agent could finish inside the session's budget is not a program.

Ceremony must scale with the program. On cheap near-identical units, collapse it as each section directs.

Three rules carry the rest.

- Completions are queue events, not interrupts.
- Every spawn and every resume carries the standing orders verbatim.
- The brief is the product. A vague brief fails quietly, because a worker cannot ask you a question.

#### Roles and placement

- **Coordinator (this session).** Local. Frames, authors briefs, drains the inbox, owns the human report, makes judgment calls. It never authors or edits code. Conflicted merges, restacks, and code changes are always tasks. Mechanically landing a verified unit (fast-forward or clean cherry-pick of a worker's commit onto its stack branch, then pushing that branch) is bookkeeping the coordinator may do itself on repos where local git is cheap. Trunk moves only through `gh pr merge`. Queueing finished work behind an idle stacker is how a deadline harvests nothing. The loop is agentic end to end. Agents are spawned through the `Agent` tool, stopped with `TaskStop`, and messaged with `SendMessage` only under harness-mode's reuse rule. State reads and writes go to the plain files in the store at drain points (**Store layout**). The store never spawns, waits, or wakes anything.
- **Sub-coordinator.** A `harness-agent`, one per track, and only when the program exceeds what one coordinator's drains can manage. A track the coordinator can drain itself needs no middle layer. Each nested layer re-pays a full orientation preamble, and a blocking sub-coordinator hides its children while the parent idles. Owns its track's units and boards, authors its workers' briefs, spawns its own workers and verifiers through the `Agent` tool (keep nesting to depth 3). Rolls up aggregates at wave boundaries. Never forwards raw child reports. Cap in-flight children at what one drain can process, roughly ten, as a rolling window. Never as blocking batches, which cost the slowest child of every batch.
- **Worker / verifier.** Workers are `harness-agent`, the hardest units go to `deep-reasoner`, and mechanical sweeps go to `fast-worker`. Spawn each with `isolation: "remote"` where the account has it, otherwise `isolation: "worktree"`. A worker stays local only when the task needs this machine: runtime verification with the **run** or **claude-in-chrome** skill, reading local transcripts under `$CLAUDE_CONFIG_DIR/projects/`, simulators and local IDE state, or auth that exists only here. Remote agents cannot read the local store, so their briefs inline what they need or point at repo paths. Prefer fewer, broader workers. One writer per worktree or branch (principle-separate-before-serializing-shared-state). Run a unit's verifier on a different model from its worker: `deep-reasoner` against a `harness-agent` worker, plus a Codex lane (`codex exec -c model="gpt-6-sol" -c model_reasoning_effort="xhigh" "<prompt>"`) for high-blast-radius units.

Depth stays at coordinator, track, worker. Author the track decomposition per project (build, landing, and verification are common cuts, not a required shape). Hard-coded swarm trees were tried and parked as too rigid.

#### Store layout

Create `.audit/orchestrate/<project-slug>/` in the coordinator's checkout and keep it out of git (add `.audit/` to `.git/info/exclude`). Every file has exactly one writer, the coordinator, unless a line below names another. Owners publish facts, readers aggregate at read time. The files are plain TSV, JSON, and markdown, readable with `column -s$'\t' -t` and `jq`.

- `preferences.md` is the standing-orders register: numbered lines, one constraint each (model policy, stack shape and count, verification bar, forbidden paths, escalation policy). Paste it verbatim into every spawn and every resume. Directives decay across resumes, and each dropped one costs a human turn. When you catch yourself restating an instruction, append the line before you act (principle-encode-lessons-in-structure).
- `overview.md` is the durable PR and issue DB. Append. Never rewrite wholesale per event.
- `units.tsv` has one row per unit with columns `id track state branch pr head_sha brief`. States are `queued`, `running`, `needs-verify`, `verified`, `landed`, `failed`, `abandoned`, and `zombie`. Update rows in place.
- `frontier.json` is the computed merge frontier, per **Stack safety**.
- `ledger.tsv` is the verification ledger, per **Verification**.
- `inbox/` holds completion pointers, one file each. `gates.md` parks human gates (question, options, default on no answer).
- `decisions.tsv` is the trail via the **show-me-your-work** skill, written with its `scripts/log.sh`.
- `status.md` is derived from `units.tsv` and `ledger.tsv` at each drain, never hand-maintained. Regenerate it from the tables instead of narrating events into it.

Bookkeeping, with `store` set to the store path:

- **Init.** `mkdir -p "$store/inbox/drained"`, then write the header rows: `printf 'id\ttrack\tstate\tbranch\tpr\thead_sha\tbrief\n' > "$store/units.tsv"` and `printf 'ts\tpr\thead_sha\tverdict\tverifier\tevidence\n' > "$store/ledger.tsv"`.
- **Inbox push.** `printf '%s\t%s\t%s\t%s\n' <agent> <unit> <status> <report-path> > "$store/inbox/$(date -u +%Y%m%dT%H%M%SZ)-<agent>.tsv"`
- **Inbox drain.** List `"$store"/inbox/*.tsv` once when the drain starts, process exactly those files, and move each into `inbox/drained/` after its rows are written.
- **Unit set.** `awk -F'\t' -v OFS='\t' -v id=<id> -v col=<column-number> -v val=<value> '$1 == id { $col = val } 1' "$store/units.tsv" > "$store/units.tsv.tmp" && mv "$store/units.tsv.tmp" "$store/units.tsv"`. A new unit is one appended row.
- **Ledger record.** `printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(date -u +%FT%TZ)" <pr> <head-sha> <verdict> <verifier> <evidence> >> "$store/ledger.tsv"`
- **Ledger check.** Read the current head with `gh pr view <pr> --json headRefOid --jq .headRefOid`, then `awk -F'\t' -v pr=<pr> -v sha=<head-sha> '$2 == pr && $3 == sha' "$store/ledger.tsv" | tail -1`. No row means unverified at that head.
- **Status.** `tail -n +2 "$store/units.tsv" | cut -f3 | sort | uniq -c` for counts per state, plus the open entries in `gates.md`.

If a drain keeps retyping one of these, promote it to a script in the repo (principle-build-the-lever).

#### The brief

Your prompts to agents are your only product, and a sloppy brief compounds into slop across the whole tree. Every spawn carries all of it. A field you cannot fill is a unit you have not scoped yet.

```
GOAL         one sentence, the outcome, executable by a stranger with no chat access
SCOPE        paths this unit may write; paths it may not; its exclusive worktree or branch
CONTEXT      pointers to files and PRs; upstream reports pasted in full when this unit
             depends on them, because workers cannot see siblings
ACCEPTANCE   checkable criteria, one per line
VERIFY       exact commands or the run / claude-in-chrome path, plus known gotchas
TIMEBOX      rough cap on runtime; on expiry, return partial findings and stop rather than run on
FORBIDDEN    no gt, no rebase, no force-push, no push to trunk, no fixes outside scope,
             plus unit-specific bans
REPORT       status, branch, head SHA, PRs, verdict, what you actually ran, deviations,
             suggested follow-ups
STANDING     <preferences.md pasted verbatim>
```

Size the brief to the unit. A one-command unit gets the template collapsed to a paragraph that still names goal, scope, the verify command, and the report shape. A 4KB scaffold around a two-line edit costs more to write and obey than the edit. Local spawns may reference the standing-orders file by store path. Verbatim paste is for remote spawns and every resume.

A sub-coordinator brief adds its track boundary and unit list, its spawn budget with the remote default and the local exception list, the drain protocol, and the rollup format (per child: name, status, PR, head SHA, verdict, one line, plus track status and frontier delta).

A dependency is a context relay, not just ordering. Undeclared upstream context makes the worker guess. Missing fields are a refuse-to-spawn condition. Audit one sampled worker brief per sub-coordinator per wave, concurrently with the wave it samples, never as a gate in front of it. A failing brief stops that track and fixes the sub-coordinator's instructions, not just the worker, because brief quality decays late in a run. Never resume-chain a brief. Respawn fresh with consolidated scope.

#### Steps

1. **Frame.** State the done predicate as something countable ("all 126 units merged, each ledger-verified `unit-test-verified` or better"). Quantify scope: units, rough effort, expected stacks, and the wall-clock budget. If one agent could finish inside that budget, stop here and run Autonomous run instead. Collapsing must not depend on another document being present. It means do the work directly in this session, plain workers where they help, verification inline, landing as you go, and none of the store, register, or pilot machinery below. Schedule landing against the budget. By roughly 70% of it, stop spawning and land what is verified. Name the tracks per project. A contested decomposition or one-way door goes through the **arena** skill before the pilot. Present the framing once. Reversible prep proceeds without waiting.
2. **Install the runtime.** Create the store per **Store layout**. Open the trail via the **show-me-your-work** skill, write the standing orders before any spawn, and seed `frontier.json` from existing PRs per **Stack safety**.
3. **Pilot.** Push one unit through the whole path: brief, worker, verification, stack entry, ledger row, merge. The pilot exists to falsify the brief template, the verify recipe, and the unit size while that costs one agent instead of fifty. Fix the contract from pilot evidence before any fan-out. Scale the pilot to the unit. On programs of near-identical cheap units, the first unit is the pilot, run as a normal unit with its verify command inline, and fan-out starts the moment it lands. The dedicated pilot pipeline (separate verifier agent, audit gate) is for expensive or novel unit shapes, not for clone-units where a serialized pilot has nothing to falsify.
4. **Scale.** Spawn a rolling window of workers up to the in-flight cap, refilling as children finish. Blocking batches pay the slowest child of every batch. Spawn track sub-coordinators only past the one-drain threshold in Roles. Recompute ready work after each drain. Relay upstream reports into downstream briefs. Keep sibling communication upward only. The sampled brief audit runs alongside the wave it samples and stops the next refill on failure, not the current one.
5. **Drain.** Run the queue discipline below at every drain point.
6. **Land.** Landing is continuous, never a terminal phase. Integration starts with the first verified unit and runs alongside the remaining waves. On heavy repos the stacker is a standing role from wave one, integrating as units verify. On repos where local git is cheap, the coordinator lands verified units itself per Roles. Keep the frontier green before upper-stack work. Stack safety governs. Advance `frontier.json` only on merge or reported new head SHAs. Every landing on trunk is a `gh pr merge` per `playbooks/shipping.md`.
7. **Close.** Drain the final inbox, reconcile every spawned agent to a terminal row (done, abandoned, zombie-reconciled), confirm the predicate on the real artifact, confirm every landed PR has a verdict for its current head SHA, audit the trail per show-me-your-work including its cross-model review, encode recurring corrections into `preferences.md` or the brief template. Leave the store intact. It is the postmortem.

#### Queue and drain

- On a completion notification, write an inbox pointer (**Inbox push**) and return to what you were doing. Never deep-review inline. A completion that needs review becomes a verifier unit. Never review a diff inside a drain.
- Drain in batches at four points: the end of a critical section, a track rollup, a frontier wake (a background `gh pr checks --watch` or a `Monitor` poll per `playbooks/babysit.md`, with a long `/loop` heartbeat as the fallback), and before a human report. Begin each batch with **Inbox drain**. Arrivals during a drain wait for the next one.
- Critical sections you finish first: authoring a brief, a stack operation, a conflict decision, writing a gate, updating ledger or frontier.
- Each drain classifies every pointer (landed, needs-verify, failed, zombie, noise), writes the resulting rows (**Unit set**, **Ledger record**), regenerates `status.md` (**Status**), then spawns the next wave in one message.
- Account for every spawned child at its track's rollup: arrived, respawned, or its scope explicitly absorbed. Silently redoing a missing child's work hides both the wasted spend and the coverage gap its result existed to close.
- A drain turn ends with three lines: counts against the states, what changed, gates open. Detail lives in `status.md`. The full reply contract applies at checkpoints and close.

#### Stack safety

- The frontier is a computed object, never narrative. Recompute `frontier.json` after every merge and stack mutation: ordered PR list, branch names, head SHAs, a generation number, the lowest unmerged PR. Build it from GitHub by walking base refs up from trunk (`gh pr list --state open --json number,headRefName,baseRefName,headRefOid`), then compare it against the stacker's recorded bottom-to-top list. GitHub base refs drift mid-restack, so a mismatch is a stop for the stacker to reconcile, never a guess. Bump the generation on every change.
- Exactly one stacker per stack may change its topology (rebase, retarget, `--force-with-lease` push), serialized within its stack. Record the holder in the standing orders. Restacks run in the stacker's own worktree, remote where the account allows. A large local restack can take the machine down.
- Workers never rebase and never change topology. Babysitters follow `playbooks/babysit.md`, one per stack, scoped to one immutable frontier generation. They report conflicts to the stacker rather than restacking.
- PR closes and retargets go through the stacker only. Closing a base PR orphans every chain above it. Merges and stack surgery are units with briefs like any other.
- One retro watcher follows merged PRs for reverts, post-merge CI breaks, and orphaned follow-ups.

#### Verification

Scale verification to the unit. When VERIFY is a single cheap command, the worker runs it and reports the output, and the coordinator spot-checks receipts. A dedicated verifier agent (a different model from the worker, per Roles) is for units whose verification is expensive, judgment-laden, or high-blast-radius. A verifier agent whose entire product would be rerunning one command is ceremony, not verification.

Write ledger rows with **Ledger record**. Check the current PR and head SHA with **Ledger check**. `ledger.tsv` has one row per verdict, keyed by PR number plus head SHA, and the verdict is one of `live-ui-verified`, `unit-test-verified`, `type-check-only`, `verifier-blocked`, or `verifier-failed`. CI green is an input to a verdict, not a verdict. Behavioral work needs better than `type-check-only`. `verifier-blocked` is not a pass. Respawn when the environment heals. `verifier-failed` gets a fix unit, not a re-verify. A worker may self-report. A verifier overrides it on the same key. A new head SHA voids the row, so re-verify after restack. The ledger answers "was this verified", not memory and not the transcript.

A unit is not done until its output is externalized the moment it lands, never batched to the end of the run. A worker pushes its branch, a verifier's ledger row gets written, receipts land in the store. Work that exists only in one agent's worktree or remote sandbox when that agent dies was never done.

#### Liveness and failure

- Never resume an agent to check on it. A resume restarts an idle agent. Probe read-only: the ledger, `units.tsv`, `gh`, pushed branches (`git ls-remote`), and a remote agent's session status. Transcript mtime is not liveness.
- A silent death gets a synthetic postmortem row in the inbox (unit, failure mode, last evidence, options). Replan on evidence as it arrives. Never wait for full quiescence.
- Retry by mode: cap-hit or out of memory, respawn with smaller scope. Network-drop, retry as-is. Tool-error, retry on a different model. Unknown, retry once. Two retries, then abandon the unit and replan around it.
- A zombie that returns hours late reconciles against the current frontier and ledger before anything is accepted. Salvage unique findings through a fresh unit, never a blind merge.
- When continued spawning would produce garbage tree-wide (bad upstream output, broken acceptance, dead infra), write a stop line at the top of the standing orders, let in-flight work finish, fix the cause, clear it.
- Bound your own infra retries the same way you bound a child's. After a few consecutive tool aborts, stop retrying. Write a terminal handoff into the store (what is done, where it lives, the exact command to resume) and end the run.
- After a Claude Code restart (crash, closed terminal, `/clear`): local subagents are dead, remote agents and pushed branches are not. Reopen the coordinator with `claude --resume <session-id>` or pick it up per `playbooks/session-pickup.md`. Re-read the standing orders and `units.tsv`, recompute the frontier, reattach remote work by PR and branch rather than agent id, respawn one sub-coordinator per track from its stored brief plus current state, drain, resume. The coordinator is the store's only writer, so there is no lock to clear.

#### Escalation

Reaches the human, batched into the status page rather than per item: irreversible actions (force-push to shared branches, deploys, deletions, closing someone else's PR), genuine product or preference calls no experiment settles, a standing order that contradicts observed reality, a program-level dead end that survived a replan. Park each as a `gates.md` entry before asking, and route work around it.

Never reaches the human: frontier nudges, restack mechanics, retries, CI flake triage, review-thread triage, format fixes, scope the brief already forbids (refuse and continue), and "should I keep going". When in doubt, act and log.

Mid-run discoveries fix only what blocks the frontier. Everything else parks in follow-ups. At this fan-out a small scope leak multiplies into PRs nobody asked for.

**Reply:** at checkpoints and close: the predicate and the count against it from `units.tsv` and `ledger.tsv`, tracks and what each landed, the frontier (PR list plus SHAs), verdicts summary, what was abandoned and why, gates awaiting the human (the only asks), the store path, and the trail path. Numbers from the tables, not narrative. Include PR links.
