# Generated from config/default.caratrc by bin/carat-gen-config.rb.
# Do not edit. Change config/default.caratrc and run: spin run carat-gen-config
module Carat
  module Domain
    DEFAULT_CARATRC = <<~'CARATRC'.freeze
      # Carat's shipped configuration: every default option, key binding,
      # language command, and plugin setting. The binary embeds this file;
      # after a change, run make gen-config.
      #
      # Every line is "scope.name value": a dotted key, then a word, a number,
      # true or false, or a space-separated list. A word with spaces is quoted,
      # with \" and \\ as escapes inside the quotes. # starts a comment.
      # ~/.config/carat/caratrc and then a project's .caratrc are read after
      # this file, and a later line wins.

      # Options, by their Vim names.
      option.number true
      option.relativenumber false
      option.tabstop 2
      option.shiftwidth 2
      option.expandtab true
      option.autoindent true
      option.ignorecase false
      option.smartcase true
      option.hlsearch true
      option.incsearch true
      option.cursorline true
      option.wrap false
      option.scroll 0
      option.scrolloff 5
      option.clipboard ""
      option.icons nerd
      option.undolevels 1000
      option.timeoutlen 500
      # Milliseconds a key that begins longer bindings waits before the key
      # hints list what may follow; 0 turns them off.
      option.keyhints.delay 300
      # The width of the left and right sidebars in columns and the height of
      # the bottom panel in rows, 0 to 500; 0 keeps the size the view asks for.
      option.layout.left_width 0
      option.layout.right_width 0
      option.layout.panel_height 0
      # When file windows show a winbar with their path and the cursor's
      # symbols: auto (with two or more file windows), always, or never.
      option.breadcrumbs auto
      # What a jump (gd, a pick-list choice, Ctrl-O, Ctrl-I) does with the tab
      # of the buffer it leaves: replace (the target takes it) or keep (Vim's).
      option.jumptab replace
      # The border of floats, as Neovim's winborder: none, single, double,
      # rounded, or solid; +, -, and | with option.icons ascii.
      option.winborder rounded
      # Indent guides in file windows: a guide at each shiftwidth level of
      # the indentation, in one character one column wide, drawn as | with
      # option.icons ascii when the character is not ASCII.
      option.indentguides true
      option.indentguides.char ┊
      option.theme one_dark
      option.background terminal
      option.startscreen true
      option.reducedmotion false

      # Key bindings: keymap.<mode> <keys> <action>, the keys in Vim notation
      # and the action an action name, a key sequence to replay, or none to
      # unbind. keymap.leader is what <leader> stands for.
      keymap.leader <Space>

      # Normal mode.
      keymap.normal h cursor.left
      keymap.normal j cursor.down
      keymap.normal k cursor.up
      keymap.normal l cursor.right
      keymap.normal <Left> cursor.left
      keymap.normal <Down> cursor.down
      keymap.normal <Up> cursor.up
      keymap.normal <Right> cursor.right
      keymap.normal 0 cursor.line_start
      keymap.normal ^ cursor.first_nonblank
      keymap.normal $ cursor.line_end
      keymap.normal gg cursor.buffer_start
      keymap.normal G cursor.buffer_end
      keymap.normal f motion.find_forward
      keymap.normal F motion.find_backward
      keymap.normal t motion.till_forward
      keymap.normal T motion.till_backward
      keymap.normal ; motion.repeat_find
      keymap.normal , motion.repeat_find_reverse
      keymap.normal + motion.line_down
      keymap.normal - motion.line_up
      keymap.normal _ motion.line
      keymap.normal w motion.word_forward
      keymap.normal W motion.big_word_forward
      keymap.normal b motion.word_backward
      keymap.normal B motion.big_word_backward
      keymap.normal e motion.word_end
      keymap.normal E motion.big_word_end
      keymap.normal ge motion.word_end_backward
      keymap.normal gE motion.big_word_end_backward
      keymap.normal ( motion.sentence_backward
      keymap.normal ) motion.sentence_forward
      keymap.normal { motion.paragraph_backward
      keymap.normal } motion.paragraph_forward
      keymap.normal / search.forward
      keymap.normal ? search.backward
      keymap.normal n search.next
      keymap.normal N search.previous
      keymap.normal * search.word_forward
      keymap.normal "#" search.word_backward
      keymap.normal g* search.partial_word_forward
      keymap.normal g# search.partial_word_backward
      keymap.normal H motion.screen_top
      keymap.normal M motion.screen_middle
      keymap.normal L motion.screen_bottom
      keymap.normal % motion.match_pair
      keymap.normal d operator.delete
      keymap.normal c operator.change
      keymap.normal y operator.yank
      keymap.normal > operator.indent
      keymap.normal < operator.dedent
      keymap.normal x operator.delete_char
      keymap.normal s operator.substitute_char
      keymap.normal S operator.substitute_line
      keymap.normal C operator.change_to_end
      keymap.normal D operator.delete_to_end
      keymap.normal Y operator.yank_to_end
      keymap.normal J operator.join
      keymap.normal p operator.put_after
      keymap.normal P operator.put_before
      keymap.normal "\"" register.select
      keymap.normal r operator.replace_char
      keymap.normal ~ operator.toggle_case
      keymap.normal u history.undo
      keymap.normal <C-r> history.redo
      keymap.normal U history.undo_line
      keymap.normal g- history.older
      keymap.normal g+ history.newer
      keymap.normal . history.repeat
      keymap.normal & substitute.repeat
      keymap.normal g& substitute.repeat_all
      keymap.normal i mode.insert
      keymap.normal a mode.insert_after
      keymap.normal I mode.insert_line_start
      keymap.normal A mode.insert_line_end
      keymap.normal o mode.insert_open_below
      keymap.normal O mode.insert_open_above
      keymap.normal v mode.visual
      keymap.normal V mode.visual_line
      keymap.normal <C-v> mode.visual_block
      keymap.normal gv visual.reselect
      keymap.normal : mode.cmdline
      keymap.normal <C-c> message.quit_hint
      keymap.normal <C-w>s window.split
      keymap.normal <C-w>v window.vsplit
      keymap.normal <C-w>h window.left
      keymap.normal <C-w>j window.down
      keymap.normal <C-w>k window.up
      keymap.normal <C-w>l window.right
      keymap.normal <C-w>w window.next
      keymap.normal <C-w>W window.previous
      keymap.normal <C-w>p window.last_accessed
      keymap.normal <C-w>c window.close
      keymap.normal <C-w>o window.only
      keymap.normal <C-w>= window.equalize
      keymap.normal <C-w>q window.quit
      keymap.normal <C-w><C-s> window.split
      keymap.normal <C-w><C-v> window.vsplit
      keymap.normal <C-w><C-h> window.left
      keymap.normal <C-w><C-j> window.down
      keymap.normal <C-w><C-k> window.up
      keymap.normal <C-w><C-l> window.right
      keymap.normal <C-w><C-w> window.next
      keymap.normal <C-w><C-p> window.last_accessed
      keymap.normal <C-w><C-o> window.only
      keymap.normal <C-w><C-q> window.quit
      keymap.normal <C-f> scroll.page_down
      keymap.normal <PageDown> scroll.page_down
      keymap.normal <C-b> scroll.page_up
      keymap.normal <PageUp> scroll.page_up
      keymap.normal <C-d> scroll.half_page_down
      keymap.normal <C-u> scroll.half_page_up
      keymap.normal <C-e> scroll.line_down
      keymap.normal <C-y> scroll.line_up
      keymap.normal zt scroll.cursor_top
      keymap.normal zz scroll.cursor_middle
      keymap.normal zb scroll.cursor_bottom
      keymap.normal gt tab.next
      keymap.normal gT tab.previous
      keymap.normal <Esc> float.close
      keymap.normal K docs.hover
      keymap.normal gd definition.jump
      keymap.normal <C-o> jump.older
      keymap.normal <C-i> jump.newer
      keymap.normal <C-s> file.save
      # The leader groups: w windows, q quit, f files, b buffers, d docs, l
      # layout; e is the explorer plugin's.
      # keymap.group <keys> <name> names a normal-mode prefix in the key hints.
      keymap.group <leader>w windows
      keymap.group <leader>q quit
      keymap.group <leader>f files
      keymap.group <leader>b buffers
      keymap.group <leader>d docs
      keymap.group <leader>l layout
      keymap.group g goto
      keymap.group z view
      keymap.group <C-w> window
      keymap.normal <leader>ws window.split
      keymap.normal <leader>wv window.vsplit
      keymap.normal <leader>wh window.left
      keymap.normal <leader>wj window.down
      keymap.normal <leader>wk window.up
      keymap.normal <leader>wl window.right
      keymap.normal <leader>wc window.close
      keymap.normal <leader>wo window.only
      keymap.normal <leader>qq quit.all
      keymap.normal <leader>qw quit.write_all
      keymap.normal <leader>fs file.save
      keymap.normal <leader>bb buffer.list
      keymap.normal <leader>bn buffer.next
      keymap.normal <leader>bp buffer.previous
      keymap.normal <C-^> buffer.alternate
      keymap.normal <leader>bd buffer.delete
      keymap.normal <leader>dp docs.pin
      keymap.normal <leader>dd definition.peek
      # keymap.pick <keys> <action> binds in normal mode of a pick list's
      # buffer, as the definition pick list's, and in no editor mode.
      keymap.pick <CR> definition.choose
      keymap.normal <leader>ls layout.toggle_sidebar
      keymap.normal <leader>lr layout.toggle_right_sidebar
      keymap.normal <leader>lp layout.toggle_panel
      keymap.normal <leader>p palette.open
      keymap.normal <F1> palette.open

      # Insert mode.
      keymap.insert <Esc> mode.normal
      keymap.insert <CR> insert.newline
      keymap.insert <BS> insert.backspace
      keymap.insert <Del> insert.delete
      keymap.insert <Tab> insert.tab
      keymap.insert <Left> cursor.left
      keymap.insert <Down> cursor.down
      keymap.insert <Up> cursor.up
      keymap.insert <Right> cursor.right
      keymap.insert <PageDown> scroll.page_down
      keymap.insert <PageUp> scroll.page_up
      keymap.insert <C-s> file.save
      keymap.insert <C-n> completion.keyword_next
      keymap.insert <C-p> completion.keyword_previous

      # While the completion popup shows in insert mode, these keys are looked
      # up first; any other key goes on to the insert bindings. Single keys only.
      keymap.completion <CR> completion.insert
      keymap.completion <Tab> completion.replace
      keymap.completion <C-n> completion.next
      keymap.completion <Down> completion.next
      keymap.completion <C-p> completion.previous
      keymap.completion <Up> completion.previous
      keymap.completion <Esc> completion.close

      # Visual mode.
      keymap.visual <Esc> mode.normal
      keymap.visual <C-c> mode.normal
      keymap.visual v mode.visual
      keymap.visual V mode.visual_line
      keymap.visual <C-v> mode.visual_block
      keymap.visual h cursor.left
      keymap.visual j cursor.down
      keymap.visual k cursor.up
      keymap.visual l cursor.right
      keymap.visual <Left> cursor.left
      keymap.visual <Down> cursor.down
      keymap.visual <Up> cursor.up
      keymap.visual <Right> cursor.right
      keymap.visual 0 cursor.line_start
      keymap.visual ^ cursor.first_nonblank
      keymap.visual $ cursor.line_end
      keymap.visual gg cursor.buffer_start
      keymap.visual G cursor.buffer_end
      keymap.visual f motion.find_forward
      keymap.visual F motion.find_backward
      keymap.visual t motion.till_forward
      keymap.visual T motion.till_backward
      keymap.visual ; motion.repeat_find
      keymap.visual , motion.repeat_find_reverse
      keymap.visual + motion.line_down
      keymap.visual - motion.line_up
      keymap.visual _ motion.line
      keymap.visual w motion.word_forward
      keymap.visual W motion.big_word_forward
      keymap.visual b motion.word_backward
      keymap.visual B motion.big_word_backward
      keymap.visual e motion.word_end
      keymap.visual E motion.big_word_end
      keymap.visual ge motion.word_end_backward
      keymap.visual gE motion.big_word_end_backward
      keymap.visual ( motion.sentence_backward
      keymap.visual ) motion.sentence_forward
      keymap.visual { motion.paragraph_backward
      keymap.visual } motion.paragraph_forward
      keymap.visual / search.forward
      keymap.visual ? search.backward
      keymap.visual n search.next
      keymap.visual N search.previous
      keymap.visual * search.word_forward
      keymap.visual "#" search.word_backward
      keymap.visual g* search.partial_word_forward
      keymap.visual g# search.partial_word_backward
      keymap.visual H motion.screen_top
      keymap.visual M motion.screen_middle
      keymap.visual L motion.screen_bottom
      keymap.visual % motion.match_pair
      keymap.visual "\"" register.select
      keymap.visual o visual.swap_ends
      keymap.visual O visual.swap_corner
      keymap.visual gv visual.reselect
      keymap.visual : mode.cmdline
      keymap.visual d operator.delete
      keymap.visual x operator.delete
      keymap.visual <Del> operator.delete
      keymap.visual y operator.yank
      keymap.visual c operator.change
      keymap.visual s operator.change
      keymap.visual > operator.indent
      keymap.visual < operator.dedent
      keymap.visual J visual.join
      keymap.visual gJ visual.join_raw
      keymap.visual p visual.put
      keymap.visual P visual.put_keep
      keymap.visual r visual.replace
      keymap.visual ~ visual.toggle_case
      keymap.visual u visual.lowercase
      keymap.visual U visual.uppercase
      keymap.visual X visual.delete_lines
      keymap.visual D visual.delete_to_end
      keymap.visual C visual.change_to_end
      keymap.visual S visual.change_lines
      keymap.visual R visual.change_lines
      keymap.visual Y visual.yank_lines
      keymap.visual I visual.insert
      keymap.visual A visual.append
      keymap.visual iw textobject.inner_word
      keymap.visual aw textobject.a_word
      keymap.visual iW textobject.inner_big_word
      keymap.visual aW textobject.a_big_word
      keymap.visual is textobject.inner_sentence
      keymap.visual as textobject.a_sentence
      keymap.visual ip textobject.inner_paragraph
      keymap.visual ap textobject.a_paragraph
      keymap.visual i( textobject.inner_paren
      keymap.visual a( textobject.a_paren
      keymap.visual i) textobject.inner_paren
      keymap.visual a) textobject.a_paren
      keymap.visual ib textobject.inner_paren
      keymap.visual ab textobject.a_paren
      keymap.visual i[ textobject.inner_bracket
      keymap.visual a[ textobject.a_bracket
      keymap.visual i] textobject.inner_bracket
      keymap.visual a] textobject.a_bracket
      keymap.visual i{ textobject.inner_brace
      keymap.visual a{ textobject.a_brace
      keymap.visual i} textobject.inner_brace
      keymap.visual a} textobject.a_brace
      keymap.visual iB textobject.inner_brace
      keymap.visual aB textobject.a_brace
      keymap.visual i< textobject.inner_angle
      keymap.visual a< textobject.a_angle
      keymap.visual i> textobject.inner_angle
      keymap.visual a> textobject.a_angle
      keymap.visual i" textobject.inner_double_quote
      keymap.visual a" textobject.a_double_quote
      keymap.visual i' textobject.inner_single_quote
      keymap.visual a' textobject.a_single_quote
      keymap.visual i` textobject.inner_backtick
      keymap.visual a` textobject.a_backtick
      keymap.visual <C-f> scroll.page_down
      keymap.visual <PageDown> scroll.page_down
      keymap.visual <C-b> scroll.page_up
      keymap.visual <PageUp> scroll.page_up
      keymap.visual <C-d> scroll.half_page_down
      keymap.visual <C-u> scroll.half_page_up
      keymap.visual <C-e> scroll.line_down
      keymap.visual <C-y> scroll.line_up
      keymap.visual zt scroll.cursor_top
      keymap.visual zz scroll.cursor_middle
      keymap.visual zb scroll.cursor_bottom

      # Linewise visual mode.
      keymap.visual_line <Esc> mode.normal
      keymap.visual_line <C-c> mode.normal
      keymap.visual_line v mode.visual
      keymap.visual_line V mode.visual_line
      keymap.visual_line <C-v> mode.visual_block
      keymap.visual_line h cursor.left
      keymap.visual_line j cursor.down
      keymap.visual_line k cursor.up
      keymap.visual_line l cursor.right
      keymap.visual_line <Left> cursor.left
      keymap.visual_line <Down> cursor.down
      keymap.visual_line <Up> cursor.up
      keymap.visual_line <Right> cursor.right
      keymap.visual_line 0 cursor.line_start
      keymap.visual_line ^ cursor.first_nonblank
      keymap.visual_line $ cursor.line_end
      keymap.visual_line gg cursor.buffer_start
      keymap.visual_line G cursor.buffer_end
      keymap.visual_line f motion.find_forward
      keymap.visual_line F motion.find_backward
      keymap.visual_line t motion.till_forward
      keymap.visual_line T motion.till_backward
      keymap.visual_line ; motion.repeat_find
      keymap.visual_line , motion.repeat_find_reverse
      keymap.visual_line + motion.line_down
      keymap.visual_line - motion.line_up
      keymap.visual_line _ motion.line
      keymap.visual_line w motion.word_forward
      keymap.visual_line W motion.big_word_forward
      keymap.visual_line b motion.word_backward
      keymap.visual_line B motion.big_word_backward
      keymap.visual_line e motion.word_end
      keymap.visual_line E motion.big_word_end
      keymap.visual_line ge motion.word_end_backward
      keymap.visual_line gE motion.big_word_end_backward
      keymap.visual_line ( motion.sentence_backward
      keymap.visual_line ) motion.sentence_forward
      keymap.visual_line { motion.paragraph_backward
      keymap.visual_line } motion.paragraph_forward
      keymap.visual_line / search.forward
      keymap.visual_line ? search.backward
      keymap.visual_line n search.next
      keymap.visual_line N search.previous
      keymap.visual_line * search.word_forward
      keymap.visual_line "#" search.word_backward
      keymap.visual_line g* search.partial_word_forward
      keymap.visual_line g# search.partial_word_backward
      keymap.visual_line H motion.screen_top
      keymap.visual_line M motion.screen_middle
      keymap.visual_line L motion.screen_bottom
      keymap.visual_line % motion.match_pair
      keymap.visual_line "\"" register.select
      keymap.visual_line o visual.swap_ends
      keymap.visual_line O visual.swap_corner
      keymap.visual_line gv visual.reselect
      keymap.visual_line : mode.cmdline
      keymap.visual_line d operator.delete
      keymap.visual_line x operator.delete
      keymap.visual_line <Del> operator.delete
      keymap.visual_line y operator.yank
      keymap.visual_line c operator.change
      keymap.visual_line s operator.change
      keymap.visual_line > operator.indent
      keymap.visual_line < operator.dedent
      keymap.visual_line J visual.join
      keymap.visual_line gJ visual.join_raw
      keymap.visual_line p visual.put
      keymap.visual_line P visual.put_keep
      keymap.visual_line r visual.replace
      keymap.visual_line ~ visual.toggle_case
      keymap.visual_line u visual.lowercase
      keymap.visual_line U visual.uppercase
      keymap.visual_line X visual.delete_lines
      keymap.visual_line D visual.delete_to_end
      keymap.visual_line C visual.change_to_end
      keymap.visual_line S visual.change_lines
      keymap.visual_line R visual.change_lines
      keymap.visual_line Y visual.yank_lines
      keymap.visual_line I visual.insert
      keymap.visual_line A visual.append
      keymap.visual_line iw textobject.inner_word
      keymap.visual_line aw textobject.a_word
      keymap.visual_line iW textobject.inner_big_word
      keymap.visual_line aW textobject.a_big_word
      keymap.visual_line is textobject.inner_sentence
      keymap.visual_line as textobject.a_sentence
      keymap.visual_line ip textobject.inner_paragraph
      keymap.visual_line ap textobject.a_paragraph
      keymap.visual_line i( textobject.inner_paren
      keymap.visual_line a( textobject.a_paren
      keymap.visual_line i) textobject.inner_paren
      keymap.visual_line a) textobject.a_paren
      keymap.visual_line ib textobject.inner_paren
      keymap.visual_line ab textobject.a_paren
      keymap.visual_line i[ textobject.inner_bracket
      keymap.visual_line a[ textobject.a_bracket
      keymap.visual_line i] textobject.inner_bracket
      keymap.visual_line a] textobject.a_bracket
      keymap.visual_line i{ textobject.inner_brace
      keymap.visual_line a{ textobject.a_brace
      keymap.visual_line i} textobject.inner_brace
      keymap.visual_line a} textobject.a_brace
      keymap.visual_line iB textobject.inner_brace
      keymap.visual_line aB textobject.a_brace
      keymap.visual_line i< textobject.inner_angle
      keymap.visual_line a< textobject.a_angle
      keymap.visual_line i> textobject.inner_angle
      keymap.visual_line a> textobject.a_angle
      keymap.visual_line i" textobject.inner_double_quote
      keymap.visual_line a" textobject.a_double_quote
      keymap.visual_line i' textobject.inner_single_quote
      keymap.visual_line a' textobject.a_single_quote
      keymap.visual_line i` textobject.inner_backtick
      keymap.visual_line a` textobject.a_backtick
      keymap.visual_line <C-f> scroll.page_down
      keymap.visual_line <PageDown> scroll.page_down
      keymap.visual_line <C-b> scroll.page_up
      keymap.visual_line <PageUp> scroll.page_up
      keymap.visual_line <C-d> scroll.half_page_down
      keymap.visual_line <C-u> scroll.half_page_up
      keymap.visual_line <C-e> scroll.line_down
      keymap.visual_line <C-y> scroll.line_up
      keymap.visual_line zt scroll.cursor_top
      keymap.visual_line zz scroll.cursor_middle
      keymap.visual_line zb scroll.cursor_bottom

      # Blockwise visual mode.
      keymap.visual_block <Esc> mode.normal
      keymap.visual_block <C-c> mode.normal
      keymap.visual_block v mode.visual
      keymap.visual_block V mode.visual_line
      keymap.visual_block <C-v> mode.visual_block
      keymap.visual_block h cursor.left
      keymap.visual_block j cursor.down
      keymap.visual_block k cursor.up
      keymap.visual_block l cursor.right
      keymap.visual_block <Left> cursor.left
      keymap.visual_block <Down> cursor.down
      keymap.visual_block <Up> cursor.up
      keymap.visual_block <Right> cursor.right
      keymap.visual_block 0 cursor.line_start
      keymap.visual_block ^ cursor.first_nonblank
      keymap.visual_block $ cursor.line_end
      keymap.visual_block gg cursor.buffer_start
      keymap.visual_block G cursor.buffer_end
      keymap.visual_block f motion.find_forward
      keymap.visual_block F motion.find_backward
      keymap.visual_block t motion.till_forward
      keymap.visual_block T motion.till_backward
      keymap.visual_block ; motion.repeat_find
      keymap.visual_block , motion.repeat_find_reverse
      keymap.visual_block + motion.line_down
      keymap.visual_block - motion.line_up
      keymap.visual_block _ motion.line
      keymap.visual_block w motion.word_forward
      keymap.visual_block W motion.big_word_forward
      keymap.visual_block b motion.word_backward
      keymap.visual_block B motion.big_word_backward
      keymap.visual_block e motion.word_end
      keymap.visual_block E motion.big_word_end
      keymap.visual_block ge motion.word_end_backward
      keymap.visual_block gE motion.big_word_end_backward
      keymap.visual_block ( motion.sentence_backward
      keymap.visual_block ) motion.sentence_forward
      keymap.visual_block { motion.paragraph_backward
      keymap.visual_block } motion.paragraph_forward
      keymap.visual_block / search.forward
      keymap.visual_block ? search.backward
      keymap.visual_block n search.next
      keymap.visual_block N search.previous
      keymap.visual_block * search.word_forward
      keymap.visual_block "#" search.word_backward
      keymap.visual_block g* search.partial_word_forward
      keymap.visual_block g# search.partial_word_backward
      keymap.visual_block H motion.screen_top
      keymap.visual_block M motion.screen_middle
      keymap.visual_block L motion.screen_bottom
      keymap.visual_block % motion.match_pair
      keymap.visual_block "\"" register.select
      keymap.visual_block o visual.swap_ends
      keymap.visual_block O visual.swap_corner
      keymap.visual_block gv visual.reselect
      keymap.visual_block : mode.cmdline
      keymap.visual_block d operator.delete
      keymap.visual_block x operator.delete
      keymap.visual_block <Del> operator.delete
      keymap.visual_block y operator.yank
      keymap.visual_block c operator.change
      keymap.visual_block s operator.change
      keymap.visual_block > operator.indent
      keymap.visual_block < operator.dedent
      keymap.visual_block J visual.join
      keymap.visual_block gJ visual.join_raw
      keymap.visual_block p visual.put
      keymap.visual_block P visual.put_keep
      keymap.visual_block r visual.replace
      keymap.visual_block ~ visual.toggle_case
      keymap.visual_block u visual.lowercase
      keymap.visual_block U visual.uppercase
      keymap.visual_block X visual.delete_lines
      keymap.visual_block D visual.delete_to_end
      keymap.visual_block C visual.change_to_end
      keymap.visual_block S visual.change_lines
      keymap.visual_block R visual.change_lines
      keymap.visual_block Y visual.yank_lines
      keymap.visual_block I visual.insert
      keymap.visual_block A visual.append
      keymap.visual_block iw textobject.inner_word
      keymap.visual_block aw textobject.a_word
      keymap.visual_block iW textobject.inner_big_word
      keymap.visual_block aW textobject.a_big_word
      keymap.visual_block is textobject.inner_sentence
      keymap.visual_block as textobject.a_sentence
      keymap.visual_block ip textobject.inner_paragraph
      keymap.visual_block ap textobject.a_paragraph
      keymap.visual_block i( textobject.inner_paren
      keymap.visual_block a( textobject.a_paren
      keymap.visual_block i) textobject.inner_paren
      keymap.visual_block a) textobject.a_paren
      keymap.visual_block ib textobject.inner_paren
      keymap.visual_block ab textobject.a_paren
      keymap.visual_block i[ textobject.inner_bracket
      keymap.visual_block a[ textobject.a_bracket
      keymap.visual_block i] textobject.inner_bracket
      keymap.visual_block a] textobject.a_bracket
      keymap.visual_block i{ textobject.inner_brace
      keymap.visual_block a{ textobject.a_brace
      keymap.visual_block i} textobject.inner_brace
      keymap.visual_block a} textobject.a_brace
      keymap.visual_block iB textobject.inner_brace
      keymap.visual_block aB textobject.a_brace
      keymap.visual_block i< textobject.inner_angle
      keymap.visual_block a< textobject.a_angle
      keymap.visual_block i> textobject.inner_angle
      keymap.visual_block a> textobject.a_angle
      keymap.visual_block i" textobject.inner_double_quote
      keymap.visual_block a" textobject.a_double_quote
      keymap.visual_block i' textobject.inner_single_quote
      keymap.visual_block a' textobject.a_single_quote
      keymap.visual_block i` textobject.inner_backtick
      keymap.visual_block a` textobject.a_backtick
      keymap.visual_block <C-f> scroll.page_down
      keymap.visual_block <PageDown> scroll.page_down
      keymap.visual_block <C-b> scroll.page_up
      keymap.visual_block <PageUp> scroll.page_up
      keymap.visual_block <C-d> scroll.half_page_down
      keymap.visual_block <C-u> scroll.half_page_up
      keymap.visual_block <C-e> scroll.line_down
      keymap.visual_block <C-y> scroll.line_up
      keymap.visual_block zt scroll.cursor_top
      keymap.visual_block zz scroll.cursor_middle
      keymap.visual_block zb scroll.cursor_bottom

      # Operator-pending mode.
      keymap.operator_pending <Esc> mode.normal
      keymap.operator_pending h cursor.left
      keymap.operator_pending j cursor.down
      keymap.operator_pending k cursor.up
      keymap.operator_pending l cursor.right
      keymap.operator_pending <Left> cursor.left
      keymap.operator_pending <Down> cursor.down
      keymap.operator_pending <Up> cursor.up
      keymap.operator_pending <Right> cursor.right
      keymap.operator_pending 0 cursor.line_start
      keymap.operator_pending ^ cursor.first_nonblank
      keymap.operator_pending $ cursor.line_end
      keymap.operator_pending gg cursor.buffer_start
      keymap.operator_pending G cursor.buffer_end
      keymap.operator_pending f motion.find_forward
      keymap.operator_pending F motion.find_backward
      keymap.operator_pending t motion.till_forward
      keymap.operator_pending T motion.till_backward
      keymap.operator_pending ; motion.repeat_find
      keymap.operator_pending , motion.repeat_find_reverse
      keymap.operator_pending + motion.line_down
      keymap.operator_pending - motion.line_up
      keymap.operator_pending _ motion.line
      keymap.operator_pending w motion.word_forward
      keymap.operator_pending W motion.big_word_forward
      keymap.operator_pending b motion.word_backward
      keymap.operator_pending B motion.big_word_backward
      keymap.operator_pending e motion.word_end
      keymap.operator_pending E motion.big_word_end
      keymap.operator_pending ge motion.word_end_backward
      keymap.operator_pending gE motion.big_word_end_backward
      keymap.operator_pending ( motion.sentence_backward
      keymap.operator_pending ) motion.sentence_forward
      keymap.operator_pending { motion.paragraph_backward
      keymap.operator_pending } motion.paragraph_forward
      keymap.operator_pending / search.forward
      keymap.operator_pending ? search.backward
      keymap.operator_pending n search.next
      keymap.operator_pending N search.previous
      keymap.operator_pending * search.word_forward
      keymap.operator_pending "#" search.word_backward
      keymap.operator_pending g* search.partial_word_forward
      keymap.operator_pending g# search.partial_word_backward
      keymap.operator_pending H motion.screen_top
      keymap.operator_pending M motion.screen_middle
      keymap.operator_pending L motion.screen_bottom
      keymap.operator_pending % motion.match_pair
      keymap.operator_pending d operator.delete
      keymap.operator_pending c operator.change
      keymap.operator_pending y operator.yank
      keymap.operator_pending > operator.indent
      keymap.operator_pending < operator.dedent
      keymap.operator_pending iw textobject.inner_word
      keymap.operator_pending aw textobject.a_word
      keymap.operator_pending iW textobject.inner_big_word
      keymap.operator_pending aW textobject.a_big_word
      keymap.operator_pending is textobject.inner_sentence
      keymap.operator_pending as textobject.a_sentence
      keymap.operator_pending ip textobject.inner_paragraph
      keymap.operator_pending ap textobject.a_paragraph
      keymap.operator_pending i( textobject.inner_paren
      keymap.operator_pending a( textobject.a_paren
      keymap.operator_pending i) textobject.inner_paren
      keymap.operator_pending a) textobject.a_paren
      keymap.operator_pending ib textobject.inner_paren
      keymap.operator_pending ab textobject.a_paren
      keymap.operator_pending i[ textobject.inner_bracket
      keymap.operator_pending a[ textobject.a_bracket
      keymap.operator_pending i] textobject.inner_bracket
      keymap.operator_pending a] textobject.a_bracket
      keymap.operator_pending i{ textobject.inner_brace
      keymap.operator_pending a{ textobject.a_brace
      keymap.operator_pending i} textobject.inner_brace
      keymap.operator_pending a} textobject.a_brace
      keymap.operator_pending iB textobject.inner_brace
      keymap.operator_pending aB textobject.a_brace
      keymap.operator_pending i< textobject.inner_angle
      keymap.operator_pending a< textobject.a_angle
      keymap.operator_pending i> textobject.inner_angle
      keymap.operator_pending a> textobject.a_angle
      keymap.operator_pending i" textobject.inner_double_quote
      keymap.operator_pending a" textobject.a_double_quote
      keymap.operator_pending i' textobject.inner_single_quote
      keymap.operator_pending a' textobject.a_single_quote
      keymap.operator_pending i` textobject.inner_backtick
      keymap.operator_pending a` textobject.a_backtick

      # Command-line mode.
      keymap.cmdline <Esc> mode.normal
      keymap.cmdline <CR> cmdline.execute
      keymap.cmdline <BS> cmdline.backspace
      keymap.cmdline <Up> cmdline.history_older
      keymap.cmdline <Down> cmdline.history_newer
      keymap.cmdline <C-n> palette.next
      keymap.cmdline <C-p> palette.previous

      # Language commands: language.<name>.lsp and language.<name>.formatter.
      # A server starts on its own only in a directory under a root of
      # language.trusted_roots, set in the user file, as
      # language.trusted_roots ~/src /work; elsewhere :LspStart starts it.
      language.ruby.lsp ruby-lsp
      language.ruby.formatter rubocop -A --stdin {file} --stderr

      # Plugins: plugin.<name>.enabled and plugin.<name>.<option>.
      plugin.explorer.enabled true
      plugin.explorer.width 30
      plugin.explorer.side left
      plugin.explorer.show_hidden false
      plugin.explorer.ignore .git build tmp
      plugin.ruby.enabled true
      plugin.finder.enabled true
      plugin.finder.ignore .git build tmp
    CARATRC
  end
end
