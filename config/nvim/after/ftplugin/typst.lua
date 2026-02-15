vim.opt_local.spell = true
vim.opt_local.wrap = true


local function setup_formatters()
    vim.keymap.set("v", "<localleader>fi", function()
        return "c_<C-r>-_<Esc>"
    end, {
        expr = true,
        buffer = true,
        desc = "Wrap selected text with italic markers (*)",
    })
    vim.keymap.set("v", "<localleader>fb", function()
        return "c*<C-r>-*<Esc>"
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
        return "c#link(\"<C-r>+\")[<C-r>-]<Esc>"
    end, {
        expr = true,
        buffer = true,
        desc = "Wrap selected text with link ([]()), link valus is + register",
    })
end


setup_formatters()
