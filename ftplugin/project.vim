if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1
let b:variablemessage="Variables \"g:project_current_filelist\" and \"g:project_current_existing_filelist\" populated."
setlocal formatoptions-=a
setlocal formatoptions+=l
setlocal textwidth=0
setlocal wrapmargin=0
setlocal winfixwidth
" From DoSetup
setlocal foldenable foldmethod=marker foldmarker={,} commentstring=%s foldcolumn=0 nonumber noswapfile shiftwidth=1
setlocal foldtext=Project#ProjFoldText() nobuflisted nowrap
setlocal winwidth=1
setlocal conceallevel=2
if match(g:proj_flags, '\Cn') != -1
    setlocal number
endif

" From "C:\vim\vimfiles\ftplugin\project.vim" Begin

if !exists('g:proj_window_width')
    let g:proj_window_width=24              " Default project window width
endif
if !exists('g:proj_window_increment')
    let g:proj_window_increment=100         " Project Window width increment
endif
if !exists('g:proj_flags')
    if has("win32") || has("mac")
        let g:proj_flags='imst'             " Project default flags for windows/mac
    else
        let g:proj_flags='imstb'            " Project default flags for everything else
    endif
endif

" Process the flags
let b:proj_cd_cmd='cd'
if match(g:proj_flags, '\Cl') != -1
    let b:proj_cd_cmd = 'lcd'
endif

let b:proj_locate_command='silent! wincmd H'
let b:proj_resize_command='exec ''vertical resize ''.g:proj_window_width'
if match(g:proj_flags, '\CF') != -1         " Set the resize commands to nothing
    let b:proj_locate_command=''
    let b:proj_resize_command=''
endif

setlocal balloonexpr=Project#Balloonexpr()

command! -nargs=1 ProjectGetAllFileNames call Project#ProjectGetAllFileNames(<q-args>)
command! -nargs=1 ProjectGetExistingFileNames call Project#ProjectGetExistingFileNames(<q-args>)
"		Workaround by calling ws because function ProjectGrepTODOInAllFileNames sometimes bails out when executing xxcmd
command! -nargs=0 ProjectGrepTODOInAllFileNames call Project#ProjectGrepTODOInAllFileNames()<bar>cw

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
" From "C:\vim\vimfiles\ftplugin\project.vim" End
"
" From "~\.vimproject_mappings"" Begin
nnoremap <buffer> <silent> <LocalLeader>I :let @*="\"".expand(Project#GetFname(line('.')))."\""\|echo @*<Cr>
nnoremap <buffer> <silent> <LocalLeader>st :exe "sil! !start /b cmd /c ".shellescape(expand(Project#GetFname(line('.'))),1)<Cr>
nnoremap <buffer> <silent> t :exe "tab new ".Project#GetFname(line('.'))<Cr>

" Mappings from the Project#Project function
nnoremap <buffer> <silent> <c-f9>  \|:call hgsutils#ToggleFoldmethod()<CR>
inoremap <buffer> <silent> <c-f9>  <Esc>:call hgsutils#ToggleFoldmethod()<CR>a
nnoremap <buffer> <silent> <Return>   \|:call Project#DoFoldOrOpenEntry('', 'e')<CR>
nnoremap <buffer> <silent> <S-Return> \|:call Project#DoFoldOrOpenEntry('', 'sp')<CR>
nnoremap <buffer> <silent> <C-Return> \|:call Project#DoFoldOrOpenEntry('silent! only', 'e')<CR>
nnoremap <buffer> <silent> <LocalLeader>T \|:call Project#DoFoldOrOpenEntry('', 'tabe')<CR>
nmap     <buffer> <silent> <LocalLeader>s <S-Return>
nnoremap <buffer> <silent> <LocalLeader>S \|:call Project#LoadAllSplit(0, line('.'))<CR>
nmap     <buffer> <silent> <LocalLeader>o <C-Return>
nnoremap <buffer> <silent> <LocalLeader>i :echo Project#RecursivelyConstructDirectives(line('.'))<CR>
" nnoremap <buffer> <silent> <LocalLeader>I :echo Project#GetFname(line('.'))<CR>
" nmap     <buffer> <silent> <M-CR> <Return><C-W>p
nnoremap <buffer> <silent> <M-CR> :exe "botright new ".Project#GetFname(line('.'))<Cr><C-W>p
nmap     <buffer> <silent> <LocalLeader>v <M-CR>
nmap     <buffer> <silent> d<Cr> <M-CR>
nnoremap <buffer> <silent> <LocalLeader>l \|:call Project#LoadAll(0, line('.'))<CR>
nnoremap <buffer> <silent> <LocalLeader>L \|:call Project#LoadAll(1, line('.'))<CR>
nnoremap <buffer> <silent> <LocalLeader>w \|:call Project#WipeAll(0, line('.'))<CR>
nnoremap <buffer> <silent> <LocalLeader>W \|:call Project#WipeAll(1, line('.'))<CR>
nnoremap <buffer> <silent> <LocalLeader>W \|:call Project#WipeAll(1, line('.'))<CR>
nnoremap <buffer> <silent> <LocalLeader>g \|:call Project#GrepAll(0, line('.'), "")<CR>
nnoremap <buffer> <silent> <LocalLeader>G \|:call Project#GrepAll(1, line('.'), "")<CR>
nnoremap <buffer> <silent> <LocalLeader>j \|:call Project#GrepAll(0, line('.'), @/)<CR>
nnoremap <buffer> <silent> <LocalLeader>J \|:call Project#GrepAll(1, line('.'), @/)<CR>
nnoremap <buffer> <silent> <2-LeftMouse>   \|:call Project#DoFoldOrOpenEntry('', 'e')<CR>
nnoremap <buffer> <silent> <S-2-LeftMouse> \|:call Project#DoFoldOrOpenEntry('', 'sp')<CR>
nnoremap <buffer> <silent> <M-2-LeftMouse> <M-CR>
nnoremap <buffer> <silent> <S-LeftMouse>   <LeftMouse>
nmap     <buffer> <silent> <C-2-LeftMouse> <C-Return>
nnoremap <buffer> <silent> <C-LeftMouse>   <LeftMouse>
nnoremap <buffer> <silent> <3-LeftMouse>  <Nop>
nmap     <buffer> <silent> <RightMouse>   <space>
nmap     <buffer> <silent> <2-RightMouse> <space>
nmap     <buffer> <silent> <3-RightMouse> <space>
nmap     <buffer> <silent> <4-RightMouse> <space>
nnoremap <buffer> <silent> <space>  \|:silent exec 'vertical resize '.(match(g:proj_flags, '\Ct')!=-1 && winwidth('.') > g:proj_window_width?(g:proj_window_width):(winwidth('.') + g:proj_window_increment))<CR>
nnoremap <buffer> <silent> <C-Up>   \|:silent call Project#MoveUp()<CR>
nnoremap <buffer> <silent> <C-Down> \|:silent call Project#MoveDown()<CR>
nmap     <buffer> <silent> <LocalLeader><Up> <C-Up>
nmap     <buffer> <silent> <LocalLeader><Down> <C-Down>
let k=1
while k < 10
    exec 'nnoremap <buffer> <LocalLeader>'.k.'  \|:call Project#Spawn('.k.')<CR>'
    exec 'nnoremap <buffer> <LocalLeader>f'.k.' \|:call Project#SpawnAll(0, '.k.')<CR>'
    exec 'nnoremap <buffer> <LocalLeader>F'.k.' \|:call Project#SpawnAll(1, '.k.')<CR>'
    let k=k+1
endwhile
nnoremap <buffer>          <LocalLeader>0 \|:call Project#ListSpawn("")<CR>
nnoremap <buffer>          <LocalLeader>f0 \|:call Project#ListSpawn("_fold")<CR>
nnoremap <buffer>          <LocalLeader>F0 \|:call Project#ListSpawn("_fold")<CR>
nnoremap <buffer> <silent> <LocalLeader>c :call Project#CreateEntriesFromDir(0)<CR>
nnoremap <buffer> <silent> <LocalLeader>C :call Project#CreateEntriesFromDir(1)<CR>
nnoremap <buffer> <silent> <LocalLeader>r :call Project#RefreshEntriesFromDir(0)<CR>
nnoremap <buffer> <silent> <LocalLeader>R :call Project#RefreshEntriesFromDir(1)<CR>
" For Windows users: same as \R
" hgs Collides with my F5 mappings for folding
" nnoremap <buffer> <silent>           <F5> :call Project#RefreshEntriesFromDir(1)<CR>
nnoremap <buffer> <silent> <LocalLeader>e :call Project#OpenEntry(line('.'), '', '', 0)<CR>
nnoremap <buffer> <silent> <LocalLeader>E :call Project#OpenEntry(line('.'), '', 'e', 1)<CR>
" The :help command stomps on the Project Window.  Try to avoid that.
" This is not perfect, but it is alot better than without the mappings.
cnoremap <buffer> help let g:proj_doinghelp = 1<CR>:help
nnoremap <buffer> <F1> :let g:proj_doinghelp = 1<CR><F1>
" This is to avoid changing the buffer, but it is not fool-proof.
nnoremap <buffer> <silent> <C-^> <Nop>
"nnoremap <script> <Plug>ProjectOnly :let lzsave=&lz<CR>:set lz<CR><C-W>o:Project<CR>:silent! wincmd p<CR>:let &lz=lzsave<CR>:unlet lzsave<CR>
nnoremap <script> <Plug>ProjectOnly :call Project#DoProjectOnly()<CR>
if match(g:proj_flags, '\Cm') != -1
    if !hasmapto('<Plug>ProjectOnly')
        nmap <silent> <unique> <C-W>o <Plug>ProjectOnly
        nmap <silent> <unique> <C-W><C-O> <C-W>o
    endif
endif " >>>
" if filereadable(glob('~/.vimproject_mappings')) | source ~/.vimproject_mappings | endif

sil so ~/book_Marks_Project.vim|exe "silent! so ".expand("%:p:r")."_book_marks.vim"
exe "silent! so ".expand("%:p:r")."_config.vim"

augroup Project
	autocmd!
  " autocmd FileType Project sil so ~/book_Marks_Project.vim|exe "silent! so ".expand("%:p:r")."_book_marks.vim"
  " autocmd FileType Project exe "silent! so ".expand("%:p:r")."_config.vim"
  autocmd BufLeave *.vpj if &filetype == 'Project'|let b:vop_save=&vop|set vop-=options|mkview!|let &vop=b:vop_save|unlet b:vop_save|endif
  " autocmd BufWinEnter,BufEnter *.vim if &filetype == 'Project'|silent loadview|set isf-=32|set fcl=|set fdo+=search|exe 'normal z.'|endif
  autocmd BufWinEnter,BufEnter *.vpj if &filetype == 'Project'|set isf-=32|set fcl=|set fdo+=search|exe 'normal z.'|endif
augroup End

" Streamline space mapping with general map <space> za

nun 	<buffer> <silent> <RightMouse>
nun 	<buffer> <silent> <2-RightMouse>
nun 	<buffer> <silent> <3-RightMouse>
nun 	<buffer> <silent> <4-RightMouse>
nun 	<buffer> <silent> <space>

nmap     <buffer> <silent> <RightMouse>   <S-space>
nmap     <buffer> <silent> <2-RightMouse> <S-space>
nmap     <buffer> <silent> <3-RightMouse> <S-space>
nmap     <buffer> <silent> <4-RightMouse> <S-space>
nnoremap <buffer> <silent> <S-space>  \|:silent exec 'vertical resize '.(match(g:proj_flags, '\Ct')!=-1 && winwidth('.') > g:proj_window_width?(g:proj_window_width):(winwidth('.') + g:proj_window_increment))<CR>

nnoremap <buffer> <silent> q :call Project#DoToggleProject()<CR> 
" From "~\.vimproject_mappings"" End
