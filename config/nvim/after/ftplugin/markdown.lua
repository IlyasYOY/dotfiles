vim.opt_local.spell = true
vim.opt_local.wrap = true
vim.bo.formatprg = "mdsf format --stdin --log-level=off"

local function setup_formatters()
    vim.keymap.set("v", "<localleader>fi", function()
        return "c*<C-r>-*<Esc>"
    end, {
        expr = true,
        buffer = true,
        desc = "Wrap selected text with italic markers (*)",
    })
    vim.keymap.set("v", "<localleader>fb", function()
        return "c**<C-r>-**<Esc>"
    end, {
        expr = true,
        buffer = true,
        desc = "Wrap selected text with bold markers (**)",
    })
    vim.keymap.set("v", "<localleader>fc", function()
        return "c`<C-r>-`<Esc>"
    end, {
        expr = true,
        buffer = true,
        desc = "Wrap selected text with code markers (`)",
    })
    vim.keymap.set("v", "<localleader>fl", function()
        return "c[<C-r>-](<C-r>+)<Esc>"
    end, {
        expr = true,
        buffer = true,
        desc = "Wrap selected text with link ([]()), link valus is + register",
    })
end

local function setup_ai()
    vim.api.nvim_buf_create_user_command(0, "AIChatMDCreateTitle", function()
        local filename = vim.api.nvim_buf_get_name(0)
        local cmd = "cat "
            .. vim.fn.shellescape(filename)
            .. " | opencode run --agent 'create-title' | sed '1,3d'"

        local output = vim.fn.systemlist(cmd)
        if vim.v.shell_error ~= 0 then
            vim.notify(
                "OpenCode failed: " .. table.concat(output, "\n"),
                vim.log.levels.ERROR
            )
            return
        end

        local title = table.concat(output, "\n"):gsub("%s+$", "")

        vim.fn.setreg('"', title)

        vim.notify(
            "AI-generated title (" .. title .. ') copied to " register.',
            vim.log.levels.INFO
        )
    end, {
        range = false,
        desc = 'Create a title for the current markdown buffer using OpenCode and copy it to the " register',
    })
end

setup_ai()
setup_formatters()
