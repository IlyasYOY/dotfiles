local function get_git_ignored_files_in(dir)
    local found = vim.fs.find(".git", {
        upward = true,
        path = dir,
    })
    if #found == 0 then
        return {}
    end

    local result = vim.system({
        "git",
        "-C",
        dir,
        "ls-files",
        "--ignored",
        "--exclude-standard",
        "--others",
        "--directory",
    }, { text = true }):wait()
    if result.code ~= 0 then
        return {}
    end

    local ignored_files = {}
    for line in (result.stdout or ""):gmatch "[^\n]+" do
        -- filter out nested directories (keep only top-level entries)
        local stripped = line:gsub("/$", "")
        if not stripped:find "/" then
            table.insert(ignored_files, stripped)
        end
    end

    return ignored_files
end

local cache = {}

local function cached_get_git_ignored_files_in(dir)
    local val
    val = cache[dir]
    if val then
        return val
    end
    val = get_git_ignored_files_in(dir)
    cache[dir] = val
    return val
end

local oil = require "oil"

oil.setup {
    keymaps = {
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<C-v>"] = "actions.select_vsplit",
        ["<C-s>"] = "actions.select_split",
        ["<C-t>"] = "actions.select_tab",
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = "actions.close",
        ["<C-r>"] = "actions.refresh",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["`"] = "actions.cd",
        ["~"] = "actions.tcd",
        ["gs"] = "actions.change_sort",
        ["gx"] = "actions.open_external",
        ["g."] = "actions.toggle_hidden",
        ["g\\"] = "actions.toggle_trash",
    },
    use_default_keymaps = false,
    view_options = {
        show_hidden = true,
        is_hidden_file = function(name, bufnr)
            local ignored_files =
                cached_get_git_ignored_files_in(oil.get_current_dir())
            return vim.tbl_contains(ignored_files, name)
                or vim.startswith(name, ".")
        end,
    },
}

vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })
vim.keymap.set(
    "n",
    "<leader>e",
    "<cmd>Oil<CR>",
    { desc = "Open file explorer" }
)
vim.keymap.set(
    "n",
    "<leader>E",
    "<cmd>Oil --float<CR>",
    { desc = "Open floating file explorer" }
)
