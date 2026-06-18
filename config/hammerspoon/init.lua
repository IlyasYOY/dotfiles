for _, app in ipairs {
    { shortcut = "1", name = "WezTerm" },
    { shortcut = "2", name = "Zen" },
    { shortcut = "5", name = "Final Cut Pro" },

    { shortcut = "7", name = "Calendar" },
    { shortcut = "8", name = "Mail" },
} do
    hs.hotkey.bind({ "alt" }, app.shortcut, function()
        hs.application.launchOrFocus(app.name)
    end)
end


-- Here I load files with custom settings for machine.
-- This lua file is hidden from VCS, so I can do tricky stuff there.
pcall(require, "hidden")
