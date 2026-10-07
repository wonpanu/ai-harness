### Authoring or modifying a skill

**You own the skill's voice.**

1. Use the **creating-skills** skill.
2. Validate the skill: frontmatter has `name` and `description` (plus `disable-model-invocation: true` when it should run only on request) and no keys Claude Code does not read, referenced files exist, cross-skill links resolve. In the ai-harness repo, also run `CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}" ./install.sh` so the skill links into the live Claude Code and cross-tool skill dirs, and update the AGENTS.md and PLAYBOOK.html lines that describe it (AGENTS.md "Keep the playbook in sync").
3. Test cases if structural. Skip if subjective. A change meant to shift agent behavior runs the Eval playbook (`playbooks/eval.md`) before it is promoted.
4. Run **Opening a PR** (`playbooks/opening-a-pr.md`).

When in doubt, delete. Keep only prose that changes a decision. Tell it to do the thing and skip the reason. Explain only when the rule is confusing without one. Match tone to scope. Point at structural sources (types, READMEs, config) per the **encode-lessons-in-structure** principle skill. Delegate to other skills by path. Don't restate. A workflow you keep hitting but isn't captured → propose a new skill. Skill prose is a written artifact, so the **unslop** skill applies to it.

**Reply** in the harness output style (AGENTS.md "Output style", i-have-adhd). Lead with what the skill now does. Then the key design decisions and the validation notes. Unslop and technical-writing apply to the skill text and PR body, not to this reply.
