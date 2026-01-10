vim.keymap.set("n", "<localleader>g", function()
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
    local goals = {}
    for id, node in query:iter_captures(root, 0) do
        local text = vim.treesitter.get_node_text(node, 0)
        for goal in text:gmatch "%S+" do
            goals[goal] = true
        end
    end

    local goal_list = {}
    for goal, _ in pairs(goals) do
        table.insert(goal_list, goal)
    end

    if #goal_list == 0 then
        vim.notify("No goals found in Makefile.", vim.log.levels.WARN)
        return
    end

    vim.ui.select(
        goal_list,
        { prompt = "Select a make goal:" },
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
end)
