### Investigation

**You own the answer. Plan, route, write.**

Investigation requests are read-only. They produce a cited explanation or a recommendation, not a code change.

1. Route through the **how** skill. For motivation questions, also route through the **why** skill.
2. Throughput checkpoint stays one line: `throughput checkpoint: n/a, read-only investigation`.
3. Produce the `how`-shaped output (Overview / Key Concepts / How It Works / Where Things Live / Gotchas), or a recommendation with a tradeoffs table if the request is a decision between alternatives.
4. Write the reply in the harness output style (AGENTS.md "Output style", i-have-adhd), answer first. The style's "explain fully when asked" exception covers the step 3 sections. If the answer lands in a doc instead of chat, apply the **unslop** and **technical-writing** skills to the doc.

No PR, no Babysit, no `architect` unless the investigation precedes a code change. If it does, hand back to the user and re-route to Bug fix or Feature.

**Reply** in the harness output style. Lead with the answer or the recommendation, then the investigation output. For "are we sure?" answers, include your real judgment with reasons. Push back if the premise is wrong (the mode's Autonomy section).
