vim.opt_local.spell = true
vim.opt_local.wrap = true
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.shiftwidth = 2
vim.bo.formatprg = "mdsf format --stdin --log-level=off"

local function show_toc_side()
    local current_win = vim.api.nvim_get_current_win()

    require("vim.treesitter._headings").show_toc()

    if
        vim.api.nvim_get_current_win() == current_win
        or vim.bo.filetype ~= "qf"
    then
        return
    end

    vim.cmd.wincmd "H"
    vim.cmd "vertical resize 42"
end

local function setup_formatters()
    vim.keymap.set("v", "<localleader>fi", function()
        return "c*<C-r>-*<Esc>"
    end, {
        expr = true,
        buffer = true,
        desc = "Wrap selected text with italic markers (*)",
    })
    vim.keymap.set("v", "<localleader>fb", function()
        return "c**<C-r>-**<Esc>"
    end, {
        expr = true,
        buffer = true,
        desc = "Wrap selected text with bold markers (**)",
    })
    vim.keymap.set("v", "<localleader>fc", function()
        return "c`<C-r>-`<Esc>"
    end, {
        expr = true,
        buffer = true,
        desc = "Wrap selected text with code markers (`)",
    })
    vim.keymap.set("v", "<localleader>fl", function()
        return "c[<C-r>-](<C-r>+)<Esc>"
    end, {
        expr = true,
        buffer = true,
        desc = "Wrap selected text with link ([]()), link valus is + register",
    })
end

vim.keymap.set("n", "gO", show_toc_side, {
    buffer = true,
    silent = true,
    desc = "Show an Outline of the current buffer in a side pane",
})

setup_formatters()
