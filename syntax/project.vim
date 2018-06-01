"=============================================================================
" File:        syntax\project.vim
" Author:      Aric Blumer (Aric.Blumer at aricvim@charter.net)
" Last Change: 19.02.2018
" Version:     2.0.0
"=============================================================================

if exists("b:current_syntax")
    finish
endif

let s:cpo_save = &cpo
set cpo&vim

syntax match projectDescriptionDir '^\s*.\{-}=\s*\(\\ \|\f\|:\|"\)\+' contains=projectDescription,projectWhiteError
syntax match projectDescription    '\<.\{-}='he=e-1,me=e-1         contained nextgroup=projectDirectory contains=projectWhiteError
syntax match projectDescription    '{\|}'
syntax match projectDirectory      '=\(\\ \|\f\|:\)\+'             contained
syntax match projectDirectory      '=".\{-}"'                      contained
syntax match projectScriptinout    '\<in\s*=\s*\(\\ \|\f\|:\|"\)\+' contains=projectDescription,projectWhiteError
syntax match projectScriptinout    '\<out\s*=\s*\(\\ \|\f\|:\|"\)\+' contains=projectDescription,projectWhiteError
syntax keyword projectTodo         contained TODO Todo
syntax match projectTodo           contained "\*!\*!\*"
syntax match projectComment        '#.*'                           contains=projectpragmakeep,projecturlProject,projectTodo,@Spell
syntax match projectpragmakeep     contained /\s*pragma keep/      conceal cchar=p
syntax match projecturlProject     contained containedin=UtlUrl /vimscript:tab Pro/ conceal cchar=v
syntax match projectCD             '\<CD\s*=\s*\(\\ \|\f\|:\|"\)\+' contains=projectDescription,projectWhiteError
syntax match projectFilterEntry    '\<filter\s*=.*"'               contains=projectWhiteError,projectFilterError,projectFilter,projectFilterRegexp
syntax match projectFilter         '\<filter='he=e-1,me=e-1        contained nextgroup=projectFilterRegexp,projectFilterError,projectWhiteError
syntax match projectFlagsEntry     '\<flags\s*=\( \|[^ ]*\)'       contains=projectFlags,projectWhiteError
syntax match projectFlags          '\<flags'                       contained nextgroup=projectFlagsValues,projectWhiteError
syntax match projectFlagsValues    '=[^ ]* 'hs=s+1,me=e-1          contained contains=projectFlagsError
syntax match projectFlagsError     '[^rtTsSwl= ]\+'                contained
syntax match projectWhiteError     '=\s\+'hs=s+1                   contained
syntax match projectWhiteError     '\s\+='he=e-1                   contained
syntax match projectFilterError    '=[^"]'hs=s+1                   contained
syntax match projectFilterRegexp   '=".*"'hs=s+1                   contained
syntax match projectFoldText       '^[^=]\+{'

highlight def link projectDescription  Identifier
highlight def link projectScriptinout  Identifier
highlight def link projectFoldText     Identifier
highlight def link projectpragmakeep   Comment
highlight def link projectComment      Comment
highlight def link projectTodo         Todo
highlight def link projectFilter       Identifier
highlight def link projectFlags        Identifier
highlight def link projectDirectory    Constant
highlight def link projectFilterRegexp String
highlight def link projectFlagsValues  String
highlight def link projectWhiteError   Error
highlight def link projectFlagsError   Error
highlight def link projectFilterError  Error

let b:current_syntax = "project"

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 et
