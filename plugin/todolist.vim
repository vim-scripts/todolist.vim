" ----------------------
" TodoList
" ----------------------
" author: Kevin Krouse <krousekh at math whitman edu>
" date: 3/16/02
" version: 0.0alpha
"
" WARNING: This is an alpha release.  Good luck.
"
" ----------------------
" Installation:
"   0) Install the winmanager plugin.
"   1) Copy this file into your .vim/plugin directory
"   2) Add the string 'TodoList' to your g:winManagerWindowLayout variable.
"   3) (Re)start vim and run :WMToggle
" ----------------------
" Usage:
"   [tbd]
" ----------------------
" Variables:
"   [tbd]
" ----------------------
" Features and bugs:
"   BUG:  Do search for todo when jumping to it (like ctags)
"   BUG:  Refresh should update only changed buffers
"         and should only delete/update todos that have changed.
"         Incremental updates that are fast.
"   BUG:  Can't refresh without messing up buf order
"   BUG:  Escape any special chars from data
"   BUG:  Cursor/window position restored after a BufferChanged()
"         When we switch back to current buffer, cursor is in middle of screen.
"         This is really annoying.
"   BUG:  Why does todo window sometimes put top line at first todo line?
"   TODO: Use BufNew,BufWrite,BufLeave,CursorHold to update the todo list
"   TODO: Cache rendered column; update only bufflag.
"         Invalidate the cache on change to ColumnsList. ugh.
"   TODO: Update '%' and '#' on buffer enter/leave
"   TODO: Implement delete todo ('d' key).
"   TODO: Delete todos for BufDelete?
"   TODO: Custom date display.
"
"   DONE: Preview pane close needs to force resize on todo list
" ----------------------

"set verbose =9

" don't load if already loaded or user doesn't want to
if exists("loaded_TodoList")
  finish
endif
let loaded_TodoList=1


" ----------------
" setup autocommands

augroup todolist
  autocmd!

  autocmd BufWrite * silent call <SID>CheckBufferChanged()

  autocmd BufNew     * silent call <SID>BufferChanged()
  autocmd CursorHold * silent call <SID>CheckBufferChanged()
  autocmd BufDelete  * silent call <SID>BufferDeleted()

  "autocmd BufEnter   * silent call <SID>BufferEnter()

  autocmd CursorHold *Todo\ List* call <SID>CursorHoldPreviewTodo()

  " >>>> autocommands for debugging >>>>
"  autocmd BufNewFile * call DEBUGMSG("BufNewFile: ".expand("%"))
"  autocmd BufReadPre * call DEBUGMSG("BufReadPre: ".expand("%"))
"  autocmd BufRead * call DEBUGMSG("BufRead: ".expand("%"))
"  autocmd BufReadPost * call DEBUGMSG("BufReadPost: ".expand("%"))
"
"  autocmd BufFilePre * call DEBUGMSG("BufFilePre: ".expand("%"))
"  autocmd BufFilePost * call DEBUGMSG("BufFilePost: ".expand("%"))
"
"  autocmd FileReadPre * call DEBUGMSG("FileReadPre: ".expand("%"))
"  autocmd FileReadPost * call DEBUGMSG("FileReadPost: ".expand("%"))
"
"  autocmd FilterReadPre * call DEBUGMSG("FilterReadPre: ".expand("%"))
"  autocmd FilterReadPost * call DEBUGMSG("FilterReadPost: ".expand("%"))
"
"  autocmd BufWrite * call DEBUGMSG("BufWrite: ".expand("%"))
"  autocmd BufWritePre * call DEBUGMSG("BufWritePre: ".expand("%"))
"  autocmd BufWritePost * call DEBUGMSG("BufWritePost: ".expand("%"))
"
"  autocmd FileWritePre * call DEBUGMSG("FileWritePre: ".expand("%"))
"  autocmd FileWritePost * call DEBUGMSG("FileWritePost: ".expand("%"))
"  autocmd FileAppendPre * call DEBUGMSG("FileAppendPre: ".expand("%"))
"  autocmd FileAppendPost * call DEBUGMSG("FileAppendPost: ".expand("%"))
"
"  autocmd FilterWritePre * call DEBUGMSG("FilterWritePre: ".expand("%"))
"  autocmd FilterWritePost * call DEBUGMSG("FilterWritePost: ".expand("%"))
"
"  autocmd FileChangedShell * call DEBUGMSG("FileChangedShell: ".expand("%"))
"  autocmd FileChangedRO * call DEBUGMSG("FileChangedRO: ".expand("%"))
"
"  autocmd CursorHold * call DEBUGMSG("CursorHold: ".expand("%"))
"
"  autocmd BufEnter * call DEBUGMSG("BufEnter: ".expand("%"))
"  autocmd BufLeave * call DEBUGMSG("BufLeave: ".expand("%"))
"  autocmd BufWinEnter * call DEBUGMSG("BufWinEnter: ".expand("%"))
"  autocmd BufWinLeave * call DEBUGMSG("BufWinLeave: ".expand("%"))
"
"  autocmd BufUnload * call DEBUGMSG("BufUnload: ".expand("%"))
"  autocmd BufHidden * call DEBUGMSG("BufHidden: ".expand("%"))
"  autocmd BufNew * call DEBUGMSG("BufNew: ".expand("%"))
"  autocmd BufAdd * call DEBUGMSG("BufAdd: ".expand("%"))
"  autocmd BufDelete * call DEBUGMSG("BufDelete: ".expand("%"))
"  autocmd BufWipeout * call DEBUGMSG("BufWipeout: ".expand("%"))
"
"  autocmd WinEnter * call DEBUGMSG("WinEnter: ".expand("%"))
"  autocmd WinLeave * call DEBUGMSG("WinLeave: ".expand("%"))
  " <<<< autocommands for debugging <<<<


augroup End



" ----------------
" global variables


" File name of todo list on disk
"if !exists('g:todoFileName')
  "let g:todoFileName = '.vimtodo'
"endif

" scan all open buffers for todos, or just current?
if !exists('g:todoCurrentOnly')
  "let g:todoCurrentOnly = 1
  let g:todoCurrentOnly = 0
endif

" Allow only todos within a syntax element named '*Todo$'
if !exists('g:todoEnableSyntax')
  let g:todoEnableSyntax = 1
  "let g:todoEnableSyntax = 0
endif

" Handles dynamic resizing of the window.
if !exists('g:todoWindowHeight')
  let g:todoWindowHeight = 20
endif

" Handles zooming of the window.
if !exists('g:todoWindowWidth')
  " this should really always be the same as g:winManagerWidth
  let g:todoWindowWidth = 25
endif

if !exists('g:todoHorizontalWindow')
  let g:todoHorizontalWindow = 0
  "let g:todoHorizontalWindow = 1
endif

" Sort todo list by (file, type, line, date, or text)
if !exists('g:todoSortBy')
  let g:todoSortBy = "type"
endif

" Sort order for the todo types
if !exists('g:todoTypeSortOrder')
  let g:todoTypeSortOrder = "BUG,TODO,FIXME,NOTE,XXX"
endif

" Sort in forward (1) or reverse order (-1)
if !exists('g:todoSortDirection')
  let g:todoSortDirection = 1
  "let g:todoSortDirection = -1
endif

" Allow preview pane on CursorHold to display
if !exists('g:todoPreviewOnCursorHold')
  "let g:todoPreviewOnCursorHold = 1
  let g:todoPreviewOnCursorHold = 0
endif

" Show detailed help. 0 = Don't show, 1 = Do show.
if !exists('g:todoDetailedHelp')
  let g:todoDetailedHelp = 0
  "let g:todoDetailedHelp = 1
endif

" When opening a new window, split the new windows below or above the
" current window?  1 = below, 0 = above.
"if !exists('g:todoSplitBelow')
  "let g:todoSplitBelow = &splitbelow
"endif

" When opening a new window, split the new window horzontally or vertically?
" '' = Horizontal, 'v' = Vertical.
"if !exists('g:todoSplitType')
  "let g:todoSplitType = ''
"endif

" When selected buffer is opened, open in current window or open a separate
" one. 1 = use current, 0 = use new.
"if !exists('g:todoOpenMode')
  "let g:todoOpenMode = 0
"endif

" List of columns as they appear from left->right
" special column 'bufflag' used for marking current/alt buffers
if !exists('g:todoColumnList')
  "let g:todoColumnList = "bufflag,type,date,text"
  let g:todoColumnList = "bufflag,type,text"
endif

let g:todoColumnWidth_BufFlag = 1  " #
let g:todoColumnWidth_Type    = 6  " fixme:
let g:todoColumnWidth_Date    = 11 " MM/DD/YYYY
let g:todoColumnWidth_Text    = 20 " upto 20 characters


" Format for the date
"if !exists("g:todoDateFormat")
  "let g:todoDateFormat="%d".s:todoDateDivider."%b".s:todoDateDivider."%Y"
"endif


" ----------------
" script variables

" a todo comment is any one of these patterns
let s:todoType = '\<\(TODO\|FIXME\|NOTE\|BUG\|XXX\)\>'

" date is either MM/DD or MM/DD/YY or MM/DD/YYYY
let s:todoDateDivider = '/'
let s:todoDate = '\(\d\{1,2}\)'.s:todoDateDivider.'\(\d\{1,2}\)'.s:todoDateDivider.'\?\(\d\{2}\(\d\{2}\)\?\)\?'
" 1 = MM, 2 = DD, 3 = YYYY

let s:todoLine = s:todoType.':\?\s*\('.s:todoDate.'\)\?\s*\(.*\)'
" 1 = type, 2 = date, 3 = MM, 4 = DD, 5 = YYYY, 7 = todo

" todo comments belong to one of the syntax groups listed
let s:todoSyntaxNames = '\(Todo\|Comment\)'
"let s:todoSyntaxNames = 'Todo'

" todo help needs to be created
let s:todoHelpDirty = 1

" set to 1 if the todo window is zoomed
let s:todoWindowMaximized = 0


" --------------------------------
" winmanager variables

" visible buffer name of to list view
let g:TodoList_title = "[Todo List]"

if !exists('g:todoResize')
  let g:todoResize = 1
endif


" Function to start display.
let s:todoInitialized = 0
let s:todoSuspend = 0
function! TodoList_Start()
  call DEBUGMSG("+TodoList_Start() currbuf: ".bufname('%').", altbuf: ".bufname('#'))

  " suspend any todo list refreshing while starting up
  let s:todoInitialized = 0

  let _showcmd = &showcmd
  set noshowcmd

  " mark the [Todo List] buffer as modifiable
  setlocal modifiable

  " scan the last buffer for todos
  call <SID>RefreshTodoList()

  " clean up
  silent! setlocal bufhidden=delete
  silent! setlocal buftype=nofile
  silent! setlocal nomodifiable
  silent! setlocal nomodified
  silent! setlocal nowrap
  silent! setlocal noswapfile
  silent! setlocal nonumber

  " Due to a bug in Vim 6.0, the winbufnr() function fails for unlisted
  " buffers. So if the todolist buffer is unlisted, multiple todolist
  " windows will be opened. This bug is fixed in Vim 6.1 and above
  if v:version >= 601
    silent! setlocal nobuflisted
  endif

  let &showcmd = _showcmd
  unlet! _showcmd

  " set up some _really_ elementary syntax highlighting.
  if has("syntax") && !has("syntax_items") && exists("g:syntax_on")
    syn match TodoListHelp         '^"\s\+.*' contains=TodoListHelpKey
    syn match TodoListHelpKey      '\[\w\]' contained
    syn match TodoListHelpSortBy   '^" Sort by: .*$'
    syn match TodoListHelpColumns  '^" Columns: .*$'
    syn match TodoListHelpDivider  '^" ----------------$'
    syn match TodoListHelpEnd      '^"=$'

    syn match TodoListData         '^[^"].*$' contains=TodoListDataIgnore,TodoListDataKeyword,TodoListDataBufFlag,TodoListDataNoDate
    syn keyword TodoListDataKeyword TODO FIXME NOTE BUG XXX contained
    syn match TodoListDataBufFlag '%' contained
    syn match TodoListDataBufFlag '#' contained
    syn match TodoListDataNoDate '<no date>' contained
    syn match TodoListDataIgnore   '";.*$'

    if !exists('g:did_todolist_syntax_inits')
      let g:did_todolist_syntax_inits = 1
      hi def link TodoListHelp        Special
      hi def link TodoListHelpKey     Identifier
      hi def link TodoListHelpSortBy  String
      hi def link TodoListHelpColumns Constant
      hi def link TodoListHelpDivider Comment
      hi def link TodoListHelpEnd     Special

      hi def link TodoListDataKeyword Keyword
      hi def link TodoListDataBufFlag Comment
      hi def link TodoListDataNoDate  String
      hi def link TodoListDataIgnore  Ignore
      " uncomment the below line to see the todo data
      "hi def link TodoListDataIgnore  String

    endif
  end

  " setup maps
  nnoremap <buffer> <silent> <2-leftmouse> :call <SID>GotoTodo()<cr>
  nnoremap <buffer> <silent> <cr> :call <SID>GotoTodo()<cr>
  nnoremap <buffer> <silent> p :call <SID>PreviewTodo()<cr>
  nnoremap <buffer> <silent> <c-w>z :pclose<cr>:call WinManagerForceReSize(g:TodoList_title)<cr>
  nnoremap <buffer> <silent> ? :call <SID>ToggleHelp()<cr>
  nnoremap <buffer> <silent> R :call TodoList_Start()<cr>
  nnoremap <buffer> <silent> r :call <SID>ToggleSortDirection()<cr>
  nnoremap <buffer> <silent> c :call <SID>TogglePreviewOnCursorHold()<cr>
  nnoremap <buffer> <silent> y :call <SID>ToggleEnableSyntax()<cr>
  nnoremap <buffer> <silent> s :call <SID>CycleSortMethod()<cr>
  nnoremap <buffer> <silent> x :call <SID>ZoomWindow()<cr>

  " allow todo list refreshing to happen
  let s:todoInitialized = 1

  call DEBUGMSG("-TodoList_Start()")
endfunction


" Returns whether the display is ok or not.
function! TodoList_IsValid()
  call DEBUGMSG("+TodoList_IsValid()")
  return 1
endfunction


" TodoList_ReSize()
" NOTE: renamed _hide so winmanager will never call it for now.
function! TodoList_ReSize_hide()
  call DEBUGMSG("+TodoList_Resize()")

  if !g:todoResize
    return
  end

  let nlines = line('$')

  if nlines > g:todoWindowHeight
    let nlines = g:todoWindowHeight
  endif

  exe nlines.' wincmd _'

  " The following lines restore the layout so that the last file line is also
  " the last window line. sometimes, when a line is deleted, although the
  " window size is exactly equal to the number of lines in the file, some of
  " the lines are pushed up and we see some lagging '~'s.
  let presRow = line('.')
  let presCol = virtcol('.')
  exe $
  let _scr = &scrolloff
  let &scrolloff = 0
  normal! z-
  let &scrolloff = _scr
  exe presRow
  exe 'normal! '.presCol.'|'

  call DEBUGMSG("-TodoList_Resize()")
endfunction


" ----------------
" script functions


" debugging messages
let g:todoDebugMsg = ""
function! DEBUGMSG(s)
  let g:todoDebugMsg = g:todoDebugMsg.a:s."\n"
endfunction



" RefreshTodoList
function! <SID>RefreshTodoList()
  call DEBUGMSG("+RefreshTodoList() currbuf: ".bufname('%').", altbuf: ".bufname('#'))

  " suspend winmanager
  call WinManagerSuspendAUs()

  " resulting todolist
  let g:todolist = ""

  if g:todoCurrentOnly == 1

    " only search the current buffer
    let bufnum = WinManagerGetLastEditedFile()
    if !<SID>InvalidBuffer(bufnum)
      exe "e #".bufnum
      call <SID>SearchTodo()
    endif

  else

    " loop over all open buffers
    if g:todoEnableSyntax == 0
      " loop over buffers and search for todos
      bufdo! call <SID>SearchTodo()
    else
      " alternate loop doesn't suspend Syntax autocommand
      let i = 0
      let last = bufnr('$')
      while i < last
        let i = i+1
        call DEBUGMSG('  RefreshTodoList: opening #'.i.' ('.bufname(i).')')

        " skip over invalid buffers
        if <SID>InvalidBuffer(i)
          continue
        endif

        exe "e #".i

        call <SID>SearchTodo()
      endwhile
    endif

  endif

  " directly open up [Todo List]
  exe 'e '.g:TodoList_title

  " render todo view
  call <SID>RenderTodoView(g:todolist)

  call WinManagerResumeAUs()

  call DEBUGMSG("-RefreshTodoList()")
endfunction


" ToggleWindow()
" open or close the todolist window
function! <SID>ToggleWindow(bufnum)
  let curline = line('.')

  " if todolist window is open, then close it
  if winnum = bufwinnr(g:TodoList_title)
  if winnum != -1
    if winnr() == winnum
      " already in the todolit window. close it
      close
    else
      " goto the todolist window, close it and come back
      let currBuffer = bufnr('%')
      exe winnum . 'wincmd w'
      close

      " need to jump back to the original window only if we are not
      " already in that window
      let winnum = bufwinnr(currBuffer)
      if winnr() != winnum
          exe winnum . 'wincmd w'
      endif
    endif
    return
  endif

  " TODO: otherwise open the window

endfunction


" ZoomWindow
" zoom (maximize/minimize) the todolist window
function! <SID>ZoomWindow()
  if s:todoWindowMaximized == 1
    if g:todoHorizontalWindow == 1
      exe 'resize ' . g:todoWindowHeight
    else
      exe 'vert resize ' . g:todoWindowWidth
    endif
    let s:todoWindowMaximized = 0
  else
    " set the window size to the maximum possible
    if g:todoHorizontalWindow == 1
      resize
    else
      vert resize
    endif
    let s:todoWindowMaximized = 1
  endif
endfunction


" InvalidBuffer()
" return 1 if the bufnum is can be skipped
function! <SID>InvalidBuffer(bufnum)

  " normal buffers return have 'buftype' of ''
  if getbufvar(a:bufnum, "&buftype") != ''
    call DEBUGMSG("  InvalidBuffer: buftype = " . getbufvar(a:bufnum, "&buftype"))
    return 1
  endif

  " unlisted buffers can be skipped
  if !buflisted(a:bufnum)
    call DEBUGMSG("  InvalidBuffer: unlisted ")
    return 1
  endif

  let filename = fnamemodify(bufname(a:bufnum), '%:p')

  if filename == ""
    call DEBUGMSG("  InvalidBuffer: no filename ")
    return 1
  endif

  " skip unreadable files
  if !filereadable(filename)
    call DEBUGMSG("  InvalidBuffer: unreadable ")
    return 1
  endif

  return 0
endfunction


" BufferDeleted()
function! <SID>BufferDeleted()
  call DEBUGMSG("+BufferDeleted: bufname('%')=".bufname('%').", <afile>=".expand("<afile>"))

  if s:todoInitialized == 0
    call DEBUGMSG("  todoInitialized == 0")
    return
  endif

  if s:todoSuspend == 1
    call DEBUGMSG("  todoSuspend == 0")
    return
  endif

  let currBufName = bufname('%')
  let currBuffer = bufnr('%')
  let altBuffer = bufnr('#')

  if <SID>InvalidBuffer(currBuffer)
    return
  endif

  call WinManagerSuspendAUs()

"  exe "e ".g:TodoList_title
"  setlocal modifiable
"
"  " delete any todo items in for this buffer
"  exe "g#file(".currBufName.")#d"
"
"  call <SID>RenderTodoView("")
"
"  setlocal nomodifiable
"  setlocal nomodified
"
"  " restore original buffer
"  if bufnr('%') != currBuffer
"    if altBuffer != -1
"      exe "e #".altBuffer
"    endif
"    if currBuffer != -1
"      exe "e #".currBuffer
"    endif
"  endif

  call WinManagerResumeAUs()

  call DEBUGMSG("-BufferDeleted: ".bufname('%'))
endfunction


" BufferEnter()
function! <SID>BufferEnter()
  call DEBUGMSG("+BufferEnter: ".bufname('%'))

  if s:todoInitialized == 0
    call DEBUGMSG("  todoInitialized == 0")
    return
  endif

  if s:todoSuspend == 1
    call DEBUGMSG("  todoSuspend == 0")
    return
  endif

  let bufnum = bufnr('%')

  if <SID>InvalidBuffer(bufnum)
    return
  endif

  call <SID>BufferChanged()

endfunction


" CheckBufferChanged()
function! <SID>CheckBufferChanged()
  call DEBUGMSG("+CheckBufferChanged: ".bufname('%'))

  if s:todoInitialized == 0
    call DEBUGMSG("  todoInitialized == 0")
    return
  endif

  if s:todoSuspend == 1
    call DEBUGMSG("  todoSuspend == 0")
    return
  endif

  let bufnum = bufnr('%')

  if <SID>InvalidBuffer(bufnum)
    return
  endif

  if !exists('g:tick_'.bufnum)
    exe 'let g:tick_'.bufnum.' = b:changedtick - 1'
    return
  endif

  " check the buffer variable 'changedtick'
  exe "if g:tick_".bufnum." < b:changedtick"
    call <SID>BufferChanged()
  endif

  call DEBUGMSG("-CheckBufferChanged: ".bufname('%'))
endfunction



" BufferChanged()
function! <SID>BufferChanged()
  call DEBUGMSG("+BufferChanged: ".bufname('%'))

  if s:todoInitialized == 0
    call DEBUGMSG("  todoInitialized == 0")
    return
  endif

  if s:todoSuspend == 1
    call DEBUGMSG("  todoSuspend == 0")
    return
  endif

  let currBufName = bufname('%')
  let currBuffer = bufnr('%')
  let altBuffer = bufnr('#')

  if <SID>InvalidBuffer(currBuffer)
    return
  endif

  " save changed tick number (used by CheckBufferChanged() function)
  "exe 'let g:tick_'.bufnr('%').' = b:changedtick'

  let _report = &report
  let &report = 10000

  " suspend
  let s:todoSuspend = 1
  call WinManagerSuspendAUs()

  "let position = <SID>SaveCursorPosition()

  " get the list of todos
  let g:todolist = ""
  call <SID>SearchTodo()

  exe "e ".g:TodoList_title
  setlocal modifiable

  if g:todoCurrentOnly
    " delete all but help lines if we interested only in the current buf
    exe 'g#^[^"]#d'
  else
    " delete any todo items in for this buffer
    call DEBUGMSG(" >> deleted lines:")
    exe "g#file(".currBufName."#call DEBUGMSG(\" >> \".getline('.'))"
    exe "g#file(".currBufName.")#d"
    call <SID>CleanUpHistory()
  endif

  " add to list of todos
  call DEBUGMSG(" ** updated list of todos:")
  call DEBUGMSG(g:todolist)

  call <SID>RenderTodoView(g:todolist)

  " cleanup
  setlocal nomodifiable
  setlocal nomodified
  "setlocal nobuflisted

  " restore original buffer
  if bufnr('%') != currBuffer
    if altBuffer != -1
      exe "e #".altBuffer
    endif
    if currBuffer != -1
      exe "e #".currBuffer
    endif
  endif

  "call <SID>RestoreCursorPosition(position)

  " resume
  let s:todoSuspend = 0
  call WinManagerResumeAUs()

  let &report = _report

  call DEBUGMSG("-BufferChanged: ".bufname('%'))
endfunction


" SearchTodo()
" search the current buffer for todos
" return result in global variable g:todolist
function! <SID>SearchTodo()
  call DEBUGMSG("+SearchTodo: ".bufname('%'))

  " save cursor line and column
  let save_line = line('.')
  let save_col = col('.')

  " the resulting todo list
  let todolist = ""

  " start search at first line, first char
  normal 1G
  let lastline = -1
  while search(s:todoType, 'W') > 0
    "call DEBUGMSG("match: " . getline("."))

    " skip any duplicate matches on same line
    if lastline != -1 && lastline == line('.')
      continue
    endif

    " checking the syntax of the item is _very_ expensive!
    if g:todoEnableSyntax == 1

      let synID = synID(line("."), col("."), 1)
      let synName = synIDattr(synID, "name")

      " if the syntax highlighting is of type 'todo'
      " add it to the list
      if match(synName, s:todoSyntaxNames) == -1
        "call DEBUGMSG("  !! not in syntax")
        continue
      endif
    endif

    let todolist = todolist . ParseTodoLine()

    let lastline = line('.')

  endwhile

  " save changed tick number (used by CheckBufferChanged() function)
  exe 'let g:tick_'.bufnr('%').' = b:changedtick'

  " restore line and column
  " BUG: need to restore the ' mark as well?
  0
  exe "normal!". save_line . "G"
  exe "normal!". save_col . "|"

  " instead of returning, set global variable g:todolist
  " need to do it this way because this method is called by bufdo
  let g:todolist = g:todolist . todolist

  call DEBUGMSG(g:todolist)

endfunction


" ParseTodoLine()
" cursor is on line and column of a todo comment.
" returns a string representation of the todo for later retrieval.
function! ParseTodoLine()
  let bufname = bufname('%')
  let line = line('.')
  let col = col('.')

  " save current 'a' register
  let a_save = @a

  " put everything from current col to end of line into 'a' register
  normal "ay$
  "echo "  parse: ".@a

  let todo = substitute(@a, s:todoLine, "type(\\1),date(\\2),mon(\\3),day(\\4),year(\\5),text(\\7)", '')
  "echo "  ".substitute(@a, s:todoLine, '\="type(".submatch(1)."),mon(".submatch(3)."),day(".submatch(4)."),year(".submatch(5)."),text(".EscapeTodo(submatch(7)).")"', '')

  " restore old 'a' register
  let @a = a_save

  return "file(".bufname."),line(".line."),col(".col."),".todo."\n"
  "return "\"; file(".bufname."),line(".line."),col(".col."),".todo."\n"

endfunction


" ExtractFileName(line)
" get str part from the line 'file(str)'
function! <SID>ExtractFileName(line)
  return strpart(matchstr(a:line, "file([^)]*"), 5)
endfunction


" ExtractLineNum(line)
" get line number part from the line 'line(num)'
function! <SID>ExtractLineNum(line)
  return strpart(matchstr(a:line, "line([^,]*"), 5) + 0
endfunction


" ExtractColNum(line)
" get column number part from the line 'col(num)'
function! <SID>ExtractColNum(line)
  return strpart(matchstr(a:line, "col([^,]*"), 4) + 0
endfunction


" ExtractTypeStr(line)
function! <SID>ExtractTypeStr(line)
  return strpart(matchstr(a:line, "type([^)]*"), 5)
endfunction


" ExtractDateStr(line)
function! <SID>ExtractDateStr(line)
  return strpart(matchstr(a:line, "date([^)]*"), 5)
endfunction


" ExtractMonthNum(line)
function! <SID>ExtractMonthNum(line)
  return strpart(matchstr(a:line, "mon([^)]*"), 4) + 0
endfunction


" ExtractDayNum(line)
function! <SID>ExtractDayNum(line)
  return strpart(matchstr(a:line, "day([^)]*"), 4) + 0
endfunction


" ExtractYearNum(line)
function! <SID>ExtractYearNum(line)
  return strpart(matchstr(a:line, "year([^)]*"), 5) + 0
endfunction


" ExtractTextStr(line)
" BUG: doesn't work when text has ) in it
function! <SID>ExtractTextStr(line)
  return strpart(matchstr(a:line, "text([^)]*"), 5)
endfunction


" escape a string for storage in the todo record
"function! EscapeTodo(todo)
  "return substitute(a:todo, '\([(),]\)', '\\\1', '')
"endfunction


" CursorHoldPreviewTodo()
function! <SID>CursorHoldPreviewTodo()
  if g:todoPreviewOnCursorHold == 1
    call <SID>PreviewTodo()
  endif
endfunction


" PreviewTodo()
" current line is a todoline in [Todo List]
function! <SID>PreviewTodo()
  call DEBUGMSG("+PreviewTodo()")
  call DEBUGMSG("  curr=".bufname('%').", alt=".bufname('#').", line=".getline('.'))

  let todoline = getline('.')

  " skip help lines
  if todoline[0] == '"'
    return
  endif

  let file = <SID>ExtractFileName(todoline)
  let line = <SID>ExtractLineNum(todoline)
  let col = <SID>ExtractColNum(todoline)
  "let text = <SID>ExtractTextStr(todoline)

  exe "pedit +".line." ".file

  call DEBUGMSG("-PreviewTodo()")
endfunction


" GotoTodo
" current line is a todoline in [Todo List]
function! <SID>GotoTodo()
  call DEBUGMSG("+GotoTodo()")
  call DEBUGMSG("  curr=".bufname('%').", alt=".bufname('#').", line=".getline('.'))

  let todoline = getline('.')

  " ignore help lines
  if todoline[0] == '"'
    return
  endif

  let file = <SID>ExtractFileName(todoline)
  let line = <SID>ExtractLineNum(todoline)
  let col = <SID>ExtractColNum(todoline)
  let text = <SID>ExtractTextStr(todoline)

  " check for valid filename
  if file == '' || !filereadable(file)
    return
  endif

  " let winmanager open the file
  call WinManagerFileEdit(file, 0)

  " goto line and column of the todo
  "exe line
  "exe "normal! ". col ."|"
  call cursor(line, col)

  " search for the text just in case the todo moved
  "exe "normal /".text

  " put line in middle of window
  normal! z.

  call DEBUGMSG("-GotoTodo()")
endfunction


" RenderTodoView()
" render the view from the scratch buffer
function! <SID>RenderTodoView(data)
  call DEBUGMSG("+RenderTodoView()")

  call <SID>UpdateHelp()

  setlocal modifiable

  if a:data != ""
    " Prevent odd huge indent when first invoked.
    normal! 0

    $put = a:data

  endif

  call <SID>SortListing()

  " put cursor on first todo line
  " BUG: why is window top line on /= line ?!?!
  "normal! 0
  "normal! 1G
  "silent! /^"=/+1
  "call <SID>CleanUpHistory()
  "normal! z.

  " cleanup
  setlocal nomodified
  setlocal nomodifiable
  "setlocal nobuflisted

  call DEBUGMSG("-RenderTodoView()")
endfunction


" RenderColumns
function! <SID>RenderColumns(bufnum, altnum)
  "call DEBUGMSG("+RenderColumns: ".getline('.'))

  " delete any previous columns
  silent! s/^.*"; //
  call <SID>CleanUpHistory()

  let line = getline('.')

  " this is the resulting column specification
  let data = ''

  " compose the columns from the column list
  let colNum = 0
  while 1
    let colNum = colNum + 1

    let curColumn = <SID>Strntok(g:todoColumnList, ',', colNum)
    if curColumn == ''
      break
    endif

    let colVal = ''

    " a 'bufflag' column marked with '%', '#', or ' '
    if curColumn == 'bufflag'
      let num = bufnr(<SID>ExtractFileName(line))
      if num == a:bufnum
        let colVal = '%'
      elseif num == a:altnum
        let colVal = '#'
      elseif num == -1
        let colVal = '?'
      else
        let colVal = ' '
      endif

    " a 'file' name column. extract base file name
    elseif curColumn == 'file'
      let colVal = fnamemodify(<SID>ExtractFileName(line), ":t")

    " a 'type' column. width is 5 (for fixme) plus 1 for ':'
    elseif curColumn == 'type'
      let colVal = <SID>ExtractTypeStr(line) . ':'
      while strlen(colVal) < 6
        let colVal = colVal.' '
      endwhile

    " a 'text' column.
    elseif curColumn == 'text'
      let colVal = <SID>ExtractTextStr(line)

    " a 'date' column. width is 11 for MM/DD/YYYY (too big!)
    elseif curColumn == 'date'
      let colVal = <SID>ExtractDateStr(line)
      if colVal == ''
        let colVal = ' <no date> '
      else
        while strlen(colVal) < 11
          let colVal = colVal.' '
        endwhile
      endif

    " a 'line' column. pretty worthless
    elseif curColumn == 'line'
      let colVal = <SID>ExtractLineNum(line)

    " a 'col' column. pretty worthless
    elseif curColumn == 'col'
      let colVal = <SID>ExtractColNum(line)

    " a 'fullfile' column. pretty worthless
    elseif curColumn == 'fullfile'
      let colVal = <SID>ExtractFileName(line)

    " just ignore anything we don't handle above
    else
      continue
    endif

    " default is to append to column spec
    let data = data.colVal

  endwhile

  call setline('.', data.' "; '.line)
endfunction


" TodoFileCmp
function! <SID>TodoFileCmp(line1, line2, direction)
  let a = <SID>ExtractFileName(a:line1)
  let b = <SID>ExtractFileName(a:line2)
  return <SID>StrCmp(toupper(a), toupper(b), a:direction)
endfunction


" TodoTypeCmp
" TODO: cmp done in order of g:todoTypeSortOrder
function! <SID>TodoTypeCmp(line1, line2, direction)
  let a = <SID>ExtractTypeStr(a:line1)
  let b = <SID>ExtractTypeStr(a:line2)
  return <SID>StrCmp(toupper(a), toupper(b), a:direction)
endfunction


" TodoLineCmp
function! <SID>TodoLineCmp(line1, line2, direction)
  let a = <SID>ExtractLineNum(a:line1)
  let b = <SID>ExtractLineNum(a:line2)
  return <SID>NumCmp(a, b, a:direction)
endfunction


" TodoDateCmp
" TODO: cmp done by year, month, day
function! <SID>TodoDateCmp(line1, line2, direction)
  let a = <SID>ExtractDateStr(a:line1)
  let b = <SID>ExtractDateStr(a:line2)
  return <SID>StrCmp(toupper(a), toupper(b), a:direction)
endfunction


" TodoTextCmp
function! <SID>TodoTextCmp(line1, line2, direction)
  let a = <SID>ExtractTextStr(a:line1)
  let b = <SID>ExtractTextStr(a:line2)
  return <SID>StrCmp(toupper(a), toupper(b), a:direction)
endfunction


" StrCmp
function! <SID>StrCmp(line1, line2, direction)
  if a:line1 < a:line2
    return -a:direction
  elseif a:line1 > a:line2
    return a:direction
  else
    return 0
  endif
endfunction


" NumCmp
function! <SID>NumCmp(num1, num2, direction)
  if a:num1 < a:num2
    return -a:direction
  elseif a:num1 > a:num2
    return a:direction
  else
    return 0
  endif
endfunction


" CycleSortMethod
function! <SID>CycleSortMethod()
  call DEBUGMSG("+CycleSortMethod()")

  if !exists('g:todoSortBy')
    let g:todoSortBy = "type"
  elseif g:todoSortBy == "type"
    let g:todoSortBy = "line"
  elseif g:todoSortBy == "line"
    let g:todoSortBy = "date"
  elseif g:todoSortBy == "date"
    let g:todoSortBy = "file"
  elseif g:todoSortBy == "file"
    let g:todoSortBy = "text"
  elseif g:todoSortBy == "text"
    let g:todoSortBy = "type"
  endif

  " force redraw of help
  let s:todoHelpDirty = 1

  call <SID>RenderTodoView("")

  call DEBUGMSG("-CycleSortMethod()")
endfunction


" SortListing
" g:todoSortBy is one of:
"   file = sort by file name (alphabetically)
"   line = sort by line number
"   date = sort by date
"   type = sort by todo type (by type sort order)
"   text = sort by todo text (alphabetically)
function! <SID>SortListing()
  " call DEBUGMSG("+SortListing()")

  let cmp = "<SID>TodoTypeCmp"

  if g:todoSortBy == "type"
    let cmp = "<SID>TodoTypeCmp"
  elseif g:todoSortBy == "line"
    let cmp = "<SID>TodoLineCmp"
  elseif g:todoSortBy == "date"
    let cmp = "<SID>TodoDateCmp"
  elseif g:todoSortBy == "file"
    let cmp = "<SID>TodoFileCmp"
  elseif g:todoSortBy == "text"
    let cmp = "<SID>TodoTextCmp"
  endif

  /^"=/
  call <SID>CleanUpHistory()
  if line('.') != line('$')
    call <SID>DoSortAndRender(cmp)
  endif

  " call DEBUGMSG("-SortListing()")
endfunction



" DoSortAndRender
" for some reason, vim complained about the lines below when inline in the
" SortListing method above
function! <SID>DoSortAndRender(cmp)
  .+1,$call <SID>Sort(a:cmp, g:todoSortDirection)
  "call <SID>CleanUpHistory()
  .,$call <SID>RenderColumns(WinManagerGetLastEditedFile(1), WinManagerGetLastEditedFile(2))
  "call <SID>CleanUpHistory()
endfunction


" Sort
function! <SID>Sort(cmp, direction) range
  call <SID>SortR(a:firstline, a:lastline, a:cmp, a:direction)
endfunction


" SortR is recursive
function! <SID>SortR(start, end, cmp, direction)
  " Bottom of the recursion if start reaches end
  if a:start >= a:end
    return
  endif

  let partition = a:start - 1
  let middle = partition
  let partStr = getline((a:start + a:end) / 2)

  let i = a:start

  while i <= a:end
    let str = getline(i)

    exec "let result = " . a:cmp . "(str, partStr, " . a:direction . ")"

    if result <= 0
      " Need to put it before the partition.
      " Swap lines i and partition.
      let partition = partition + 1

      if result == 0
        let middle = partition
      endif

      if i != partition
        let str2 = getline(partition)
        call setline(i, str2)
        call setline(partition, str)
      endif
    endif

    let i = i + 1
  endwhile

  " Now we have a pointer to the 'middle' element, as far as 
  " partitioning goes, which could be anywhere before the partition.
  " Make sure it is at the end of the partition.
  if middle != partition
    let str = getline(middle)
    let str2 = getline(partition)
    call setline(middle, str2)
    call setline(partition, str)
  endif

  call <SID>SortR(a:start, partition - 1, a:cmp, a:direction)
  call <SID>SortR(partition + 1, a:end, a:cmp, a:direction)
endfunction


" ToggleSortDirection
function! <SID>ToggleSortDirection()
  if g:todoSortDirection == -1
    let g:todoSortDirection = 1
  else
    let g:todoSortDirection = -1
  endif

  " force redraw of help
  let s:todoHelpDirty = 1

  let position = <SID>SaveCursorPosition()
  call <SID>RenderTodoView("")
  call <SID>RestoreCursorPosition(position)
endfunction


" TogglePreviewOnCursorHold
function! <SID>TogglePreviewOnCursorHold()
  let g:todoPreviewOnCursorHold = !g:todoPreviewOnCursorHold
endfunction


" ToggleEnableSyntax
function! <SID>ToggleEnableSyntax()
  let g:todoEnableSyntax = !g:todoEnableSyntax

  "let position = call <SID>SaveCursorPosition()
  call TodoList_Start()
  "call <SID>RestoreCursorPosition(position)
endfunction


" ToggleHelp
function! <SID>ToggleHelp()
  let g:todoDetailedHelp = !g:todoDetailedHelp

  " force redraw of help
  let s:todoHelpDirty = 1

  call <SID>UpdateHelp()

  call WinManagerForceReSize("TodoList")
endfunction


" UpdateHelp
function! <SID>UpdateHelp()
  call DEBUGMSG("+UpdateHelp()")

  setlocal modifiable

  " save position
  normal! mZ

  " delete old help and redraw
  if s:todoHelpDirty == 1
    silent! 0,/"=/d _
    call <SID>CleanUpHistory()
    call <SID>AddHelp()
  endif

  " drawing help leaves a blank line for some reason
  silent! /^$/d
  call <SID>CleanUpHistory()

  " return to position
  0
  if line("'Z") != 0
    normal! `Z
  endif

  setlocal nomodified
  setlocal nomodifiable
  "setlocal nobuflisted

  call DEBUGMSG("-UpdateHelp()")
endfunction


" AddHelp.
function! <SID>AddHelp()
  " call DEBUGMSG("+AddHelp()")

  " start at the top
  0

  if g:todoDetailedHelp == 1
    let s:todoHelp = "\" Todo Explorer\n"
    let s:todoHelp = s:todoHelp."\" ----------------\n"
    let s:todoHelp = s:todoHelp."\" <cr> : open todo under cursor\n"
    let s:todoHelp = s:todoHelp."\" p : [p]review todo under cursor\n"
    let s:todoHelp = s:todoHelp."\" C-w z : close preview window\n"
    let s:todoHelp = s:todoHelp."\" x : zoom todo list window\n"
    "let s:todoHelp = s:todoHelp."\" d : [d]elete todo\n"

    "if b:todoSplitWindow == 1
      "let s:todoHelp = s:todoHelp."\" o : toggle open mode\n"
    "endif

    "let s:todoHelp = s:todoHelp."\" q : quit the TodoList\n"
    let s:todoHelp = s:todoHelp."\" s : cycle [s]ort field\n"

    "if b:todoSplitWindow == 1
      "let s:todoHelp = s:todoHelp."\" t : toggle split type\n"
    "endif

    let s:todoHelp = s:todoHelp."\" c : toggle preview on [C]ursorHold\n"
    let s:todoHelp = s:todoHelp."\" y : toggle s[y]ntax\n"

    let s:todoHelp = s:todoHelp."\" r : [r]everse sort\n"
    let s:todoHelp = s:todoHelp."\" R : [R]escan buffers for todos\n"
    let s:todoHelp = s:todoHelp."\" ? : toggle this help\n"

    let s:todoHelp = s:todoHelp."\" ----------------\n"
    let s:todoHelp = s:todoHelp."\" Columns: ".g:todoColumnList."\n"
  else
    let s:todoHelp = "\" Press ? for Help\n"
  endif

  let s:todoHelp = s:todoHelp."\" Sort by: ".g:todoSortBy
  if g:todoSortDirection == 1
    let s:todoHelp = s:todoHelp." (desc)"
  else
    let s:todoHelp = s:todoHelp." (asc)"
  endif
  let s:todoHelp = s:todoHelp."\n"

  let s:todoHelp = s:todoHelp."\"="

  " call DEBUGMSG("-AddHelp(): ".s:todoHelp)
  put! =s:todoHelp
endfunction


" SaveCursorPosition
" returns a string representing the position as 'winline,wincol'
function! <SID>SaveCursorPosition()
  call DEBUGMSG(" ** saved   line: ".line('.').", col: ".col('.')." ** winline: ".winline().", wincol: ".wincol())

  " get cursor position within window
  let winline = winline()
  let wincol = wincol()

  " move cursor to middle
  "normal M

  " get cursor position within file
  "let s:line = line('.')
  "let s:column = col('.')

  return winline.",".wincol
endfunction


" RestoreCursorPosition
" put cursor back on winline, wincolumn from string "winline,wincol"
function! <SID>RestoreCursorPosition(position)
  call DEBUGMSG("+RestoreCursorPosition(".a:position.")")

  let winline = matchstr(a:position, '^\d\+,')
  let winline = strpart(winline, 0, strlen(winline) - 1)

  let wincol = strpart(matchstr(a:position, ',\d\+$'), 1)

  call <SID>RestorePosition(winline, wincol)
endfunction


" RestorePosition
function! <SID>RestorePosition(winline, wincol)
  call DEBUGMSG(" ** current line: ".line('.').", col: ".col('.')." ** winline: ".winline().", wincol: ".wincol())

  "execute a:winline
  execute "normal! ".a:winline

  call DEBUGMSG(" ** moved line: ".line('.').", col: ".col('.')." ** winline: ".winline().", wincol: ".wincol())

  execute "normal! ".a:wincol . "|"

  call DEBUGMSG(" ** restore line: ".line('.').", col: ".col('.')." ** winline: ".winline().", wincol: ".wincol())
endfunction


" CleanUpHistory
function! <SID>CleanUpHistory()
  call histdel("/", -1)
  let @/ = histget("/", -1)
endfunction


" Strntok:
" extract the n^th token from s seperated by tok.
" example: Strntok('1,23,3', ',', 2) = 23
fun! <SID>Strntok(s, tok, n)
  return matchstr( a:s.a:tok[0], '\v(\zs([^'.a:tok.']*)\ze['.a:tok.']){'.a:n.'}')
endfun


" vim:sw=2:ts=2:et
