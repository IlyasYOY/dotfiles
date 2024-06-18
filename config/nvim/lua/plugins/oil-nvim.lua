local function get_git_ignored_files_in(dir)
    local found = vim.fs.find(".git", {
        upward = true,
        path = dir,
    })
    if #found == 0 then
        return {}
    end

    local cmd = string.format(
        'git -C %s ls-files --ignored --exclude-standard --others --directory | grep -v "/.*\\/"',
        dir
    )

    local handle = io.popen(cmd)
    if handle == nil then
        return
    end

    local ignored_files = {}
    for line in handle:lines "*l" do
        line = line:gsub("/$", "")
        table.insert(ignored_files, line)
    end
    handle:close()

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

return {
    {
        "stevearc/oil.nvim",
        config = function()
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
                        local ignored_files = cached_get_git_ignored_files_in(
                            oil.get_current_dir()
                        )
                        return vim.tbl_contains(ignored_files, name)
                            or vim.startswith(name, ".")
                    end,
                },
            }
            vim.keymap.set("n", "-", "<cmd>Oil<CR>")
            vim.keymap.set("n", "<leader>e", "<cmd>Oil<CR>")
            vim.keymap.set("n", "<leader>E", "<cmd>Oil --float<CR>")
        end,
    },
}
