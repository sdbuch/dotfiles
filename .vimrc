" export a PYTHONHOME environment variable
" vim seems to need this to run python... but other python software doesn't
" interact properly
" so after this is set here, probably can't run many other programs in this
" session
let $PYTHONHOME = "/Users/sadboys/anaconda3"
" set python 3 dll
set pythonthreedll=/Users/sadboys/anaconda3/bin/python

" set leader character
let mapleader = ","

" VIM 8: load packages
" see h: add-package
packadd! matchit
" packadd! onedark.vim
packloadall

" TAGS
" let g:gutentags_trace=1 " this is a debug command
let g:gutentags_resolve_symlinks=0
silent! helptags ALL

" vim-indent-guides package settings
let g:indent_guides_auto_colors = 0

"" ALE integration with lightline
"" Taken from https://github.com/maximbaz/lightline-ale
let g:lightline = {}
"
"let g:lightline.component_expand = {
"      \  'linter_checking': 'lightline#ale#checking',
"      \  'linter_warnings': 'lightline#ale#warnings',
"      \  'linter_errors': 'lightline#ale#errors',
"      \  'linter_ok': 'lightline#ale#ok',
"      \ }
"
"let g:lightline.component_type = {
"      \     'linter_checking': 'left',
"      \     'linter_warnings': 'warning',
"      \     'linter_errors': 'error',
"      \     'linter_ok': 'left',
"      \ }
"
"let g:lightline.active = { 'right': [ 
"      \ [ 'linter_checking', 'linter_errors', 'linter_warnings', 'linter_ok' ],
"      \ [ 'percent' ],
"      \ [ 'filetype', 'fileformat', 'fileencoding'] ]
"      \ }
"
"" Custom symbols for lightline-ALE
"let g:lightline#ale#indicator_warnings = "(!) "
"let g:lightline#ale#indicator_errors = "(✗) "
"let g:lightline#ale#indicator_ok = "(✓)"

"" ALE settings
"let g:ale_lint_on_text_changed = 'never' " don't auto-update
"let g:ale_lint_on_enter = 0 " update after writing file
"let g:ale_set_balloons = 1 " add hover information using mouse
"let g:ale_pattern_options = {'\.tex$': {'ale_enabled': 0}}

" set up alternate line breaking with gq to operate on lines in
" range individually
noremap <silent> <Leader>gq :set opfunc=BreakLines<CR>g@
ounmap <Leader>gq
" opfunc for breaking lines
function! BreakLines(type)
  execute "normal `["
  let st_line= line('.')
  execute "normal `]"
  let end_line= line('.')
  " operate in reverse so that every line in range is broken
  for i in reverse(range(st_line, end_line))
    execute "normal ". i ."Ggqq"
  endfor
  execute "normal `]"
endfunction

" Set options for syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
"let g:syntastic_check_on_open = 1
"" let g:syntastic_check_on_wq = 0
" let g:syntastic_python_checkers = ['flake8']
" let g:syntastic_tex_checkers = ['']
" let g:syntastic_python_flake8_args='--ignore=E501,E225,W503'
"let g:syntastic_python_pylint_args = "--indent-string='\t'"


" lightline settings / colors
set laststatus=2
let g:lightline.colorscheme = 'wombat'

colorscheme wombat256mod

" setup matlab plugins
" source $VIMRUNTIME/macros/matchit.vim

" setup mlint code checker
autocmd BufEnter *.m compiler mlint

" yank to clipbipboard
set clipboard=unnamed " copy to the system clipboard
"paste from clipboard
nnoremap <silent> <Leader>p :r !pbpaste<CR>

" Turn on spellchecking
nnoremap <silent> <F7> :setlocal spell! spelllang=en_us<CR>

" Tagbar Commands
nmap <F8> :TagbarToggle<CR>

"set up vimtex shortcuts
let g:vimtex_quickfix_mode = 0
let g:vimtex_syntax_nospell_comments = 1
let g:tex_flavor = 'latex'
let g:vimtex_motion_matchparen = 0
let g:vimtex_fold_enabled = 1
let g:vimtex_imaps_leader = '`'
let g:vimtex_imaps_enabled = 0
"let g:vimtex_view_general_viewer = '/Applications/Preview.app/Contents/MacOS/Preview'
let g:vimtex_view_general_viewer = 'open'
let g:vimtex_view_general_options = '-a Preview -g @pdf'
let g:vimtex_disable_version_warning = 1
let g:vimtex_echo_ignore_wait = 1
let g:vimtex_indent_on_ampersands = 0
let g:vimtex_matchparen_enabled = 0
let g:vimtex_indent_ignored_envs = [
      \ 'document',
      \ 'theorem',
      \ 'corollary',
      \ 'proposition',
      \ 'exercise',
      \ 'proof',
      \ 'claim',
      \]
let g:vimtex_fold_types = {
      \ 'sections': {
        \ 'parse_levels' : 0,
        \ 'sections' : [
          \ '%(add)?part',
          \ '%(chapter|addchap)',
          \ '%(section|addsec)',
          \ 'subsection',
          \ 'subsubsection',
          \ 'paragraph',
          \ 'subparagraph',
        \ ],
        \ 'parts' : [
          \ 'appendix',
          \ 'frontmatter',
          \ 'mainmatter',
          \ 'backmatter',
        \ ],
      \ },
    \ }
let g:vimtex_indent_ignored_envs = ['document']
let g:vimtex_toc_config = {}
let g:vimtex_toc_config['layer_status'] = {
      \ 'content': 1,
      \ 'label': 0,
      \ 'todo': 1,
      \ 'include': 0,
      \}
let g:vimtex_toc_config['split_pos'] = 'vert belowright'
let g:vimtex_toc_config['split_width'] = 52
let g:vimtex_toc_config['tocdepth'] = 5
" comment the above for compiling documents without proofs

" Set up tex spellchecking options
let g:tex_comment_nospell = 1

"set up forward and backward search with skim in vimtex
" -g switch makes the viewer open in the background
"let g:vimtex_view_general_viewer
"     \ = '/Applications/Skim.app/Contents/SharedSupport/displayline'
""et g:vimtex_view_general_options = '-r -g @line @pdf @tex'
"
"" This adds a callback hook that updates Skim after compilation
"let g:vimtex_latexmk_callback_hooks = ['UpdateSkim']
"function! UpdateSkim(status)
"  if !a:status | return | endif
"
"  let l:out = b:vimtex.out()
"  let l:tex = expand('%:p')
"  let l:cmd = [g:vimtex_view_general_viewer, '-r']
"  if !empty(system('pgrep Skim'))
"    call extend(l:cmd, ['-g'])
"  endif
"  if has('nvim')
"    call jobstart(l:cmd + [line('.'), l:out, l:tex])
"    echom 'nvim'
"  elseif has('job')
"    call job_start(l:cmd + [line('.'), l:out, l:tex])
"    echom 'job'
"  else
"    call system(join(l:cmd + [line('.'), shellescape(l:out), shellescape(l:tex)], ' '))
"    echom 'system'
"  endif
"endfunction

" load indent file for plugins
filetype indent on

" Delete newlines with backspace
set backspace=indent,eol,start

" jemdoc?
filetype plugin on

"show line numbers
set nu

" set path searching
set path=.,**
nnoremap <Leader>f :find *
nnoremap <Leader>s :sfind *
nnoremap <leader>v :vert sfind *
nnoremap <Leader>t :tabfind *

" set buffer manipulation
set wildcharm=<C-z>
nnoremap <Leader>b :buffer <C-z><S-Tab>
nnoremap <Leader>q :bp\|bd #<CR>
nnoremap <Leader>B :sbuffer <C-z><S-Tab>
nnoremap <Leader>gb :bnext<CR>
nnoremap <Leader>gB :bprevious<CR>

"set window movements
nnoremap <Leader>w <C-W>w
nnoremap <Leader>W <C-W>W

" set wildmenu
set wildmode=list:full
set wildignore=*.swp,*.bak
set wildignore+=*.pyc,*.class,*.sln,*.Master,*.csproj,*.csproj.user,*.cache,*.dll,*.pdb,*.min.*
set wildignore+=*/.git/**/*,*/.hg/**/*,*/.svn/**/*
set wildignore+=tags
set wildignore+=*.tar.*
set wildignore+=*.synctex.gz,*.pdf,*.dvi,*.fls,*.fdb_latexmk,*.blg,*.toc,*.out

" for wildmenu on osx
set wildignorecase

" set tag manipulations
nnoremap <Leader>j :tjump /

" set line size; 'set tw' works too
set textwidth=79

" enable syntax highlighting by default
syntax on

" custom tab width and stops
set tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab

" turn on autoindent
set autoindent

" change hl settings
set hlsearch
nnoremap <silent> <F9> :noh<CR>
hi Search ctermbg=DarkRed
hi Search ctermfg=Black

" Change case sensitive searching
" Note that this also affects substitutions.
set ignorecase " search case-insensitive by default
set smartcase  " automatically put a \C if capitalization

" Change hl settings for spell
hi clear SpellBad
hi SpellBad ctermbg=None
hi SpellBad ctermfg=196
hi SpellBad cterm=underline
hi SpellCap ctermbg=None
hi SpellCap ctermfg=12
hi SpellCap cterm=underline
hi SpellRare ctermbg=None
hi SpellRare ctermfg=13
hi SpellRare cterm=underline
hi SpellLocal ctermbg=None
hi SpellLocal ctermfg=14
hi SpellLocal cterm=underline

" Add some shortcut commands for templates
command! Makegcc :r ~/.vim/gcc_makefile.txt
command! Maketex :r ~/.vim/tex_makefile.txt
command! Memoir :r ~/.vim/memoir_base.txt
command! Article :r ~/.vim/article_base.txt
command! Chapter :r ~/.vim/chapter_base.txt
command! Figure :r ~/.vim/figure_base.txt
command! Subfigure :r ~/.vim/subfigure_base.txt
command! Beamer :r ~/.vim/beamer_base.txt
command! Poster :r ~/.vim/poster_base.txt
command! Tikz :r ~/.vim/tikz_base.txt
command! Python :r ~/.vim/python_skeleton.py
command! Listings :r ~/.vim/listings_base.txt

" Add a shortcut command for git pushing to overleaf
command! Overleaf :Git add * | Git commit -m asdf | Git push

" New file templates
au BufNewFile *.py 0r ~/.vim/python_skeleton.py

" A shortcut for quickfix windows
nnoremap <Leader>c :cclose<CR>

" Format with yapf
" autocmd FileType python nnoremap <Leader>= :0,$!yapf<CR>

" NERDTree Configuration
nmap <F6> :NERDTreeToggle<CR>
let g:NERDTreeGitStatusIndicatorMapCustom = {
                \ 'Modified'  :'✹',
                \ 'Staged'    :'✚',
                \ 'Untracked' :'✭',
                \ 'Renamed'   :'➜',
                \ 'Unmerged'  :'═',
                \ 'Deleted'   :'✖',
                \ 'Dirty'     :'✗',
                \ 'Ignored'   :'☒',
                \ 'Clean'     :'✔︎',
                \ 'Unknown'   :'?',
                \ }

" jedi-vim settings
set noshowmode
let g:jedi#goto_assignments_command = "<leader>a"
let g:jedi#popup_on_dot = 0
"let g:jedi#force_py_version=3.8
let g:jedi#show_call_signatures = "2"
let g:jedi#show_call_signatures_delay = 0

" fastfold settings
let g:fastfold_savehook = 0

" SympylFold options
let g:SimpylFold_docstring_preview = 1

" Hack to get the correct versions of jedi and parso on path
" seems there is a conflict with the versions anaconda wants for other packages
python3 << EOF
import sys
#sys.path.insert(-1, "~/.vim/pack/git-plugins/start/jedi-vim/pythonx")
sys.path.insert(0, "/Users/sadboys/.vim/pack/git-plugins/start/jedi-vim/pythonx/jedi")
sys.path.insert(0, "/Users/sadboys/.vim/pack/git-plugins/start/jedi-vim/pythonx/parso")
EOF
