return {
    {
        "IlyasYOY/minuet-ai.nvim",
        dependences = {
            "nvim-lua/plenary.nvim",
            "j-hui/fidget.nvim",
        },
        keys = {
            {
                "<leader>M",
                "<cmd>Minuet virtualtext toggle<CR>",
                mode = "n",
                desc = "Toggle Minuet virtual text",
            },
        },
        config = function()
            local pass = require "ilyasyoy.functions.pass"

            require("minuet").setup {
                virtualtext = {
                    auto_trigger_ft = {},

                    keymap = {
                        -- accept whole completion
                        accept = "<A-l>",
                        -- accept one line
                        accept_line = "<A-;>",
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
                throttle = 1500,
                debounce = 300,
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

            require("minuet.fidget"):init()
        end,
    },
}
