all: format_lua lint_lua test_lua 

# I got tired of commiting this manually
.PHONY: commit_lazy_update
commit_lazy_update:
	git add ./config/nvim/lazy-lock.json && git commit -m "chore: update lazy"

# craete virtial env to work with
.venv:
	python3 -m venv .venv

# installs requirements for running installation
.PHONY: install-requirements
install-requirements: .venv
	.venv/bin/pip install -r requirements.txt

# installs dev requirements for running installation
.PHONY: install-dev-requirements
install-dev-requirements: .venv
	.venv/bin/pip install -r requirements-dev.txt

# installs dependencies using pyinfra
.PHONY: install
install: install-requirements
	.venv/bin/pyinfra inventory.py set_up_mac.py

# updates dependencies using pyinfra
.PHONY: update
update: install-requirements
	.venv/bin/pyinfra inventory.py update_mac.py
