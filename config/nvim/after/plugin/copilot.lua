require("copilot").setup {
    filetypes = {
        ["*"] = false,
        markdown = true,
        lua = true,
        gitcommit = true,
        python = true,
        go = true,
        java = true,
        make = true,
        sh = true,
    },
    panel = { enabled = true, },
    suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
            accept = "<M-l>",
            accept_word = "<M-w>",
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<M-h>",
        },
    },
}

vim.keymap.set(
    "n",
    "<leader>ae",
    "<cmd>Copilot enable<CR>",
    { desc = "Enable Copilot" }
)
vim.keymap.set(
    "n",
    "<leader>ad",
    "<cmd>Copilot disable<CR>",
    { desc = "Disable Copilot" }
)
vim.keymap.set(
    "n",
    "<leader>ar",
    "<cmd>Copilot restart<CR>",
    { desc = "Reload Copilot" }
)
vim.keymap.set(
    "n",
    "<leader>ap",
    "<cmd>Copilot panel<CR>",
    { desc = "Toggle Copilot Panel" }
)
