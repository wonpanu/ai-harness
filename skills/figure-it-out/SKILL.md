---
name: figure-it-out
description: "Design an auditable playbook when no narrower one fits: a large migration, an ambitious multi-part change, or work a human reviews after stepping away. Scales rigor to the task, runs a hypothesis loop, and logs decisions via show-me-your-work. Use for /figure-it-out, 'figure it out', a large migration, or when no harness-mode playbook applies."
---

# Figure it out

When the task matches no playbook, design one. The deliverable before any code is the workflow itself: a sequence of phases that scales rigor to the task, runs the scientific method, and leaves a decision trail a human can audit after stepping away.

## Start

Open a todo list whose first item is to read the Principles section of the **harness-mode** skill (`../harness-mode/SKILL.md`). Then add the phases below as todos.

## Phase A: Frame

Ground first, then commit. Don't start the run until you can state:

- The definition of done as a falsifiable predicate (the **principle-prove-it-works** skill).
- Scope, quantified: rough units and effort, plus the blockers grounding surfaced.
- The rigor level, biased high. One-way doors and high blast radius get more. Reversible low-stakes steps get less. Rigor is gates and artifacts, not "try harder".

Write these down as the PRD (AGENTS.md "PRD before starting"): the goal, the predicate as acceptance criteria, and the context. Every worker and judge gets it. A domain term that could mean something else in this project goes through `grill-with-docs` before the PRD.

Present the framing and tradeoffs before committing to a long run. Reversible work proceeds (the **principle-never-block-on-the-human** skill), but a multi-hour run earns one checkpoint.

## Phase B: Design the workflow

Decompose into atomic, independently-landable units. Sequence riskiest-unknown-first. Scaffold and verification come before features (the **principle-foundational-thinking** skill).

- Build the verification harness before the work, with the baseline captured from the pre-change state, so the check reads as "old value vs new value".
- For one-way-door design decisions, run the **architect** skill (it runs **arena**). Skip it for mechanical work whose shape is already concrete. A second arena over a settled design is over-engineering (the **principle-laziness-protocol** skill).
- Decide what fans out and who does it. `harness-agent` writes code that needs judgment, `fast-worker` takes mechanical, well-specified units, `deep-reasoner` takes the hardest ones. Parallelize only across seams, and give each worker its own worktree (`Agent` with `isolation: "worktree"`) or branch (the **principle-separate-before-serializing-shared-state** skill). Don't over-fan.
- Write the designed phase list down. That list is what the human reviews.

Then execute the design. Add its steps to the todo list as concrete items, after the Phase C entry and before Phase D. Run each under the Phase C loop discipline, and weave the Phase D log through them, a row as each step lands, rather than saving the whole trail for the end.

## Phase C: Run the loop

Each unit is an experiment. State the hypothesis, make the smallest change, measure against the predicate on the real artifact, keep it if it advanced, revert it if it didn't. A unit that changes behavior goes red → green through the **tdd** skill, mandatory in `harness-mode`.
Apply the **principle-sequence-verifiable-units** skill, verifying each unit before starting the next instead of batching checks at the end.

- Verify by inspecting the artifact, never a self-report. When something passes too easily, suspect the observation method before the system.
- Pair delegated work with a judge: a `deep-reasoner` that reads the diff and the check output, not the worker's summary. If a worker games the gate, reset and harden the contract. If the gate itself is wrong, fix the gate in its own change rather than routing around it.
- A verdict is VERIFIED, NOT VERIFIED, or INCONCLUSIVE. Inconclusive is not a pass. Don't hide a negative.

## Phase D: Keep the audit trail

Log the run via the **show-me-your-work** skill. figure-it-out's work is usually ambitious enough to commit the trail so the reviewer can read it in the PR. The trail plus the diff is what lets the human come back and trust the work.

## Phase E: Verify and hand back

Check the whole against the Phase A predicate on the real product, not just the harness. Before it ships, `senior-lead-reviewer` reviews the diff for maintainability, tech-debt, and operability (AGENTS.md "When to delegate"). Encode any recurring correction as a gate, a lint rule, a check, or a script (the **principle-encode-lessons-in-structure** skill). A mistake class that recurs across the repo goes to `/correct`. Ship through `code-committer` on a branch with a PR, never a push to main.

**Reply:** harness output style (AGENTS.md "Output style"). Lead with what's verified against the predicate and what isn't, then the playbook you designed, the rigor level and why, the decision-trail path, what's still open, and the PR link. End with the one next action.
