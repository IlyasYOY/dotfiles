return {
    {
        "olimorris/codecompanion.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "j-hui/fidget.nvim",
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
                prompt_library = {
                    ["Go Error Wrap Prompt"] = {
                        strategy = "inline",
                        description = "Wraps errors in Go",
                        opts = {
                            is_default = true,
                            is_slash_cmd = false,
                            user_prompt = false,
                            modes = { "v" },
                            stop_context_insertion = true,
                        },
                        prompts = {
                            {
                                role = "system",
                                content = function(context)
                                    local code = require(
                                        "codecompanion.helpers.actions"
                                    ).get_code(
                                        context.start_line,
                                        context.end_line
                                    )

                                    return string.format(
                                        [[
Context: You are provided with a code block written in the GO language. Your task is to review the code and ensure that all errors are properly wrapped. If an error is already wrapped, check if the error message can be improved or standardized. If an error is not wrapped, wrap it in a consistent manner.

Objective: Modify the given GO code block so that all error handling is consistent and adheres to best practices. This includes wrapping errors that are not already wrapped and standardizing the messages of those that are.

Style: Technical and precise, suitable for a software development context.

Tone: Neutral and professional.

Audience: Software developers familiar with the GO language.

Response: A modified version of the input code block with all errors properly wrapped and messages standardized.

Workflow:
1. Parse the input code block to identify all instances of error handling.
2. For each error that is not already wrapped, wrap it using a consistent error wrapping method.
3. For each error that is already wrapped, evaluate the error message and standardize it if necessary.
4. Return the modified code block.

Code:

```%s
%s
```
]],
                                        context.filetype,
                                        code
                                    )
                                end,
                                opts = {
                                    visible = false,
                                    tag = "system_tag",
                                    contains_code = true,
                                },
                            },
                        },
                    },
                },
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

            require("ilyasyoy.code-companion-fidget-spinner"):init()

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
