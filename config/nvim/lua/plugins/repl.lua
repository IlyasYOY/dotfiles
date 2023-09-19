return {
    "Olical/conjure",
    ft = { "clojure", "fennel", "python", "lua" },
    dependencies = {
        "clojure-vim/vim-jack-in",
        "tpope/vim-dispatch",
        "radenling/vim-dispatch-neovim",
    },
    config = function(_, opts)
        require("conjure.main").main()
        require("conjure.mapping")["on-filetype"]()

        vim.keymap.set({ "v", "s" }, "<leader>c", "<cmd>ConjureEvalVisual<cr>")
        vim.keymap.set("n", "<leader>c", "<cmd>ConjureEval<cr>")
        vim.keymap.set("n", "<leader>C", "<cmd>ConjureEvalBuf<cr>")
    end,
    init = function()
        vim.g["conjure#extract#tree_sitter#enabled"] = true
    end,
}
