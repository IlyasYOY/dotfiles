" Vim compiler file
" Compiler:     OpenCode review

if exists("current_compiler") | finish | endif
let current_compiler = "opencodereview"

let s:cpo_save = &cpo
set cpo&vim

CompilerSet makeprg=opencode\ run\ --command\ review

let s:errorformat = [
            \ "%f:%l: %t%*[^:]: %m",
            \ "%f:%l: %m",
            \ "%-GNO FINDINGS",
            \ "%-G%.%#",
            \ ]
execute "CompilerSet errorformat=" .. escape(join(s:errorformat, ","), ' \|"')

let &cpo = s:cpo_save
unlet s:cpo_save
unlet s:errorformat
