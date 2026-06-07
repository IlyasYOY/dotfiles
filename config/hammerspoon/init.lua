for _, app in ipairs {
    { shortcut = "1", name = "WezTerm" },
    { shortcut = "2", name = "Zen" },
    { shortcut = "3", name = "SingularityApp" },
    { shortcut = "4", name = "Final Cut Pro" },

    { shortcut = "6", name = "ChatGPT" },
    { shortcut = "7", name = "Codex" },
    { shortcut = "8", name = "Telegram" },
    { shortcut = "9", name = "Calendar" },
    { shortcut = "0", name = "Mail" },
} do
    hs.hotkey.bind({ "alt" }, app.shortcut, function()
        hs.application.launchOrFocus(app.name)
    end)
end
