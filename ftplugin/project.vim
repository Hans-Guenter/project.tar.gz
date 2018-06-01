if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1
let b:variablemessage="Variables \"g:project_current_filelist\" and \"g:project_current_existing_filelist\" populated."
set formatoptions-=a
set formatoptions+=l
set textwidth=0
set wrapmargin=0

if ( !exists("*ProjectGetFileNames"))
  fun! s:ProjectGetFileNames(recur)
    let g:project_current_filelist=map(map(split(Project_GetAllFnames(a:recur,line("."),";"), ";"),"expand(v:val)"),"fnamemodify(v:val,\":p\")")
    let g:project_current_existing_filelist=filter(map(copy(g:project_current_filelist),'filereadable(escape(v:val,"\\ "))?(v:val):""'),'v:val!~"^\s*$"')
  endfun
endif

if ( !exists("*ProjectGetExistingFileNames"))
  fun! s:ProjectGetExistingFileNames(recur)
  	call s:ProjectGetFileNames(a:recur)
    let @*=join(g:project_current_existing_filelist,"\n")
    echomsg b:variablemessage . "(recur = " . a:recur . ", @* = g:project_current_existing_filelist)"
  endfun
endif

if ( !exists("*ProjectGetAllFileNames"))
  fun! s:ProjectGetAllFileNames(recur)
  	call s:ProjectGetFileNames(a:recur)
    let @*=join(g:project_current_filelist,"\n")
    echomsg b:variablemessage . "(recur = " . a:recur . ", @* = g:project_current_filelist)"
  endfun
endif

if ( !exists("*ProjectGrepTODOInAllFileNames"))
  fun! s:ProjectGrepTODOInAllFileNames()
  	call s:ProjectGetFileNames(1)
  	if exists("g:tlTokenList")
  	  let sstring="\\(" . join(g:tlTokenList,"\\|") ."\\)"
  	else
  	  let sstring="todo"
    endif
		let xxcmd = 'silent! noau vimgrep /' . sstring . '/j ' . expand("%") . ' ' . join(g:project_current_existing_filelist, ' ') . '|cw'
		" echomsg xxcmd
		" silent! exe xxcmd
		exe xxcmd
		" exe bufwinnr(g:proj_running) . "wincmd w"
		" hide
		cclose
		normal ,p
		copen
  endfun
endif

if ( !exists("*Project_Balloonexpr"))
  function! Project_Balloonexpr()
    return Project_GetFname(v:beval_lnum)
  endfunction
endif
setlocal balloonexpr=Project_Balloonexpr()

command! -nargs=1 ProjectGetAllFileNames call <SID>ProjectGetAllFileNames(<q-args>)
command! -nargs=1 ProjectGetExistingFileNames call <SID>ProjectGetExistingFileNames(<q-args>)
"		Workaround by calling ws because function ProjectGrepTODOInAllFileNames sometimes bails out when executing xxcmd
command! -nargs=0 ProjectGrepTODOInAllFileNames call <SID>ProjectGrepTODOInAllFileNames()<bar>cw

imap <buffer> <localleader>a <c-\><c-n>:ProjectGetAllFileNames 0<Cr>
nmap <buffer> <localleader>a :ProjectGetAllFileNames 0<Cr>
imap <buffer> <localleader>A <c-\><c-n>:ProjectGetAllFileNames 1<Cr>
nmap <buffer> <localleader>A :ProjectGetAllFileNames 1<Cr>

imap <buffer> <localleader>xa <c-\><c-n>:ProjectGetExistingFileNames 0<Cr>
nmap <buffer> <localleader>xa :ProjectGetExistingFileNames 0<Cr>

imap <buffer> <localleader>xA <c-\><c-n>:ProjectGetExistingFileNames 1<Cr>
nmap <buffer> <localleader>xA :ProjectGetExistingFileNames 1<Cr>
imap <buffer> <localleader>XA <c-\><c-n>:ProjectGetExistingFileNames 1<Cr>
nmap <buffer> <localleader>XA :ProjectGetExistingFileNames 1<Cr>

call arpeggio#map('n', 'b', 1, ',.', ':ProjectGrepTODOInAllFileNames<CR>')
call arpeggio#map('i', 'b', 1, ',.', '<Esc>:ProjectGrepTODOInAllFileNames<CR>')
call arpeggio#map('n', 'b', 1, '^.', ':ProjectGrepTODOInAllFileNames<CR>')
call arpeggio#map('i', 'b', 1, '^.', '<Esc>:ProjectGrepTODOInAllFileNames<CR>')
