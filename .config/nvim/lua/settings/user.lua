local mapping = require "functions/map"

local map_terminal = mapping.map_terminal

-- Terminal commands
map_terminal("<Esc>", "<C-\\><C-n>")

vim.g.netrw_banner = 0 -- Now we won't have bloated top of the window
vim.g.netrw_liststyle = 3 -- Now it will be a tree view
vim.g.netrw_bufsettings = "nu nobl"

vim.cmd "source ~/.vimrc"

vim.cmd "colorscheme gruvbox"

-- Spelling

vim.cmd [[
set spelllang=ru_ru,en_us
set spellfile=~/.config/nvim/spell/custom.utf-8.add
]]

vim.keymap.set("n", "<leader>sc", function()
    vim.opt_local.spell = not (vim.opt_local.spell:get())
    print("spell: " .. tostring(vim.o.spell))
end)

vim.cmd [[
set langmap=йq,цw,уe,кr,еt,нy,гu,шi,щo,зp,х[,ъ],фa,ыs,вd,аf,пg,рh,оj,лk,дl,ж\\;,э',ё\\,яz,чx,сc,мv,иb,тn,ьm,б\\,,ю.,ЙQ,ЦW,УE,КR,ЕT,НY,ГU,ШI,ЩO,ЗP,Х{,Ъ},ФA,ЫS,ВD,АF,ПG,РH,ОJ,ЛK,ДL,Ж:,Э\\",ЯZ,ЧX,СC,МV,ИB,ТN,ЬM,Б<,Ю>,Ё/|
imap <C-ц> <C-w>
]]
