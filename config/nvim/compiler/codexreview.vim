" Vim compiler file
" Compiler:     Codex review

if exists("current_compiler") | finish | endif
let current_compiler = "codexreview"

let s:cpo_save = &cpo
set cpo&vim

CompilerSet makeprg=codex\ review

let s:errorformat = [
            \ "%W%*[^P]P%n%*[^ ] %m %*[^/]%f:%l-%e",
            \ "%W%*[^P]P%n%*[^ ] %m %*[^/]%f:%l",
            \ "%C  %m",
            \ "%-G%.%#",
            \ ]
execute "CompilerSet errorformat=" .. escape(join(s:errorformat, ","), ' \|"')

let &cpo = s:cpo_save
unlet s:cpo_save
unlet s:errorformat
