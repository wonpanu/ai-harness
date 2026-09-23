# pi coding agent — parked evaluation (2026-09-23)

Status: **not adopted yet.** Research only; revisit when choosing between (a) trial alongside Claude Code, (b) add `pi/` config to this harness, (c) full switch.

## Install (macOS)
```sh
brew install pi-coding-agent          # or: npm i -g @earendil-works/pi-coding-agent
pi                                    # TUI → /login anthropic, /login openai
```
Config: `~/.pi/agent/settings.json` (global) · `~/.pi/agent/AGENTS.md` (global rules — this repo's AGENTS.md can be symlinked there) · `.pi/AGENTS.md` per project · auth in `~/.pi/agent/auth.json`.

## What it gives vs Claude Code
| | pi | Claude Code |
|---|---|---|
| Providers | 15+ (Anthropic, OpenAI, Google, Bedrock…), switch mid-session | Claude only |
| Subagents / roles | not built-in — packages `pi-roles`, `pi-subagents` | built-in `agents/*.md` |
| AGENTS.md | global + project | CLAUDE.md |
| MCP / hooks / plugins | not built-in, extensions only | built-in |
| System prompt | ~1k tokens, 4 tools | ~14k tokens, 10+ tools |
| Safety | YOLO by default (no permission prompts, no sandbox) | permission modes |

## Risks
1. Claude **subscription OAuth** in third-party agents was blocked by Anthropic in Apr 2026 and re-allowed in May 2026; issue earendil-works/pi#3372 still open — may be cut again. ChatGPT Plus OAuth works.
2. Lost on switch unless ported as pi extensions: ponytail + i-have-adhd plugins (hook-based), MCP servers, Artifacts, built-in subagents.
3. Orca supports pi (onorca.dev/docs/agents/supported), so the manager layer survives a switch.

## Sources
- https://pi.dev/docs/latest/quickstart · https://pi.dev/docs/latest/providers
- https://github.com/earendil-works/pi (docs/settings.md)
- https://pi.dev/packages/pi-roles · https://github.com/tintinweb/pi-subagents
- https://composio.dev/content/pi-agent-vs-claude-code · https://github.com/disler/pi-vs-claude-code
- https://www.onorca.dev/docs/agents/supported
