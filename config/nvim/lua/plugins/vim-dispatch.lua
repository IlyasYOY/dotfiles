return {
    {
        "tpope/vim-dispatch",
        config = function()
            vim.keymap.set("n", "<leader>ta", function()
                local cwf = vim.fn.expand "%:."
                if string.find(cwf, ".go$") then
                    vim.cmd.Dispatch { "go test ./..." }
                end
            end, { desc = "run test for a package" })

            vim.keymap.set("n", "<leader>tp", function()
                local cwf = vim.fn.expand "%:."
                if string.find(cwf, ".go$") then
                    vim.cmd.Dispatch {
                        "go test " .. vim.fn.expand "%:p:h",
                    }
                end
            end, { desc = "run test for a package" })

            vim.keymap.set("n", "<leader>tt", function()
                local cwf = vim.fn.expand "%:."
                if string.find(cwf, "_test%.go$") then
                    vim.cmd.Dispatch { "go test " .. cwf }
                end
            end, { desc = "run test for a file" })

            vim.keymap.set("n", "<leader>tf", function()
                local cwf = vim.fn.expand "%:."

                local bufnr = vim.api.nvim_get_current_buf()
                if string.find(cwf, "_test%.go$") then
                    local function_name = nil
                    local node_under_cursor = vim.treesitter.get_node()
                    local curr_node = node_under_cursor
                    while curr_node do
                        if curr_node:type() == "function_declaration" then
                            local name_node = curr_node:field("name")[1]
                            if name_node then
                                function_name = vim.treesitter.get_node_text(
                                    name_node,
                                    bufnr
                                )
                                break
                            end
                        end
                        curr_node = curr_node:parent()
                    end
                    if not function_name then
                        vim.notify "test function was not found"
                    elseif string.match(function_name, "^Test.+") then
                        vim.cmd.Dispatch {
                            "go test " .. cwf .. " -run " .. function_name,
                        }
                    else
                        vim.notify "function is not a test"
                    end
                end
            end, { desc = "run test for a file" })
        end,
    },
}
