LUA_CHECK_PATHS := .
SHELL_FRAGMENT_FILES := sh/aliases.sh sh/exports.sh
SHELL_SCRIPT_FILES := $(filter-out $(SHELL_FRAGMENT_FILES),$(wildcard sh/*.sh)) \
	$(wildcard sh/setup/*.sh)

.PHONY: install update check check-lua check-shell format-lua
install:
	@./sh/setup/install.sh

update:
	@./sh/setup/update.sh

check: check-lua check-shell

check-lua:
	@luacheck $(LUA_CHECK_PATHS)
	@stylua --check $(LUA_CHECK_PATHS)

check-shell:
	@bin_shell_files=""; \
	for file in bin/*; do \
		[ -f "$$file" ] || continue; \
		IFS= read -r first_line < "$$file" || continue; \
		case "$$first_line" in \
			'#!/usr/bin/env bash'|'#!/usr/bin/env sh'|'#!/bin/bash'|'#!/bin/sh') \
				bin_shell_files="$$bin_shell_files $$file" ;; \
		esac; \
	done; \
	if [ -n "$(strip $(SHELL_SCRIPT_FILES))$$bin_shell_files" ]; then \
		shellcheck $(SHELL_SCRIPT_FILES) $$bin_shell_files; \
	fi
	@shellcheck -s bash $(SHELL_FRAGMENT_FILES)

format-lua:
	@stylua $(LUA_CHECK_PATHS)
