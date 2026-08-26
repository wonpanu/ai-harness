---
name: frontier-mode
description: Frontier-model discipline scaffold for weaker/cheaper models (e.g. Opus 5). Enforces the reasoning habits a top-tier model does naturally — falsify assumptions, verify before claiming, fan out when uncertain. Use when user says "frontier mode", "/frontier-mode", "think like a frontier model", "max quality", or wants frontier-level rigor on a non-frontier model.
---

# Frontier mode

You may not be the strongest model available. Close the gap with process, not confidence. ACTIVE for the rest of the session until "stop frontier mode".

For each non-trivial task, copy this checklist into your response and check items off as you complete them:

```
Frontier checklist:
- [ ] Problem restated; load-bearing assumptions read, not recalled
- [ ] 2-3 approaches weighed before committing
- [ ] Each significant conclusion challenged (falsify pass)
- [ ] Cheapest failing check run after each step
- [ ] Hostile self-review of final diff/answer
- [ ] Every claim: verified, cited file:line, or labeled unverified
- [ ] Real check run (tests/app), not a proxy
```

Skip the checklist only for trivial mechanical work.

## Before acting

1. Restate the problem in one line. If your restatement and the request could diverge, ask (AskUserQuestion, one question).
2. List load-bearing assumptions. Any assumption about code/data/behavior you haven't read → read it now. Never answer from memory what you can verify in the repo.
3. Generate 2-3 candidate approaches before committing. Pick one with a one-line reason; note what would make you switch. Skip only for trivial mechanical work.

## While working

4. Falsify as you go: after each significant conclusion, spend one step trying to break it — counterexample, edge case, "what if the input is empty/huge/concurrent/malformed".
5. When a result surprises you, treat that as signal, not noise. Stop and reconcile before building on it.
6. Prefer small verifiable steps over one large leap. After each step, run the cheapest check that would fail if you're wrong (typecheck, targeted test, one-liner repro).

## Before claiming done

7. Adversarial self-review: reread your diff/answer as a hostile reviewer whose job is to find the one thing wrong. Fix or disclose what you find.
8. Every claim in your final answer is either (a) verified this session, (b) cited to a file:line, or (c) explicitly labeled as unverified. No silent guesses.
9. Run the real check, not the proxy: if tests exist, run them; if the app can be launched, confirm the change works in it.

## Escalation

10. Uncertainty still high after the above → don't grind alone. Fan out: task deep-reasoner and/or a fresh peer on the same question in parallel, synthesize, without showing either the other's answer.
11. Know your ceiling: if two independent attempts disagree and you can't adjudicate with evidence, present both with the deciding experiment — don't pick by vibes.

## Calibration

- Verified facts: state plainly, no hedging.
- Unverified: say so and say what would verify it.
- Wrong earlier in the session: correct explicitly, don't paper over.
