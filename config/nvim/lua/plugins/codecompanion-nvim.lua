return {
    {
        "olimorris/codecompanion.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
        config = function()
            local function yandex_openai_compatible_for_model(model)
                return function()
                    local pass = require "ilyasyoy.functions.pass"

                    local yandex_api_key =
                        pass.load_secret "cloud/yandex/ilyasyoy-ai-api-key"
                    local yandex_catalog_id =
                        pass.load_secret "cloud/yandex/ilyasyoy-catalog-id"

                    return require("codecompanion.adapters").extend(
                        "openai_compatible",
                        {
                            env = {
                                url = "https://llm.api.cloud.yandex.net",
                                api_key = yandex_api_key,
                            },
                            schema = {
                                model = {
                                    default = "gpt://"
                                        .. yandex_catalog_id
                                        .. "/"
                                        .. model,
                                },
                            },
                        }
                    )
                end
            end

            require("codecompanion").setup {
                strategies = {
                    chat = {
                        adapter = "yandex_yandexgpt_openai",
                    },
                    inline = {
                        adapter = "yandex_yandexgpt_openai",
                    },
                    cmd = {
                        adapter = "yandex_yandexgpt_openai",
                    },
                },
                adapters = {
                    yandex_yandexgpt_lite_openai = yandex_openai_compatible_for_model "yandexgpt-lite",
                    yandex_yandexgpt_openai = yandex_openai_compatible_for_model "yandexgpt",
                    yandex_yandexgpt_32k_openai = yandex_openai_compatible_for_model "yandexgpt-32k",
                    yandex_yandexgpt_llama_openai = yandex_openai_compatible_for_model "llama",
                    yandex_yandexgpt_llama_lite_openai = yandex_openai_compatible_for_model "llama-lite",

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
