### Perf issue

**You own the measurement story. Plan, review, verify the numbers.** Tie every fix to a measurement, don't read source instead of measuring.

1. Capture a baseline trace on the real surface. Drive it with the matching control skill (`run` for CLIs, servers, and Electron apps; `claude-in-chrome` for browser UIs) and record it with the stack's profiler. Vet the baseline, and each later number, with the **benchmark-checklist** skill.
2. `how` to ground hypotheses. Don't claim a perf ceiling without running it first.
   Try the performance mantras in order, cheapest first:
   1. Don't do it. Stop work whose result nothing uses rather than cheapening it.
   2. Do it, but don't do it again.
   3. Do it less.
   4. Do it later.
   5. Do it when they're not looking.
   6. Do it concurrently.
   7. Do it cheaper.

   When an earlier mantra meets the target, stop.
3. Plan the fix from the trace. If it crosses a function boundary, `architect` first. Delegate implementation to `harness-agent` (`deep-reasoner` for the hardest changes: cross-cutting design, gnarly concurrency, subtle algorithms). Its brief is the PRD (AGENTS.md "PRD before starting"): the trace finding, the files in scope, the baseline, and the target number. A fix you can finish yourself in one turn stays with you, per AGENTS.md "When to delegate". Review the diff. Capture a post-fix trace.
   Apply the **sequence-verifiable-units** principle skill, verifying each attempt before trying the next.
4. Parse and compare the artifacts (JSON to sqlite, diff). Hand the parse of a large artifact to a `fast-worker` and keep only the reduced comparison. "Inconclusive" or wrong-surface is not a pass. Flag it.
5. Cite the measurement in the PR.
6. Run **Opening a PR** (`playbooks/opening-a-pr.md`).

For sustained improvement against a metric rather than a one-off fix, use the Hillclimb playbook (`playbooks/hillclimb.md`).

**Reply** in the harness output style (AGENTS.md "Output style", i-have-adhd). Lead with the delta. Then the baseline number, the post-fix number, and the artifact path. Unslop and technical-writing apply to the PR body and docs, not to this reply.
