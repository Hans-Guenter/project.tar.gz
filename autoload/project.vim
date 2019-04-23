"=============================================================================
" File:        project.vim
" Author:      Aric Blumer (Aric.Blumer at aricvim@charter.net)
" Last Change: Fri 13 Oct 2006 09:47:08 AM EDT
" Version:     1.4.1
"=============================================================================
" See documentation in accompanying help file
" You may use this code in whatever way you see fit.

" Initialization <<<
function! Project#Project(filename) " <<<
    set lazyredraw
		" let l:foldenable = &l:foldenable
		"DONE saving views currently disabled
  	" let l:save_view = winsaveview()
		" setlocal nofoldenable
    if exists("g:proj_running")
        if strlen(a:filename) != 0
            call confirm('Project already loaded; ignoring filename "'.a:filename."\".\n".'See ":help project-invoking" for information about changing project files.', "&OK", 1)
        endif
        let filename=bufname(g:proj_running)
    else
        if strlen(a:filename) == 0
            if exists("g:proj_file") && strlen(g:proj_file) > 0
                let filename = g:proj_file      " Global project file variable
            else
                let filename ='~/.vimprojects'  " Default project filename
            endif
        else
            let filename = a:filename
        endif
    endif
    if !exists("g:proj_running") || (bufwinnr(g:proj_running) == -1) " Open the Project Window
    	  if !filereadable(filename)
    	  	call s:ReverseStart()
    			" TODO Error message disappears
    	  	call confirm ("Project file " . filename . " does not exist!", "&oK", 1)
    	  	return
				endif
        exec 'silent leftabove vertical new '.filename
        if match(g:proj_flags, '\CF') == -1      " We're floating
            silent! wincmd H
            exec 'leftabove vertical resize '.g:proj_window_width
        endif
        setlocal nomodeline
    else
        silent! 99wincmd h
        if bufwinnr(g:proj_running) == -1
            leftabove vertical split
            let v:errmsg="nothing"
            silent! bnext
            if 'nothing' != v:errmsg
                enew
            endif
        endif
        call s:ReverseStart()
        return
    endif

    let g:proj_last_buffer = -1
    ">>>
    if !exists("g:proj_running")
        " Autocommands <<<
        " Autocommands to clean up if we do a buffer wipe
        " These don't work unless we substitute \ for / for Windows
        let bufname=escape(substitute(expand('%:p', 0), '\\', '/', 'g'), ' ')
        exec 'au BufWipeout '.bufname.' au! * '.bufname
        exec 'au BufWipeout '.bufname.' unlet g:proj_running'
        exec 'au BufWipeout '.bufname.' nunmap <C-W>o'
        exec 'au BufWipeout '.bufname.' nunmap <C-W><C-O>'
        " Autocommands to keep the window the specified size
        exec 'au WinLeave '.bufname.' call Project#DoEnsurePlacementSize_au()'
        exec 'au BufEnter '.bufname.' call Project#DoSetupAndSplit_au()'
        au WinLeave * call Project#RecordPrevBuffer_au()
        " >>>
        setlocal buflisted
        silent loadview
        let g:proj_running = bufnr(bufname.'\>')
        if g:proj_running == -1
            call confirm('Project/Vim error. Please Enter :Project again and report this bug.', "&OK", 1)
            unlet g:proj_running
        endif
        doautocmd BufEnter
        setlocal nobuflisted
    endif
    call s:ReverseStart()
endfunction " >>>
" DoProjectOnly() <<<
function! Project#DoProjectOnly()
		if winbufnr(0) != g:proj_running
				" let lzsave=&lz
				" set lz
				" only
				Project
				" silent! wincmd p
				" let &lz=lzsave
				" unlet lzsave
		endif
endfunction " >>>
" ProjFoldText() <<<
"   The foldtext function for displaying just the description.
function! Project#ProjFoldText()
    let line=substitute(getline(v:foldstart),'^[ \t#]*\([^=]*\)[^#]*#\?\s*\(.*\)', '\1   # \2', '')
    let line=substitute(line,'#\?\s*$', '', '')
    let line=substitute(line,'{\s*#', '  #', '')
    let line=strpart('                                     ', 0, (v:foldlevel - 1)).substitute(line,'\s*{\+\s*', '', '')
    return line
endfunction ">>>
" Change to avoid conflict with utl plugin HS 22.12.2006
" if match(g:proj_flags, '\Cs')!=-1 && has('syntax') && exists('g:syntax_on') && !has('syntax_items')
" Project#SortR(start, end) <<<
" Sort lines.  SortR() is called recursively.
"  from ":help eval-examples" by Robert Webb, slightly modified
function! Project#SortR(start, end)
    if (a:start >= a:end)
        return
    endif
    let partition = a:start - 1
    let middle = partition
    let partStr = getline((a:start + a:end) / 2)
    let i = a:start
    while (i <= a:end)
        let str = getline(i)
        if str < partStr
            let result = -1
        elseif str > partStr
            let result = 1
        else
            let result = 0
        endif
        if (result <= 0)
            let partition = partition + 1
            if (result == 0)
                let middle = partition
            endif
            if (i != partition)
                let str2 = getline(partition)
                call setline(i, str2)
                call setline(partition, str)
            endif
        endif
        let i = i + 1
    endwhile
    if (middle != partition)
        let str = getline(middle)
        let str2 = getline(partition)
        call setline(middle, str2)
        call setline(partition, str)
    endif
    call Project#SortR(a:start, partition - 1)
    call Project#SortR(partition + 1, a:end)
endfunc ">>>
" Project#IsAbsolutePath(path) <<<
"   Returns true if filename has an absolute path.
function! Project#IsAbsolutePath(path)
    if a:path =~ '^ftp:' || a:path =~ '^rcp:' || a:path =~ '^scp:' || a:path =~ '^https\?:'
        return 2
    endif
    if a:path =~ '\$'
        let path=expand(a:path) " Expand any environment variables that might be in the path
    else
        let path=a:path
    endif
    if path[0] == '/' || path[0] == '~' || path[0] == '\\' || path[1] == ':'
        return 1
    endif
    return 0
endfunction " >>>
" Project#DoSetupAndSplit() <<<
function! Project#DoSetupAndSplit()
    let n = winnr()                 " Determine if there is a CTRL_W-p window
    silent! wincmd p
    if n == winnr()
        silent! wincmd l
    endif
    if n == winnr()
        " If n == winnr(), then there is no CTRL_W-p window
        " So we have to create a new one
        if bufnr('%') == g:proj_running
            exec 'silent leftabove vertical new'
        else
            exec 'silent leftabove vertical split | silent! bnext'
        endif
        wincmd p " Go back to the Project Window and ensure it is the right width
        exec b:proj_locate_command
        exec b:proj_resize_command
        wincmd p
    endif
endfunction ">>>
" Project#DoSetupAndSplit_au() <<<
"   Same as above but ensure that the Project window is the current
"   window.  Only called from an autocommand
function! Project#DoSetupAndSplit_au()
    if winbufnr(0) != g:proj_running
        return
    endif
    if winbufnr(2) == -1            " We're the only window right now.
        exec 'silent leftabove vertical split | bnext'
        if bufnr('%') == g:proj_running
            enew
        endif
        if bufnr('%') == g:proj_last_buffer | bnext | bprev | bnext | endif
        wincmd p " Go back to the Project Window and ensure it is the right width
        exec b:proj_locate_command
        exec b:proj_resize_command
    elseif(winnr() != 1)
        exec b:proj_locate_command
        exec b:proj_resize_command
    endif
endfunction
function! Project#RecordPrevBuffer_au()
    let g:proj_last_buffer = bufnr('%')
endfunction ">>>
" Project#RecursivelyConstructDirectives(lineno) <<<
"   Construct the inherited directives
function! Project#RecursivelyConstructDirectives(lineno)
    let lineno=Project#FindFoldTop(a:lineno)
    let foldlineno = lineno
    let foldlev=foldlevel(lineno)
    let parent_infoline = ''
    if foldlev > 1
        while foldlevel(lineno) >= foldlev " Go to parent fold
            if lineno < 1
                echoerr 'Some kind of fold error.  Check your syntax.'
                return
            endif
            let lineno = lineno - 1
        endwhile
        let parent_infoline = Project#RecursivelyConstructDirectives(lineno)
    endif
    let parent_home = Project#GetHome(parent_infoline, '')
    let parent_c_d = Project#GetCd(parent_infoline, parent_home)
    let parent_scriptin = Project#GetScriptin(parent_infoline, parent_home)
    let parent_scriptout = Project#GetScriptout(parent_infoline, parent_home)
    let parent_filter = Project#GetFilter(parent_infoline, '*')
    let infoline = getline(foldlineno)
    " Extract the home directory of this fold
    let home=Project#GetHome(infoline, parent_home)
    if home != ''
        if (foldlevel(foldlineno) == 1) && !Project#IsAbsolutePath(home)
            call confirm('Outermost Project Fold must have absolute path!  Or perhaps the path does not exist.', "&OK", 1)
            let home = '~'  " Some 'reasonable' value
        endif
    endif
    " Extract any CD information
    let c_d = Project#GetCd(infoline, home)
    if c_d != ''
        if (foldlevel(foldlineno) == 1) && !Project#IsAbsolutePath(c_d)
            call confirm('Outermost Project Fold must have absolute CD path!  Or perhaps the path does not exist.', "&OK", 1)
            let c_d = '.'  " Some 'reasonable' value
        endif
    else
        let c_d=parent_c_d
    endif
    " Extract scriptin
    let scriptin = Project#GetScriptin(infoline, home)
    if scriptin == ''
        let scriptin = parent_scriptin
    endif
    " Extract scriptout
    let scriptout = Project#GetScriptout(infoline, home)
    if scriptout == ''
        let scriptout = parent_scriptout
    endif
    " Extract filter
    let filter = Project#GetFilter(infoline, parent_filter)
    if filter == '' | let filter = parent_filter | endif
    return Project#ConstructInfo(home, c_d, scriptin, scriptout, '', filter)
endfunction ">>>
" Project#ConstructInfo(home, c_d, scriptin, scriptout, flags, filter) <<<
function! Project#ConstructInfo(home, c_d, scriptin, scriptout, flags, filter)
    let retval='Directory='.a:home
    if a:c_d[0] != ''
        let retval=retval.' CD='.a:c_d
    endif
    if a:scriptin[0] != ''
        let retval=retval.' in='.a:scriptin
    endif
    if a:scriptout[0] != ''
        let retval=retval.' out='.a:scriptout
    endif
    if a:filter[0] != ''
        let retval=retval.' filter="'.a:filter.'"'
    endif
    return retval
endfunction ">>>
" Project#OpenEntry(line, precmd, editcmd) <<<
"   Get the filename under the cursor, and open a window with it.
function! Project#OpenEntry(line, precmd, editcmd, dir)
    silent exec a:precmd
    if (a:editcmd[0] != '')
        if a:dir
            let fname='.'
        else
            if (foldlevel(a:line) == 0) && (a:editcmd[0] != '')
                return 0                    " If we're outside a fold, do nothing
            endif
            let fname=substitute(getline(a:line), '\s*#.*', '', '') " Get rid of comments and whitespace before comment
            let fname=substitute(fname, '^\s*\(.*\)', '\1', '') " Get rid of leading whitespace
            if strlen(fname) == 0
              " DONE try to perform commands from the pragma keep part.
                let fname=substitute(getline(a:line), '\s*#\s*pragma keep\s*', '', '') " Get rid of pragma keep and preceeding parts
                echomsg "fname in Project is " . fname
                call hgsutils#OpenLink(0,fname)
                return -1                    " The line is blank. Do nothing.
            endif
        endif
    else
        let fname='.'
    endif
    let infoline = Project#RecursivelyConstructDirectives(a:line)
    let retval=Project#OpenEntry2(a:line, infoline, fname, a:editcmd)
    call Project#DisplayInfo()
    return retval
endfunction
">>>
" Project#OpenEntry2(line, infoline, precmd, editcmd) <<<
"   Get the filename under the cursor, and open a window with it.
function! Project#OpenEntry2(line, infoline, fname, editcmd)
    let fname=escape(a:fname, ' %#')        " Thanks to Thomas Link for cluing me in on % and #
    let home=Project#GetHome(a:infoline, '').'/'
    if home=='/'
        echoerr 'Project structure error. Check your syntax.'
        return
    endif
    "Save the cd command
    let cd_cmd = b:proj_cd_cmd
    if a:editcmd[0] != '' " If editcmd is '', then just set up the environment in the Project Window
        call Project#DoSetupAndSplit()
        " If it is an absolute path, don't prepend home
        if !Project#IsAbsolutePath(fname)
            let fname=home.fname
        endif
        if Project#IsAbsolutePath(fname) == 2
            exec a:editcmd.' '.fname
        else
            silent exec 'silent '.a:editcmd.' '.fname
        endif
    else " only happens in the Project File
        exec 'au! BufEnter,BufLeave '.expand('%:p')
    endif
    " Extract any CD information
    let c_d = Project#GetCd(a:infoline, home)
    if c_d != '' && (Project#IsAbsolutePath(home) != 2)
        if match(g:proj_flags, '\CL') != -1
            call Project#SetupAutoCommand(c_d)
        endif
        if !isdirectory(glob(c_d))
            call confirm("From this fold's entry,\nCD=".'"'.c_d.'" is not a valid directory.', "&OK", 1)
        else
            silent exec cd_cmd.' '.c_d
        endif
    endif
    " Extract any scriptin information
    let scriptin = Project#GetScriptin(a:infoline, home)
    if scriptin != ''
        if !filereadable(glob(scriptin))
            call confirm('"'.scriptin.'" not found. Ignoring.', "&OK", 1)
        else
            call Project#SetupScriptAutoCommand('BufEnter', scriptin)
            exec 'source '.scriptin
        endif
    endif
    let scriptout = Project#GetScriptout(a:infoline, home)
    if scriptout != ''
        if !filereadable(glob(scriptout))
            call confirm('"'.scriptout.'" not found. Ignoring.', "&OK", 1)
        else
            call Project#SetupScriptAutoCommand('BufLeave', scriptout)
        endif
    endif
    return 1
endfunction
">>>
" Project#DoFoldOrOpenEntry(cmd0, cmd1) <<<
"   Used for double clicking. If the mouse is on a fold, open/close it. If
"   not, try to open the file.
function! Project#DoFoldOrOpenEntry(cmd0, cmd1)
	if getline('.')=~'{\|}' || foldclosed('.') != -1
		normal! za
	else
		call Project#DoEnsurePlacementSize_au()
		let retval=Project#OpenEntry(line('.'), a:cmd0, a:cmd1, 0)
		if retval == -1
			" hgsutils#OpenLink had been called
			call Project#DoToggleProject()
			return
		endif
		if (match(g:proj_flags, '\Cc') != -1)
			let proj_mybufname = bufname("%")
			Project
			hide
			if(proj_mybufname != bufname("%"))
				wincmd p
				" from some vim version on (v7.0?) would have
				" switched to hidden Project window.
				exe bufwinnr(proj_mybufname)."wincmd w"
			endif
			wincmd =
		endif
	endif
endfunction ">>>
" Project#VimDirListing(filter, padding, separator, filevariable, filecount, dirvariable, dircount) <<<
function! Project#VimDirListing(filter, padding, separator, filevariable, filecount, dirvariable, dircount)
    let end = 0
    let files=''
    let filter = a:filter
    " Chop up the filter
    "   Apparently glob() cannot take something like this: glob('*.c *.h')
    let while_var = 1
    while while_var
        let end = stridx(filter, ' ')
        if end == -1
            let end = strlen(filter)
            let while_var = 0
        endif
        let single=glob(strpart(filter, 0, end))
        if strlen(single) != 0
            let files = files.single."\010"
        endif
        let filter = strpart(filter, end + 1)
    endwhile
    " files now contains a list of everything in the directory. We need to
    " weed out the directories.
    let fnames=files
    let {a:filevariable}=''
    let {a:dirvariable}=''
    let {a:filecount}=0
    let {a:dircount}=0
    while strlen(fnames) > 0
        let fname = substitute(fnames,  '\(\(\f\|[ :\[\]]\)*\).*', '\1', '')
        let fnames = substitute(fnames, '\(\f\|[ :\[\]]\)*.\(.*\)', '\2', '')
        if isdirectory(glob(fname))
            let {a:dirvariable}={a:dirvariable}.a:padding.fname.a:separator
            let {a:dircount}={a:dircount} + 1
        else
            let {a:filevariable}={a:filevariable}.a:padding.fname.a:separator
            let {a:filecount}={a:filecount} + 1
        endif
    endwhile
endfunction ">>>
" Project#GenerateEntry(recursive, name, absolute_dir, dir, c_d, filter_directive, filter, foldlev, sort) <<<
function! Project#GenerateEntry(recursive, line, name, absolute_dir, dir, c_d, filter_directive, filter, foldlev, sort)
    let line=a:line
    if a:dir =~ '\\ '
        let dir='"'.substitute(a:dir, '\\ ', ' ', 'g').'"'
    else
        let dir=a:dir
    endif
    let spaces=strpart('                                                             ', 0, a:foldlev)
    let c_d=(strlen(a:c_d) > 0) ? 'CD='.a:c_d.' ' : ''
    let c_d=(strlen(a:filter_directive) > 0) ? c_d.'filter="'.a:filter_directive.'" ': c_d
    call append(line, spaces.'}')
    call append(line, spaces.a:name.'='.dir.' '.c_d.'{')
    if a:recursive
        exec 'cd '.a:absolute_dir
        call Project#VimDirListing("*", '', "\010", 'b:files', 'b:filecount', 'b:dirs', 'b:dircount')
        cd -
        let dirs=b:dirs
        let dcount=b:dircount
        unlet b:files b:filecount b:dirs b:dircount
        while dcount > 0
            let dname = substitute(dirs,  '\(\( \|\f\|:\)*\).*', '\1', '')
            let edname = escape(dname, ' ')
            let dirs = substitute(dirs, '\( \|\f\|:\)*.\(.*\)', '\2', '')
            let line=Project#GenerateEntry(1, line + 1, dname, a:absolute_dir.'/'.edname, edname, '', '', a:filter, a:foldlev+1, a:sort)
            let dcount=dcount-1
        endwhile
    endif
    return line+1
endfunction " >>>
" Project#DoEntryFromDir(line, name, absolute_dir, dir, c_d, filter_directive, filter, foldlev, sort) <<<
"   Generate the fold from the directory hierarchy (if recursive), then
"   fill it in with RefreshEntriesFromDir()
function! Project#DoEntryFromDir(recursive, line, name, absolute_dir, dir, c_d, filter_directive, filter, foldlev, sort)
    call Project#GenerateEntry(a:recursive, a:line, a:name, escape(a:absolute_dir, ' '), escape(a:dir, ' '), escape(a:c_d, ' '), a:filter_directive, a:filter, a:foldlev, a:sort)
    normal! j
    call Project#RefreshEntriesFromDir(1)
endfunction ">>>
" Project#CreateEntriesFromDir(recursive) <<<
"   Prompts user for information and then calls Project#DoEntryFromDir()
function! Project#CreateEntriesFromDir(recursive)
    " Save a mark for the current cursor position
    normal! mk
    let line=line('.')
    let name = inputdialog('Enter the Name of the Entry: ')
    if strlen(name) == 0
        return
    endif
    let foldlev=foldlevel(line)
    if (foldclosed(line) != -1) || (getline(line) =~ '}')
        let foldlev=foldlev - 1
    endif
    let absolute = (foldlev <= 0)?'Absolute ': ''
    let home=''
    let filter='*'
    if (match(g:proj_flags, '\Cb') != -1) && has('browse')
        " Note that browse() is inconsistent: On Win32 you can't select a
        " directory, and it gives you a relative path.
        let dir = browse(0, 'Enter the '.absolute.'Directory to Load: ', '', '')
        let dir = fnamemodify(dir, ':p')
    else
        let dir = input('Enter the '.absolute.'Directory to Load: ', '', 'file')
    endif
    if (dir[strlen(dir)-1] == '/') || (dir[strlen(dir)-1] == '\\')
        let dir=strpart(dir, 0, strlen(dir)-1) " Remove trailing / or \
    endif
    let dir = substitute(dir, '^\~', $HOME, 'g')
    if (foldlev > 0)
        let parent_directive=Project#RecursivelyConstructDirectives(line)
        let filter = Project#GetFilter(parent_directive, '*')
        let home=Project#GetHome(parent_directive, '')
        if home[strlen(home)-1] != '/' && home[strlen(home)-1] != '\\'
            let home=home.'/'
        endif
        unlet parent_directive
        if Project#IsAbsolutePath(dir)
            " It is not a relative path  Try to make it relative
            let hend=matchend(dir, '\C'.glob(home))
            if hend != -1
                let dir=strpart(dir, hend)          " The directory can be a relative path
            else
                let home=""
            endif
        endif
    endif
    if strlen(home.dir) == 0
        return
    endif
    if !isdirectory(home.dir)
        if has("unix")
            silent exec '!mkdir '.home.dir.' > /dev/null'
        else
            call confirm('"'.home.dir.'" is not a valid directory.', "&OK", 1)
            return
        endif
    endif
    let c_d = inputdialog('Enter the CD parameter: ', '')
    let filter_directive = inputdialog('Enter the File Filter: ', '')
    if strlen(filter_directive) != 0
        let filter = filter_directive
    endif
    " If I'm on a closed fold, go to the bottom of it
    if foldclosedend(line) != -1
        let line = foldclosedend(line)
    endif
    let foldlev = foldlevel(line)
    " If we're at the end of a fold . . .
    if getline(line) =~ '}'
        let foldlev = foldlev - 1           " . . . decrease the indentation by 1.
    endif
    " Do the work
    call Project#DoEntryFromDir(a:recursive, line, name, home.dir, dir, c_d, filter_directive, filter, foldlev, 0)
    " Restore the cursor position
    normal! `k
endfunction ">>>
" Project#RefreshEntriesFromDir(recursive) <<<
"   Finds metadata at the top of the fold, and then replaces all files
"   with the contents of the directory.  Works recursively if recursive is 1.
function! Project#RefreshEntriesFromDir(recursive)
    if foldlevel('.') == 0
        echo 'Nothing to refresh.'
        return
    endif
    " Open the fold.
    if getline('.') =~ '}'
        normal! zo[z
    else
        normal! zo]z[z
    endif
    let just_a_fold=0
    let infoline = Project#RecursivelyConstructDirectives(line('.'))
    let immediate_infoline = getline('.')
    if strlen(substitute(immediate_infoline, '[^=]*=\(\(\f\|:\|\\ \)*\).*', '\1', '')) == strlen(immediate_infoline)
        let just_a_fold = 1
    endif
    " Extract the home directory of the fold
    let home = Project#GetHome(infoline, '')
    if home == ''
        " No Match.  This means that this is just a label with no
        " directory entry.
        if a:recursive == 0
            return          " We're done--nothing to do
        endif
        " Mark that it is just a fold, so later we don't delete filenames
        " that aren't there.
        let just_a_fold = 1
    endif
    if just_a_fold == 0
        " Extract the filter between quotes (we don't care what CD is).
        let filter = Project#GetFilter(infoline, '*')
        " Extract the description (name) of the fold
        let name = substitute(infoline, '^[#\t ]*\([^=]*\)=.*', '\1', '')
        if strlen(name) == strlen(infoline)
            return                  " If there's no name, we're done.
        endif
        if (home == '') || (name == '')
            return
        endif
        " Extract the flags
        let flags = Project#GetFlags(immediate_infoline)
        let sort = (match(g:proj_flags, '\CS') != -1)
        if flags != ''
            if match(flags, '\Cr') != -1
                " If the flags do not contain r (refresh), then treat it just
                " like a fold
                let just_a_fold = 1
            endif
            if match(flags, '\CS') != -1
                let sort = 1
            endif
            if match(flags, '\Cs') != -1
                let sort = 0
            endif
        else
            let flags=''
        endif
    endif
    " Move to the first non-fold boundary line
    normal! j
    " Delete filenames until we reach the end of the fold
    while getline('.') !~ '}'
        if line('.') == line('$')
            break
        endif
        if getline('.') !~ '{'
            " We haven't reached a sub-fold, so delete what's there.
            if (just_a_fold == 0) && (getline('.') !~ '^\s*#') && (getline('.') !~ '#.*pragma keep')
                d _
            else
                " Skip lines only in a fold and comment lines
                normal! j
            endif
        else
            " We have reached a sub-fold. If we're doing recursive, then
            " call this function again. If not, find the end of the fold.
            if a:recursive == 1
                call Project#RefreshEntriesFromDir(1)
                normal! ]zj
            else
                if foldclosed('.') == -1
                    normal! zc
                endif
                normal! j
            endif
        endif
    endwhile
    if just_a_fold == 0
        " We're not just in a fold, and we have deleted all the filenames.
        " Now it is time to regenerate what is in the directory.
        if !isdirectory(glob(home))
            call confirm('"'.home.'" is not a valid directory.', "&OK", 1)
        else
            let foldlev=foldlevel('.')
            " T flag.  Thanks Tomas Z.
            if (match(flags, '\Ct') != -1) || ((match(g:proj_flags, '\CT') == -1) && (match(flags, '\CT') == -1))
                " Go to the top of the fold (force other folds to the
                " bottom)
                normal! [z
                normal! j
                " Skip any comments
                while getline('.') =~ '^\s*#'
                    normal! j
                endwhile
            endif
            normal! k
            let cwd=getcwd()
            let spaces=strpart('                                               ', 0, foldlev)
            exec 'cd '.home
            if match(g:proj_flags, '\Ci') != -1
                echon home."\r"
            endif
            call Project#VimDirListing(filter, spaces, "\n", 'b:files', 'b:filecount', 'b:dirs', 'b:dircount')
            if b:filecount > 0
                normal! mk
                silent! put =b:files
                normal! `kj
                if sort
                    call Project#SortR(line('.'), line('.') + b:filecount - 1)
                endif
            else
                normal! j
            endif
            unlet b:files b:filecount b:dirs b:dircount
            exec 'cd '.cwd
        endif
    endif
    " Go to the top of the refreshed fold.
    normal! [z
endfunction ">>>
" Project#MoveUp() <<<
"   Moves the entity under the cursor up a line.
function! Project#MoveUp()
    let lineno=line('.')
    if lineno == 1
        return
    endif
    let fc=foldclosed('.')
    let a_reg=@a
    if lineno == line('$')
        normal! "add"aP
    else
        normal! "addk"aP
    endif
    let @a=a_reg
    if fc != -1
        normal! zc
    endif
endfunction ">>>
" Project#MoveDown() <<<
"   Moves the entity under the cursor down a line.
function! Project#MoveDown()
    let fc=foldclosed('.')
    let a_reg=@a
    normal! "add"ap
    let @a=a_reg
    if (fc != -1) && (foldclosed('.') == -1)
        normal! zc
    endif
endfunction " >>>
" Project#DisplayInfo() <<<
"   Displays filename and current working directory when i (info) is in
"   the flags.
function! Project#DisplayInfo()
    if match(g:proj_flags, '\Ci') != -1
        echo 'file: '.expand('%').', cwd: '.getcwd().', lines: '.line('$')
    endif
endfunction ">>>
" Project#SetupAutoCommand(cwd) <<<
"   Sets up an autocommand to ensure that the cwd is set to the one
"   desired for the fold regardless.  :lcd only does this on a per-window
"   basis, not a per-buffer basis.
function! Project#SetupAutoCommand(cwd)
    if !exists("b:proj_has_autocommand")
        let b:proj_cwd_save = escape(getcwd(), ' ')
        let b:proj_has_autocommand = 1
        let bufname=escape(substitute(expand('%:p', 0), '\\', '/', 'g'), ' ')
        exec 'au BufEnter '.bufname." let b:proj_cwd_save=escape(getcwd(), ' ') | cd ".a:cwd
        exec 'au BufLeave '.bufname.' exec "cd ".b:proj_cwd_save'
        exec 'au BufWipeout '.bufname.' au! * '.bufname
    endif
endfunction ">>>
" Project#SetupScriptAutoCommand(bufcmd, script) <<<
"   Sets up an autocommand to run the scriptin script.
function! Project#SetupScriptAutoCommand(bufcmd, script)
    if !exists("b:proj_has_".a:bufcmd)
        let b:proj_has_{a:bufcmd} = 1
        exec 'au '.a:bufcmd.' '.escape(substitute(expand('%:p', 0), '\\', '/', 'g'), ' ').' source '.a:script
    endif
endfunction " >>>
" Project#DoEnsurePlacementSize_au() <<<
"   Ensure that the Project window is on the left of the window and has
"   the correct size. Only called from an autocommand
function! Project#DoEnsurePlacementSize_au()
    if (winbufnr(0) != g:proj_running) || (winnr() != 1)
        if exists("g:proj_doinghelp")
            if g:proj_doinghelp > 0
                let g:proj_doinghelp = g:proj_doinghelp - 1
                return
            endif
            unlet g:proj_doinghelp
            return
        endif
        exec b:proj_locate_command
    endif
    exec b:proj_resize_command
endfunction ">>>
" Project#Spawn(number) <<<
"   Spawn an external command on the file
function! Project#Spawn(number)
    echo | if exists("g:proj_run".a:number)
        let fname=getline('.')
        if fname!~'{\|}'
            let fname=substitute(fname, '\s*#.*', '', '')
            let fname=substitute(fname, '^\s*\(.*\)\s*', '\1', '')
            if fname == '' | return | endif
            let parent_infoline = Project#RecursivelyConstructDirectives(line('.'))
            let home=expand(Project#GetHome(parent_infoline, ''))
            let c_d=expand(Project#GetCd(parent_infoline, ''))
            let command=substitute(g:proj_run{a:number}, '%%', "\010", 'g')
            let command=substitute(command, '%f', escape(home.'/'.fname, '\'), 'g')
            let command=substitute(command, '%F', substitute(escape(home.'/'.fname, '\'), ' ', '\\\\ ', 'g'), 'g')
            let command=substitute(command, '%s', escape(home.'/'.fname, '\'), 'g')
            let command=substitute(command, '%n', escape(fname, '\'), 'g')
            let command=substitute(command, '%N', substitute(fname, ' ', '\\\\ ', 'g'), 'g')
            let command=substitute(command, '%h', escape(home, '\'), 'g')
            let command=substitute(command, '%H', substitute(escape(home, '\'), ' ', '\\\\ ', 'g'), 'g')
            if c_d != ''
                if c_d == home
                    let percent_r='.'
                else
                    let percent_r=substitute(home, escape(c_d.'/', '\'), '', 'g')
                endif
            else
                let percent_r=home
            endif
            let command=substitute(command, '%r', percent_r, 'g')
            let command=substitute(command, '%R', substitute(percent_r, ' ', '\\\\ ', 'g'), 'g')
            let command=substitute(command, '%d', escape(c_d, '\'), 'g')
            let command=substitute(command, '%D', substitute(escape(c_d, '\'), ' ', '\\\\ ', 'g'), 'g')
            let command=substitute(command, "\010", '%', 'g')
            exec command
        endif
    endif
endfunction ">>>
" Project#ListSpawn(varnamesegment) <<<
"   List external commands
function! Project#ListSpawn(varnamesegment)
    let number = 1
    while number < 10
        if exists("g:proj_run".a:varnamesegment.number)
            echohl LineNr | echo number.':' | echohl None | echon ' '.substitute(escape(g:proj_run{a:varnamesegment}{number}, '\'), "\n", '\\n', 'g')
        else
            echohl LineNr | echo number.':' | echohl None
        endif
        let number=number + 1
    endwhile
endfunction ">>>
" Project#FindFoldTop(line) <<<
"   Return the line number of the directive line
function! Project#FindFoldTop(line)
    let lineno=a:line
    if getline(lineno) =~ '}'
        let lineno = lineno - 1
    endif
    while getline(lineno) !~ '{' && lineno > 1
        if getline(lineno) =~ '}'
            let lineno=Project#FindFoldTop(lineno)
        endif
        let lineno = lineno - 1
    endwhile
    return lineno
endfunction ">>>
" Project#FindFoldBottom(line) <<<
"   Return the line number of the directive line
function! Project#FindFoldBottom(line)
    let lineno=a:line
    if getline(lineno) =~ '{'
        let lineno=lineno + 1
    endif
    while getline(lineno) !~ '}' && lineno < line('$')
        if getline(lineno) =~ '{'
            let lineno=Project#FindFoldBottom(lineno)
        endif
        let lineno = lineno + 1
    endwhile
    return lineno
endfunction ">>>
" Project#LoadAll(recurse, line) <<<
"   Load all files in a project
function! Project#LoadAll(recurse, line)
    let b:loadcount=0
    function! s:SpawnExec(infoline, fname, lineno, data)
        if Project#OpenEntry2(a:lineno, a:infoline, a:fname, 'e')
            wincmd p
            let b:loadcount=b:loadcount+1
            echon b:loadcount."\r"
            if getchar(0) != 0
                let b:stop_everything=1
            endif
        endif
    endfunction
    call Project#ForEach(a:recurse, line('.'), "*<SID>SpawnExec", 0, '^\(.*l\)\@!')
    delfunction s:SpawnExec
    echon b:loadcount." Files Loaded\r"
    unlet b:loadcount
    if exists("b:stop_everything") | unlet b:stop_everything | endif
endfunction ">>>
" Project#WipeAll(recurse, line) <<<
"   Wipe all files in a project
function! Project#WipeAll(recurse, line)
    let b:wipecount=0
    let b:totalcount=0
    function! s:SpawnExec(home, c_d, fname, lineno, data)
        let fname=escape(a:fname, ' ')
        if Project#IsAbsolutePath(fname)
            let fname=fnamemodify(fname, ':n')  " :n is coming, won't break anything now
        else
            let fname=fnamemodify(a:home.'/'.fname, ':n')  " :n is coming, won't break anything now
        endif
        let b:totalcount=b:totalcount+1
        let fname=substitute(fname, '^\~', $HOME, 'g')
        let fname=expand(fname)
         echomsg fname
        if bufloaded(substitute(fname, '\\ ', ' ', 'g'))
            if getbufvar(fname.'\>', '&modified') == 1
                exec 'sb '.fname
                wincmd L
                w
                wincmd p
            endif
            let b:wipecount=b:wipecount+1
            exec 'bwipe! '.fname
        endif
        if b:totalcount % 5 == 0
            echon b:wipecount.' of '.b:totalcount."\r"
            redraw
        endif
        if getchar(0) != 0
            let b:stop_everything=1
        endif
    endfunction
    call Project#ForEach(a:recurse, line('.'), "<SID>SpawnExec", 0, '^\(.*w\)\@!')
    delfunction s:SpawnExec
    echon b:wipecount.' of '.b:totalcount." Files Wiped\r"
    unlet b:wipecount b:totalcount
    if exists("b:stop_everything") | unlet b:stop_everything | endif
endfunction ">>>
" Project#LoadAllSplit(recurse, line) <<<
"   Load all files in a project using split windows.
"   Contributed by A. Harrison
function! Project#LoadAllSplit(recurse, line)
    let b:loadcount=0
    function! s:SpawnExec(infoline, fname, lineno, data)
        let winNr = winnr() "get ProjectWindow number
        if Project#OpenEntry2(a:lineno, a:infoline, a:fname, 'sp')
            exec winNr."wincmd w"
            let b:loadcount=b:loadcount+1
            echon b:loadcount."\r"
            if getchar(0) != 0
                let b:stop_everything=1
            endif
        endif
    endfunction
    call Project#ForEach(a:recurse, line('.'), "*<SID>SpawnExec", 0, '^\(.*l\)\@!')
    delfunction s:SpawnExec
    echon b:loadcount." Files Loaded\r"
    unlet b:loadcount
    if exists("b:stop_everything") | unlet b:stop_everything | endif
endfunction ">>>
" Project#GrepAll(recurse, lineno, pattern) <<<
"   Grep all files in a project, optionally recursively
function! Project#GrepAll(recurse, lineno, pattern)
    cunmap <buffer> help
    let pattern=(a:pattern[0] == '')?input("GREP options and pattern: "):a:pattern
    cnoremap <buffer> help let g:proj_doinghelp = 1<CR>:help
    if pattern[0] == ''
        return
    endif
    let b:escape_spaces=1
    let fnames=Project#GetAllFnames(a:recurse, a:lineno, ' ')
    unlet b:escape_spaces
    cclose " Make sure grep window is closed
    call Project#DoSetupAndSplit()
    if match(g:proj_flags, '\Cv') == -1
        silent! exec 'silent! grep '.pattern.' '.fnames
        if v:shell_error != 0
            echo 'GREP error. Perhaps there are too many filenames.'
        else
            copen
        endif
    else
        silent! exec 'silent! noau vimgrep /'.pattern.'/j '.fnames.'|cw'
        copen
    endif
endfunction ">>>
" GetXXX Functions <<<
function! Project#GetHome(info, parent_home)
    " Thanks to Adam Montague for pointing out the need for @ in urls.
    let home=substitute(a:info, '^[^=]*=\(\(\\ \|\f\|:\|@\)\+\).*', '\1', '')
    if strlen(home) == strlen(a:info)
        let home=substitute(a:info, '.\{-}"\(.\{-}\)".*', '\1', '')
        if strlen(home) != strlen(a:info) | let home=escape(home, ' ') | endif
    endif
    if strlen(home) == strlen(a:info)
        let home=a:parent_home
    elseif home=='.'
        let home=a:parent_home
    elseif !Project#IsAbsolutePath(home)
        let home=a:parent_home.'/'.home
    endif
    return home
endfunction
function! Project#GetFilter(info, parent_filter)
    let filter = substitute(a:info, '.*\<filter="\([^"]*\).*', '\1', '')
    if strlen(filter) == strlen(a:info) | let filter = a:parent_filter | endif
    return filter
endfunction
function! Project#GetCd(info, home)
    let c_d=substitute(a:info, '.*\<CD=\(\(\\ \|\f\|:\)\+\).*', '\1', '')
    if strlen(c_d) == strlen(a:info)
        let c_d=substitute(a:info, '.*\<CD="\(.\{-}\)".*', '\1', '')
        if strlen(c_d) != strlen(a:info) | let c_d=escape(c_d, ' ') | endif
    endif
    if strlen(c_d) == strlen(a:info)
        let c_d=''
    elseif c_d == '.'
        let c_d = a:home
    elseif !Project#IsAbsolutePath(c_d)
        let c_d = a:home.'/'.c_d
    endif
    return c_d
endfunction
function! Project#GetScriptin(info, home)
    let scriptin = substitute(a:info, '.*\<in=\(\(\\ \|\f\|:\)\+\).*', '\1', '')
    if strlen(scriptin) == strlen(a:info)
        let scriptin=substitute(a:info, '.*\<in="\(.\{-}\)".*', '\1', '')
        if strlen(scriptin) != strlen(a:info) | let scriptin=escape(scriptin, ' ') | endif
    endif
    if strlen(scriptin) == strlen(a:info) | let scriptin='' | else
    if !Project#IsAbsolutePath(scriptin) | let scriptin=a:home.'/'.scriptin | endif | endif
    return scriptin
endfunction
function! Project#GetScriptout(info, home)
    let scriptout = substitute(a:info, '.*\<out=\(\(\\ \|\f\|:\)\+\).*', '\1', '')
    if strlen(scriptout) == strlen(a:info)
        let scriptout=substitute(a:info, '.*\<out="\(.\{-}\)".*', '\1', '')
        if strlen(scriptout) != strlen(a:info) | let scriptout=escape(scriptout, ' ') | endif
    endif
    if strlen(scriptout) == strlen(a:info) | let scriptout='' | else
    if !Project#IsAbsolutePath(scriptout) | let scriptout=a:home.'/'.scriptout | endif | endif
    return scriptout
endfunction
function! Project#GetFlags(info)
    let flags=substitute(a:info, '.*\<flags=\([^ {]*\).*', '\1', '')
    if (strlen(flags) == strlen(a:info))
        let flags=''
    endif
    return flags
endfunction ">>>
" Project#GetAllFnames(recurse, lineno, separator) <<<
"   Grep all files in a project, optionally recursively
function! Project#GetAllFnames(recurse, lineno, separator)
    let b:fnamelist=''
    function! s:SpawnExec(home, c_d, fname, lineno, data)
        if exists('b:escape_spaces')
            let fname=escape(a:fname, ' ')
        else
            let fname=a:fname
        endif
        if !Project#IsAbsolutePath(a:fname)
            let fname=a:home.'/'.fname
        endif
        let b:fnamelist=b:fnamelist.a:data.fname
    endfunction
    " TabMessage function s:SpawnExec
    call Project#ForEach(a:recurse, line('.'), "<SID>SpawnExec", a:separator, '')
    delfunction s:SpawnExec
    let retval=b:fnamelist
    unlet b:fnamelist
    return retval
endfunction ">>>
" Project#GetFname(lineno) <<<
"   Grep all files in a project, optionally recursively
"   DONE Only works correctly if project window is closed and reopened (check with ,I)
"        Resolved by doautocmd BufEnter in Project#Project
function! Project#GetFname(line)
	  if &fdm != "marker"
	  	echoerr "Foldmethod not marker. Operation aborted!"
	  	return
		endif
    if (foldlevel(a:line) == 0)
        return ''
    endif
    let fname=substitute(getline(a:line), '\s*#.*', '', '') " Get rid of comments and whitespace before comment
    let fname=substitute(fname, '^\s*\(.*\)', '\1', '') " Get rid of leading whitespace
    if strlen(fname) == 0
        return ''                    " The line is blank. Do nothing.
    endif
    if Project#IsAbsolutePath(fname)
        return fname
    endif
    let infoline = Project#RecursivelyConstructDirectives(a:line)
    return Project#GetHome(infoline, '').'/'.fname
endfunction ">>>
" Project#ForEach(recurse, lineno, cmd, data, match) <<<
"   Grep all files in a project, optionally recursively
function! Project#ForEach(recurse, lineno, cmd, data, match)
    let info=Project#RecursivelyConstructDirectives(a:lineno)
    let lineno=Project#FindFoldTop(a:lineno) + 1
    let flags=Project#GetFlags(getline(lineno - 1))
    if (flags == '') || (a:match=='') || (match(flags, a:match) != -1)
        call Project#ForEachR(a:recurse, lineno, info, a:cmd, a:data, a:match)
    endif
endfunction
function! Project#ForEachR(recurse, lineno, info, cmd, data, match)
    let home=Project#GetHome(a:info, '')
    let c_d=Project#GetCd(a:info, home)
    let scriptin = Project#GetScriptin(a:info, home)
    let scriptout = Project#GetScriptout(a:info, home)
    let filter = Project#GetFilter(a:info, '')
    let lineno = a:lineno
    let curline=getline(lineno)
    while (curline !~ '}') && (curline < line('$'))
        if exists("b:stop_everything") && b:stop_everything | return 0 | endif
        if curline =~ '{'
            if a:recurse
                let flags=Project#GetFlags(curline)
                if (flags == '') || (a:match=='') || (match(flags, a:match) != -1)
                    let this_home=Project#GetHome(curline, home)
                    let this_cd=Project#GetCd(curline, this_home)
                    if this_cd=='' | let this_cd=c_d | endif
                    let this_scriptin=Project#GetScriptin(curline, this_home)
                    if this_scriptin == '' | let this_scriptin=scriptin | endif
                    let this_scriptout=Project#GetScriptin(curline, this_home)
                    if this_scriptout == '' | let this_scriptout=scriptout | endif
                    let this_filter=Project#GetFilter(curline, filter)
                    let lineno=Project#ForEachR(1, lineno+1,
                        \Project#ConstructInfo(this_home, this_cd, this_scriptin, this_scriptout, flags, this_filter), a:cmd, a:data, a:match)
                else
                    let lineno=Project#FindFoldBottom(lineno)
                endif
            else
                let lineno=Project#FindFoldBottom(lineno)
            endif
        else
            let fname=substitute(curline, '\s*#.*', '', '')
            let fname=substitute(fname, '^\s*\(.*\)', '\1', '')
            if (strlen(fname) != strlen(curline)) && (fname[0] != '')
                if a:cmd[0] == '*'
                    call {strpart(a:cmd, 1)}(a:info, fname, lineno, a:data)
                else
                    call {a:cmd}(home, c_d, fname, lineno, a:data)
                endif
            endif
        endif
        let lineno=lineno + 1
        let curline=getline(lineno)
    endwhile
    return lineno
endfunction ">>>
" Project#SpawnAll(recurse, number) <<<
"   Spawn an external command on the files of a project
function! Project#SpawnAll(recurse, number)
    echo | if exists("g:proj_run_fold".a:number)
        if g:proj_run_fold{a:number}[0] == '*'
            function! s:SpawnExec(home, c_d, fname, lineno, data)
                let command=substitute(strpart(g:proj_run_fold{a:data}, 1), '%s', escape(a:fname, ' \'), 'g')
                let command=substitute(command, '%f', escape(a:fname, '\'), 'g')
                let command=substitute(command, '%h', escape(a:home, '\'), 'g')
                let command=substitute(command, '%d', escape(a:c_d, '\'), 'g')
                let command=substitute(command, '%F', substitute(escape(a:fname, '\'), ' ', '\\\\ ', 'g'), 'g')
                exec command
            endfunction
            call Project#ForEach(a:recurse, line('.'), "<SID>SpawnExec", a:number, '.')
            delfunction s:SpawnExec
        else
            let info=Project#RecursivelyConstructDirectives(line('.'))
            let home=Project#GetHome(info, '')
            let c_d=Project#GetCd(info, '')
            let b:escape_spaces=1
            let fnames=Project#GetAllFnames(a:recurse, line('.'), ' ')
            unlet b:escape_spaces
            let command=substitute(g:proj_run_fold{a:number}, '%f', substitute(escape(fnames, '\'), '\\ ', ' ', 'g'), 'g')
            let command=substitute(command, '%s', escape(fnames, '\'), 'g')
            let command=substitute(command, '%h', escape(home, '\'), 'g')
            let command=substitute(command, '%d', escape(c_d, '\'), 'g')
            let command=substitute(command, '%F', escape(fnames, '\'), 'g')
            exec command
            if v:shell_error != 0
                echo 'Shell error. Perhaps there are too many filenames.'
            endif
        endif
    endif
endfunction ">>>
function! Project#Balloonexpr() " <<<
	return Project#GetFname(v:beval_lnum)
endfunction " >>>
function! s:ReverseStart() " <<<
    set nolazyredraw
		" if exists("l:foldenable")
			" let &l:foldenable = l:foldenable
		" endif
		"DONE saving views currently disabled
		" if exists("l:save_view")
			" call winrestview(l:save_view)
		" endif
    redraw
endfunction ">>>
function! Project#DoToggleProject() " <<<
	if !exists('g:proj_running') || bufwinnr(g:proj_running) == -1
		Project
	else
		set lazyredraw
		if &ft == "qf"
			sil! wincmd t
		endif
		let proj_mywindow = winnr()
		Project
		hide
		if(winnr() != proj_mywindow)
			sil! wincmd p
		endif
		unlet proj_mywindow
		set nolazyredraw
		redraw
	endif
endfunction " >>>
fun! Project#ProjectGetFileNames(recur) " <<<
	let g:project_current_filelist=map(map(split(Project#GetAllFnames(a:recur,line("."),";"), ";"),"expand(v:val)"),"fnamemodify(v:val,\":p\")")
endfun " >>>
fun! Project#ProjectGetExistingFileNames(recur) " <<<
	call Project#ProjectGetFileNames(a:recur)
	" DONE Files with blanks need escaping leads currently to error: E110: Missing ')' 
	sil! let g:project_current_existing_filelist=filter(map(copy(g:project_current_filelist),'filereadable(escape(v:val,"\\"))?("".v:val.""):""'),'v:val!~"^\s*$"')
	let @*=join(g:project_current_existing_filelist,"\n")
	echomsg b:variablemessage . "(recur = " . a:recur . ", @* = g:project_current_existing_filelist)"
endfun " >>>
fun! Project#ProjectGetAllFileNames(recur) " <<<
	call Project#ProjectGetFileNames(a:recur)
	let @*=join(g:project_current_filelist,"\n")
	echomsg b:variablemessage . "(recur = " . a:recur . ", @* = g:project_current_filelist)"
endfun " >>>
fun! Project#ProjectGrepTODOInAllFileNames() " <<<
	call Project#ProjectGetExistingFileNames(1)
	if exists("g:tlTokenList")
		let sstring="\\(" . join(g:tlTokenList,"\\|") ."\\)"
	else
		let sstring="todo"
	endif
	if len(g:project_current_existing_filelist) > 0
		let xxcmd = 'silent! noau vimgrep /' . sstring . '/j ' . expand("%") . ' ' . join(g:project_current_existing_filelist, ' ') . '|cw'
	else
		echoerr "No files found"
		return
	endif
	" echomsg xxcmd
	" silent! exe xxcmd
	exe xxcmd
	" exe bufwinnr(g:proj_running) . "wincmd w"
	" hide
	cclose
	normal ,p
	copen
endfun " >>>
function! Project#GetCurrentProjectFilename() " <<<
	"This function can e.g. be used for statusline information
  if exists("g:proj_running")
  	let i =  g:proj_running
  	if bufloaded(i)
  		" echo i
  		" echo "- " . tolower(getbufvar(bufname(i), "&ft"))
  		" echo "- - " . fnamemodify(bufname(i),":t:r")
  		if tolower(getbufvar(bufname(i), "&ft")) == "project"
  			return fnamemodify(bufname(i),":t:r")
			endif
		endif
	endif
	return ""
endfunction " >>>
"   vim: set foldmethod=marker foldmarker=<<<,>>> foldlevel=1:
