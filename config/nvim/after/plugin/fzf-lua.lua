local pack = require "ilyasyoy.pack"
local core = require "ilyasyoy.functions.core"

pack.on_load("fzf_lua", function()
    local fzf = require "fzf-lua"
    fzf.setup {}
    fzf.register_ui_select()
end)

local function with_fzf(callback)
    return pack.wrap("fzf_lua", function()
        local fzf = require "fzf-lua"
        local fzf_utils = require "fzf-lua.utils"
        return callback(fzf, fzf_utils)
    end)
end

vim.keymap.set(
    "n",
    "<leader>fr",
    with_fzf(function(fzf)
        fzf.resume()
    end),
    { desc = "find resume" }
)

vim.keymap.set(
    "n",
    "<leader>ff",
    with_fzf(function(fzf)
        fzf.files()
    end),
    { desc = "find files" }
)

vim.keymap.set(
    "n",
    "<leader>fF",
    with_fzf(function(fzf)
        fzf.files {
            cwd = core.string_strip_prefix(vim.fn.expand "%:p:h", "oil://"),
        }
    end),
    { desc = "find files in current dir" }
)

vim.keymap.set(
    "n",
    "<leader>fg",
    with_fzf(function(fzf)
        fzf.live_grep()
    end),
    { desc = "find grep through files" }
)

vim.keymap.set(
    "v",
    "<leader>fg",
    with_fzf(function(fzf, fzf_utils)
        fzf.live_grep {
            search = fzf_utils.get_visual_selection(),
        }
    end),
    { desc = "find grep through files for selection" }
)

vim.keymap.set(
    "n",
    "<leader>fG",
    with_fzf(function(fzf)
        fzf.live_grep {
            cwd = core.string_strip_prefix(vim.fn.expand "%:p:h", "oil://"),
        }
    end),
    { desc = "find files in current dir" }
)

vim.keymap.set(
    "v",
    "<leader>fG",
    with_fzf(function(fzf, fzf_utils)
        fzf.live_grep {
            cwd = core.string_strip_prefix(vim.fn.expand "%:p:h", "oil://"),
            search = fzf_utils.get_visual_selection(),
        }
    end),
    { desc = "find files in current dir for selection" }
)

vim.keymap.set(
    "n",
    "<leader>fa",
    "<cmd>FzfLua<cr>",
    { desc = "find in commands" }
)

vim.keymap.set(
    "n",
    "<leader>fq",
    with_fzf(function(fzf)
        fzf.quickfix()
    end),
    { desc = "find in quickfix" }
)

vim.keymap.set(
    "n",
    "<leader>fQ",
    with_fzf(function(fzf)
        fzf.quickfix_stack()
    end),
    { desc = "find in quickfix stack" }
)

vim.keymap.set(
    "n",
    "<leader>fl",
    with_fzf(function(fzf)
        fzf.loclist()
    end),
    { desc = "find in loc list" }
)

vim.keymap.set(
    "n",
    "<leader>fL",
    with_fzf(function(fzf)
        fzf.loclist()
    end),
    { desc = "find in loc list stack" }
)

vim.keymap.set(
    "n",
    "<leader>fs",
    with_fzf(function(fzf)
        fzf.lsp_document_symbols()
    end),
    { desc = "find document symbols" }
)

vim.keymap.set(
    "n",
    "<leader>fS",
    with_fzf(function(fzf)
        fzf.lsp_live_workspace_symbols()
    end),
    { desc = "find workspace symbols" }
)

vim.keymap.set(
    "n",
    "<leader>fd",
    with_fzf(function(fzf)
        fzf.diagnostics_document()
    end),
    { desc = "find document diagnostics" }
)

vim.keymap.set(
    "n",
    "<leader>fD",
    with_fzf(function(fzf)
        fzf.diagnostics_workspace()
    end),
    { desc = "find workspace diagnostics" }
)

vim.keymap.set(
    "n",
    "<leader>fm",
    with_fzf(function(fzf)
        fzf.marks()
    end),
    { desc = "find marks" }
)

vim.keymap.set(
    "n",
    "<leader>fh",
    with_fzf(function(fzf)
        fzf.helptags()
    end),
    { desc = "find help tags" }
)

vim.keymap.set(
    "n",
    "<leader>fB",
    with_fzf(function(fzf)
        fzf.buffers()
    end),
    { desc = "find buffers" }
)

vim.keymap.set(
    "n",
    "<leader>fbl",
    with_fzf(function(fzf)
        fzf.blines()
    end),
    { desc = "find buffer lines" }
)

vim.keymap.set(
    "n",
    "<leader>fbt",
    with_fzf(function(fzf)
        fzf.treesitter()
    end),
    { desc = "find buffer treesitter" }
)

vim.keymap.set(
    "n",
    "<leader>gfs",
    with_fzf(function(fzf)
        fzf.git_status()
    end)
)
