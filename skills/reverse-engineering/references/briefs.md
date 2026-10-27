# Briefs

Fill every `[PLACEHOLDER]`. Prepend the House rules from SKILL.md and the path to `~/.claude/skills/reverse-engineer-anything/SKILL.md` to each brief. Return shapes are contracts; the controller parses them.

## Route (controller, step 2)

```
I want to understand how [FEATURE] works in [APP] at [ABSOLUTE PATH].
Tell me what kind of target this is (native, Electron/JS, .NET, Go, APK, WASM,
firmware) and name the one REA entry tool for it. Do not start deep analysis.
Then one paragraph: what it is built with, how big it is, where to look first
for [FEATURE]. Observations, inferences and unknowns separate, evidence cited.
```

## Recon (Reader, `effort: "medium"`, step 3)

```
Target [ABSOLUTE PATH] is open in the REA session. Map it, do not decompile.
1. binary_overview (or the JavaScript summary view).
2. search strings for URLs, error text and feature names tied to [FEATURE].
3. xrefs on every candidate address those strings lead to.
Return:
- functions.json written to [ANALYSIS DIR]/functions.json:
  [{address, name, size, xref_count}] sorted by xref_count descending
- evidence: Evidence IDs per finding
- map: one paragraph, where [FEATURE] most likely lives and why
- unknowns: what the map does not settle
```

## Annotate (Reader, default effort, step 4)

```
One cluster only: [ADDRESSES]. Structs already resolved by the controller:
[STRUCT LIST]. Reuse those names exactly; never invent a second name for a
struct the controller already gave you.
For each function in the cluster, decompile it, then:
1. Rename every variable from how it is used.
2. State its purpose in one sentence.
3. List the data structures it reads and writes.
4. Name the pattern (singleton, factory, state machine, observer, ...).
5. Rewrite it as clean idiomatic [LANGUAGE THE CALLING CONVENTIONS IMPLY].
6. Flag missing error handling, input validation or security checks.
Reason about what each value is before committing to a name. Mark what you
are unsure of. Return per function exactly:
  address, purpose, confidence (1-10), structs_used, structs_new,
  clean_source, flags, evidence_ids
Stop after this cluster.
```

## Obfuscation (Reader, `effort: "max"`, step 5)

```
Function [ADDRESS] looks obfuscated. Budget: [N] tool calls or [TOKENS]; stop
at the budget and report what you have.
1. Identify the techniques present (control-flow flattening, opaque
   predicates, dead code, string encryption, function splitting) and point
   to where each shows up in this code.
2. Resolve them: drop dead branches, evaluate opaque predicates, unflatten the
   dispatch, decrypt inline strings when the key is recoverable.
3. Show the clean function that remains.
4. Rate confidence 1-10. Below 6, name exactly which parts are uncertain and
   which neighboring context would resolve them. Do not guess silently.
Resolved neighbors for context: [NEIGHBOR SUMMARIES].
Return: address, techniques, clean_source, confidence, uncertain_parts,
budget_used, evidence_ids.
```

## Spec (Reader, default effort, step 6)

```
From the ledger at [ANALYSIS DIR]/ledger.md write a clean-room specification
to [ANALYSIS DIR]/spec.md. Describe BEHAVIOR only: every public interface,
the data model, each user-visible feature as a testable requirement, the file
formats read and written (by observed behavior and the public standard that
defines them), and the error-handling behavior.
Do NOT include addresses, offsets, decompiled variable names, assembly, or any
text copied from the original beyond plain feature names. A developer who
never saw the binary must be able to implement a compatible version from this
document alone.
Sections: Architecture, Data Model, Public API, File Formats, Test Cases.
```

## Builder (`harness-agent`, `isolation: "worktree"`, step 6)

```
Implement the application described in spec.md at the root of this worktree,
in [LANGUAGE]. spec.md is the only source. Do not search for, read, or ask
for the original program, its analysis, or its decompiled output; if you
find any, report BLOCKED and stop.
Follow the tdd skill: every row in the spec's Test Cases section becomes one
failing test before its code, one slice at a time. File formats come from the
public standards the spec names. Every asset is drawn in code, public domain
or openly licensed, with a row in ATTRIBUTION.md.
Report: files, tests passing per Test Case row, rows not yet covered.
```

## Parity (`fast-worker`, step 7)

```
Build a behavioral test harness comparing the original at [ORIGINAL PATH]
and the rebuild at [REBUILD PATH]. Generate 50 inputs: 30 normal, 10 edge
(empty, max size, unicode, special characters), 10 error (malformed, missing
fields, corrupt). Run each through both. Compare output byte-for-byte where
possible, semantically otherwise. Write [ANALYSIS DIR]/report.md with the
match rate, the divergence list, and a severity per divergence (cosmetic,
behavioral, critical). Report the match rate and the critical count.
```
