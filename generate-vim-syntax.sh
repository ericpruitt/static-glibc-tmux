#!/bin/sh
set -e -u
trap 'rm -f tmux.vim.tmp' EXIT

cat << 'HEADER' > tmux.vim.tmp
" Language: tmux(1) configuration file
" Maintainer: Eric Pruitt <eric.pruitt@gmail.com>
"
" This syntax file was derived from https://github.com/keith/tmux.vim
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
else
    let b:current_syntax = "tmux"
endif

setlocal iskeyword+=-
syntax case match

syn keyword tmuxAction  none any current other
syn keyword tmuxBoolean off on

syn keyword tmuxTodo FIXME NOTE TODO XXX contained

syn match tmuxColour            /\<colour[0-9]\+/      display
syn match tmuxKey               /\(C-\|M-\|\^\)\+\S\+/ display
syn match tmuxNumber            /\d\+/                 display
syn match tmuxFlags             /\s-\a\+/              display
syn match tmuxVariable          /\w\+=/                display
syn match tmuxVariableExpansion /\${\=\w\+}\=/         display

syn region tmuxComment start=/#/ skip=/\\\@<!\\$/ end=/$/ contains=tmuxTodo

syn region tmuxString start=+"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end='$' contains=tmuxFormatString
syn region tmuxString start=+'+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end='$' contains=tmuxFormatString

" TODO: Figure out how escaping works inside of #(...) and #{...} blocks.
syn region tmuxFormatString start=/#[#DFhHIPSTW]/ end=// contained keepend
syn region tmuxFormatString start=/#{/ skip=/#{.\{-}}/ end=/}/ contained keepend
syn region tmuxFormatString start=/#(/ skip=/#(.\{-})/ end=/)/ contained keepend

hi def link tmuxFormatString      Identifier
hi def link tmuxAction            Boolean
hi def link tmuxBoolean           Boolean
hi def link tmuxCommands          Keyword
hi def link tmuxComment           Comment
hi def link tmuxKey               Special
hi def link tmuxNumber            Number
hi def link tmuxFlags             Identifier
hi def link tmuxOptions           Function
hi def link tmuxString            String
hi def link tmuxTodo              Todo
hi def link tmuxVariable          Identifier
hi def link tmuxVariableExpansion Identifier

for i in range(0, 255)
    let s:realColor = i
    if s:realColor == 0 || s:realColor == 16 || s:realColor == 232 ||
\     s:realColor == 233 || s:realColor == 233 || s:realColor == 234
        exec "highlight tmuxColour" . i . " ctermfg=" . s:realColor . " ctermbg=15"
    else
        exec "highlight tmuxColour" . i . " ctermfg=" . s:realColor
    endif
    exec "syn match tmuxColour" . i . " /\\<colour" . i . "\\>/ display"
endfor

" GENERATED:
HEADER

awk '
    BEGIN {
        WRAP_WIDTH = 117
    }

    /options_table_entry options_table\[\] = \{$/ {
        inside_options_table = 1
    }

    inside_options_table && !/NULL/ {
        if ($1 == "};") {
            inside_options_table = 0
        } else if (/\.name/) {
            gsub(/[^a-z0-9-]/, "", $NF)
            tmuxOptions[tmuxOptions_count++] = $NF
        }
    }

    /^const struct cmd_entry.*\{$/ {
        inside_cmd_entry = 1
    }

    inside_cmd_entry && !/NULL/ {
        if ($1 == "};") {
            inside_cmd_entry = 0
        } else if (/\.(name|alias)/) {
            gsub(/[^a-z0-9-]/, "", $NF)
            tmuxCommands[tmuxCommands_count++] = $NF
        }
    }

    END {
        printf "syn keyword tmuxOptions"
        width_left = 0
        for (i in tmuxOptions) {
            word = tmuxOptions[i]
            wordlen = length(word) + 1
            if (wordlen < width_left) {
                printf " %s", word
                width_left -= wordlen
            } else {
                printf "\n\\ %s", word
                width_left = WRAP_WIDTH - wordlen
            }
        }

        printf "\nsyn keyword tmuxCommands"
        width_left = 0
        for (i in tmuxCommands) {
            word = tmuxCommands[i]
            wordlen = length(word) + 1
            if (wordlen < width_left) {
                printf " %s", word
                width_left -= wordlen
            } else {
                printf "\n\\ %s", word
                width_left = WRAP_WIDTH - wordlen
            }
        }
        print ""
    }
' tmux-src/*.c >> tmux.vim.tmp

mv tmux.vim.tmp tmux.vim
echo "Syntax file generated: $PWD/tmux.vim"
