"" export a PYTHONHOME environment variable
" vim seems to need this to run python... but other python software doesn't
" interact properly
" so after this is set here, probably can't run many other programs in this
" session
" let $PYTHONHOME = "/Users/sdbuch/anaconda3"
" set python 3 dll
set pythonthreedll=/Users/sdbuch/anaconda3/bin/python

" set leader character
let mapleader = ","

" Backport for trim()
" https://github.com/Cimbali/vim-better-whitespace/commit/855bbef863418a36bc10e5a51ac8ce78bcbdcef8
function! s:trim(s)
    if exists('*trim')
        return trim(a:s)
    else
        return substitute(a:s, '^\s*\(.\{-}\)\s*$', '\1', '')
    endif
endfunction

" Set up vim-plug
let s:vim_plug_folder = (has('nvim') ? '$HOME/.config/nvim' : '$HOME/.vim') . '/autoload/'
let s:vim_plug_path = s:vim_plug_folder . 'plug.vim'
let s:fresh_install = 0
if empty(glob(s:vim_plug_path))
  if executable('curl')
    execute 'silent !curl -fLo ' . s:vim_plug_path . ' --create-dirs '
          \ . 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  elseif executable('wget')
    execute 'silent !mkdir -p ' . s:vim_plug_folder
    execute 'silent !wget --output-document=' . s:vim_plug_path
          \ . ' https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  else
    echoerr 'Need curl or wget to download vim-plug!'
  endif
  autocmd VimEnter * PlugUpdate! --sync 32 | source $MYVIMRC
  let s:fresh_install = 1
endif

" #############################################
" ######           Plugins             ########
" #############################################

" Use Vundle-style path for vim-plug
let s:bundle_path = (has('nvim') ? '~/.config/nvim' : '~/.vim') . '/bundle'
execute 'call plug#begin("' . s:bundle_path . '")'

" Search plugin
" > Show instance # in statusline when we search
Plug 'henrik/vim-indexed-search'

" Git integration
Plug 'tpope/vim-fugitive'

" Folding
Plug 'Konfekt/FastFold'
Plug 'tmhedberg/SimpylFold'

" Lightline
Plug 'itchyny/lightline.vim'
Plug 'halkn/lightline-lsp'
" {{
  " lightline settings / colors
  let g:lightline = {}

  let g:lightline.colorscheme = 'wombat'

  " Lightline components (lsp integration)
  let g:lightline = {
        \ 'active': {
        \   'right': [ [ 'lsp_errors', 'lsp_warnings', 'lsp_ok', 'lineinfo' ],
        \              [ 'percent' ],
        \              [ 'fileformat', 'fileencoding', 'filetype' ] ]
        \ },
        \ 'component_expand': {
        \   'lsp_warnings': 'lightline_lsp#warnings',
        \   'lsp_errors':   'lightline_lsp#errors',
        \   'lsp_ok':       'lightline_lsp#ok',
        \ },
        \ 'component_type': {
        \   'lsp_warnings': 'warning',
        \   'lsp_errors':   'error',
        \   'lsp_ok':       'middle',
        \ },
        \ }

" }}

" Vimtex
Plug 'lervag/vimtex'
" {{
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
        \ 'envs' : {
        \   'blacklist' : [],
        \   'whitelist' : ['figure', 'subfigure', 'table', 'theorem', 'lemma', 'proposition', 'corollary', 'definition', 'proof'],
        \ },
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
" }}



" Tagbar
Plug 'preservim/tagbar'
" {{
  let g:tagbar_show_linenumbers = 1
" }}

" NERDTree
Plug 'preservim/nerdtree'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'Xuyuanp/nerdtree-git-plugin'

" {{
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
  let g:NERDTreeShowHidden=1
  let g:NERDTreeShowLineNumbers = 1
  let g:NERDTreeMinimalUI = 1
  let g:NERDTreeFileExtensionHighlightFullName = 1
  let g:NERDTreeExactMatchHighlightFullName = 1
  let g:NERDTreePatternMatchHighlightFullName = 1
" }}


" Gutentags
Plug 'ludovicchabant/vim-gutentags'

" {{
  " TAGS
  " let g:gutentags_trace=1 " this is a debug command
  let g:gutentags_resolve_symlinks=0
" }}

" Display markers to signify different indentation levels
Plug 'Yggdroot/indentLine'
" {{
    let g:indentLine_char = '·'
    let g:indentLine_fileTypeExclude = ['json', 'markdown', 'tex']
" }}

" Massive language pack for syntax highlighting, etc
Plug 'sheerun/vim-polyglot'
" {{
    " Disable csv.vim: this overrides a bunch of default vim bindings with
    " csv-specific ones that looks high-effort to get used to
    "
    " For highlighting etc, we use rainbow_csv (see below)
    let g:polyglot_disabled = ['csv']

    " Use Semshi for Python
    if has("nvim")
        Plug 'numirias/semshi'
    endif

    " Markdown configuration
    let g:vim_markdown_conceal = 0
    let g:vim_markdown_conceal_code_blocks = 0
    let g:vim_markdown_auto_insert_bullets = 0
    let g:vim_markdown_new_list_item_indent = 0
    let g:vim_markdown_math = 1

    augroup SyntaxSettings
        autocmd!
        function! s:HighlightPythonSpecial()
            " For Python, bold TODO keyword in strings/docstrings
            " Copy the docstring highlighting, then override (a bit superfluous)
            syn keyword DocstringTodo TODO FIXME XXX containedin=pythonString,pythonRawString

            redir => l:python_string_highlight
            silent highlight Constant
            redir END

            let l:python_string_highlight = s:trim(split(l:python_string_highlight, 'xxx')[1])
            highlight clear DocstringTodo
            execute 'highlight DocstringTodo ' . l:python_string_highlight . ' cterm=bold'
        endfunction

        " Due to trigger ordering, `autocmd Filetype python` here doesn't work!
        autocmd BufEnter,WinEnter *.py call s:HighlightPythonSpecial()
    augroup END
" }}

" LSP plugins for autocompletion, jump to def, etc
" NOTE: Have a bunch of dependencies.
" go
" > brew install go
" npm
" > brew install npm
" cargo
" > brew install rust
" Note that we also need to actually install some LSPs, eg:
" > https://github.com/mattn/vim-lsp-settings
" LspInstallServer
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'

" {{
    " Move servers into .vim directory
    let g:lsp_settings_servers_dir = expand(s:vim_plug_folder . "/../vim-lsp-settings/servers")

    " Global LSP config
    function! s:on_lsp_buffer_enabled() abort
        " setlocal omnifunc=lsp#complete
        if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
        nmap <buffer> <Leader>gd <plug>(lsp-definition)
        nmap <buffer> <Leader>gr <plug>(lsp-references)
        nmap <buffer> <Leader>gi <plug>(lsp-implementation)
        " This conflicts with an fzf binding
        nmap <buffer> <Leader>gt <plug>(lsp-type-definition)
        nmap <buffer> <Leader>rn <plug>(lsp-rename)
        nmap <buffer> <Leader>[g <Plug>(lsp-previous-diagnostic)
        nmap <buffer> <Leader>]g <Plug>(lsp-next-diagnostic)
        nmap <buffer> <Leader>le <Plug>(lsp-document-diagnostics)
        nmap <buffer> <Leader>sh <Plug>(lsp-signature-help)
        nmap <buffer> K <plug>(lsp-hover)
    endfunction

    " Call s:on_lsp_buffer_enabled only for languages with registered
    " servers
    augroup lsp_install
        autocmd!
        autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
    augroup END

    " Make colors a bit less distracting
    augroup LspColors
        autocmd!

        function! s:SetLspColors()
            highlight LspErrorText ctermfg=red ctermbg=NONE
            highlight LspErrorHighlight ctermbg=236

            highlight LspWarningText ctermfg=yellow ctermbg=NONE
            highlight LspWarningHighlight ctermbg=236

            highlight LspHintText ctermfg=blue ctermbg=NONE
            highlight LspHintHighlight ctermbg=236

            highlight LspErrorVirtualText ctermfg=238
            highlight LspWarningVirtualText ctermfg=238
            highlight LspInformationVirtualText ctermfg=238
            highlight LspHintVirtualText ctermfg=238
        endfunction

        autocmd ColorScheme * call s:SetLspColors()
    augroup END

    " Set sign column symbols
    let g:lsp_diagnostics_signs_error = {'text': '▴'}
    let g:lsp_diagnostics_signs_warning = {'text': '▴'}
    let g:lsp_diagnostics_signs_information = {'text': '▴'}
    let g:lsp_diagnostics_signs_hint = {'text': '▴'}
    let g:lsp_diagnostics_signs_priority = 10
    
    " Set some semantic highlighting
    let g:lsp_semantic_enabled = 1

    " Jump through some hoops to auto-install pylsp-mypy whenever we call :LspInstallServer
    function! s:check_for_pylsp_mypy()
        if filereadable(expand(g:lsp_settings_servers_dir . "/pylsp-all/venv/bin/pylsp"))
            \ && !filereadable(expand(g:lsp_settings_servers_dir . "/pylsp-all/venv/bin/mypy"))

            " Install from source because pypi version of pylsp-mypy is broken
            " for Python 3. Our fork includes support for various settings and
            " flags that aren't available upstream.
            let l:cmd =  g:lsp_settings_servers_dir .
                \ '/pylsp-all/venv/bin/pip3 install ' .
                \ 'git+https://github.com/brentyi/pylsp-mypy.git'

            if has('nvim')
                split new
                call termopen(l:cmd, {'cwd': g:lsp_settings_servers_dir})
            else
                let l:bufnr = term_start(l:cmd)
            endif
        endif
    endfunction

    augroup CheckForPylspMypy
        autocmd!
        autocmd User lsp_setup call s:check_for_pylsp_mypy()
    augroup END

    let g:lsp_settings = {}
    let g:lsp_settings['efm-langserver'] = {'disabled': v:false}
    let g:lsp_settings['pylsp-all'] = {
        \     'workspace_config': { 'pylsp': {
        \         'configurationSources': ['flake8'],
        \         'plugins': {
        \             'pylsp_mypy': {
        \                 'enabled': v:true,
        \                 'live_mode': v:false,
        \                 'dmypy': v:false,
        \                 'strict': v:false,
        \                 'prepend': ['--python-executable', s:trim(system('which python'))],
        \                 'colocate_cache_with_config': v:true
        \             }
        \         }
        \     }}
        \ }
    let g:lsp_settings['clangd'] = {'allowlist': ['c', 'cpp', 'objc', 'objcpp', 'cuda']}

    " Show error messages below statusbar
    let g:lsp_diagnostics_echo_cursor = 1

    " Disable tex.vim errors; texlab is far more useful
    let g:tex_no_error=1
" }}

" Async 'appears as you type' autocompletion
" > Use Tab, S-Tab to select, <CR> to confirm (see above for binding)
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'prabirshrestha/asyncomplete-file.vim'
Plug 'prabirshrestha/asyncomplete-tags.vim'
Plug 'prabirshrestha/asyncomplete-emoji.vim'
Plug 'thecontinium/asyncomplete-buffer.vim'

" {{
    " don't auto popup
    let g:asyncomplete_auto_popup = 0
    " Bindings
    " Use <CR> for completion confirmation, <Tab> and <S-Tab> for selection
    function! s:smart_carriage_return()
        if !pumvisible()
            " No completion window open -> insert line break
            return "\<CR>"
        endif
        if exists('*complete_info') && complete_info()['selected'] == -1
            " No element selected: close the completion window with Ctrl+E, then
            " carriage return
            "
            " Requires Vim >8.1ish
            return "\<C-e>\<CR>"
        endif

        " Select completion
        return "\<C-y>"
    endfunction
    inoremap <expr> <CR> <SID>smart_carriage_return()

    function! s:check_back_space() abort
        let col = col('.') - 1
        return !col || getline('.')[col - 1]  =~ '\s'
    endfunction

    " Jump forward or backward
    " Adding some vsnip integrations here
    imap <expr> <TAB>
        \ vsnip#jumpable(1) ? '<Plug>(vsnip-jump-next)' :
        \ pumvisible() ? "\<C-n>" :
        \ <SID>check_back_space() ? "\<TAB>" :
        \ asyncomplete#force_refresh()
    imap <expr><S-TAB>
        \ vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' :
        \ pumvisible() ? "\<C-p>" : "\<C-h>"
    smap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
    smap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'

    " Register path completer
    function! s:register_asyncomplete_sources() abort
        call asyncomplete#register_source(asyncomplete#sources#file#get_source_options({
            \ 'name': 'file',
            \ 'allowlist': ['*'],
            \ 'priority': 10,
            \ 'completor': function('asyncomplete#sources#file#completor')
            \ }))

        call asyncomplete#register_source(asyncomplete#sources#tags#get_source_options({
            \ 'name': 'tags',
            \ 'allowlist': ['c'],
            \ 'completor': function('asyncomplete#sources#tags#completor'),
            \ 'config': {
            \    'max_file_size': 50000000,
            \  },
            \ }))

        call asyncomplete#register_source(asyncomplete#sources#emoji#get_source_options({
            \ 'name': 'emoji',
            \ 'allowlist': ['gitcommit', 'markdown'],
            \ 'completor': function('asyncomplete#sources#emoji#completor'),
            \ }))

        call asyncomplete#register_source(asyncomplete#sources#buffer#get_source_options({
            \ 'name': 'buffer',
            \ 'allowlist': ['*'],
            \ 'blocklist': ['go'],
            \ 'completor': function('asyncomplete#sources#buffer#completor'),
            \ 'config': {
            \    'max_buffer_size': 1000000,
            \  },
            \ }))
    endfunction

    autocmd User asyncomplete_setup call s:register_asyncomplete_sources()
" }}

" https://raw.githubusercontent.com/junegunn/vim-plug/master/doc/plug.txtSnippet support
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'
" {{
    let g:vsnip_snippet_dir = expand(s:vim_plug_folder . "../snippets/")
    " Shorten the delay time for choices
    let g:vsnip_choice_delay = 100

    " <Tab>/<S-Tab> are bound under asyncomplete
    
    " Select or cut text to use as $TM_SELECTED_TEXT in the next snippet.
    " See https://github.com/hrsh7th/vim-vsnip/pull/50
    nmap <Leader>s <Plug>(vsnip-select-text)
    xmap <Leader>s <Plug>(vsnip-select-text)
    nmap <Leader>S <Plug>(vsnip-cut-text)
    xmap <Leader>S <Plug>(vsnip-cut-text)
" }}

" Automated docstrings
" Plug 'kkoomen/vim-doge', { 'do': { -> doge#install() } }
Plug 'kkoomen/vim-doge', { 'do': 'npm i --no-save && npm run build:binary:unix' }
" {{
    let g:doge_doc_standard_python = 'google'

    " Binding: *P*ut *D*oc *S*tring.
    let g:doge_mapping = '<Leader>pds'
" }}

call plug#end()


" Do the rest of the settings if not fresh install
if !s:fresh_install

  silent! helptags ALL

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

  set laststatus=2

  colorscheme wombat256mod

  " setup matlab plugins
  " source $VIMRUNTIME/macros/matchit.vim

  " setup mlint code checker
  autocmd BufEnter *.m compiler mlint

  " yank to clipbipboard
  set clipboard=unnamed " copy to the system clipboard
  "paste from clipboard
  nnoremap <silent> <Leader>pcb :r !pbpaste<CR>

  " Turn on spellchecking
  nnoremap <silent> <F7> :setlocal spell! spelllang=en_us<CR>

  " Tagbar Commands
  nmap <F8> :TagbarToggle<CR>

  " Set up tex spellchecking options
  let g:tex_comment_nospell = 1

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
  nnoremap <Leader>ff :find *
  nnoremap <Leader>sf :sfind *
  nnoremap <leader>vf :vert sfind *
  nnoremap <Leader>tf :tabfind *

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
  command! Overleaf :Git add . | Git commit -m asdf | Git push

  " New file templates
  au BufNewFile *.py 0r ~/.vim/python_skeleton.py

  " A shortcut for quickfix windows
  nnoremap <Leader>c :cclose<CR>

  " Format with yapf
  " autocmd FileType python nnoremap <Leader>= :0,$!yapf<CR>

  " NERDTree Configuration
  nmap <F6> :NERDTreeToggle<CR>

  " fastfold settings
  let g:fastfold_savehook = 0

  " SympylFold options
  let g:SimpylFold_docstring_preview = 1

endif
