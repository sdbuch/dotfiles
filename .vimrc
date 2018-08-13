" set leader character
let mapleader = ","

" run pathogen plugin manager
" execute pathogen#infect()
" Helptags

" VIM 8: load packages
" see h: add-package
packadd! matchit
packloadall
silent! helptags ALL

" ALE integration
" Taken from https://github.com/maximbaz/lightline-ale
let g:lightline = {}

let g:lightline.component_expand = {
      \  'linter_checking': 'lightline#ale#checking',
      \  'linter_warnings': 'lightline#ale#warnings',
      \  'linter_errors': 'lightline#ale#errors',
      \  'linter_ok': 'lightline#ale#ok',
      \ }

let g:lightline.component_type = {
      \     'linter_checking': 'left',
      \     'linter_warnings': 'warning',
      \     'linter_errors': 'error',
      \     'linter_ok': 'left',
      \ }

let g:lightline.active = { 'right': [ 
      \ [ 'linter_checking', 'linter_errors', 'linter_warnings', 'linter_ok' ],
      \ [ 'percent' ],
      \ [ 'filetype', 'fileformat', 'fileencoding'] ]
      \ }

" Custom symbols for lightline-ALE
let g:lightline#ale#indicator_warnings = "(!) "
let g:lightline#ale#indicator_errors = "(✗) "
let g:lightline#ale#indicator_ok = "(✓)"

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

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_python_checkers = ['flake8']
let g:syntastic_tex_checkers = ['']
let g:syntastic_python_flake8_args='--ignore=E501,E225,W503'
"let g:syntastic_python_pylint_args = "--indent-string='\t'"


" python syntax
let python_highlight_all=1

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

"set up vimtex shortcuts
let g:tex_flavor = 'latex'
let g:vimtex_motion_matchparen = 0
let g:vimtex_imaps_leader = '`'
let g:vimtex_imaps_enabled = 0
"let g:vimtex_view_general_viewer = '/Applications/Preview.app/Contents/MacOS/Preview'
let g:vimtex_view_general_viewer = 'open'
let g:vimtex_view_general_options = '-a Preview -g @pdf'
let g:vimtex_view_general_options_latexmk = '-a Preview -g @pdf'
let g:vimtex_disable_version_warning = 1
let g:vimtex_echo_ignore_wait = 1
"let g:vimtex_indent_enabled = 0
let g:vimtex_indent_on_ampersands = 0
"let g:vimtex_view_enabled = 0
"let g:vimtex_view_automatic = 0
"let g:vimtex_view_enabled = 0
let g:vimtex_matchparen_enabled = 0
let g:vimtex_index_split_pos = 'vert belowright'
let g:vimtex_indent_ignored_envs = [
      \ 'document',
      \ 'theorem',
      \ 'corollary',
      \ 'proposition',
      \ 'exercise',
      \ 'proof',
      \ 'claim',
      \]
let g:vimtex_indent_ignored_envs = ['document']
" comment the above for compiling documents without proofs

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
"    echom "nvim"
"  elseif has('job')
"    call job_start(l:cmd + [line('.'), l:out, l:tex])
"    echom "job"
"  else
"    call system(join(l:cmd + [line('.'), shellescape(l:out), shellescape(l:tex)], ' '))
"    echom "system"
"  endif
"endfunction

" load indent file for plugins
filetype indent on

" Delete newlines with backspace
set backspace=indent,eol,start

" jemdoc?
filetype plugin on
augroup filetypedetect
	au! BufNewFile,BufRead *.jemdoc setf jemdoc
augroup END

" Last line is for proper wrapping of jemdoc lists, etc.
autocmd Filetype jemdoc setlocal comments=:#,fb:-,fb:.,fb:--,fb:..,fb:\:

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
set textwidth=64

" enable syntax highlighting by default
syntax enable

" custom tab width and stops
set tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab

" turn on autoindent
set autoindent

"Add some shortcut commands
command! Makegcc :r ~/.vim/gcc_makefile.txt
command! Maketex :r ~/.vim/tex_makefile.txt
command! Memoir :r ~/.vim/memoir_base.txt
command! Article :r ~/.vim/article_base.txt
command! Figure :r ~/.vim/figure_base.txt
command! Beamer :r ~/.vim/beamer_base.txt
command! Tikz :r ~/.vim/tikz_base.txt
command! Python :r ~/.vim/python_imports.txt
command! Listings :r ~/.vim/listings_base.txt
" Edit files remotely on john-vision ssh server. Requires full
" path (~/my_file for home, or /home/user/my_file otherwise) as
" argument
" Also need this set up in .ssh/config
command! -nargs=1 Ejv :e scp://sam@john-vision/<args>

" add a shortcut to ;t for toggling tagbar
" nmap <localleader>t  :TagbarToggle<CR> 

" add a shortcut with pyclewn to place a breakpoint at current line
" map ;b :exe "Cbreak " . expand("%:p") . ":" . line(".")<CR>

" add a shortcut with pyclewn to show value of variable at current line
" map ;v :exe "Cprint " . expand("<cword>") <CR>

" add a shortcut with pyclewn to clear all breakpoints at current line
" map ;c :exe "Cclear " . line(".")<CR>

" add a shortcut with pyclewn to step to next line
nmap <F8> :exe "Cstep"<CR>

