---
name: reverse-engineering
description: Harness workflow for reverse engineering a shipped binary, Electron bundle, APK, firmware or app with no source, and for a clean-room rebuild of it. The session model only controls; deep-reasoner (Opus 5.5) does every read, annotation and de-obfuscation at a per-phase effort; a fresh harness-agent implements from the behavior spec alone; fast-worker runs the parity harness. Use for "reverse engineer X", "how does app X do Y" when no source exists, "rebuild this app", "decompile and explain", or "clean-room reimplementation". Tool-level REA calls and target routing live in reverse-engineer-anything; this skill decides who does each step, at what effort, and what proves the result.
---

# Reverse engineering

Reverse engineering is understanding a thing well enough to build your own. The deliverable is one of three: an explanation with evidence, a diff between versions, or a clean-room rebuild with a parity report. Name which one in step 1.

The controller never reads pseudocode. Every function the work touches goes through a `deep-reasoner` worker, so the session model can be any tier, including a cheap one. Nothing in the loop depends on the controller's model.

REA tool usage (routing, Evidence IDs, session state, providers) is the `reverse-engineer-anything` skill. Read its "Route the target first" section before step 2 and send its path to every worker.

## Roles

| Role | Agent | Effort | Owns |
|---|---|---|---|
| Controller | you, the session model | as is | authority, PRD, routing, dispatch, the finding ledger, synthesis, `close_binary` |
| Reader | `deep-reasoner` (Opus 5.5) | `medium` to map and navigate, default (`xhigh`) to annotate, `max` for obfuscated or pointer-heavy code | every decompile read, rename, struct, confidence rating |
| Builder | `harness-agent`, fresh context, `isolation: "worktree"` | as is | implements from the spec file only; never sees the analysis |
| Mechanic | `fast-worker` | as is | parity harness, running the input set, `report.md` |

Pass `effort` on the `Agent` call exactly as the table says. Effort is the single biggest quality knob in this workflow. One worker per function cluster; a worker never analyzes a second cluster.

## House rules

Every brief carries these verbatim.

- Only analyze targets the user owns or is authorized to examine. The controller states the basis once in the PRD; a worker that cannot see it reports `BLOCKED`.
- Every claim is tagged observation (saw it), inference (deduced it) or unknown. Cite the Evidence ID, address, bytes, pseudocode or call site. No unsourced claims.
- Smallest overview first. Expand only on a concrete gap. Never dump the whole target.
- Reuse the open REA session. Check `binary_session {}` before any `open_binary`; open the same path only when no target is active, and say so in the report. Only the controller closes.
- Static facts and runtime facts stay separate. Never imply execution from a static read.
- Rebuild from behavior and public specs, never from copied code, names or assets.
- Every recovered behavior is an obligation: it needs a passing test before "done".

## Steps

Copy these into the todo list verbatim. A skipped step stays listed with `skip: <reason>`.

1. **Authority and PRD.** Record the authorization basis, the target path, the feature in question, and which of the three deliverables is wanted. Put the analysis directory in the scratchpad, never in the repo the Builder will work in.
2. **Route the target.** One controller call per `reverse-engineer-anything` "Route the target first". Electron or an extracted JavaScript tree goes to `analyze_javascript_application` and never to a disassembler. Native goes through `open_binary`. Stop before any deep analysis.
3. **Recon map.** One Reader at `medium`: `binary_overview` (or the JavaScript summary), strings worth following (URLs, error text, feature names), then `xrefs` on the candidates. It returns `functions.json` (address, name, size, xref_count) sorted by xref count, plus the Evidence IDs. The function with the most callers is the architecture; the two-caller helper waits.
4. **Annotate hot functions.** Cluster `functions.json` by call-graph proximity, order clusters by xref count, dispatch one Reader per cluster with the annotate brief and the structs resolved so far. Above roughly twenty functions, run the dispatch through the `swarm` skill with these workers. Merge each return into the ledger; a second name for a struct the ledger already holds is a defect, send it back. Confidence below 6 queues one second pass with the resolved neighbors as context.
5. **Break the obfuscation worth breaking.** Only for a cluster flagged obfuscated: one Reader at `max` with the obfuscation brief and a per-function budget stated in the brief. A failed attempt costs about twice a successful one, so the worker stops at the budget instead of trying harder. Multi-layer obfuscation scored zero in Elastic's Tigress benchmark: bank the neighbors' context, park the function as unknown, move on.
6. **Clean-room spec, then build.** Skip when the deliverable is an explanation or a diff. A Reader writes `spec.md` from the ledger with the spec brief: behavior only, no addresses, no decompiled names, no copied text. The controller copies `spec.md` alone into the Builder's worktree and spawns the Builder with the builder brief. The Builder follows the `tdd` skill: each row in the spec's Test Cases section is one red test before its code. Original assets only, every file format from its public standard, attribution file for anything licensed.
7. **Parity report.** The Mechanic builds the harness from the parity brief: 50 inputs (30 normal, 10 edge, 10 error) through the original and the rebuild, byte-for-byte where possible, semantic otherwise, `report.md` with match rate and a severity per divergence (cosmetic, behavioral, critical). "I think it matches" is not evidence; the match rate is.
8. **Finish.** Reconcile the step 1 checklist against the ledger: answered, partial, unresolved. `export_evidence_bundle` to the analysis directory, then `close_binary`. For a rebuild, offer the MCP wrap: each command named and described, one-line install.

Briefs for steps 2 to 7 are in [references/briefs.md](references/briefs.md). Fill the placeholders; do not paraphrase the return shapes, the controller parses them.

## Mistakes that waste a weekend

- Opening a disassembler on an Electron app when the JavaScript is right there.
- Dumping everything before reading anything. The summary comes first and the bill stays small.
- Reading functions in file order instead of by xref count.
- Grinding multi-layer obfuscation past the budget.
- Letting the Builder see the analysis. Spec in one context, implementation in another, or the clean room is gone.
- Shipping without a parity report.

**Reply** in the harness output style (AGENTS.md "Output style"). Lead with the deliverable: the explanation with its evidence, the version diff, or the parity match rate with the report path. Then the ledger's unresolved unknowns, capped at five, and the analysis directory path.
