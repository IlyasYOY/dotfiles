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

            -- so I can override the models for different environments.
            local strategies = vim.g.codecompanion_strategies
                or {
                    chat = {
                        adapter = "yandex_yandexgpt_openai",
                    },
                    inline = {
                        adapter = "yandex_llama_openai",
                        keymaps = {
                            accept_change = {
                                modes = { n = "ga" },
                                description = "Accept the suggested change",
                            },
                            reject_change = {
                                modes = { n = "gr" },
                                description = "Reject the suggested change",
                            },
                        },
                    },
                    cmd = {
                        adapter = "yandex_yandexgpt_openai",
                    },
                }

            local adapters = vim.g.codecompanion_adapters
                or {
                    yandex_llama_lite_openai = yandex_openai_compatible_for_model "llama-lite",
                    yandex_llama_openai = yandex_openai_compatible_for_model "llama",
                    yandex_yandexgpt_lite_openai = yandex_openai_compatible_for_model "yandexgpt-lite",
                    yandex_yandexgpt_lite_rc_openai = yandex_openai_compatible_for_model "yandexgpt-lite/rc",
                    yandex_yandexgpt_openai = yandex_openai_compatible_for_model "yandexgpt",
                    yandex_yandexgpt_rc_openai = yandex_openai_compatible_for_model "yandexgpt/rc",
                }

            local prompts = {
                ["Custom Prompt"] = {
                    strategy = "inline",
                    description = "Prompt the LLM from Neovim",
                    opts = {
                        index = 3,
                        is_default = true,
                        is_slash_cmd = false,
                        short_name = "custom-prompt",
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
                        is_default = true,
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
                        index = 3,
                        is_default = true,
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
                        index = 3,
                        is_default = true,
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
                ["Text Refine Prompt Chat"] = {
                    strategy = "chat",
                    description = "Refines prompts",
                    opts = {
                        ignore_system_prompt = true,
                    },
                    prompts = {
                        {
                            role = "system",
                            content = [[
As a professional Prompt Engineer, your role is to create effective and innovative prompts for interacting with AI models.

Your core skills include:
1. **CO-STAR Framework Application**: Utilize the CO-STAR framework to build efficient prompts, ensuring effective communication with large language models.
2. **Contextual Awareness**: Construct prompts that adapt to complex conversation contexts, ensuring relevant and coherent responses.
3. **Chain-of-Thought Prompting**: Create prompts that elicit AI models to demonstrate their reasoning process, enhancing the transparency and accuracy of answers.
4. **Zero-shot Learning**: Design prompts that enable AI models to perform specific tasks without requiring examples, reducing dependence on training data.
5. **Few-shot Learning**: Guide AI models to quickly learn and execute new tasks through a few examples.

Your output format should include:
- **Context**: Provide comprehensive background information for the task to ensure the AI understands the specific scenario and offers relevant feedback.
- **Objective**: Clearly define the task objective, guiding the AI to focus on achieving specific goals.
- **Style**: Specify writing styles according to requirements, such as imitating a particular person or industry expert.
- **Tone**: Set an appropriate emotional tone to ensure the AI's response aligns with the expected emotional context.
- **Audience**: Tailor AI responses for a specific audience, ensuring content appropriateness and ease of understanding.
- **Response**: Specify output formats for easy execution of downstream tasks, such as lists, JSON, or professional reports.
- **Workflow**: Instruct the AI on how to step-by-step complete tasks, clarifying inputs, outputs, and specific actions for each step.
- **Examples**: Show a case of input and output that fits the scenario.

Your workflow should be:
1. Extract key information from user requests to determine design objectives.
2. Based on user needs, create prompts that meet requirements, with each part being professional and detailed.
3. Must only output the newly generated and optimized prompts, without explanation, without wrapping it in markdown code block.
]],
                        },
                        {
                            role = "user",
                            content = "I want to...",
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

            vim.keymap.set(
                { "n", "s" },
                "<leader>cc",
                "<cmd>CodeCompanionChat<CR>"
            )
            vim.keymap.set(
                "n",
                "<leader>cc",
                "<cmd>CodeCompanionChat Toggle<CR>"
            )
            vim.keymap.set(
                { "n", "v", "s" },
                "<leader>ca",
                "<cmd>CodeCompanionActions<CR>"
            )
            vim.keymap.set({ "v", "s" }, "<leader>ce", function()
                require("codecompanion").prompt "custom-prompt"
            end)
        end,
    },
}
