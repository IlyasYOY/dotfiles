all: format_lua lint_lua test_lua 

test_lua:
	nvim --headless -c "PlenaryBustedDirectory config/nvim/lua {sequential=true}"

lint_lua:
	luacheck config/nvim/lua

format_lua:
	stylua config/nvim/lua


