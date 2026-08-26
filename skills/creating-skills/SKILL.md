---
name: creating-skills
description: Authoring guide for Claude Agent Skills following Anthropic's latest best practices. Picks the right skill pattern for the use case (freedom level, progressive disclosure, checklists, feedback loops, scripts) and validates against the official checklist. Use when creating a new skill, restructuring an existing skill, or when the user asks how a skill should be organized.
---

# Creating skills

Before finalizing any skill, fetch the live checklist — it supersedes anything here:
https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices

## Core rules

- Frontmatter `name`: ≤64 chars, lowercase/numbers/hyphens, gerund form preferred (`processing-pdfs`), never "anthropic"/"claude", never vague (`helper`, `utils`).
- Frontmatter `description`: ≤1024 chars, third person only, states WHAT it does + WHEN to use it with concrete trigger terms. This field alone decides triggering — spend effort here.
- Body: assume Claude is smart; cut anything it already knows. Under 500 lines. One consistent term per concept. No time-sensitive info (use an "old patterns" collapsible if history matters).

## Pick the pattern by use case

**Degrees of freedom** — match specificity to fragility:
- Many valid approaches, context decides → high freedom: heuristics in prose.
- Preferred pattern, some variation OK → medium: template/pseudocode with parameters.
- Fragile, must be exact (migrations, destructive ops) → low: "run exactly this script", no flags added.

**Size/structure** — grow only when needed:
- Fits in one SKILL.md → keep it one file.
- Approaching 500 lines → split: SKILL.md as overview linking reference files ONE level deep (never nested chains). Reference files >100 lines get a table of contents.
- Multiple domains (e.g. finance/sales/product) → one reference file per domain so only the relevant one loads.
- Basic vs advanced use → conditional links: inline the common case, "See X.md" for the rare one.

**Reliability mechanisms** — add only what the task's risk justifies:
- Multi-step process where skipping a step hurts → copyable checklist the agent ticks in its response.
- Quality-critical output → feedback loop: draft → validate (script or reference doc) → fix → repeat; proceed only when clean.
- Output format matters → template pattern (strict: "ALWAYS use this exact structure"; flexible: "sensible default, adapt").
- Style/judgment output → 2-3 input→output example pairs beat description.
- Batch/destructive/high-stakes ops → plan-validate-execute: emit a plan file, validate it with a script, then apply.

**Scripts** (when the skill bundles code):
- Scripts solve, never defer errors to Claude; verbose error messages that name valid alternatives.
- No voodoo constants — justify every value in a comment.
- Say explicitly: "Run x.py" (execute) vs "See x.py" (read as reference). Forward slashes always.
- List required packages; don't assume installs.
- MCP tools: fully qualified `Server:tool_name`.

## Process

1. Do the task once WITHOUT a skill; note what context you repeatedly supplied — that's the skill's content. Build 3 evaluation scenarios from real failures BEFORE writing docs.
2. Write the minimal skill that passes them.
3. Test with a fresh instance (and every model tier it will run on — weaker models need more guidance, stronger ones need less).
4. Observe navigation: files never read → delete or signal better; file always read → merge into SKILL.md. Rules the agent skips → promote/strengthen ("MUST"), don't just repeat.
5. Fetch the URL above and walk its final checklist before shipping.
