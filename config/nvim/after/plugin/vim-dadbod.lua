vim.api.nvim_create_autocmd("FileType", {
    pattern = "sql",
    callback = function(args)
        vim.bo[args.buf].omnifunc = "vim_dadbod_completion#omni"
    end,
})

-- Mirrors kb-link/kb-note in sh/helpers.sh: resolve the kb-store notes dir
-- for the current git repo/branch (projector worktrees included) and use it
-- as the dadbod-ui save location. Falls back to <cwd>/sql/ outside $HOME/git.
local function db_ui_save_location()
    local kb_dir = vim.env.ILYASYOY_KB_STORE_DIR
        or (vim.env.HOME .. "/Projects/kb-store")

    local function realpath(path)
        return vim.uv.fs_realpath(path) or path
    end

    local function run(cmd)
        local r = vim.system(cmd, { text = true }):wait()
        if r.code ~= 0 then
            return nil
        end
        return (r.stdout or ""):gsub("%s+$", "")
    end

    local function fallback()
        local path = vim.fn.getcwd() .. "/sql/"
        vim.fn.mkdir(path, "p")
        return path
    end

    if vim.fn.isdirectory(kb_dir) == 0 then
        return fallback()
    end

    -- main_root: main repo root (projector worktree-aware via
    -- --git-common-dir), else physical cwd. Mirrors _kb_main_root.
    local common = run { "git", "rev-parse", "--git-common-dir" }
    local main_root
    if common and common ~= "" then
        local abs_common = vim.uv.fs_realpath(common)
        if abs_common then
            main_root = vim.fn.fnamemodify(abs_common, ":h")
        else
            main_root = realpath(vim.fn.getcwd())
        end
    else
        main_root = realpath(vim.fn.getcwd())
    end

    local home_phy = realpath(vim.env.HOME)
    local rel_path
    if main_root == home_phy then
        return fallback()
    elseif vim.startswith(main_root, home_phy .. "/") then
        rel_path = main_root:sub(#home_phy + 1)
    else
        return fallback()
    end

    local branch = run { "git", "branch", "--show-current" }
    if not branch or branch == "" then
        branch = "master"
    end
    branch = branch:gsub("/", "-")

    local path = kb_dir .. rel_path .. "/branch-" .. branch .. "/sql/"
    vim.fn.mkdir(path, "p")
    return path
end

vim.g.db_ui_save_location = db_ui_save_location()

vim.g.db_ui_table_helpers = {
    postgresql = {
        ["Table Size"] = [[
select
    table_name,
    pg_size_pretty(pg_total_relation_size(quote_ident(table_name))),
    pg_total_relation_size(quote_ident(table_name))
from information_schema.tables
where table_schema = 'public'
    and table_name = '{table}';
]],
        ["Count"] = [[
select count(*) from {table};
]],
    },
}
