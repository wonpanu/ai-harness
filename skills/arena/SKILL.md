---
name: arena
description: "Spawn N parallel candidates at the same task, pick a base, graft the strongest parts of the losers into it. Use for /arena, 'arena this', 'throw it in the arena', or when one attempt at a non-trivial artifact would lock in the wrong shape."
---

# Arena

Fan out N parallel attempts at the same task. Read every candidate end to end. Pick the strongest as the base. Graft the best ideas from the others into it. Verify the synthesized result.

## Start

Open a todo list with one entry per phase before launching anything.

1. Frame
2. Fan out
3. Cross-judge
4. Pick
5. Graft
6. Verify

## Phase A: Frame

The N candidates will receive the same prompt, so the prompt is the contract.

1. State the artifact each candidate is producing.
2. Derive the rubric. State what success looks like for *this* task, then turn it into 3-6 concrete gradeable criteria. The rubric is the picker's tool in Phase D. Candidates only see the task.
3. Pick the runners. The default panel is three seats, one per model:
   - `deep-reasoner`, an `Agent` call.
   - `harness-agent`, an `Agent` call.
   - One Codex run on `gpt-6-sol` at `xhigh`, launched with `codex exec` (command in Phase B).

   Spawn more seats when the arena covers multiple design directions: one extra `deep-reasoner` or `harness-agent` seat per direction, with the direction named in its brief. Use the same role N times when the work is generation-bound rather than judgment-sensitive: N `harness-agent` seats, or `fast-worker` seats when the artifact is mechanical. If `codex` is missing or the run fails, fill that seat with a second `deep-reasoner` and say so in the synthesis note. Roles and models are pinned in `agents/*.md`, so never pass a model slug to an `Agent` call.
4. Assign output paths. Each candidate writes to its own location, per the **separate-before-serializing-shared-state** principle skill. Label every candidate `candidate-<n>`, never by model, and keep the seat-to-model map only in the synthesis note.
   - `Agent` seats: `isolation: "worktree"`. The candidate reports its worktree's absolute path and the files it wrote.
   - Codex seat: its own worktree, `git worktree add --detach <scratchpad>/arena-<slug>/candidate-<n>`, passed to Codex as `-C`.
   - Outside a git repo: a per-candidate directory `<scratchpad>/arena-<slug>/candidate-<n>/` for every seat, and add `--skip-git-repo-check` to the Codex run.

## Phase B: Fan out

Spawn all N seats in one message: the `Agent` calls plus one Bash call for the Codex seat. Each gets the task, the path to the shared grounding, its own output path, and instructions to produce both the artifact and a short rationale.

Write the Codex seat's prompt to a file and pipe it on stdin. Launch it with the Bash tool's `run_in_background: true`, since an `xhigh` run outlasts the foreground timeout:

```bash
codex exec -c model="gpt-6-sol" -c model_reasoning_effort="xhigh" \
  -s workspace-write -C "<candidate dir>" \
  -o "<candidate dir>/final-message.md" - < "<prompt file>"
```

Each rationale names the alternatives the candidate considered and what it rejected.

If a candidate fails to produce output, proceed with N-1 and note the dropout in the synthesis record.

## Phase C: Cross-judge

After all Phase B candidates complete, spawn one read-only judge from the panel's pool, preferring a different model family from yours: the Codex run when you run on Claude, `deep-reasoner` when you run on Codex or `codex` is unavailable.

- Codex judge: same command as Phase B with `-s read-only`, `-C` at the repo root, and `-o "<scratchpad>/arena-<slug>/judge.md"`.
- `deep-reasoner` judge: an `Agent` call whose brief says it writes nothing.

The judge sees the rubric and the candidates by path label, scores each criterion, and recommends a base with rationale. It runs in parallel with the parent's reading in Phase D, not with the candidates themselves. Don't spawn the judge while candidates are still writing.

## Phase D: Pick a base

Read every candidate end to end before picking.

Score each candidate against the rubric criterion by criterion, not on holistic feel. Compare against the cross-judge. Agreement on the base confirms the pick. Disagreement means one of you is biased or the rubric was ambiguous. Read both rationales before deciding.

Pick the base on which candidate a future maintainer can extend most easily without breaking invariants. Prefer the cleaner boundary or smaller API when two feel tied, per the **laziness-protocol** principle skill.

Record the pick and the reason in a short synthesis note alongside the base artifact, including the cross-judge's verdict.

## Phase E: Graft

Walk each losing candidate once more and identify what is worth porting into the base. The signal is usually one or two things per candidate, not most of it.

Fold each graft in by hand, per the **redesign-from-first-principles** principle skill. Don't paste mechanically. The result has to remain coherent under one mental model.

Record what was grafted, from which candidate, and what was rejected and why.

When N candidates converge on the same shape, that is a strong agreement signal. Note the convergence in the record and ship the consensus shape. No graft is needed. When N candidates wildly diverge, Phase A was under-specified. Reframe and re-run rather than averaging the divergence.

## Phase F: Verify

The synthesized artifact has to hold up under the same scrutiny as any other output, per the **prove-it-works** principle skill.

If verification surfaces a problem the arena did not catch, either Phase A was wrong (re-frame and re-run) or one candidate caught it and you missed the graft (go back to Phase E). Don't paper over.

Leave the candidate worktrees in place until the user has seen the synthesis. They hold uncommitted work, so clean them up through the `worktree-cleanup` playbook of **harness-mode**, not by hand.

## Outputs

One synthesized artifact. One short synthesis note alongside, naming the base, the grafts (with source candidate), the rejections, the dropouts if any, the seat-to-model map, and the verification result.

**Reply:** in the harness output style (AGENTS.md Output style). Lead with the synthesized artifact's path and the verification result, then the base and why, the grafts, and any dropout. End with the next action.
