for _, app in ipairs {
    { shortcut = "1", name = "WezTerm" },
    { shortcut = "2", name = "Google Chrome" },
    { shortcut = "3", name = "Todoist" },
    { shortcut = "4", name = "Obsidian" },
    { shortcut = "8", name = "Telegram" },
    { shortcut = "9", name = "Calendar" },
    { shortcut = "0", name = "Mail" },
} do
    hs.hotkey.bind({ "alt" }, app.shortcut, function()
        hs.application.launchOrFocus(app.name)
    end)
end

-- Fix grammar with aichat
hs.hotkey.bind({ "alt" }, "g", function()
    local input = hs.pasteboard.getContents()
    if not input or input == "" then
        hs.alert.show "No text in clipboard"
        return
    end

    local escaped = input:gsub("'", "'\"'\"'")
    local cmd = "echo '"
        .. escaped
        .. "' | aichat --role %fix-grammar% --code 2>&1"
    hs.alert.show(cmd)
    local output = hs.execute(cmd, true)

    if not output or output == "" then
        hs.alert.show "Failed to run aichat or no output"
        return
    end

    local found_index = string.find(output, input)
    if found_index then
        hs.alert.show "Text was correct, nothing has changed"
        return
    end

    hs.pasteboard.setContents(output)
    hs.alert.show "Grammar fixed and copied to clipboard"
end)
