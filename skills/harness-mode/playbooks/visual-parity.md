### Visual parity

**You own pixel-exact equivalence. The baseline is the spec. You do not touch it.** Equivalence is verified by image diff, not by eye.

1. Establish the baseline first, before any migration: a visual regression harness that screenshots the current component across its states, plus the target when matching two implementations. No baseline, no parity claim. A blocking prerequisite, not a follow-up.
2. Anti-shortcut clauses, stated and held: no harness modifications, no baseline tampering, no component restructuring to make a diff pass. If the baseline looks wrong, stop and ask (`AskUserQuestion`), don't edit it.
3. Migrate one component at a time. Parallelize across worktrees, one `harness-agent` owner per component, each spawned with Agent `isolation: "worktree"` (the **separate-before-serializing-shared-state** principle skill). Each owner's brief is the PRD (AGENTS.md "PRD before starting"): the component, its baseline, the harness command, and the step 2 anti-shortcut clauses verbatim. Shared primitives migrate first as a blocking phase.
4. Verify each component against its baseline via image diff on the matching surface via the control skill (`claude-in-chrome` for browser UIs, the `run` skill for Electron). A nonzero diff is a fail. Investigate the pixel delta. `/loop` per component until the diff is zero.
5. Run **Opening a PR** (`playbooks/opening-a-pr.md`) per component or per safe batch.

**Reply** in the harness output style (AGENTS.md "Output style", i-have-adhd). Lead with what's left. Then the components migrated with the diff result for each (a table past five), and the baseline harness location. Unslop and technical-writing apply to the PR body and docs, not to this reply.
