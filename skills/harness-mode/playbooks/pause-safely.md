### Pause safely

**You own a clean stop. Leave a checkpoint a cold-start agent can resume from.** This is explicit only: a pause request, going offline, a Claude Code restart, or imminent context compaction (auto-compact near the context limit, or a `/compact` about to run). On "keep going", "going to bed, keep going", or "don't stop", do not pause.

1. Stop at a safe boundary. Finish the current atomic step or back out of it. Start nothing new, and stop any running subagents and background tasks with `TaskStop`.
2. Take no irreversible action to pause. No PR and no push unless you already had one out. Never push to trunk.
3. Make the work durable. Commit uncommitted edits as one clear `wip:` commit on the current branch through `code-committer`, so nothing is lost. If the current branch is trunk, branch first. A `wip:` commit never lands on trunk. If the tree is broken, say so in the commit body in one line.
4. Write the resume note off-context with the `handoff` skill, or by hand in its shape when the skill is unavailable. Capture intent, what you were doing, progress and what's verified, current state, next steps, key files, and gotchas. The skill saves it to the OS temp directory. For the compaction trigger, name that path in the reply so the compacted context keeps it. If a show-me-your-work trail exists, point at it instead of duplicating it.

**Reply:** where you are in the loop, what's on disk versus still in your head (paths, no diff dumps), the commits you made and whether the tree is clean, the resume note's path, and the first action on resume. This is a pause, not a final report.
