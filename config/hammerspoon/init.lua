for _, app in ipairs {
    { shortcut = "1", name = "WezTerm" },
    { shortcut = "2", name = "Google Chrome" },
    { shortcut = "3", name = "TickTick" },
    { shortcut = "4", name = "Telegram" },
    { shortcut = "5", name = "Obsidian" },
} do
    hs.hotkey.bind({ "alt" }, app.shortcut, function()
        hs.application.launchOrFocus(app.name)
    end)
end
