.PHONY: commit_lazy_update
commit_lazy_update:
	git add ./config/nvim/lazy-lock.json && git commit -m "chore: update lazy"

.PHONY: install
install:
	@./sh/setup/install.sh

.PHONY: update
update:
	@./sh/setup/update.sh
