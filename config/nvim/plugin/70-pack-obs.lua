local pack = require "ilyasyoy.pack"

vim.pack.add(pack.specs.obs, pack.no_load())

for _, command in ipairs {
    "ObsNvimFollowLink",
    "ObsNvimRandomNote",
    "ObsNvimNewNote",
    "ObsNvimCopyObsidianLinkToNote",
    "ObsNvimOpenInObsidian",
    "ObsNvimDailyNote",
    "ObsNvimWeeklyNote",
    "ObsNvimRename",
    "ObsNvimTemplate",
    "ObsNvimMove",
    "ObsNvimBacklinks",
} do
    pack.lazy_user_command(
        "obs",
        command,
        { nargs = "*", bang = true, range = true }
    )
end
