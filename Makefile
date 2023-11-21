all: format_lua lint_lua test_lua 


config_scripts: 
	python3 -m scripts

test_lua:
	nvim --headless -c "PlenaryBustedDirectory config/nvim/lua {sequential=true}"

lint_lua:
	luacheck config/nvim/lua

format_lua:
	stylua config/nvim/lua

commit_lazy_update:
	git add ./config/nvim/lazy-lock.json && git commit -m "chore: update lazy"
