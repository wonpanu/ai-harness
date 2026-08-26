.PHONY: install update

install: ## symlink CLAUDE.md/agents/skills into ~/.claude (CLAUDE_DIR to override)
	./install.sh

update: ## pull latest and re-link (picks up new agents/skills)
	git pull --ff-only
	./install.sh
