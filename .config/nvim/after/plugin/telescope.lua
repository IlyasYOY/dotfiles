local telescope = require "telescope"
local builtin = require "telescope.builtin"

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
    builtin.live_grep()
end)

vim.keymap.set("n", "<leader>ft", function()
    builtin.builtin()
end)

vim.keymap.set("n", "<leader>fm", function()
    builtin.man_pages()
end)

vim.keymap.set("n", "<leader>fh", function()
    builtin.help_tags()
end)

vim.keymap.set("n", "<leader>fb", function()
    builtin.buffers()
end)

vim.keymap.set("n", "<leader>fc", function()
    builtin.current_buffer_fuzzy_find()
end)
