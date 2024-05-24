return {
    {
        "David-Kunz/gen.nvim",
        config = function()
            local gen = require "gen"
            gen.setup {
                model = "llama3",
                display_mode = "spit",
                show_prompt = true,
                show_model = true,
                no_auto_close = true,
            }

            gen.prompts.Create_Commit_Message_For_Code =
                { prompt = "Create commit message for this code:\n$text" }
            gen.prompts.Create_Commit_Message_For_Diff =
                { prompt = "Create commit message for this diff:\n$text" }

            vim.keymap.set({ "n", "v" }, "<<leader><leader>ll", ":Gen<CR>")
            vim.keymap.set({ "n" }, "<<leader><leader>lL", function()
                gen.select_model()
            end)
            vim.keymap.set({ "n", "v" }, "<<leader><leader>lc", function()
                gen.exec(gen.prompts.Chat)
            end)
            vim.keymap.set({ "n", "v" }, "<<leader><leader>ls", function()
                gen.exec(gen.prompts.Summarize)
            end)
            vim.keymap.set({ "n", "v" }, "<<leader><leader>lg", function()
                gen.exec(gen.prompts.Create_Commit_Message_For_Code)
            end)
            vim.keymap.set({ "n", "v" }, "<<leader><leader>la", function()
                gen.exec(gen.prompts.Ask)
            end)
            vim.keymap.set({ "n", "v" }, "<<leader><leader>lr", function()
                gen.exec(gen.prompts.Review_Code)
            end)
            vim.keymap.set({ "n", "v" }, "<<leader><leader>le", function()
                gen.exec(gen.prompts.Enhance_Code)
            end)
        end,
    },
}
