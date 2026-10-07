### Eval

**You own the experiment design. Plan, blind, run, synthesize.**

**Non-negotiables for blinding:**

- No `eval`, `test`, `judge`, `experiment`, `rubric`, `score`, `compare`, `benchmark`, `candidate`, or `arena` in any directory, file, or prompt the candidate sees.
- The candidate prompt looks like an organic user request. State the goal, not the meta.
- No chain-eliciting cues. Don't ask the candidate to list which skills, principles, or files they applied. Ask for design notes generally and grade chain-following from code shape, not self-report.
- Sanitize directory and slug names. Use project-shaped names a user might pick.
- Don't tell the candidate other candidates exist.
- The judge can know it's judging but sees outputs by sanitized label only, never by model name.
- Comparing two variants: one judge scores both sets in a single pass on one scale, blind to which set each came from.
- Blinding outranks AGENTS.md "PRD before starting". The frame and rubric are your PRD and stay with you and the judge. Candidates get only the organic prompt.

**Steps:**

1. **Frame.** State what variant is under test and what behavior counts as success. Write the rubric (3-6 concrete criteria) for the judge only. Hold it back from candidates.
2. **Set up sanitized environments.** Per-candidate working dir with the variant in place. Plant any context an organic task would have: a project skeleton, the skills the candidate would naturally read (under `.claude/skills/` and `CLAUDE.md` in the dir, or `.agents/skills/` and `AGENTS.md` for Codex).
3. **Author one organic prompt.** What a user would type. No leakage of what's being measured.
4. **Spawn N parallel candidates** per the **arena** skill's Phase B, one per seat on the harness panel: `deep-reasoner`, `harness-agent`, and one Codex run (`codex exec -C <sanitized dir> -s workspace-write --skip-git-repo-check -c model="gpt-6-sol" -c model_reasoning_effort="xhigh" --json "<prompt>"`, stdout saved outside the dir). Each works in its own sanitized dir. Same prompt to each. An Agent subagent sees the session's installed skills and instructions, not the ones planted in its dir. When the variant is a skill, CLAUDE.md, or AGENTS.md change, run the Claude seats as fresh headless sessions from inside their dirs instead (`claude -p --model <opus for the deep-reasoner seat, the session model for the harness-agent seat> --permission-mode acceptEdits "<prompt>"`).
5. **Spawn one blinded judge** per the **arena** skill's Phase C, on a model family other than the session's: a read-only Codex run (`-s read-only`) when the session runs on Claude, `deep-reasoner` when it runs on Codex. Judge sees outputs by sanitized label and the rubric, never a model name.
6. **Verify the chain from transcripts, not self-report.** Read each candidate's own transcript and nothing else. An Agent subagent's is `${CLAUDE_CONFIG_DIR:-~/.claude}/projects/<session cwd slug>/<session id>/subagents/agent-*.jsonl`. A headless `claude -p` run's is under `${CLAUDE_CONFIG_DIR:-~/.claude}/projects/<candidate dir slug>/`. A Codex run's is its saved `--json` output, or its rollout under `~/.codex/sessions/`. Do not glob across `projects/*/`. That crosses project boundaries and reads private chats from unrelated projects. Look at which files each candidate actually opened, and confirm it read the planted variant, not an installed copy. Grade chain-following from the files it really read plus the shape of the code, never from the candidate's own claims.
7. **Read every candidate output yourself** end to end. Compare to the judge's verdict. Disagreement means a model is biased or the rubric is ambiguous. Synthesize.

**Reply** in the harness output style (AGENTS.md "Output style", i-have-adhd). Lead with the recommendation for whether to promote the variant. Then the variant under test, the rubric, per-candidate notes, the judge's verdict, and your synthesis. Unslop and technical-writing apply to docs, not to this reply.
