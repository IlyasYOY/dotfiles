if vim.g.copilot_disable then
    return
end

require("copilot").setup {
    filetypes = {
        ["*"] = false,
        markdown = true,
        gitcommit = true,
        make = true,
        sh = true,
    },
    panel = { enabled = true },
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
    "<leader>aa",
    "<cmd>Copilot toggle<CR>",
    { desc = "Toggle Copilot" }
)
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
    "<leader>as",
    "<cmd>Copilot status<CR>",
    { desc = "Status Copilot" }
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
