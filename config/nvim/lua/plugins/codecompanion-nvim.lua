return {
    {
        "olimorris/codecompanion.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
        config = function()
            require("codecompanion").setup {
                strategies = {
                    chat = {
                        adapter = "ollama-qwen2.5-coder",
                    },
                    inline = {
                        adapter = "ollama-qwen2.5-coder",
                    },
                    cmd = {
                        adapter = "ollama-qwen2.5-coder",
                    },
                },
                adapters = {
                    ["ollama-qwen3"] = function()
                        return require("codecompanion.adapters").extend(
                            "ollama",
                            {
                                name = "qwen3",
                                schema = {
                                    model = {
                                        default = "qwen3:latest",
                                    },
                                    num_ctx = {
                                        default = 16384,
                                    },
                                    num_predict = {
                                        default = -1,
                                    },
                                },
                            }
                        )
                    end,
                    ["ollama-qwen2.5-coder"] = function()
                        return require("codecompanion.adapters").extend(
                            "ollama",
                            {
                                name = "qwen2.5-coder",
                                schema = {
                                    model = {
                                        default = "qwen2.5-coder:latest",
                                    },
                                    num_ctx = {
                                        default = 16384,
                                    },
                                    num_predict = {
                                        default = -1,
                                    },
                                },
                            }
                        )
                    end,
                },
            }

            vim.keymap.set(
                "n",
                "<leader>Cc",
                "<cmd>CodeCompanionChat Toggle<CR>"
            )
            vim.keymap.set(
                { "n", "v", "s" },
                "<leader>Ca",
                "<cmd>CodeCompanionActions<CR>"
            )
        end,
    },
}
