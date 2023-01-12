local telescope = require "telescope"
local builtin = require "telescope.builtin"
local themes = require "telescope.themes"

telescope.setup {
    defaults = { file_ignore_patterns = { "node_modules", ".git" } },
    pickers = {
        find_files = {
            hidden = true,
        },
        live_grep = {
            additional_args = function(opts)
                return { "--hidden", "-g", "!.git" }
            end,
        },
    },
}

vim.keymap.set("n", "<leader>ff", function()
    builtin.find_files()
end)

vim.keymap.set("n", "<leader>fg", function()
    builtin.live_grep(themes.get_dropdown {
        layout_config = {
            width = function(_, max_columns, _)
                return math.min(max_columns, 100)
            end,
        },
    })
end)

vim.keymap.set("n", "<leader>ft", function()
    builtin.builtin(themes.get_ivy())
end)

vim.keymap.set("n", "<leader>fs", function()
    builtin.lsp_document_symbols(themes.get_ivy())
end)

vim.keymap.set("n", "<leader>fS", function()
    builtin.lsp_dynamic_workspace_symbols(themes.get_ivy())
end)

vim.keymap.set("n", "<leader>fm", function()
    builtin.man_pages()
end)

vim.keymap.set("n", "<leader>fh", function()
    builtin.help_tags(themes.get_ivy())
end)

vim.keymap.set("n", "<leader>fb", function()
    builtin.buffers(themes.get_ivy())
end)

vim.keymap.set("n", "<leader>fc", function()
    builtin.commands(themes.get_ivy())
end)
