### Opening a PR

Invoked at the end of every other playbook.

**Branch and PR, never trunk.** Nothing reaches trunk except through a merged PR. GitHub CLI (`gh`) is the forge tool for create, edit, view, watch, and merge. Never require Graphite (`gt`).

**Worktree.** Work from a git worktree off trunk. Subagents inherit it. Multiple `Agent` calls on the same branch each get their own worktree (`isolation: "worktree"`), or `git fetch && git reset --hard origin/<branch>` between them. Dirty branch with unrelated work: patch out, fresh worktree, apply. Snarled worktree: reset from trunk, redo minimally.

**Commits.** Nothing is committed, pushed, or opened as a PR until the user says so in the current turn; a plan or scope answer that mentions PRs is not that go. The `commit-guard` hook in `claude/hooks/` blocks `git commit`, `git push` and `gh pr` in every repo except `~/ai-harness` until the user's message asks for it. Once asked, commit through `code-committer`. Name the files and the reason. It reads the diff, matches the repo's message convention, and reports the hash. It never amends, rebases, or force-pushes, so shape history yourself on the unpushed branch. Rebase into small, ordered commits before opening PRs. Each commit is a future PR: landable, ordered to tell the story. Fold a fix into a just-made commit when it belongs there. New commit when separable.

**PRs.** Run the **simplifying-code** pass over the diff before commit. Run `/no-comments` before review. Write every PR title, PR description, and commit body with `/technical-writing`, then apply `/unslop`. Apply every technical-writing layer except Diátaxis. Use one word for each action, keep articles, and avoid `-ing` when a plain verb works.

**Titles.** Use Conventional Commits in the form `type(scope): subject`. Use `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, or `perf` as the type. Use the changed area, such as `harness-mode` or `install`, as the scope. Keep the subject short and imperative. Name a real symbol when one carries the change. For example, `fix(harness-mode): retarget opening-a-pr babysit trigger`. Do not add a trailing period.

**Descriptions.** The PR body is a briefing, not the lab notebook. A reviewer who has the diff should learn why the change exists, what it leaves out, what it could break, and how you proved it works, in under a minute. Write short, simple sentences with few identifiers. Do not write walls of text. The squash commit body is the PR body. If the body would make the squash commit longer than about 40 lines, cut the body.

Put each section under a `##` heading, not a bold lead-in, so the sections stand apart. Use these sections in order. Drop a section when it has nothing to say.

- `## Why` gives the problem and the approach in one to three short sentences. Do not list SHAs or rebase genealogy. Do not add a "based on main" preamble.
- `## What changed` has one to three short bullets. Name a real symbol or path only when it carries the change. Name both sides of a rename or retarget.
- `## Scope` always names what the PR covers and what it deliberately leaves out, for example a related follow-up or a known gap. Use one to three short items. Do not list symbols or paths, and do not write a file-by-file essay.
- `## Tradeoffs` names only rejected alternatives that a reviewer would otherwise ask about. Skip this section when there was no real choice.
- `## Blast Radius` gives one or two sentences on who or what the change touches and why that is safe or risky. If trunk is red, state the cost of leaving it red.
- `## Verification` has one to three bullets. Each bullet names a real run path and its outcome. For a performance change, report one primary number with its unit in `before → after` form. Link the arena or swarm directory for the remaining evidence. Do not include sample-size methodology, swarm recitals, or metric tables.

After these sections, attach videos or screenshots when they prove a claim. Do not paste full SHAs, swarm or arena lane recitals, lever-correction essays, file-by-file checklists, or "CLEAN" verdicts. Put these details in a linked artifact. A commit body does not restate its subject.

**Creating the PR.** Write the title and the body file first. Then hand `code-committer` the branch name (`<type>/<short-slug>`), the title, the body file, and the base. It branches if you are on trunk, pushes the branch, and runs `gh pr create --title "<title>" --body-file <body.md> --base <base>`. Update an existing PR's body with `gh pr edit <number> --body-file <body.md>`.

**Size and stacks.** Prefer five narrow PRs to one large PR. A stack is a base-branch chain. The root PR targets trunk. Each child branch rebases onto its parent's exact tip and its PR targets the parent branch. Create a child with `gh pr create --base <parent-branch>`, and retarget an existing child with `gh pr edit <pr> --base <parent-branch>`. Branch from trunk only for independent work. Rebase on trunk before substantial stack work.

**Readiness.** Open every PR ready, never as a draft. Omit `--draft`. If a PR still opens as a draft, run `gh pr ready <number>`. Run `gh pr view <number>` before you refer to PR status.

**Babysit.** Opening a PR does not start a babysit. Post the URL and keep building. Finish the phase or stack first. Run a separate babysit pass only when the user asks for one after the whole stack exists. A babysit for each new PR stalls the build and spends checks on commits that later waves restart. Push back when feedback drifts from intent.

A subagent that opens a PR runs `interrogate`, the **simplifying-code** pass, and `/no-comments`, and posts the URL. Then it returns to the parent without babysitting, unless it is an Autopilot-full or Autopilot-stack owner. That owner's brief assigns the babysit loop and is the ask `playbooks/babysit.md` waits for. The owner starts the loop after its code-ready report and reports merge-ready or STACK-READY as its playbook says. The rules here and in `playbooks/babysit.md` that hold babysitting until a whole stack is built do not apply to that owner.
