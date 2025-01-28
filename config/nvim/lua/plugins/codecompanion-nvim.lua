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
                },
                adapters = {
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
                    ["ollama-deepseek-r1"] = function()
                        return require("codecompanion.adapters").extend(
                            "ollama",
                            {
                                name = "ollama-deepseek-r1",
                                schema = {
                                    model = {
                                        default = "deepseek-r1:latest",
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
        end,
    },
}
