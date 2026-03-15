local gh = function(x)
    return "https://github.com/" .. x
end

local noop = function() end

-- Dev plugins: use local path if it exists, else fall back to GitHub.
local function ilyasyoy(name)
    local local_path = vim.fn.expand("~/Projects/IlyasYOY/" .. name)
    if vim.fn.isdirectory(local_path) == 1 then
        return { src = "file://" .. local_path, name = name }
    else
        return gh("IlyasYOY/" .. name)
    end
end

local callbacks = {}
local command_stubs = {}
local loaded = {}
local loading = {}

local function replay_command(name, cmdargs)
    local prefix = ""
    if cmdargs.range > 0 then
        if cmdargs.line1 == cmdargs.line2 then
            prefix = tostring(cmdargs.line1)
        else
            prefix = string.format("%d,%d", cmdargs.line1, cmdargs.line2)
        end
    end

    local command = prefix .. name
    if cmdargs.bang then
        command = command .. "!"
    end

    local parts = { command }
    if cmdargs.mods ~= "" then
        table.insert(parts, 1, cmdargs.mods)
    end
    if cmdargs.args ~= "" then
        table.insert(parts, cmdargs.args)
    end

    vim.cmd(table.concat(parts, " "))
end

local function clear_command_stubs(group)
    local names = command_stubs[group]
    if not names then
        return
    end

    for name in pairs(names) do
        pcall(vim.api.nvim_del_user_command, name)
    end

    command_stubs[group] = nil
end

local function spec_name(spec)
    if type(spec) == "table" then
        if spec.name then
            return spec.name
        end

        spec = spec.src
    end

    return vim.fs.basename(spec):gsub("%.git$", "")
end

local M = {
    specs = {
        core = {
            -- Dev (own) plugins
            ilyasyoy "theme.nvim",

            -- Colors
            gh "norcalli/nvim-colorizer.lua",
            gh "f-person/auto-dark-mode.nvim",

            -- Navigation & file management
            gh "christoomey/vim-tmux-navigator",

            -- UI
            gh "nvim-lualine/lualine.nvim",
            gh "mbbill/undotree",

            -- Snippets
            gh "L3MON4D3/LuaSnip",

            -- LSP
            gh "neovim/nvim-lspconfig",

            -- Mason (LSP/tool installer)
            gh "williamboman/mason.nvim",
            gh "WhoIsSethDaniel/mason-tool-installer.nvim",

            -- Treesitter
            gh "nvim-treesitter/nvim-treesitter",
            {
                src = gh "nvim-treesitter/nvim-treesitter-textobjects",
                version = "main",
            },
            gh "nvim-treesitter/nvim-treesitter-context",

            -- Utilities
            gh "nvim-lua/plenary.nvim",

            -- Text manipulation
            gh "tpope/vim-abolish",
        },
        fzf_lua = {
            gh "ibhagwan/fzf-lua",
        },
        oil = {
            gh "stevearc/oil.nvim",
        },
        dap = {
            gh "mfussenegger/nvim-dap",
            gh "theHamsta/nvim-dap-virtual-text",
            gh "rcarriga/nvim-dap-ui",
            gh "nvim-neotest/nvim-nio",
        },
        dap_go = {
            gh "leoluz/nvim-dap-go",
        },
        dap_python = {
            gh "mfussenegger/nvim-dap-python",
        },
        jdtls = {
            gh "mfussenegger/nvim-jdtls",
        },
        dadbod = {
            gh "tpope/vim-dadbod",
            gh "kristijanhusak/vim-dadbod-completion",
            gh "kristijanhusak/vim-dadbod-ui",
        },
        git_tools = {
            gh "tpope/vim-dispatch",
            gh "shumphrey/fugitive-gitlab.vim",
            gh "tommcdo/vim-fubitive",
            gh "tpope/vim-rhubarb",
            gh "tpope/vim-fugitive",
        },
        copilot = {
            gh "zbirenbaum/copilot.lua",
            -- This plugin is required for NES support.
            -- I don't use NES, but I include it anyway.
            gh "copilotlsp-nvim/copilot-lsp",
        },
        obs = {
            ilyasyoy "obs.nvim",
        },
    },
}

function M.no_load()
    return { load = noop }
end

function M.on_load(group, callback)
    if loaded[group] then
        callback()
        return
    end

    callbacks[group] = callbacks[group] or {}
    table.insert(callbacks[group], callback)
end

function M.load(group)
    if loaded[group] then
        return
    end
    if loading[group] then
        return
    end

    local specs = M.specs[group]
    if not specs then
        error("Unknown vim.pack group: " .. group)
    end

    loading[group] = true
    clear_command_stubs(group)

    local ok, err = pcall(function()
        for _, spec in ipairs(specs) do
            vim.cmd("packadd " .. spec_name(spec))
        end
    end)
    loading[group] = nil
    if not ok then
        error(err)
    end

    loaded[group] = true
    for _, callback in ipairs(callbacks[group] or {}) do
        callback()
    end
end

function M.wrap(group, callback)
    return function(...)
        M.load(group)
        return callback(...)
    end
end

function M.lazy_user_command(group, name, opts)
    command_stubs[group] = command_stubs[group] or {}
    command_stubs[group][name] = true

    vim.api.nvim_create_user_command(name, function(cmdargs)
        M.load(group)
        replay_command(name, cmdargs)
    end, opts or { nargs = "*" })
end

return M
