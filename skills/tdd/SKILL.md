---
name: tdd
description: Test-driven development, mandatory in this harness for every behavior change. Red (failing test at an agreed seam) → green (minimal code) per slice, then refactor at review time. Use for any feature or bug fix, "red-green-refactor", or integration tests.
---

# Test-Driven Development

Adapted from Matt Pocock's `tdd` skill (MIT). In this harness the loop is not optional: the Feature and Bug fix playbooks in `harness-mode` run it for every behavior change, and `harness-mode` itself names it as a non-negotiable. Every test carries `// Arrange`, `// Act`, `// Assert` markers (AGENTS.md "Code style"). Expected values are literals from an independent source, per **principle-test-behavior-not-implementation**.

TDD is the red → green loop. This skill is the reference that makes that loop produce tests worth keeping: what a good test is, where tests go, the anti-patterns, and the rules of the loop. Every section applies on every cycle: consult them before and during the loop, not after.

When exploring the codebase, read `GLOSSARY.md` (if it exists) so test names and interface vocabulary match the project's domain language, and respect ADRs in the area you're touching.

## What a good test is

Tests verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't. A good test reads like a specification: "user can checkout with valid cart" tells you exactly what capability exists, and it survives refactors because it doesn't care about internal structure.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## Seams: where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside. Tests live at seams, never against internals.

**Test only at pre-agreed seams.** Before writing any test, write down the seams under test. They come from the up-front grill with the user, the PRD, or the delegate brief (Feature step 2 names them). Under an autonomy grant, or as a delegate who cannot reach the user, pick them yourself, write them in the todo list or decision log, and report them; never block on the question. No test is written at a seam that is not written down. You can't test everything, so agreeing the seams up front is how testing effort lands on the critical paths and complex logic instead of every edge case.

When the user is reachable and the seams are not obvious, ask once: "What's the public interface, and which seams should we test?"

## When the loop may be skipped

This is the only skip clause; every other document points here. Skip the automated red for a slice only when no local test path exists at any seam (the behavior is observable only through a manual UI flow with no harness, or only in a third-party system). Then the recorded runtime repro or the control-skill run is the red, and the todo list carries `skip: tdd, <reason>`. A slow or inconvenient test is not a reason. The Prototype playbook is outside this rule: a throwaway sketch has no tests by design.

When the shape of that interface is itself in question (how deep the module is, where the seam belongs, what the interface should expose), read the `codebase-design` skill (this harness ships it next to this one) for the vocabulary. It is the shared source of the module, interface, depth, seam, adapter, leverage and locality terms, and it is a reference to consult, not a session to run.

## Anti-patterns

- **Implementation-coupled**: mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). The tell: the test breaks when you refactor but behavior hasn't changed.
- **Tautological**: the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way, a constant asserted equal to itself), so it passes by construction and can never disagree with the code. Expected values must come from an independent source of truth: a known-good literal, a worked example, the spec.
- **Horizontal slicing**: writing all tests first, then all implementation. Bulk tests verify _imagined_ behavior: you test the _shape_ of things rather than user-facing behavior, the tests go insensitive to real changes, and you commit to test structure before understanding the implementation. Work in **vertical slices** instead: one test → one implementation → repeat, each test a **tracer bullet** that responds to what the last cycle taught you.

## Rules of the loop

- **Red before green.** Write the failing test first, then only enough code to pass it. Don't anticipate future tests or add speculative features.
- **One slice at a time.** One seam, one test, one minimal implementation per cycle.
- **Refactoring is not part of the loop.** It belongs to the review stage, not the red → green implementation cycle. In this harness that stage is the `simplifying-code` pass over the diff, then `/code-review`, both with the green suite as the safety net. Red → green → refactor is the full cadence; a slice is done only when all three happened.
