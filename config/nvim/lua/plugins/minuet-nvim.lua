return {
    {
        "IlyasYOY/minuet-ai.nvim",
        dependences = {
            { "nvim-lua/plenary.nvim" },
        },
        config = function()
            local pass = require "ilyasyoy.functions.pass"

            require("minuet").setup {
                virtualtext = {
                    keymap = {
                        -- accept whole completion
                        accept = "<A-l>",
                        -- accept one line
                        accept_line = "<A-L>",
                        accept_n_lines = nil,
                        -- Cycle to prev completion item, or manually invoke completion
                        prev = "<A-k>",
                        -- Cycle to next completion item, or manually invoke completion
                        next = "<A-j>",
                        dismiss = "<A-h>",
                    },

                    -- Whether show virtual text suggestion when the completion menu
                    -- (nvim-cmp or blink-cmp) is visible.
                    show_on_completion_menu = false,
                },
                provider = "openai_compatible",
                request_timeout = 2.5,
                throttle = 3000,
                debounce = 1500,
                provider_options = {
                    openai_compatible = vim.g.minuet_provider_options_openai_compatible
                        or {
                            api_key = function()
                                return pass.load_secret "cloud/yandex/ilyasyoy-ai-api-key"
                            end,
                            end_point = "https://llm.api.cloud.yandex.net/v1/chat/completions",
                            model = "gpt://"
                                .. pass.load_secret "cloud/yandex/ilyasyoy-catalog-id"
                                .. "/yandexgpt-lite",
                            name = "YandexGPT",
                            optional = {
                                max_tokens = 100,
                                top_p = 0.9,
                                provider = {
                                    sort = "latency",
                                },
                            },
                        },
                },
            }

            vim.keymap.set(
                "n",
                "<leader>M",
                "<cmd>Minuet virtualtext toggle<CR>",
                { desc = "Toggle Minuet virtual text" }
            )

            require("minuet.fidget"):init()
        end,
    },
}
