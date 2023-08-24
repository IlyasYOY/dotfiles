require "ilyasyoy.plugins"

require "ilyasyoy"
require "ilyasyoy.global"

require "ilyasyoy.mapping"

-- Here I load files with custom settings for machine.
-- This lua file is hidden from VCS, so I can do tricky stuff there.
pcall(require, "ilyasyoy.hidden")
