vim.opt_local.spell = true

local obs = require "obs"
if obs.vault:is_current_buffer_in_vault() then
    require("cmp").setup.buffer {
        sources = require("cmp").config.sources(
            { { name = "obs", max_item_count = 5000 } },
            { { name = "luasnip" } },
            { { name = "buffer" } }
        ),
    }
end
