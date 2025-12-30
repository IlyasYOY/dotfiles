vim.treesitter.start()

vim.bo.formatoptions = vim.bo.formatoptions .. "ro/"

local function setup_test()
    vim.api.nvim_buf_create_user_command(0, "PythonTestAll", function(opts)
        local cmd = "pytest"
        vim.g.last_python_test_command = cmd
        vim.cmd.Dispatch {
            "-compiler=pytest",
            vim.g.last_python_test_command,
        }
    end, {
        desc = "run test for all packages",
    })

    vim.keymap.set(
        "n",
        "<localleader>ta",
        "<cmd>PythonTestAll<cr>",
        { desc = "run test for all packages", buffer = true }
    )

    vim.api.nvim_buf_create_user_command(0, "PythonTestPackage", function(opts)
        local cmd = "pytest " .. vim.fn.expand "%:p:h"
        vim.g.last_python_test_command = cmd
        vim.cmd.Dispatch {
            "-compiler=pytest",
            vim.g.last_python_test_command,
        }
    end, {
        desc = "run test for a package",
    })

    vim.keymap.set(
        "n",
        "<localleader>tp",
        "<cmd>PythonTestPackage<cr>",
        { desc = "run test for a package", buffer = true }
    )

    vim.api.nvim_buf_create_user_command(0, "PythonTestFile", function(opts)
        local cwf = vim.fn.expand "%:."
        local cmd = "pytest " .. cwf
        vim.g.last_python_test_command = cmd
        vim.cmd.Dispatch {
            "-compiler=pytest",
            vim.g.last_python_test_command,
        }
    end, {
        desc = "run test for a file",
    })

    vim.keymap.set(
        "n",
        "<localleader>tt",
        "<cmd>PythonTestFunction<cr>",
        { desc = "run test for a function", buffer = true }
    )

    ---@param node TSNode
    ---@return string?
    local function get_test_name(node)
        if node:type() == "function_definition" then
            local name_nodes = node:field "name"
            if #name_nodes == 0 then
                return
            end

            local name_node = name_nodes[1]
            if not name_node then
                return
            end

            local bufnr = vim.api.nvim_get_current_buf()
            return vim.treesitter.get_node_text(name_node, bufnr)
        end
    end

    vim.api.nvim_buf_create_user_command(0, "PythonTestFunction", function()
        local cwf = vim.fn.expand "%:."

        if not string.find(cwf, "test_.*%.py$") then
            vim.notify "Not a test file"
            return
        end

        local test_name = nil
        local node = vim.treesitter.get_node() -- node under the cursor

        while node do
            test_name = get_test_name(node)
            if test_name then
                break
            end
            node = node:parent()
        end

        if not test_name then
            vim.notify "Test function was not found"
            return
        end

        local cmd = "pytest " .. cwf .. "::" .. test_name
        vim.g.last_python_test_command = cmd
        vim.cmd.Dispatch {
            "-compiler=pytest",
            vim.g.last_python_test_command,
        }
    end, {
        desc = "run test for a function",
    })

    vim.keymap.set("n", "<localleader>tf", "<cmd>PythonTestFile<cr>", {
        desc = "run test for a file",
        buffer = true,
    })

    vim.api.nvim_buf_create_user_command(0, "PythonTestLast", function(opts)
        if vim.g.last_python_test_command then
            vim.cmd.Dispatch { "-compiler=pytest", vim.g.last_python_test_command }
        else
            vim.notify(
                "No previous Python test command to run",
                vim.log.levels.WARN
            )
        end
    end, {
        desc = "run the last test command again",
    })

    vim.keymap.set(
        "n",
        "<localleader>tl",
        "<cmd>PythonTestLast<cr>",
        { desc = "run the last test command again", buffer = true }
    )
end

local function setup_toggle()
    vim.api.nvim_buf_create_user_command(0, "PythonToggleTest", function()
        local cwf = vim.fn.expand "%:."
        if string.find(cwf, "test_[%w_]+%.py$") then
            vim.fn.execute(
                "edit " .. string.gsub(cwf, "test_([%w_]+)%.py$", "%1.py")
            )
        elseif string.find(cwf, "[%w_]+%.py$") then
            vim.fn.execute(
                "edit " .. string.gsub(cwf, "([%w_]+)%.py$", "test_%1.py")
            )
        end
    end, {
        desc = "toggle between test and source code",
    })

    vim.keymap.set("n", "<localleader>ot", "<cmd>PythonToggleTest<cr>", {
        desc = "toggle between test and source code",
        buffer = true,
    })
end

setup_test()
setup_toggle()
