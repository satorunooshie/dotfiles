vim9script
# ---------------------------------------------------------------------------
# .vimrc
# ---------------------------------------------------------------------------
# Initialize: #{{{
#

# Disable unused standard plugins.
g:loaded_netrw             = 1
g:loaded_netrwPlugin       = 1
g:loaded_gzip              = 1
g:loaded_tar               = 1
g:loaded_tarPlugin         = 1
g:loaded_zip               = 1
g:loaded_zipPlugin         = 1
g:loaded_vimball           = 1
g:loaded_vimballPlugin     = 1
g:loaded_getscript         = 1
g:loaded_getscriptPlugin   = 1
g:loaded_spellfile_plugin  = 1
g:loaded_tutor_mode_plugin = 1
g:loaded_remote_plugins    = 1
g:loaded_openPlugin        = 1
g:loaded_matchparen        = 1
g:loaded_2html_plugin      = 1
g:loaded_manpager          = 1
g:loaded_logiPat           = 1

augroup MyVimrcCmd
  autocmd!
augroup END

# Use Vim settings, rather than Vi settings (much better!).
# This must be first, because it changes other options as a side effect.
# Avoid side effects when it was already reset.
# Using `-u` argument has the side effect that the 'compatible' option will be on by default.
# If you want to avoid this, use `-N` argument.
if &compatible
  set nocompatible
endif

# Note: that the order of the following commands is important.
set encoding=utf-8
scriptencoding utf-8

# <: Maximum number of lines saved for each register.
# h: 'hlsearch' highlighting will not be restored.
# s: Maximum size of an item in Kbyte.
# ': Maximum number of previously edited files for which the marks are remembered.
# :: Maximum number of items in the command-line history to be saved.
# overwrite default setting
set viminfo=<100,h,s100,'1000,:100

# Don't give the intro message when starting Vim.
set shortmess+=I

# ---------------------------------------------------------------------------
# Mouse: #{{{
#
# Normal mode and Terminal modes
# Visual mode, Insert mode, Command-line mode
# all previous modes when editing a help file.
set mouse=a
set nomousefocus
#}}}

# ---------------------------------------------------------------------------
# Edit: #{{{
#
set noswapfile
set nobackup
# The maximum number of items to show in the popup menu for Insert mode completion.
set pumheight=15
# Display the completion matches using the popup menu.
set wildoptions=pum
set tabstop=2
set softtabstop=2
set shiftwidth=2
# Round indent to multiple of 'shiftwidth'.
set shiftround
set smarttab
# Spaces are used in indents.
set expandtab
# Influences the working of <BS>, <Del>, CTRL-W and CTRL-U in Insert mode.
# indent	allow backspacing over autoindent
# eol	    allow backspacing over line breaks (join lines)
# start	    allow backspacing over the start of insert; CTRL-W and CTRL-U
#           stop once at the start of insert.
set backspace=indent,eol,start
# Allow specified keys that move the cursor left/right to move to the previous/next line when the cursor is on the first/last character in the line.
# b    <BS>	 Normal and Visual
# s    <Space>	 Normal and Visual
# <    <Left>	 Normal and Visual
# >    <Right>	 Normal and Visual
# [    <Left>	 Insert and Replace
# ]    <Right>	 Insert and Replace
set whichwrap=b,s,<,>,[,]
# Command-line completion operates in an enhanced mode.
set wildmenu
# Command-line history.
set history=2000
set virtualedit+=block
set autoindent
# Smart indenting.
set smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class
# Use the popup menu also when there is only one match.
# Only insert the longest common text of the matches.
set completeopt=menuone,longest
# Settings for Japanese folding.
set formatoptions+=mM
# Don't continue the comment line automatically.
set formatoptions-=ro
# Prevent overwriting format options.
autocmd MyVimrcCmd FileType * setlocal formatoptions-=ro
set nrformats=alpha,hex,bin,unsigned
autocmd MyVimrcCmd InsertLeave * if &paste | set nopaste | endif
#}}}

# tags: #{{{
# ctags
set tags=./tags
set tags+=tags;
set tags+=./**/tags
#}}}

# grep: #{{{
set grepprg=git\ grep\ --no-color\ -n\ --column\ --untracked
set grepformat=%f:%l:%c:%m,%f:%l:%m
# Cannot be used --no-index and --untracked at the same time.
# --no-index: for not using git repository.
command! UseGitGrepNoIndex setlocal grepprg=git\ grep\ --no-color\ -n\ --column\ --no-index
command! UseDefaultGitGrep set grepprg=git\ grep\ --no-color\ -n\ --column\ --untracked
#}}}

# Quickfix: #{{{
# Open a new tab when jumping to a quickfix item, splitting buffers, using stag,
# CTRL-W_f or CTRL-W_F.
set switchbuf=newtab
# Open quickfix window automatically.
autocmd MyVimrcCmd QuickfixCmdPre make,grep,grepadd,vimgrep,vimgrepadd,helpgrep copen
#}}}

# clipboard: #{{{
# Clipboard provider for pbcopy/pbpaste.
# See :help clipboard-provider.
if has('clipboard_provider') && executable('pbpaste') && executable('pbcopy')
  # Keep track of the last used register type for '*' and '+'
  final last_regtype: dict<string> = { '*': 'v', '+': 'v' }

  # Return the available registers. pbcopy/pbpaste share the same pasteboard.
  def PB_Available(): bool
    return true
  enddef

  # Paste callback.
  # reg: '*' or '+'
  # accessType: 'explicit' or 'implicit'
  #
  # Called when Vim needs to read from the clipboard.
  # For implicit access (e.g. when showing :registers or accessing the
  # clipboard indirectly), return "previous" to avoid unnecessary pbpaste calls.
  # This prevents performance overhead and permission prompts.
  # For explicit access (e.g. put, getreg()), return [regtype, lines] as required
  # by :help clipboard-provider-paste.
  def PB_Paste(reg: string): list<any>
    var lines: list<string> = systemlist('pbpaste')
    if v:shell_error
      # On error, return empty content with the last used register type.
      return [get(last_regtype, reg, 'v'), []]
    endif

    # Normalize CRLF to LF and remove trailing CR.
    def NormalizeCRLF(l: list<string>): list<string>
      return mapnew(l, (_, v) => substitute(v, '\r\(\n\)\@=', '', 'g'))
    enddef

    lines = NormalizeCRLF(lines)
    var regtype: string = get(last_regtype, reg, 'v')
    return [regtype, lines]
  enddef

  # Copy callback
  # - reg: '*' or '+'
  # - regtype: 'v', 'V', or "<C-V>"
  # - lines: list of yanked lines
  # Store the register type for later, and pass the joined text to pbcopy.
  # For linewise yanks, add a final newline to match Vim's setreg() behavior.
  def PB_Copy(reg: string, regtype: string, lines: list<string>)
    last_regtype[reg] = regtype
    var payload: string = join(lines, "\n") .. (regtype ==# 'V' ? "\n" : '')
    system('pbcopy', payload)
  enddef

  # Register the clipboard provider.
  # Both '+' and '*' use the same functions since they map to the same macOS pasteboard.
  v:clipproviders.pb = {
        available: PB_Available,
        paste: { '+': PB_Paste, '*': PB_Paste },
        copy:  { '+': PB_Copy,  '*': PB_Copy  },
  }

  # Make pb the preferred clipboard provider.
  set clipmethod=pb,x11,wayland
endif
# Register '*' and '+' for all yank, delete, change and put operations.
# unnamedplus is available when +xterm_clipboard / +wayland_clipboard / gui_running.
set clipboard=unnamed,unnamedplus
#}}}

# ---------------------------------------------------------------------------
# Color: #{{{
#
set t_Co=256
# Change cursor shape in insert mode.
if &term =~# 'xterm'
  &t_SI = "\<Esc>[5 q"
  &t_SR = "\<Esc>[3 q"
  &t_EI = "\<Esc>[1 q"
endif

# Visualization of the spaces at the end of the line.
# https://vim-jp.org/vim-users-jp/2009/07/12/Hack-40.html
augroup HighlightIdegraphicSpace
  autocmd!
  autocmd Colorscheme * highlight IdeographicSpace term=underline ctermbg=102 guibg=grey
  # Ignore if highlight group doesn't exist because of the delay of
  # colorscheme loading.
  autocmd Colorscheme,WinEnter * try
      \ | match IdeographicSpace /　\|\s\+$/
      \ | catch /E28/
      \ | endtry
augroup END

def ApplyColorscheme(timer: number): void
  try
    colorscheme pairs # github.com/satorunooshie/pairscolorscheme
  catch /E185/ # Install if not found.
    echomsg 'installing pairscolorscheme...'
    const colors_dir_path = expand('~/.vim/colors/')
    MkdirIfNotExists(colors_dir_path)
    silent! system('git clone --depth 1 --recursive https://github.com/satorunooshie/pairscolorscheme ' .. colors_dir_path .. 'pairs')
    silent! system('mv ' .. colors_dir_path .. 'pairs/colors/pairs.vim ' ..  colors_dir_path .. 'pairs.vim')

    echomsg 'installed pairscolorscheme successfully.'
    colorscheme pairs
  endtry

  # Note: Syntax generates based on settings in runtimepath
  # so it is nececcary to initialize runtimepath and
  # load file type highlight plugins prior to syntax on.
  syntax on
enddef

autocmd MyVimrcCmd VimEnter * timer_start(50, ApplyColorscheme)
#}}}

# ---------------------------------------------------------------------------
# View: #{{{
#
set number
# Always draw the signcolumn to prevent rattling.
set signcolumn=yes
set cursorline
# Highlight only numbers.
set cursorlineopt=number
# Avoid `Thanks for flying Vim`.
set title
set nowrap
# When a bracket is inserted, briefly jump to the matching one.
set showmatch
# Tenths of a second to show the matching paren is 0.1 sec.
set matchtime=1
set matchpairs+=<:>,「:」,（:）,『:』,【:】,《:》,〈:〉,｛:｝,［:］,‘:’,“:”,«:»,‹:›
# Always show status line.
set laststatus=2
# Always display the line with tab page labels.
set showtabline=2
# Show (partial) command in the last line of the screen.
set showcmd
# Number of screen lines to use for the command-line.
# Setting as 1 shows Press ENTER or type command to continue when a long
# message is displayed.
set cmdheight=2
# Never show the current mode in the last line of the screen.
set noshowmode
# Show unprintable characters hexadecimal as <xx> instead of using ^C and ~C.
# When inserting, can append a character with CTRL-V uxxxx.
set display=uhex
# Default height for a preview window.
set previewheight=12
# Not showing tabs as CTRL-I is displayed, display $ after end of line.
set nolist
set listchars=tab:>-,extends:<,precedes:>,trail:-,eol:$,nbsp:%
#}}}

# ---------------------------------------------------------------------------
# Tabline: #{{{
#
g:current_dir = fnamemodify(getcwd(), ':p:~:h') .. ' '

def! g:LightTabLine(): string
  const curbuf = bufname('%')
  return '%#TabLine#%1T[' .. pathshorten(curbuf !=# '' ? curbuf : '[No Name]') .. ']%T%#TabLineFill#%T'
enddef

def SetupFullTabLine(): void
  set tabline=%!MakeTabLine()
enddef

def! g:MakeTabLine(): string
  def TabpageLabel(n: number): string
    const title = gettabwinvar(n, 0, 'title')
    if title !=# ''
      return title
    endif
    def IsModified(bufnr: number): string
      return getbufvar(bufnr, '&modified') ? '+' : ''
    enddef
    const bufnrs: list<number> = tabpagebuflist(n)
    const buflist = join(mapnew(bufnrs, (_, bufnr: number) => bufnr .. IsModified(bufnr)), ',')
    const curbufnr: number = bufnrs[tabpagewinnr(n) - 1]
    const label = '[' .. buflist .. ']' .. pathshorten(bufname(curbufnr))
    const hi = n == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#'
    return '%' .. n .. 'T' .. hi .. label .. '%T%#TabLineFill#'
  enddef
  const titles: list<string> = map(range(1, tabpagenr('$')), (_, bufnr: number) => TabpageLabel(bufnr))
  const sep = ' | '
  const tabpages = join(titles, sep) .. sep .. '%#TabLineFill#%T'
  g:current_dir = fnamemodify(getcwd(), ':p:~:h') .. ' '
  return tabpages .. '%=' .. g:current_dir
enddef

set tabline=%!LightTabLine()

autocmd MyVimrcCmd CursorMoved * ++once SetupFullTabLine()
#}}}

# ---------------------------------------------------------------------------
# StatusLine: #{{{
#
def! g:Path(): string
  const statusline_path_max_len = 50
  var p = substitute(expand('%:.:h'), expand('$HOME'), '~', '')
  if len(p) > statusline_path_max_len
    return pathshorten(simplify(p))
  endif
  return p
enddef

def! g:RealSyntaxName(): string
  const syn_id = synID(line('.'), col('.'), 1)
  const real_syn_id = synIDtrans(syn_id)
  return syn_id == real_syn_id ? 'Normal' : synIDattr(real_syn_id, 'name')
enddef

def! g:Mode(): string
  const modes: dict<string> = {
    n: 'NORMAL', v: 'VCHAR', V: 'VLINE', '': 'VBLOCK',
    i: 'INSERT', R: 'REPLACE', s: 'SCHAR', S: 'SLINE', '': 'SBLOCK',
    t: 'JOB', c: 'COMMAND', r: 'PROMPT', '!': 'SHELL',
  }
  return modes[mode()[0]]
enddef

# Return the current file size in human readable format.
def! g:FileSize(): string
  var bytes: float = &encoding ==# &fileencoding
    || &fileencoding ==# ''
    ? line2byte(line('$') + 1) - 1.0
    : getfsize(expand('%')) - 0.0
  var i: number = 0
  while bytes >= 1024.0
    bytes /= 1024.0
    ++i
  endwhile
  const sizes: list<string> = ['B', 'KB', 'MB', 'GB']
  return bytes > 0 ? printf('%.2f%s', bytes, sizes[i]) : ''
enddef

def! g:FileType(): string
  return strlen(&ft) > 0 ? '[' .. &ft .. ']' : '[*]'
enddef

def! g:SyntaxName(): string
  return synIDattr(synID(line('.'), col('.'), 1), 'name')
enddef

def SetFullStatusLine(): void
  setlocal statusline=

  setlocal statusline+=%#StatusLineBufNr#\ %-1.2n
  setlocal statusline+=\ %h%#StatusLineFlag#%m%r%w
  setlocal statusline+=%#StatusLinePath#\ %-0.50{Path()}%0*
  setlocal statusline+=%#StatusLineFileName#\/%t
  setlocal statusline+=%#StatusLineFileSize#\ \(%{FileSize()}\)
  # setlocal statusline+=%#StatusLineTermEnc#(%{&termencoding},
  # setlocal statusline+=%#StatusLineFileEnc#%{&fileencoding},
  # setlocal statusline+=%#StatusLineFileFormat#%{&fileformat}\)
  setlocal statusline+=%#StatusLineFileType#\ %{FileType()}
  setlocal statusline+=%#StatusLineMode#\ %{Mode()}
  setlocal statusline+=%#StatusLineSyntaxName#\ %{SyntaxName()}\ %0*
  setlocal statusline+=%#StatusLineRealSyntaxName#\ %{RealSyntaxName()}\ %0*

  # Separation point between alignment sections.
  setlocal statusline+=%=
  setlocal statusline+=%#StatusLineCurrentChar#\ %B[%b]
  setlocal statusline+=%#StatusLinePosition#\ %-10.(%l/%L,%c%)
  setlocal statusline+=%#StatusLinePositionPercentage#\ %p%%
enddef

# Set a simple statusline when the current buffer is not active.
def SetSimpleStatusLine(): void
  setlocal statusline=

  setlocal statusline+=%#StatusLineNCPath#%-0.20{Path()}%0*
  setlocal statusline+=%#StatusLineNCFileName#\/%t
enddef

set statusline=%f
autocmd MyVimrcCmd CursorMoved * ++once call ApplyFullStatusLine()

def ApplyFullStatusLine(): void
  # Reset the statusline to the full status line.
  set statusline=
  SetFullStatusLine()

  # Apply the status line to the remaining buffers
  for bufnr in range(1, bufnr('$'))
    if bufexists(bufnr) && buflisted(bufnr)
      const winid = bufwinnr(bufnr)
      if winid > 0 && winid != winnr() # Skip the current window.
        execute ':' .. winid .. 'wincmd w'
        SetFullStatusLine()
      endif
    endif
  endfor

  # Normal operation.
  augroup StatusLine
    autocmd!
    autocmd BufEnter * SetFullStatusLine()
    autocmd BufLeave,BufNew,BufRead,BufNewFile * SetFullStatusLine()
    # autocmd BufLeave,BufNew,BufRead,BufNewFile * SetSimpleStatusLine()
  augroup END
enddef
#}}}

# ---------------------------------------------------------------------------
# Search: #{{{
#
# Wrap around the end of the file.
set nowrapscan
set incsearch
set ignorecase
set smartcase
set hlsearch
#}}}

# ---------------------------------------------------------------------------
# Files: #{{{
#
var git_root = ''
var git_root_cache = ''
def SetGitRoot(): void
  if g:current_dir !=# git_root_cache
    git_root_cache = g:current_dir
    git_root = system('git rev-parse --show-toplevel')
    if git_root =~# '^fatal'
      git_root = ''
    else
      git_root = git_root->trim()->expand()
    endif
  endif
enddef
command! -bar SetGitRoot SetGitRoot()

command! -bar ToScratch setlocal buftype=nofile bufhidden=hide noswapfile
command! -bar ToScratchForFiles ToScratch | setlocal iskeyword+=.
command! -bar -nargs=? ModsNew <mods> new
  | if len(<q-args>) > 0
  | edit modsnew://output/<args>
  | endif

# List files recursively in the specified directory.
# `./` after `Files:` is necessary to avoid `expand()` unexpected error(E944).
command! -bar -nargs=1 -complete=dir Files <mods> ModsNew Files:./<args>
  | ToScratchForFiles
  | setline(1, system('find "<args>" -path "*/.*" -type d -prune -o -type f -print')->split('\n'))
command! FilesBuffer <mods> Files %:p:h
command! FilesCurrent <mods> Files .

# Filter files that are not readable and not in the git repository if it exists.
def FilterFiles(files: list<string>): list<string>
  return files->copy()->filter((_, v: string) => v->expand()->filereadable())->mapnew((_, v: string) => v->trim()->expand()->substitute(expand('$HOME'), '~', ''))->filter((_, v: string) => (empty(git_root) || expand(v) =~# git_root) && v !~# '\.git/')
enddef
command! MRU <mods> ModsNew MRU
  | SetGitRoot
  | ToScratchForFiles
  | setline(1, v:oldfiles->FilterFiles())

command! -nargs=1 -complete=command L <mods> ModsNew <args>
  | ToScratchForFiles
  | setline(1, execute(<q-args>)->split('\n'))
command! Buffers <mods> L buffers
command! ScriptNames <mods> ModsNew ScriptNames
  | ToScratchForFiles
  | setline(1, execute('scriptnames')->split('\n')->map((_, v: string) => split(v, ': ')[1]))
#}}}

# ---------------------------------------------------------------------------
# Utilities: #{{{
#
# :TCD to the directory of the current file or specified path.
command! -nargs=? -complete=dir -bang TCD ChangeCurrentDir('<args>', '<bang>')
def ChangeCurrentDir(directory: string, bang: string): void
  if directory == ''
    if &buftype !=# 'terminal'
      tcd %:p:h
    endif
  else
    execute 'tcd ' .. directory
  endif

  if bang == ''
    pwd
  endif
enddef

# Restore cursor position automatically.
def RestoreCursorPosition(): void
  if line("'\"") > 1 && line("'\"") <= line("$") &&
      &filetype !~# 'commit' && index(['xxd', 'gitrebase'], &filetype) == -1
    normal! g`"
  endif
enddef
autocmd MyVimrcCmd BufReadPost * RestoreCursorPosition()

autocmd MyVimrcCmd FileType proto setlocal shiftwidth=2 tabstop=2 makeprg=buf

# Sanitize the command line history.
def SanitizeHistory(): void
  var cmd = histget(":", -1)
  if cmd ==# "x" || cmd ==# "xa" || cmd ==# "e!" ||
      cmd ==# "vs" || cmd =~# "^w\\?q\\?a\\?!\\?$"
    histdel(":", -1)
  endif
enddef
autocmd MyVimrcCmd ModeChanged c:* SanitizeHistory()

# Diff before save.
command! DiffOrig vert new | set bt=nofile | execute 'r ++edit ' .. expand('#') | deletebufline('%', 1) | diffthis | wincmd p | diffthis

# Convert location list to quickfix list.
command! Loc2Qf call setqflist(getloclist(0)) | lclose | copen

# Convert quickfix list to location list.
command! Qf2Loc call setloclist(0, getqflist()) | cclose | lopen
#}}}

# ---------------------------------------------------------------------------
# Key Mappings: #{{{
#
nnoremap <silent> <Space>ev <Cmd>edit $MYVIMRC<CR>
nnoremap <silent> <Space>el <Cmd>edit $MYLOCALVIMRC<CR>

nnoremap <silent> <Space>tv <Cmd>tabedit $MYVIMRC<CR>
nnoremap <silent> <Space>tl <Cmd>tabedit $MYLOCALVIMRC<CR>

nnoremap <silent> <Space>rv <Cmd>source $MYVIMRC<CR>

# Disable built-in openPlugin to reduce startup time.
# Therefore, redefine gx.
nnoremap <silent> gx <Cmd>call job_start(['open', expand('<cfile>')])<CR>
xnoremap <silent> gx <Cmd>call job_start(['open', join(getregion(getpos('v'), getpos('.'), {'type': mode()}))])<CR>

# Recommended by :help options.txt for indenting
# When typing '#' as the first character in a new line, the indent for
# that line is removed, the '#' is put in the first column.  The indent
# is restored for the next line.  If you don't want this, use this
# mapping: ":inoremap # X^H#", where ^H is entered with CTRL-V CTRL-H.
# When using the ">>" command, lines starting with '#' are not shifted
# right.
inoremap \# X<C-H><C-V>#
nnoremap <silent> <Space>cl <Cmd>call popup_clear()<CR>
nnoremap <silent> <Space>cc <Cmd>cclose<CR>
nnoremap <silent> <Space>hc <Cmd>helpclose<CR>
nnoremap <silent> <Space>to <Cmd>tabonly<CR>
nnoremap <silent> <Space>tc <Cmd>tabclose<CR>
nnoremap <silent> <Space>tn <Cmd>tabnew<CR>

nnoremap <silent> <Space>vn <Cmd>vnew<CR>
nnoremap <silent> <Space>vm <Cmd>vert MRU<CR>

nnoremap <silent> <C-n> <Cmd>bnext<CR>
nnoremap <silent> <C-p> <Cmd>bprev<CR>
nnoremap <silent> <C-k> {
nnoremap <silent> <C-j> }
vnoremap <silent> <C-k> {
vnoremap <silent> <C-j> }
nnoremap <silent> <C-h> <Cmd>tabprev<CR>
nnoremap <silent> <C-l> <Cmd>tabnext<CR>

tnoremap <nowait> <C-\> <C-\><C-N>

nnoremap <Space>op <Cmd>set paste! paste?<CR>
nnoremap <Space>on <Cmd>setlocal number! cursorline! number? cursorline?<CR>
nnoremap <Space>ol <Cmd>setlocal list! list?<CR>
nnoremap <silent> <ESC> :nohlsearch<CR>

nnoremap <silent> <Space>wd <Cmd>call ToggleDiff()<CR>
def! g:ToggleDiff()
  for w in range(1, winnr('$'))
    if getwinvar(w, '&diff')
      windo diffoff
      return
    endif
  endfor
  windo diffthis
enddef

# Browse oldfiles filtered by pattern.
nnoremap <Leader>e :<C-u>/ oldfiles<Home>browse filter /
nnoremap <Space>b :<C-u>buffer <C-d>
# Open the directory of the current file.
nnoremap <Leader>d <Cmd>vertical split %:h<CR>
# Improve replacement of twice the width of characters in linewise.
xnoremap <expr> r mode() ==# 'V' ? "\<C-v>0o$r" : "r"

xnoremap Q :<C-u>normal! @q<CR>

# Enable repeatedly increment or decrement in visual mode.
vnoremap <c-a> <c-a>gv
vnoremap <c-x> <c-x>gv

nnoremap J gJ
nnoremap gJ J

nnoremap gf gF

# Disable overridding the register in visual mode.
vnoremap p "_dP
vnoremap P "_dp
# Disable overridding the register in normal mode.
nnoremap s "_s
nnoremap c "_c
nnoremap C "_C
nnoremap D "_D
# Except dd, df, dt.
nnoremap d "_d
nnoremap dd dd
nnoremap df df
nnoremap dt dt

# Emacs like key bindings.
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
cnoremap <C-p> <Up>
cnoremap <C-n> <Down>
cnoremap <C-f> <Right>
cnoremap <C-b> <Left>
inoremap <C-k> <C-o>D
inoremap <C-u> <C-o>dd

# Full path.
cabbrev %% %:p:h
nnoremap Y y$
nnoremap X ^x
noremap <Space>h ^
noremap <Space>l $

# Move search results to the middle of the screen.
nnoremap n nzz
nnoremap N Nzz

# Restore previous view after search without polluting the jumplist.
nnoremap <silent><expr> *
      \ v:count != 0 ? '*' :
      \ ':silent execute "keepjumps normal! *" <Bar> call winrestview(' .. string(winsaveview()) .. ')<CR>'
nnoremap <silent><expr> #
      \ v:count != 0 ? '#' :
      \ ':silent execute "keepjumps normal! #" <Bar> call winrestview(' .. string(winsaveview()) .. ')<CR>'
nnoremap <silent><expr> g*
      \ v:count != 0 ? 'g*' :
      \ ':silent execute "keepjumps normal! g*" <Bar> call winrestview(' .. string(winsaveview()) .. ')<CR>'
nnoremap <silent><expr> g#
      \ v:count != 0 ? 'g#' :
      \ ':silent execute "keepjumps normal! g#" <Bar> call winrestview(' .. string(winsaveview()) .. ')<CR>'

# Move to the position previously changed or yanked.
nnoremap mlc '[
nnoremap mlc ']
# Select previously changed or yanked.
nnoremap slc '[v']

# 'Quote'
onoremap aq a'
xnoremap aq a'
onoremap iq i'
xnoremap iq i'

# \"Double quote\"
onoremap ad a"
xnoremap ad a"
onoremap id i"
xnoremap id i"

# {Curly bracket}
onoremap ac a}
xnoremap ac a}
onoremap ic i}
xnoremap ic i}

# <aNgle bracket>
onoremap an a>
xnoremap an a>
onoremap in i>
xnoremap in i>

# [sqUare bracket]
onoremap au a]
xnoremap au a]
onoremap iu i]
xnoremap iu i]
#}}}

# ---------------------------------------------------------------------------
# Custom commands: #{{{
#
# :TCD to the directory of the current file or specified path.
nnoremap <silent> <Space>cd <Cmd>TCD<CR>
# Copy current path.
nnoremap <silent> <C-g><C-g> 2<C-g><Cmd>let @+=expand('%:p')<CR>
# Format json.
nnoremap <silent> <Space>jq <Cmd>%!jq '.'<CR>
# Force save.
cmap w!! w !sudo tee > /dev/null %
# checkout file.
nnoremap <silent> <Leader>co <Cmd>call system('git checkout -- ' .. expand('%')) \| e!<CR>
#}}}

# ---------------------------------------------------------------------------
# Plugins: #{{{
#

# ---------------------------------------------------------------------------
# termdebug: #{{{
#
if !exists('g:termdebug_config')
  g:termdebug_config = {}
endif

g:termdebug_config['winbar'] = 0
g:termdebug_config['popup'] = 0
g:termdebug_config['sign'] = '>>'
#}}}

# ---------------------------------------------------------------------------
# forge.vim: #{{{
#
def! g:ForgeOperateUnderCursor(op: string): void
  const dir: string = forge#Curdir()
  const name: string = substitute(getline('.'), '[/\\]$', '', '')
  # forge#Curdir() always returns a path with a trailing slash.
  const path: string = dir .. name
  const completion: string = isdirectory(path) ? 'dir' : 'file'

  var dst = ''
  var cmd = ''
  if op ==# 'copy'
    dst = input('Copy to: ', dir, completion)
    if dst ==# ''
      return
    endif
    cmd = 'cp -a ' .. fnameescape(path) .. ' ' .. fnameescape(dst)
  elseif op ==# 'move'
    dst = input('Move to: ', dir, completion)
    if dst ==# ''
      return
    endif
    cmd = 'mv ' .. fnameescape(path) .. ' ' .. fnameescape(dst)
  else
    return
  endif

  const out = system(cmd)
  histadd('cmd', 'call system("' .. cmd .. '")')
  if v:shell_error
    echoerr out
    return
  endif

  forge#Reload()

  var entry = {
      'text': (op ==# 'copy'
            ? '[cp] ' .. path .. ' -> ' .. dst
            : '[mv] ' .. path .. ' -> ' .. dst),
      'filename': dst,
      'lnum': 0,
      'type': 'I',
  }
  setqflist([entry], 'a')
  setqflist([], 'r', {'title': 'Forge Extra Operations'})
  silent copen 8 | wincmd p
enddef

def ForgeSettings(): void
  augroup MyForgeCmd
    autocmd!
    autocmd FileType forge nnoremap <buffer> <Space>cp <Cmd>call ForgeOperateUnderCursor('copy')<CR>
    autocmd FileType forge nnoremap <buffer> <Space>mv <Cmd>call ForgeOperateUnderCursor('move')<CR>
  augroup END
enddef
#}}}

# ---------------------------------------------------------------------------
# git-lens: #{{{
#
def GitLensSettings(): void
  g:GIT_LENS_CONFIG = {
    blame_prefix: '    ---- ',
    blame_highlight: 'LineNr',
    blame_wrap: false,
    blame_empty_line: false,
    blame_delay: 50,
  }
enddef

def RemapGitLensKeys(): void
  nnoremap <silent> <Space>gl <Cmd>call ToggleGitLens()<CR>
enddef
#}}}

# ---------------------------------------------------------------------------
# vim-quickrun: #{{{
#
def QuickrunSettings(): void
  if !exists('g:quickrun_config')
    g:quickrun_config = {}
  endif

  g:quickrun_config['_'] = {
    'outputter/buffer/split': ':botright 8sp',
    'outputter/buffer/close_on_empty': 1,
    'runner': 'job',
  }
enddef

def RemapQuickrunKeys(): void
  nmap <Leader>r <Plug>(quickrun)
  omap <Leader>r <Plug>(quickrun)
  xmap <Leader>r <Plug>(quickrun)
enddef

#}}}

# ---------------------------------------------------------------------------
# vimhelpgenerator: #{{{
#
g:vimhelpgenerator_defaultlanguage = 'en'
#}}}

# ---------------------------------------------------------------------------
# copilot: #{{{
#
def RemapCopilotKeys(): void
  imap <C-C><C-N> <Plug>(copilot-next)
  imap <C-C><C-P> <Plug>(copilot-previous)
enddef
#}}}

# ---------------------------------------------------------------------------
# vim-lsp: #{{{
#
def LspBufferEnabled(): void
  setlocal omnifunc=lsp#complete
  setlocal tagfunc=lsp#tagfunc
enddef

# Format and organize imports on save.
def GoFormatAndOrganizeImports(): void
  silent execute 'LspDocumentFormatSync'
  silent execute 'LspCodeActionSync source.organizeImports'
enddef

def LspSettings(): void
  g:lsp_fold_enabled = 0
  g:lsp_diagnostics_echo_cursor = 1
  g:lsp_diagnostics_virtual_text_enabled = 0
  g:lsp_tagfunc_source_methods = ['definition']

  augroup LspInstall
    autocmd!
    autocmd User lsp_buffer_enabled LspBufferEnabled()
  augroup END

  autocmd MyVimrcCmd BufWritePre *.go GoFormatAndOrganizeImports()

  g:lsp_settings = {
    gopls: {
      initialization_options: {
        matcher: 'fuzzy',
        deepCompletion: false,
        usePlaceholders: false,
        symbolMatcher: 'fuzzy',
        symbolStyle: 'full',
        gofumpt: true,
        staticcheck: false,
        codelenses: {
          gc_details: true,
          test: true,
        },
      },
    }
  }

  # if not exists or not writable, do not turn on verbose logging.
  # filewritable returns 2 when the path is a directory and writable,
  # and returns 1 when the path is writable, so it is compared to 0 to convert to Bool.
  if filewritable(expand('~/tmp')) !=# 0
    g:lsp_log_verbose = 1
    g:lsp_log_file = expand('~/tmp/vim-lsp-' .. strftime('%Y%m%d') .. '.log')
    g:lsp_settings['gopls']['cmd'] = ['gopls', '-logfile', expand('~/tmp/gopls-' .. strftime('%Y%m%d') .. '.log')]
  endif

  try
    lsp#enable()
  catch /E117/
  endtry
enddef

def! g:LspDocumentDiagnostics(): void
  execute 'LspDocumentDiagnostics'
  # Technically it is better to wait for the completion of the LSP.
  if !getloclist(0)->empty()
    Loc2Qf
  endif
enddef

def! g:LspDocumentSymbolFiltered(): void
  silent execute 'LspDocumentSymbol'
  # Wait for the completion of the LSP.
  sleep 10m
  execute 'Cfilter function\|method'
enddef

def RemapLspKeys(): void
  nnoremap <silent> <Space>rf <Cmd>LspReferences<CR>
  nnoremap <silent> <Space>rn <Cmd>LspRename<CR>
  nnoremap <silent> <Space>im <Cmd>LspImplementation<CR>
  nnoremap <silent> <Space>ho <Cmd>LspHover<CR>
  nnoremap <silent> <Space>ds <Cmd>call LspDocumentSymbolFiltered()<CR>
  nnoremap <silent> <Space>dd <Cmd>call LspDocumentDiagnostics()<CR>
  nnoremap <silent> <Space>ca <Cmd>LspCodeAction<CR>
  nnoremap <silent> <Space>nr <Cmd>LspNextError<CR>
  nnoremap <silent> <Space>pr <Cmd>LspPreviousError<CR>
enddef
#}}}

# ---------------------------------------------------------------------------
# vim-signify: #{{{
#
def SignifySettings(): void
  try
    execute 'SignifyEnable'
  catch /E492/
  endtry
enddef
#}}}

# ---------------------------------------------------------------------------
# asyncomplete: #{{{
#
# Apply asyncomplete settings to the current buffer if the filetype is
# enabled.
# Handle exceptions raised by lazy loading of plugins.
def ApplyAsyncompleteSettingByFileType()
  const enabled = get(g:asyncomplete_enabled_filetype, &ft, 0)
  if enabled
    try
      call g:asyncomplete#enable_for_buffer()
    catch /E117/
    endtry
    return
  endif
  try
    call g:asyncomplete#disable_for_buffer()
  catch /E117/
  endtry
enddef

def AsyncompleteSettings(): void
  g:asyncomplete_enable_for_all = 0
  # Use BufEnter to apply settings when switching between buffers, as FileType
  # is triggered only when the filetype changes or when a file is first opened.
  # Buffer ensures that the asyncomplete settings are applied even when the
  # filetype remains the same.
  augroup AsyncompleteFiletypeToggle
    autocmd!
    autocmd BufEnter * ApplyAsyncompleteSettingByFileType()
  augroup END
enddef

g:asyncomplete_enabled_filetype = {}

# Toggle asyncomplete for the current filetype.
# Handle exceptions raised by lazy loading of plugins.
def! g:ToggleAsyncompleteForFiletype()
  const enabled = get(g:asyncomplete_enabled_filetype, &ft, 0)
  if enabled
    remove(g:asyncomplete_enabled_filetype, &ft)
    try
      call g:asyncomplete#disable_for_buffer()
    catch /E117/
    endtry
    return
  endif
  try
    call g:asyncomplete#enable_for_buffer()
  catch /E117/
    echomsg 'asyncomplete not loaded yet.'
    return
  endtry
  # If the plugin is not loaded, it is conceivable that this will be called
  # again without being applied to the current buffer at least, so set the
  # flag only when successful.
  g:asyncomplete_enabled_filetype[&ft] = 1
enddef

def RemapAsyncompleteKeys(): void
  nnoremap <silent> <Space>tac <Cmd>call ToggleAsyncompleteForFiletype()<CR>
enddef
#}}}

# ---------------------------------------------------------------------------
# rainbowcyclone.vim: #{{{
#
def RemapRainbowCycloneKeys(): void
  nmap c/ <Plug>(rc_search_forward)
  nmap c? <Plug>(rc_search_backward)
  nmap c* <Plug>(rc_search_forward_with_cursor)
  nmap c# <Plug>(rc_search_backward_with_cursor)
  nmap cn <Plug>(rc_search_forward_with_last_pattern)
  nmap cN <Plug>(rc_search_backward_with_last_pattern)
# nmap <Esc><Esc> <Plug>(rc_reset):nohlsearch<CR>
# nnoremap <Esc><Esc> <Cmd>RCReset<CR>:nohlsearch<CR>
enddef
#}}}

# ---------------------------------------------------------------------------
# vim-cursorword: #{{{
#
def CursorwordSettings(): void
  g:cursorword_delay = 0
  g:cursorword_clear_on_leave = 1
  augroup MyCursorWord
    autocmd!
    autocmd InsertEnter * b:cursorword = 0 | call cursorword#clear()
    autocmd InsertLeave * b:cursorword = 1
  augroup END
enddef
#}}}

# ---------------------------------------------------------------------------
# vim-sandwich: #{{{
#
def RemapSandwichKeys(): void
  g:sandwich_no_default_key_mappings = 1
  nmap ys <Plug>(sandwich-add)
  nmap ds <Plug>(sandwich-delete)
  nmap dsb <Plug>(sandwich-delete-auto)
  nmap cs <Plug>(sandwich-replace)
  nmap csb <Plug>(sandwich-replace-auto)
  xmap S  <Plug>(sandwich-add)
enddef
#}}}
#}}}

# ---------------------------------------------------------------------------
# Load Plugins: #{{{
#
def AddPlugins(urls: list<string>, Postprocesses: list<func(): void> = []): list<dict<any>>
  return urls->mapnew((idx: number, url: string) => ({
    'url': url,
    'postprocesses': idx == len(urls) - 1 ? copy(Postprocesses) : [],
  }))
enddef

# Skip loading plugins in the start directory, because they are loaded
# automatically.
$PACKPATH = expand('~/.vim/pack/Bundle')
final plugins: dict<list<dict<any>>> = {
  'start': AddPlugins(['https://github.com/satorunooshie/forge.vim'], [ForgeSettings]),
  'opt': AddPlugins([
    'https://github.com/kana/vim-textobj-user',
    'https://github.com/kana/vim-operator-user',
    'https://github.com/kana/vim-textobj-indent',
    'https://github.com/kana/vim-textobj-syntax',
    'https://github.com/kana/vim-textobj-line',
    'https://github.com/kana/vim-textobj-fold',
    'https://github.com/kana/vim-textobj-entire',
    'https://github.com/thinca/vim-textobj-between',
    'https://github.com/thinca/vim-textobj-comment',
    'https://github.com/h1mesuke/textobj-wiw',
    'https://github.com/sgur/vim-textobj-parameter',
    'https://github.com/kana/vim-operator-replace',
  ]) +
  AddPlugins(['https://github.com/satorunooshie/vim-cursorword'], [CursorwordSettings]) +
  AddPlugins(['https://github.com/machakann/vim-sandwich'], [RemapSandwichKeys]) +
  AddPlugins(['https://github.com/thinca/vim-quickrun'], [QuickrunSettings, RemapQuickrunKeys]) +
  AddPlugins([
    'https://github.com/prabirshrestha/asyncomplete.vim',
    'https://github.com/prabirshrestha/asyncomplete-lsp.vim',
  ], [RemapAsyncompleteKeys]) +
  AddPlugins([
    'https://github.com/prabirshrestha/vim-lsp',
    'https://github.com/mattn/vim-lsp-settings',
  ], [LspSettings, RemapLspKeys]) +
  AddPlugins(['https://github.com/Eliot00/git-lens.vim'], [GitLensSettings, RemapGitLensKeys]) +
  AddPlugins(['https://github.com/mhinz/vim-signify'], [SignifySettings]) +
  AddPlugins(['https://github.com/daisuzu/rainbowcyclone.vim'], [RemapRainbowCycloneKeys]) +
  AddPlugins(['https://github.com/github/copilot.vim'], [RemapCopilotKeys]) +
  AddPlugins([
    # Make blockwise visual mode more useful.
    # ex: shift v + shift i.
    'https://github.com/kana/vim-niceblock',
    'https://github.com/knsh14/vim-github-link',
    'https://github.com/thinca/vim-qfreplace',
    'https://github.com/itchyny/vim-qfedit',
    # Replace the built-in matchparen for better performance.
    'https://github.com/itchyny/vim-parenmatch',
    # Replace the built-in logipat.vim for better performance.
    'https://github.com/satorunooshie/logicpat.vim',
    # Live preview substitute result and
    # highlight patterns and ranges for Ex commands in Command-line mode.
    'https://github.com/markonm/traces.vim',
    # Star for visual mode.
    # ex: shift v + *.
    'https://github.com/thinca/vim-visualstar',
    'https://github.com/mattn/vim-maketable',
    'https://github.com/vim-jp/vimdoc-ja',
    # Prettyprint vim variables.
    'https://github.com/thinca/vim-prettyprint',
    'https://github.com/thinca/vim-showtime',
    'https://github.com/LeafCage/vimhelpgenerator',
    'https://github.com/lifepillar/vim-colortemplate',
  ])
}

def CreateHelpTags(path: string): void
  if isdirectory(path)
    execute 'helptags ' .. path
  endif
enddef

def MkdirIfNotExists(path: string): void
  if !isdirectory(path)
    mkdir(path, 'p')
  endif
enddef

def SetupLoggingBuffer(name: string): number
  var prev = bufnr(name)
  if prev != -1 | execute ':' .. prev .. 'bwipeout!' | endif
  var nr = bufadd(name)
  bufload(nr)
  execute ':' .. nr .. 'sb'
  ToScratch
  return nr
enddef

def! g:InstallPackPlugins(): void
  var tasks: list<dict<any>> = []
  # loop from `start` avoid dependency problems.
  for key in reverse(sort(keys(plugins)))
    const dir = expand($PACKPATH .. '/' .. key)
    MkdirIfNotExists(dir)

    for plugin in plugins[key]
      const url = plugin.url
      const name = split(url, '/')[-1]
      const dst = expand(dir .. '/' .. name)
      add(tasks, {
        'url': url,
        'dst': dst,
        'postprocesses': plugin.postprocesses,
        'name': name,
      })
    endfor
  endfor

  if empty(tasks)
    echomsg 'All plugins are already installed.'
    return
  endif

  const nr: number = SetupLoggingBuffer('vimrc://install/plugins')

  var idx = 0
  var finished_count = 0
  const total = len(tasks)

  def OnMessage(name: string, ch: any, msg: string): void
    appendbufline(nr, 0, printf('[%-25s] %s', name, msg))
  enddef

  def OnExit(name: string, path: string, postprocesses: list<func(): void>, job: any, status: number): void
    ++finished_count
    if status ==# 0
      appendbufline(nr, 0, printf('[%-25s] Installed successfully.', name))
      CreateHelpTags(expand(path .. '/doc/'))
      execute 'packadd ' .. name
      for Postprocess in postprocesses
        Postprocess()
      endfor
    elseif status ==# -1
      # Plugin has already been installed.
      appendbufline(nr, 0, printf('[%-25s] Already installed, skipped.', name))
    else
      appendbufline(nr, 0, printf('[%-25s] Failed to install (status: %d)', name, status))
    endif


    if finished_count == total
      appendbufline(nr, 0, '--- All plugins have been installed ---')
    endif
  enddef

  def PluginInstallHandler(timer: number): void
    const task = tasks[idx]
    if isdirectory(task.dst)
      OnExit(task.name, task.dst, task.postprocesses, null, -1)
    else
      job_start(
        'git clone --recursive ' .. task.url .. ' ' .. task.dst,
        {
          'out_cb': function(OnMessage, [task.name]),
          'err_cb': function(OnMessage, [task.name]),
          'exit_cb': function(OnExit, [task.name, task.dst, task.postprocesses]),
        },
      )
    endif
    ++idx
  enddef

  timer_start(100, PluginInstallHandler, {'repeat': total})
enddef

def! g:UpdatePackPlugins(): void
  var tasks: list<dict<any>> = []
  for [type, list] in items(plugins)
    for plugin in list
      const url = plugin.url
      const name = split(url, '/')[-1]
      const dir = expand($PACKPATH .. '/' .. type)
      const dst = expand(dir .. '/' .. name)
      add(tasks, {
        'type': type,
        'dst': dst,
        'url': url,
        'postprocesses': plugin.postprocesses,
        'name': split(url, '/')[-1],
      })
    endfor
  endfor

  if empty(tasks)
    echomsg 'No plugins found.'
    return
  endif

  const nr: number = SetupLoggingBuffer('vimrc://update/plugins')

  var idx = 0
  var finished_count = 0
  const total = len(tasks)

  def OnMessage(name: string, ch: any, msg: string): void
    appendbufline(nr, 0, printf('[%-25s] %s', name, msg))
  enddef

  def OnExit(name: string, job: any, status: number): void
    ++finished_count
    if status ==# 0
      # Successfully updated.
    elseif status ==# -1
      # If not installed, treat it as completed and proceed with the count.
      appendbufline(nr, 0, printf('[%-25s] Not installed, skipped.', name))
    else
      appendbufline(nr, 0, printf('[%-25s] Failed to update (status: %d)', name, status))
    endif

    if finished_count == total
      for task in tasks
        echomsg 'helptags: ' .. task.dst
        CreateHelpTags(expand(task.dst .. '/doc/'))
      endfor
      appendbufline(nr, 0, '--- All plugins have been updated. Please restart Vim to apply changes. ---')
    endif
  enddef

  def PluginUpdateHandler(timer: number): void
    const task = tasks[idx]
    if isdirectory(task.dst)
      job_start(
        'git -C ' .. task.dst .. ' pull --ff --ff-only',
        {
          'out_cb': function(OnMessage, [task.name]),
          'err_cb': function(OnMessage, [task.name]),
          'exit_cb': function(OnExit, [task.name]),
        },
      )
    else
      OnExit(task.name, null, -1)
    endif
    ++idx
  enddef

  timer_start(100, PluginUpdateHandler, {'repeat': total})
enddef

def StartPackAdd(): void
  var pidx = 0

  def PackAddHandler(timer: number)
    if pidx >= len(plugins.opt)
      return
    endif

    const plugin = plugins.opt[pidx]
    const url = plugin.url
    const plugin_name = split(url, '/')[-1]

    const plugin_path = expand($PACKPATH .. '/opt/' .. plugin_name)
    if isdirectory(plugin_path)
      execute 'packadd ' .. plugin_name
      for Postprocess in plugin.postprocesses
        Postprocess()
      endfor
    endif

    ++pidx
    if pidx == len(plugins.opt)
      # Install fzf.
      if executable('fzf')
        set rtp+=/opt/homebrew/opt/fzf
        runtime plugin/fzf.vim
      endif

      packadd comment
      packadd cfilter
      # Extended % matching.
      packadd matchit
      # For filetype plugin.
      doautocmd FileType
    endif
  enddef
  timer_start(15, PackAddHandler, {'repeat': len(plugins.opt)})
enddef

if has('vim_starting') && has('timers')
  autocmd MyVimrcCmd VimEnter * StartPackAdd()
endif

# For ftdetect scripts to be loaded, need to write AFTER all `packadd!` commands.
filetype plugin indent on
#}}}

# ---------------------------------------------------------------------------
# External Settings: #{{{
#
$MYLOCALVIMRC = expand('~/.vim/.local.vimrc')
if 1 && filereadable($MYLOCALVIMRC)
  source $MYLOCALVIMRC
endif
#}}}
#}}}
