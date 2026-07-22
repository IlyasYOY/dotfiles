-- Launch or focus the first available app from a list of candidate names.
-- Prefers an already-running candidate (earliest in the list wins); otherwise
-- launches the first candidate whose .app bundle exists in a standard location.
local function launch_or_focus_first(names)
    for _, name in ipairs(names) do
        if hs.application.get(name) then
            hs.application.launchOrFocus(name)
            return
        end
    end
    local home = os.getenv "HOME"
    for _, name in ipairs(names) do
        local candidates = {
            "/Applications/" .. name .. ".app",
            "/System/Applications/" .. name .. ".app",
            home .. "/Applications/" .. name .. ".app",
        }
        for _, path in ipairs(candidates) do
            if hs.fs.attributes(path) then
                hs.application.launchOrFocus(name)
                return
            end
        end
    end
    hs.alert.show("No matching app: " .. table.concat(names, ", "))
end

for _, app in ipairs {
    { shortcut = "1", names = { "WezTerm" } },
    { shortcut = "2", names = { "Firefox" } },
    { shortcut = "3", names = { "ChatGPT", "Codex" } },
    { shortcut = "4", names = { "Telegram" } },
    { shortcut = "5", names = { "Final Cut Pro" } },
} do
    hs.hotkey.bind({ "alt" }, app.shortcut, function()
        launch_or_focus_first(app.names)
    end)
end

-- Here I load files with custom settings for machine.
-- This lua file is hidden from VCS, so I can do tricky stuff there.
pcall(require, "hidden")
