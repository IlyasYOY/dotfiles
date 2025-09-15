for _, app in ipairs {
    { shortcut = "1", name = "WezTerm" },
    { shortcut = "2", name = "Google Chrome" },
    { shortcut = "3", name = "TickTick" },
    { shortcut = "4", name = "Obsidian" },
    { shortcut = "8", name = "Telegram" },
    { shortcut = "9", name = "Calendar" },
    { shortcut = "0", name = "Mail" },
} do
    hs.hotkey.bind({ "alt" }, app.shortcut, function()
        hs.application.launchOrFocus(app.name)
    end)
end
