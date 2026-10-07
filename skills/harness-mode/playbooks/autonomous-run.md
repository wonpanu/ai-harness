### Autonomous run

**You own the exit condition. Define done, then drive to it without stopping.**

1. State the exit condition as a checkable predicate before the first iteration (tests green, repro fixed, all N PRs merged, pixel-diff zero). The predicate is the PRD's acceptance criteria (AGENTS.md "PRD before starting"), and every delegate gets the same PRD.
2. Pick the wake mechanism. An event to watch (CI, a merge, a ref advancing) gets a watcher that wakes you on the event: the `Monitor` tool, or a background Bash command that exits on it (`gh pr checks <pr> --watch`), with a long Claude Code `/loop` heartbeat as fallback. No event gets a fixed-interval `/loop` heartbeat sized to when the result is worth re-checking.
3. Each iteration makes the smallest change the evidence justifies, verifies it against the predicate, commits if it advanced, discards changes that didn't help. Belt-and-suspenders that "might help" gets reverted, not left to ride.
   Sequence the work via the **sequence-verifiable-units** principle skill, verifying each unit before the next instead of batching checks at the end.
4. Mid-run discoveries are yours. Address broken skills, related bugs, flaky verifiers, review noise, tooling failures, orphaned follow-ups, and fixable drift yourself via harness-mode. Put out-of-band fixes in their own PR. Do not park reversible work for the human or use `AskUserQuestion`. Surface only irreversible actions, genuine product or preference calls no experiment can settle, or a real dead end. Keep the predicate as the main drive, and return to it after each side fix.
5. Checkpoint every iteration via the **show-me-your-work** skill, a row for what changed and whether the predicate moved.
6. Stop when the predicate is met. A plateau is not a stop, so keep going and pivot your approach to push past it. Surface a genuine dead end rather than spinning, and never relax the predicate to declare victory.

**Reply** in the harness output style (AGENTS.md "Output style", i-have-adhd). Lead with the final predicate state against the exit condition. Then iterations run, what landed, what was discarded, and the decision-trail path. Unslop and technical-writing apply to the PR body and docs, not to this reply.
