local function create_inline_replace_prompt(opts)
    return {
        strategy = "inline",
        description = opts.text,
        opts = {
            is_default = true,
            is_slash_cmd = false,
            user_prompt = false,
            modes = { "v" },
            short_name = opts.short_name,
            stop_context_insertion = true,
            placement = "replace",
        },
        prompts = {
            {
                role = "system",
                content = function(context)
                    local code =
                        require("codecompanion.helpers.actions").get_code(
                            context.start_line,
                            context.end_line
                        )

                    return string.format(
                        [[
%s

Must only output the newly generated and optimized prompts, without
explanation, without wrapping it in markdown code block.

---

Input:

```%s
%s
```
]],
                        opts.text,
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
    }
end

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
                    ["Go Wrap Error Inline"] = create_inline_replace_prompt {
                        text = [[
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
]],
                        short_name = "go-wrap-error",
                    },
                    ["Text Fix Spelling And Grammar Inline"] = create_inline_replace_prompt {
                        text = [[
Fix the grammar and spelling. Preserve all formatting, line breaks, and special
characters. Do not add or remove any content. Return only the corrected text.
]],
                        short_name = "text-fix-spelling-and-grammar",
                    },
                    ["Text Refine Prompt Inline"] = create_inline_replace_prompt {
                        text = [[
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
                },
                strategies = {
                    chat = {
                        adapter = "yandex_yandexgpt_openai",
                    },
                    inline = {
                        adapter = "yandex_yandexgpt_openai",
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

            vim.keymap.set("n", "<leader>Cgc", function()
                require("codecompanion").prompt "commit"
            end)
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
