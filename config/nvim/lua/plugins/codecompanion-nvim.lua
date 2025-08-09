return {
    {
        "olimorris/codecompanion.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "j-hui/fidget.nvim",
        },
        keys = {
            {
                "<leader>cc",
                "<cmd>CodeCompanionChat<CR>",
                mode = { "n", "s", "v" },
            },
            {
                "<leader>cc",
                "<cmd>CodeCompanionChat Toggle<CR>",
                mode = "n",
            },
            {
                "<leader>ca",
                "<cmd>CodeCompanionActions<CR>",
                mode = { "n", "v", "s" },
            },

            {
                "<leader>ce",
                function()
                    require("codecompanion").prompt "code-edit-inline"
                end,
                mode = { "v", "s" },
            },
            {
                "<leader>cr",
                function()
                    require("codecompanion").prompt "review-diff"
                end,
                mode = { "n" },
            },
        },
        config = function()
            local pass = require "ilyasyoy.functions.pass"

            -- so I can override the models for different environments.
            local strategies = vim.g.codecompanion_strategies
                or {
                    chat = {
                        adapter = {
                            name = "yandexgpt",
                            model = "gpt://"
                                .. pass.load_secret "cloud/yandex/catalog-id"
                                .. "/qwen3-235b-a22b-fp8/latest",
                        },
                    },
                    inline = {
                        adapter = {
                            name = "yandexgpt",
                            model = "gpt://"
                                .. pass.load_secret "cloud/yandex/catalog-id"
                                .. "/llama",
                        },
                    },
                    cmd = {
                        adapter = "yandexgpt",
                    },
                }

            local adapters = vim.g.codecompanion_adapters
                or {
                    yandexgpt = function()
                        return require("codecompanion.adapters").extend(
                            "openai_compatible",
                            {
                                env = {
                                    url = "https://llm.api.cloud.yandex.net",
                                    api_key = pass.load_secret "cloud/yandex/llm-api-key",
                                },
                            }
                        )
                    end,
                }

            local prompts = {
                ["Code Edit"] = {
                    strategy = "inline",
                    description = "Prompt the LLM from Neovim",
                    opts = {
                        is_slash_cmd = false,
                        short_name = "code-edit-inline",
                        user_prompt = true,
                    },
                    prompts = {
                        {
                            role = "system",
                            content = function(context)
                                return string.format(
                                    [[I want you to act as a senior %s developer. I will ask you specific questions and I want you to return raw code only (no codeblocks and no explanations). If you can't respond with code, respond with nothing]],
                                    context.filetype
                                )
                            end,
                            opts = {
                                visible = false,
                                tag = "system_tag",
                            },
                        },
                    },
                },
                ["Git Generate a Commit Message Inline"] = {
                    strategy = "inline",
                    description = "Generate a commit message",
                    opts = {
                        is_slash_cmd = false,
                        user_prompt = false,
                        short_name = "commit-inline",
                        placement = "before",
                        stop_context_insertion = true,
                        auto_submit = true,
                    },
                    prompts = {
                        {
                            role = "user",
                            content = function()
                                return string.format(
                                    [[
You are an expert at following the Conventional Commit specification. Given the
git diff listed below, please generate a commit message for me:

```diff
%s
```
]],
                                    vim.fn.system "git diff --no-ext-diff --staged"
                                )
                            end,
                            opts = {
                                contains_code = true,
                            },
                        },
                    },
                },
                ["Text Fix Spelling Inline"] = {
                    strategy = "inline",
                    opts = {
                        is_slash_cmd = false,
                        user_prompt = false,
                        placement = "replace",
                        short_name = "text-fix-spelling-inline",
                        auto_submit = true,
                    },
                    prompts = {
                        {
                            role = "system",
                            content = function(context)
                                return [[
Fix the grammar and spelling.
Preserve all formatting, line breaks, and special characters.
Do not add or remove any content.
Return only the corrected text.
]]
                            end,
                            opts = {
                                visible = false,
                                tag = "system_tag",
                            },
                        },
                    },
                    {
                        role = "user",
                        content = function(context)
                            local code = require(
                                "codecompanion.helpers.actions"
                            ).get_code(
                                context.start_line,
                                context.end_line
                            )

                            return string.format(
                                [[
Fix spelling for this:

```%s
%s
```
]],
                                context.filetype,
                                code
                            )
                        end,
                        opts = {
                            contains_code = true,
                        },
                    },
                },
                ["Go Wrap Error Inline"] = {
                    strategy = "inline",
                    description = "Wrap errors in go code",
                    opts = {
                        is_slash_cmd = false,
                        user_prompt = false,
                        placement = "replace",
                        short_name = "go-wrap-error-inline",
                        auto_submit = true,
                    },
                    prompts = {
                        {
                            role = "system",
                            content = function(context)
                                return [[
Context: You are provided with a code block written in the GO language. Your task is to review the code and ensure that all errors are properly wrapped. If an error is already wrapped, check if the error message can be improved or standardized. If an error is not wrapped, wrap it in a consistent manner.
Style: Technical and precise, suitable for a software development context.
Tone: Neutral and professional.
Audience: Software developers familiar with the GO language.
Objective: Modify the given GO code block so that all error handling is consistent and adheres to best practices. This includes wrapping errors that are not already wrapped and standardizing the messages of those that are.
Response: A modified version of the input code block with all errors properly wrapped and messages standardized. Don't create errors from nil values. I want you to return raw code only (no codeblocks and no explanations).

Workflow:
1. Parse the input code block to identify all instances of error handling.
2. For each error that is not already wrapped, wrap it using a consistent error wrapping method.
3. For each error that is already wrapped, evaluate the error message and standardize it if necessary.
4. Return the modified code block.
]]
                            end,
                            opts = {
                                visible = false,
                                tag = "system_tag",
                            },
                        },
                    },
                    {
                        role = "user",
                        content = function(context)
                            local code = require(
                                "codecompanion.helpers.actions"
                            ).get_code(
                                context.start_line,
                                context.end_line
                            )

                            return string.format(
                                [[
Wrap errors in this code:

```%s
%s
```
]],
                                context.filetype,
                                code
                            )
                        end,
                        opts = {
                            contains_code = true,
                        },
                    },
                },
            }

            if vim.g.codecompanion_prompts then
                for key, value in pairs(vim.g.codecompanion_prompts) do
                    prompts[key] = value
                end
            end

            require("codecompanion").setup {
                strategies = strategies,
                adapters = adapters,
                prompt_library = prompts,
            }

            require("ilyasyoy.code-companion-fidget-spinner"):init()
        end,
    },
}
