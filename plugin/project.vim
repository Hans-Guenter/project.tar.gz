"=============================================================================
" File:        project.vim
" Author:      Aric Blumer (Aric.Blumer at aricvim@charter.net)
" Last Change: Fri 13 Oct 2006 09:47:08 AM EDT
" Version:     1.4.1
"=============================================================================
" See documentation in accompanying help file
" You may use this code in whatever way you see fit.

if exists('loaded_project') || &cp
  finish
endif
let loaded_project=1


if exists(':Project') != 2
    command -nargs=? -complete=file Project call Project#Project('<args>')
endif
" Toggle Mapping
nnoremap <script> <Plug>ToggleProject :call Project#DoToggleProject()<CR>
if exists('g:proj_flags') && (match(g:proj_flags, '\Cg') != -1)
    if !hasmapto('<Plug>ToggleProject')
        nmap <silent> <F12> <Plug>ToggleProject
    endif
endif
