vim.api.nvim_buf_create_user_command(0, 'MakeTargets', function()
    local parser = vim.treesitter.get_parser(0, "make")
    if not parser then
        vim.notify(
            "Treesitter make parser not available.",
            vim.log.levels.ERROR
        )
        return
    end

    local tree = parser:parse()[1]
    local root = tree:root()
    local query =
        vim.treesitter.query.parse("make", "(rule (targets) @targets)")
    local targets = {}
    for _, node in query:iter_captures(root, 0) do
        local text = vim.treesitter.get_node_text(node, 0)
        for target in text:gmatch "%S+" do
            targets[target] = true
        end
    end

    local target_list = {}
    for target, _ in pairs(targets) do
        table.insert(target_list, target)
    end

    if #target_list == 0 then
        vim.notify("No targets found in Makefile.", vim.log.levels.WARN)
        return
    end

    vim.ui.select(
        target_list,
        { prompt = "Select a make target:" },
        function(choice)
            if choice then
                if vim.fn.exists(":Make") > 0 then
                    vim.cmd("Make -C %:p:h " .. choice)
                else
                    vim.cmd("make -C %:p:h " .. choice)
                end
            end
        end
    )
end, { desc = "run target from the current file" })


vim.api.nvim_buf_create_user_command(0, 'MakeTarget', function()
    local parser = vim.treesitter.get_parser(0, "make")
    if not parser then
        vim.notify("Treesitter make parser not available.", vim.log.levels.ERROR)
        return
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local node = vim.treesitter.get_node({ bufnr = 0, pos = { cursor[1] - 1, cursor[2] } })
    while node and node:type() ~= 'rule' do
        node = node:parent()
    end
    if not node then
        vim.notify("Cursor is not within a make target rule.", vim.log.levels.WARN)
        return
    end

    -- Extract target from (targets) child
    local target_node = node:child(0) -- Assuming (targets) is the first child in (rule (targets) ...)
    if target_node and target_node:type() == 'targets' then
        local text = vim.treesitter.get_node_text(target_node, 0)
        local target = text:match("%S+") -- First word as target
        if target then
            if vim.fn.exists(":Make") > 0 then
                vim.cmd("Make -C %:p:h " .. target)
            else
                vim.cmd("make -C %:p:h " .. target)
            end
        else
            vim.notify("No valid target found in current rule.", vim.log.levels.WARN)
        end
    else
        vim.notify("Unable to parse target in current rule.", vim.log.levels.ERROR)
    end
end, { desc = "run the current make target" })

vim.keymap.set("n", "<localleader>T", ":MakeTargets<CR>", { buffer = true })
vim.keymap.set("n", "<localleader>t", ":MakeTarget<CR>", { buffer = true })
