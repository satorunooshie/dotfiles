"---------------------------------------------------------------------------
" .vimrc
"---------------------------------------------------------------------------
" Initialize:"{{{
"
augroup MyVimrcCmd
    autocmd!
augroup END

" Note: that the order of the following commands is important.
set encoding=utf-8
scriptencoding utf-8

" Note: Syntax generates based on settings in runtimepath
" so it is nececcary to initialize runtimepath and
" load file type highlight plugins prior to syntax on.
syntax on

" <: Maximum number of lines saved for each register.
" h: 'hlsearch' highlighting will not be restored.
" s: Maximum size of an item in Kbyte.
" ': Maximum number of previously edited files for which the marks are remembered.
" :: Maximum number of items in the command-line history to be saved.
set viminfo+=<1000,h,s100,'10000,:100000
" delete default setting
set viminfo-=<50,s10,'100
set rtp+=/opt/homebrew/opt/fzf

filetype plugin indent on

"---------------------------------------------------------------------------
" Load Plugins:"{{{
"
let $PACKPATH = expand('~/.vim/pack/Bundle')
let s:plugins = {'start': [], 'opt': []}
call add(s:plugins.opt, 'https://github.com/vim-jp/vimdoc-ja')
call add(s:plugins.opt, 'https://github.com/mhinz/vim-signify')
call add(s:plugins.opt, 'https://github.com/kana/vim-textobj-user')
call add(s:plugins.opt, 'https://github.com/kana/vim-textobj-indent')
call add(s:plugins.opt, 'https://github.com/kana/vim-textobj-syntax')
call add(s:plugins.opt, 'https://github.com/kana/vim-textobj-line')
call add(s:plugins.opt, 'https://github.com/kana/vim-textobj-fold')
call add(s:plugins.opt, 'https://github.com/kana/vim-textobj-entire')
call add(s:plugins.opt, 'https://github.com/thinca/vim-textobj-between')
call add(s:plugins.opt, 'https://github.com/thinca/vim-textobj-comment')
call add(s:plugins.opt, 'https://github.com/h1mesuke/textobj-wiw')
call add(s:plugins.opt, 'https://github.com/sgur/vim-textobj-parameter')
call add(s:plugins.opt, 'https://github.com/kana/vim-operator-user')
call add(s:plugins.opt, 'https://github.com/kana/vim-operator-replace')
call add(s:plugins.opt, 'https://github.com/thinca/vim-qfreplace')
call add(s:plugins.opt, 'https://github.com/mattn/vim-maketable')
" Live preview substitute result and
" highlight patterns and ranges for Ex commands in Command-line mode.
call add(s:plugins.opt, 'https://github.com/markonm/traces.vim')
" Highlight each by a different color.
call add(s:plugins.opt, 'https://github.com/daisuzu/rainbowcyclone.vim')
" Extended % matching.
call add(s:plugins.opt, 'https://github.com/vim-scripts/matchit.zip')
call add(s:plugins.opt, 'https://github.com/tpope/vim-surround')
" An extensible & universal comment vim-plugin that also handles embedded filetypes.
" ex) gcc.
call add(s:plugins.opt, 'https://github.com/tomtom/tcomment_vim')
" Make blockwise visual mode more useful.
" ex) shift v + shift i.
call add(s:plugins.opt, 'https://github.com/kana/vim-niceblock')
" Star for visual mode.
" ex) shift v + *.
call add(s:plugins.opt, 'https://github.com/thinca/vim-visualstar')
call add(s:plugins.opt, 'https://github.com/thinca/vim-quickrun')
" Prettyprint vim variables.
" ex) :PP.
call add(s:plugins.opt, 'https://github.com/thinca/vim-prettyprint')
call add(s:plugins.opt, 'https://github.com/thinca/vim-showtime')
call add(s:plugins.opt, 'https://github.com/LeafCage/vimhelpgenerator')
call add(s:plugins.opt, 'https://github.com/prabirshrestha/vim-lsp')
call add(s:plugins.opt, 'https://github.com/mattn/vim-lsp-settings')
call add(s:plugins.opt, 'https://github.com/knsh14/vim-github-link')
call add(s:plugins.opt, 'https://github.com/satorunooshie/vim-drawbox')
call add(s:plugins.opt, 'https://github.com/lifepillar/vim-colortemplate')

function! s:has_plugin(name)
    return globpath(&runtimepath, 'plugin/' . a:name . '.vim') !=# ''
                \ || globpath(&runtimepath, 'autoload/' . a:name . '.vim') !=# ''
endfunction

function! s:mkdir_if_not_exists(path)
    if !isdirectory(a:path)
        call mkdir(a:path, 'p')
    endif
endfunction

function! s:create_helptags(path)
    if isdirectory(a:path)
        execute 'helptags ' . a:path
    endif
endfunction

function! InstallPackPlugins() "{{{
    for key in keys(s:plugins)
        let dir = expand($PACKPATH . '/' . key)
        call s:mkdir_if_not_exists(dir)

        for url in s:plugins[key]
            let dst = expand(dir . '/' . split(url, '/')[-1])
            if isdirectory(dst)
                " Plugin has already been installed.
                continue
            endif

            echo 'installing: ' . dst
            let cmd = printf('git clone --recursive %s %s', url, dst)
            call system(cmd)
            call s:create_helptags(expand(dst . '/doc/'))
        endfor
    endfor
endfunction "}}}

function! UpdateHelpTags() "{{{
    for key in keys(s:plugins)
        let dir = expand($PACKPATH . '/' . key)

        for url in s:plugins[key]
            let dst = expand(dir . '/' . split(url, '/')[-1])
            if !isdirectory(dst)
                " plugin is not installed
                continue
            endif

            echomsg 'helptags: ' . dst
            call s:create_helptags(expand(dst . '/doc/'))
        endfor
    endfor
endfunction "}}}

function! UpdatePackPlugins() "{{{
    topleft split
    edit `='[update plugins]'`
    setlocal buftype=nofile

    let s:pidx = 0
    call timer_start(100, 'PluginUpdateHandler', {'repeat': len(s:plugins.opt)})
endfunction "}}}

function! PluginUpdateHandler(timer) "{{{
    let dir = expand($PACKPATH . '/' . 'opt')
    let url = s:plugins.opt[s:pidx]
    let dst = expand(dir . '/' . split(url, '/')[-1])

    let cmd = printf('git -C %s pull --ff --ff-only', dst)
    call job_start(cmd, {'out_io': 'buffer', 'out_name': '[update plugins]'})

    let s:pidx += 1
    if s:pidx == len(s:plugins.opt)
        call UpdateHelpTags()
    endif
endfunction "}}}

let s:pidx = 0
function! PackAddHandler(timer) "{{{
    let plugin_name = split(s:plugins.opt[s:pidx], '/')[-1]

    let plugin_path = expand($PACKPATH . '/opt/' . plugin_name)
    if isdirectory(plugin_path)
        execute 'packadd ' . plugin_name
    endif

    let s:pidx += 1
    if s:pidx == len(s:plugins.opt)
        packadd cfilter
        " For filetype plugin.
        doautocmd FileType
        " For vim-lsp.
        call lsp#enable()
        " For vim-signify.
        SignifyEnable
    endif
endfunction "}}}

if has('vim_starting') && has('timers')
    packadd vim-textobj-user
    packadd vim-operator-user
    autocmd MyVimrcCmd VimEnter * call timer_start(1, 'PackAddHandler', {'repeat': len(s:plugins.opt)})
endif
"}}}

"---------------------------------------------------------------------------
" Mouse:"{{{
"
" Normal mode and Terminal modes
" Visual mode, Insert mode, Command-line mode
" all previous modes when editing a help file.
set mouse=a
set nomousefocus
"}}}

"---------------------------------------------------------------------------
" Edit:"{{{
"
set noswapfile
set nobackup
" The maximum number of items to show in the popup menu for Insert mode completion.
set pumheight=15
" Register '*' and '+' for all yank, delete, change and put operations.
set clipboard=unnamed,unnamedplus
set tabstop=4
set softtabstop=4
set shiftwidth=4
set smarttab
" Spaces are used in indents.
set expandtab
" Influences the working of <BS>, <Del>, CTRL-W and CTRL-U in Insert mode.
" indent	allow backspacing over autoindent
" eol	    allow backspacing over line breaks (join lines)
" start	    allow backspacing over the start of insert; CTRL-W and CTRL-U
"           stop once at the start of insert.
set backspace=indent,eol,start
" Allow specified keys that move the cursor left/right to move to the previous/next line when the cursor is on the first/last character in the line.
" b    <BS>	 Normal and Visual
" s    <Space>	 Normal and Visual
" <    <Left>	 Normal and Visual
" >    <Right>	 Normal and Visual
" [    <Left>	 Insert and Replace
" ]    <Right>	 Insert and Replace
set whichwrap=b,s,<,>,[,]
" Command-line completion operates in an enhanced mode.
set wildmenu
" Command-line history.
set history=2000
set virtualedit+=block
set autoindent
" Smart indenting.
set smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class
" Use the popup menu also when there is only one match.
" Only insert the longest common text of the matches.
set completeopt=menuone,longest
" Settings for Japanese folding.
set formatoptions+=mM
" Don't continue the comment line automatically.
set formatoptions-=ro
" Prevent overwriting format options.
autocmd MyVimrcCmd FileType * setlocal formatoptions-=ro
set nrformats=alpha,hex,bin,unsigned

" tags:"{{{
" ctags
set tags=./tags
set tags+=tags;
set tags+=./**/tags
"}}}

" grep:"{{{
set grepprg=git\ grep\ --no-color\ -n\ --column\ --untracked\ --full-name
" Cannot be used --no-index and --untracked at the same time.
" --no-index: for not using git repository.
command! UseGitGrepNoIndex set grepprg=git\ grep\ --no-color\ -n\ --column\ --no-index\ --full-name
command! UseDefaultGitGrep set grepprg=git\ grep\ --no-color\ -n\ --column\ --untracked\ --full-name

" Open quickfix window automatically.
autocmd MyVimrcCmd QuickfixCmdPre make,grep,grepadd,vimgrep,vimgrepadd,helpgrep copen
"}}}

autocmd MyVimrcCmd InsertLeave * if &paste | set nopaste | endif
"}}}

"---------------------------------------------------------------------------
" Color:"{{{
"
set t_Co=256
" Change cursor shape in insert mode.
if &term =~# 'xterm'
    let &t_SI = "\<Esc>[5 q"
    let &t_SR = "\<Esc>[3 q"
    let &t_EI = "\<Esc>[1 q"
endif

" Visualization of the full-width space at the end of the line "{{{
" https://vim-jp.org/vim-users-jp/2009/07/12/Hack-40.html
augroup highlightIdegraphicSpace
    autocmd!
    autocmd Colorscheme * highlight IdeographicSpace term=underline ctermbg=45 guibg=Blue
    autocmd VimEnter,WinEnter * match IdeographicSpace /　/
augroup END
"}}}

" github.com/satorunooshie/pairscolorscheme
colorscheme Pairs
"}}}

"---------------------------------------------------------------------------
" netrw:"{{{
"
" The percentage of the current netrw buffer's window to be used for the new window.
let g:netrw_winsize = 30
" Preview window shown in a vertically split window.
let g:netrw_preview=1
" Hide swap files.
let g:netrw_list_hide='^.*.swp'
"}}}

"---------------------------------------------------------------------------
" View:"{{{
"
set number
" Always draw the signcolumn to prevent rattling.
set signcolumn=yes
set cursorline
" Highlight only numbers.
set cursorlineopt=number
"}}}

" Avoid `Thanks for flying Vim`.
set title
set nowrap
" When a bracket is inserted, briefly jump to the matching one.
set showmatch
" Tenths of a second to show the matching paren is 0.1 sec.
set matchtime=1
" Always show status line.
set laststatus=2
" Always display the line with tab page labels.
set showtabline=2
" Show (partial) command in the last line of the screen.
set showcmd
" Number of screen lines to use for the command-line.
set cmdheight=1
" Never show the current mode in the last line of the screen.
set noshowmode
" Show unprintable characters hexadecimal as <xx> instead of using ^C and ~C.
" When inserting, can append a character with CTRL-V uxxxx.
set display=uhex
" Default height for a preview window.
set previewheight=12
" Not showing tabs as CTRL-I is displayed, display $ after end of line.
set nolist
set listchars=tab:>-,extends:<,precedes:>,trail:-,eol:$,nbsp:%

" Tabline settings "{{{
function! s:is_modified(n) "{{{
    return getbufvar(a:n, '&modified') == 1 ? '+' : ''
endfunction "}}}

function! s:tabpage_label(n) "{{{
    let title = gettabwinvar(a:n, 0, 'title')
    if title !=# ''
        return title
    endif

    let bufnrs = tabpagebuflist(a:n)
    let buflist = join(map(copy(bufnrs), 'v:val . s:is_modified(v:val)'), ',')

    let curbufnr = bufnrs[tabpagewinnr(a:n) - 1]
    let fname = pathshorten(bufname(curbufnr))

    let label = '[' . buflist . ']' . fname

    let hi = a:n is tabpagenr() ? '%#TabLineSel#' : '%#TabLine#'

    return '%' . a:n . 'T' . hi . label . '%T%#TabLineFill#'
endfunction "}}}

function! MakeTabLine() "{{{
    let titles =map(range(1, tabpagenr('$')), 's:tabpage_label(v:val)')
    let sep = ' | '
    let tabpages = join(titles, sep) . sep . '%#TabLineFill#%T'
    let info = fnamemodify(getcwd(), '~:') . ' '
    return tabpages . '%=' . info
endfunction "}}}

set tabline=%!MakeTabLine()
"}}}

" StatusLine settings "{{{
augroup StatusLine "{{{
    autocmd! StatusLine
    autocmd BufEnter * call <SID>SetFullStatusLine()
    autocmd BufLeave,BufNew,BufRead,BufNewFile * call <SID>SetFullStatusLine()
    "autocmd BufLeave,BufNew,BufRead,BufNewFile * call <SID>SetSimpleStatusLine()
augroup END "}}}

let g:statusline_max_path = 50
function! StatusLineGetPath() "{{{
    let p = expand('%:.:h')
    let p = substitute(p, expand('$HOME'), '~', '')
    if len(p) > g:statusline_max_path
        let p = simplify(p)
        let p = pathshorten(p)
    endif
    return p
endfunction "}}}

function! StatusLineRealSyntaxName() "{{{
    let synId = synID(line('.'),col('.'),1)
    let realSynId = synIDtrans(synId)
    if synId == realSynId
        return 'Normal'
    else
        return synIDattr( realSynId, 'name' )
    endif
endfunction "}}}

function! StatusLineMode() abort "{{{
    let l:modes = { 'n': 'NORMAL', 'v': 'VCHAR', 'V': 'VLINE', '': 'VBLOCK',
                \ 'i': 'INSERT', 'R': 'REPLACE', 's': 'SCHAR', 'S': 'SLINE','': 'SBLOCK',
                \ 't': 'JOB', 'c': 'COMMAND', '!': 'SHELL', 'r': 'PROMPT', }
    return l:modes[mode()[0]]
endfunction "}}}

function! s:SetFullStatusLine() "{{{
    setlocal statusline=

    setlocal statusline+=%#StatusLineBufNr#\ %-1.2n
    setlocal statusline+=\ %h%#StatusLineFlag#%m%r%w
    setlocal statusline+=%#StatusLinePath#\ %-0.50{StatusLineGetPath()}%0*
    setlocal statusline+=%#StatusLineFileName#\/%t
    setlocal statusline+=%#StatusLineFileSize#\ \(%{GetFileSize()}\)
    "setlocal statusline+=%#StatusLineTermEnc#(%{&termencoding},
    "setlocal statusline+=%#StatusLineFileEnc#%{&fileencoding},
    "setlocal statusline+=%#StatusLineFileFormat#%{&fileformat}\)
    setlocal statusline+=%#StatusLineFileType#\ %{strlen(&ft)?'['.&ft.']':'[*]'}
    setlocal statusline+=%#StatusLineMode#\ %{StatusLineMode()}
    setlocal statusline+=%#StatusLineSyntaxName#\ %{synIDattr(synID(line('.'),col('.'),1),'name')}\ %0*
    setlocal statusline+=%#StatusLineRealSyntaxName#\ %{StatusLineRealSyntaxName()}\ %0*

    " Separation point between alignment sections.
    setlocal statusline+=%=
    setlocal statusline+=%#StatusLineCurrentChar#\ %B[%b]
    setlocal statusline+=%#StatusLinePosition#\ %-10.(%l/%L,%c%)
    setlocal statusline+=%#StatusLinePositionPercentage#\ %p%%
endfunction "}}}

" Set a simple statusline when the current buffer is not active.
function! s:SetSimpleStatusLine() "{{{
    setlocal statusline=

    setlocal statusline+=%#StatusLineNCPath#%-0.20{StatusLineGetPath()}%0*
    setlocal statusline+=%#StatusLineNCFileName#\/%t
endfunction "}}}

" Return the current file size in human readable format.
function! GetFileSize() "{{{
    let l:bytes = &encoding ==# &fileencoding || &fileencoding ==# ''
                \        ? line2byte(line('$') + 1) - 1 : getfsize(expand('%'))
    let l:sizes = ['B', 'KB', 'MB', 'GB']
    let l:i = 0
    while l:bytes >= 1024 | let l:bytes = l:bytes / 1024.0 | let l:i += 1 | endwhile
    return l:bytes > 0 ? printf('%.2f%s', l:bytes, l:sizes[l:i]) : ''
endfunction "}}}
"}}}

"---------------------------------------------------------------------------
" Search:"{{{
"
" Wrap around the end of the file.
set nowrapscan
set incsearch
set ignorecase
set smartcase
set hlsearch
"}}}

"---------------------------------------------------------------------------
" Utilities:"{{{
"
" :TCD to the directory of the current file or specified path. "{{{
command! -nargs=? -complete=dir -bang TCD call s:ChangeCurrentDir('<args>', '<bang>')
function! s:ChangeCurrentDir(directory, bang)
    if a:directory == ''
        if &buftype !=# 'terminal'
            tcd %:p:h
        endif
    else
        execute 'tcd' . a:directory
    endif

    if a:bang == ''
        pwd
    endif
endfunction
"}}}

" Restore cursor position automatically. "{{{
autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

autocmd FileType yaml setlocal shiftwidth=2 tabstop=2
autocmd FileType make setlocal shiftwidth=2 tabstop=2
autocmd FileType json setlocal shiftwidth=2 tabstop=2
autocmd FileType sql setlocal shiftwidth=2 tabstop=2
autocmd FileType proto setlocal shiftwidth=2 tabstop=2 makeprg=buf
"}}}

"---------------------------------------------------------------------------
" Files:"{{{
"
let s:files_cmd = 'find '
let s:files_opts = '-type f'
command! -bar ToScratch setlocal buftype=nofile bufhidden=hide noswapfile
command! -bar ToScratchForFiles ToScratch | setlocal iskeyword+=.
command! -bar -nargs=? ModsNew <mods> new | if <q-args> ==# 'Files:.' | edit `='[Files:' . fnamemodify(getcwd(), ':p:h') . ']'` | elseif len(<q-args>) | edit [<args>] | endif
command! MRU <mods> ModsNew MRU | ToScratchForFiles | call setline(1, filter(v:oldfiles, 'filereadable(expand(v:val))'))
command! MRUQuickFix call setqflist(map(filter(v:oldfiles, 'filereadable(expand(v:val))'), '{"filename": expand(v:val)}')) | copen
command! -nargs=1 -complete=command L <mods> ModsNew <args> | ToScratchForFiles | call setline(1, split(execute(<q-args>), '\n'))
command! Buffers <mods> L buffers
command! ScriptNames <mods> ModsNew ScriptNames | ToScratchForFiles | call setline(1, execute('scriptnames')->split("\n")->map({_, v -> split(v, ': ')[1]}))
"}}}
"}}}

"---------------------------------------------------------------------------
" Plugins:"{{{
"
"---------------------------------------------------------------------------
" vim-quickrun:"{{{
"
if !exists('g:quickrun_config')
    let g:quickrun_config = {}
endif

let g:quickrun_config['_'] = {
    \     'outputter/buffer/split' : ':botright 8sp',
    \     'runner' : 'job',
    \ }
"}}}

"---------------------------------------------------------------------------
" vimhelpgenerator:"{{{
"
let g:vimhelpgenerator_defaultlanguage = 'en'
"}}}

"---------------------------------------------------------------------------
" vim-lsp:"{{{
"
let g:lsp_fold_enabled = 0
let g:lsp_diagnostics_echo_cursor = 1
let g:goimports_simplify = 1
let g:lsp_tagfunc_source_methods = ['definition']

function! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    setlocal tagfunc=lsp#tagfunc
endfunction

augroup lsp_install
    au!
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

" Format and organize imports on save.
autocmd! BufWritePre *.go call execute('LspDocumentFormatSync') | call execute('LspCodeActionSync source.organizeImports')

let g:lsp_settings = {
    \    'gopls': {
    \        'initialization_options': {
    \            'matcher': 'fuzzy',
    \            'completeUnimported': v:false,
    \            'deepCompletion': v:false,
    \            'usePlaceholders': v:false,
    \            'symbolMatcher': 'fuzzy',
    \            'symbolStyle': 'full',
    \            'gofumpt': v:true,
    \            'staticcheck': v:false,
    \            'analyses': {'fillstruct': v:true, 'unusedwrite': v:true},
    \            'codelenses': {'gc_details': v:true, 'test': v:true},
    \        },
    \    }
    \}
"}}}
"}}}

"---------------------------------------------------------------------------
" Key Mappings:"{{{
"
nnoremap <silent> <Space>ev :<C-u>edit $MYVIMRC<CR>
nnoremap <silent> <Space>el :<C-u>edit $MYLOCALVIMRC<CR>

nnoremap <silent> <Space>tv :<C-u>tabedit $MYVIMRC<CR>
nnoremap <silent> <Space>tl :<C-u>tabedit $MYLOCALVIMRC<CR>

nnoremap <silent> <Space>rv :<C-u>source $MYVIMRC<CR>
nnoremap <silent> <Space>rl :<C-u>if 1 && filereadable($MYLOCALVIMRC) \| source $MYLOCALVIMRC \| endif <CR>

" Recommended by :help options.txt for indenting
" When typing '#' as the first character in a new line, the indent for
" that line is removed, the '#' is put in the first column.  The indent
" is restored for the next line.  If you don't want this, use this
" mapping: ":inoremap # X^H#", where ^H is entered with CTRL-V CTRL-H.
" When using the ">>" command, lines starting with '#' are not shifted
" right.
inoremap # X<C-H><C-V>#
nnoremap <silent> <Space>cl :<C-u>call popup_clear()<CR>
nnoremap <silent> <Space>hc :<C-u>helpclose<CR>
nnoremap <silent> <C-j> :<C-u>bprev<CR>
nnoremap <silent> <C-k> :<C-u>bnext<CR>
nnoremap <silent> <C-h> :<C-u>tabprev<CR>
nnoremap <silent> <C-l> :<C-u>tabnext<CR>

nnoremap <Space>op :<C-u>set paste! paste?<CR>
nnoremap <Space>on :<C-u>setlocal number! cursorline! number? cursorline?<CR>
nnoremap <Space>ol :<C-u>setlocal list! list?<CR>
nnoremap <ESC><ESC> :nohlsearch<CR>

nnoremap <silent> <Space>wd :<C-u>windo diffthis<CR>
" Browse oldfiles filtered by pattern.
nnoremap <Leader>e :<C-u>/ oldfiles<Home>browse filter /
nnoremap <Space>b :<C-u>buffer <C-d>
nnoremap <Space>vb :<C-u>vert buffer <C-d>
" Open the directory of the current file.
nnoremap <Leader>d :<C-u>vertical split %:h<CR>
" Improve replacement of twice the width of characters in linewise.
xnoremap <expr> r mode() ==# 'V' ? "\<C-v>0o$r" : "r"

" Emacs like key bindings.
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
cnoremap <C-p> <Up>
cnoremap <C-n> <Down>
cnoremap <C-f> <Right>
cnoremap <C-b> <Left>
inoremap <C-k> <C-o>D
inoremap <C-u> <C-o>dd

" Full path.
cabbrev %% %:p:h
nnoremap Y y$
nnoremap X ^x
noremap <Space>h ^
noremap <Space>l $

" Move search results to the middle of the screen.
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap g* g*zz
nnoremap g# g#zz

" Move to the position last edited.
nnoremap gb '[
nnoremap gp ']

" Select last changed.
nnoremap gc `[v`]
vnoremap gc :<C-u>normal gc<CR>
onoremap gc :<C-u>normal gc<CR>

" 'Quote'
onoremap aq a'
xnoremap aq a'
onoremap iq i'
xnoremap iq i'

" \"Double quote\"
onoremap ad a"
xnoremap ad a"
onoremap id i"
xnoremap id i"

" {Curly bracket}
onoremap ac a}
xnoremap ac a}
onoremap ic i}
xnoremap ic i}

" <aNgle bracket>
onoremap an a>
xnoremap an a>
onoremap in i>
xnoremap in i>

" [sqUare bracket]
onoremap au a]
xnoremap au a]
onoremap iu i]
xnoremap iu i]

"---------------------------------------------------------------------------
" Custom commands:"{{{
"
" :TCD to the directory of the current file or specified path.
nnoremap <silent> <Space>cd :<C-u>TCD<CR>
" Copy current path.
nnoremap <silent> <Space>cp :<C-u>!echo % \| pbcopy<CR>
" Format json.
nnoremap <silent> <Space>jq :<C-u>%!jq '.'<CR>
" Force save.
cmap w!! w !sudo tee > /dev/null %
"}}}

"---------------------------------------------------------------------------
" Plugins:"{{{
"
" vim-quickrun:"{{{
nmap <Leader>r <Plug>(quickrun)
omap <Leader>r <Plug>(quickrun)
xmap <Leader>r <Plug>(quickrun)
"}}}

" rainbowcyclone.vim:"{{{
nmap c/ <Plug>(rc_search_forward)
nmap c? <Plug>(rc_search_backward)
nmap c* <Plug>(rc_search_forward_with_cursor)
nmap c# <Plug>(rc_search_backward_with_cursor)
nmap cn <Plug>(rc_search_forward_with_last_pattern)
nmap cN <Plug>(rc_search_backward_with_last_pattern)
" nmap <Esc><Esc> <Plug>(rc_reset):nohlsearch<CR>
" nnoremap <Esc><Esc> :<C-u>RCReset<CR>:nohlsearch<CR>
"}}}

" vim-lsp:"{{{
nnoremap <silent> <Space>rf :<C-u>LspReferences<CR>
nnoremap <silent> <Space>rn :<C-u>LspRename<CR>
nnoremap <silent> <Space>im :<C-u>LspImplementation<CR>
nnoremap <silent> <Space>ho :<C-u>LspHover<CR>
nnoremap <silent> <Space>ds :<C-u>LspDocumentSymbol<CR>
nnoremap <silent> <Space>ca :<C-u>LspCodeAction<CR>
"}}}
"}}}

"---------------------------------------------------------------------------
" External Settings:"{{{
"
let $MYLOCALVIMRC = expand('~/.vim/.local.vimrc')
if 1 && filereadable($MYLOCALVIMRC)
    source $MYLOCALVIMRC
endif
"}}}
"}}}
