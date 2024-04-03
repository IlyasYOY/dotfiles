vim.opt_local.spell = true
vim.opt_local.wrap = true

local status, obs = pcall(require, "obs")
if not status then
    return
end

if obs.vault:is_current_buffer_in_vault() then
    require("cmp").setup.buffer {
        sources = require("cmp").config.sources(
            { { name = "obs", max_item_count = 5000 } },
            { { name = "luasnip" } },
            { { name = "buffer" } }
        ),
    }
end
