# Neovim compatibility

Every Neovim command Carat implements has a row here and a table-driven test. The test column names the `test/*.rb` program whose table or assertions cover the row. Commands from later roadmap items are not listed until they land; pressing a key bound to one of them shows a "Not implemented" message. The commands plugins add are Carat's own, not Neovim's, and are listed in `docs/actions.md` and `docs/plugins.md`; the file explorer's are in the File explorer section below. A scratch window a plugin opens behaves as a `nofile` buffer in a `winfixwidth` window with `nonumber`: `:w` reports `E382`, `:wa` skips it, and `:q` closes it; `:q` in the last window that shows a file, when the only other windows of its tab page are plugin windows, closes that tab page, or ends the editor on the last one, as Neovim's tree plugins arrange.

## Command grammar

| Keys | Behavior | Test |
| --- | --- | --- |
| `[count]` | `1` to `9` start a count and `0` to `9` extend it; counts before and after an operator multiply | `editor_grammar`, `domain_grammar` |
| `"x` | Select register `"`, `a` to `z`, `A` to `Z`, `0` to `9`, `-`, `_`, `.`, `:`, `%`, or `/` for the command; another name drops the prefix | `editor_grammar`, `editor_registers` |
| operator twice | `dd`, `cc`, `yy`, `>>`, `<<` act linewise over count lines | `editor_grammar`, `editor_operators` |
| `<Esc>` in operator-pending mode | Cancel the pending operator, count, and register | `editor_grammar` |
| unbound key | Drop the pending count and register | `editor_grammar` |
| pending keys | The keys typed so far show at the right of the message row, as `showcmd` | `editor_grammar` |

Differences from Neovim: a different operator after a pending one cancels silently instead of beeping; the `o_v`, `o_V`, and `o_CTRL-V` prefixes are not implemented; counts before `i a I A o O :` are ignored.

## Normal mode

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| `[count]h`, `<Left>` | `cursor.left` | Count columns left, not past column 0 | `editor_normal`, `editor_motions` |
| `[count]l`, `<Right>` | `cursor.right` | Count columns right, not past the last character | `editor_normal`, `editor_motions` |
| `[count]k`, `<Up>` | `cursor.up` | Count rows up, keeping the wanted column | `editor_normal`, `editor_motions` |
| `[count]j`, `<Down>` | `cursor.down` | Count rows down, keeping the wanted column | `editor_normal`, `editor_motions` |
| `0` | `cursor.line_start` | Column 0 | `editor_normal`, `editor_grammar` |
| `^` | `cursor.first_nonblank` | First character that is not a space or a tab | `editor_normal` |
| `[count]$` | `cursor.line_end` | Last character, count minus one lines down; vertical motions then stick to line ends | `editor_normal`, `editor_motions` |
| `[count]gg` | `cursor.buffer_start` | Line count, or the first line, keeping the wanted column | `editor_normal`, `editor_motions` |
| `[count]G` | `cursor.buffer_end` | Line count, or the last line, keeping the wanted column | `editor_normal`, `editor_motions` |
| `[count]f{char}` | `motion.find_forward` | To the count-th occurrence of char to the right | `editor_motions` |
| `[count]F{char}` | `motion.find_backward` | To the count-th occurrence of char to the left | `editor_motions` |
| `[count]t{char}` | `motion.till_forward` | Before the count-th occurrence of char to the right | `editor_motions` |
| `[count]T{char}` | `motion.till_backward` | After the count-th occurrence of char to the left | `editor_motions` |
| `[count];` | `motion.repeat_find` | Repeat the last `f F t T`; after `t T` skip an adjacent match | `editor_motions` |
| `[count],` | `motion.repeat_find_reverse` | Repeat it in the opposite direction | `editor_motions` |
| `[count]+` | `motion.line_down` | Count lines down, on the first non-blank | `editor_motions` |
| `[count]-` | `motion.line_up` | Count lines up, on the first non-blank | `editor_motions` |
| `[count]_` | `motion.line` | Count minus one lines down, on the first non-blank | `editor_motions` |
| `[count]w` | `motion.word_forward` | Count words forward | `editor_motions` |
| `[count]W` | `motion.big_word_forward` | Count WORDs forward | `editor_motions` |
| `[count]b` | `motion.word_backward` | Count words backward | `editor_motions` |
| `[count]B` | `motion.big_word_backward` | Count WORDs backward | `editor_motions` |
| `[count]e` | `motion.word_end` | Forward to the end of word count | `editor_motions` |
| `[count]E` | `motion.big_word_end` | Forward to the end of WORD count | `editor_motions` |
| `[count]ge` | `motion.word_end_backward` | Backward to the end of word count | `editor_motions` |
| `[count]gE` | `motion.big_word_end_backward` | Backward to the end of WORD count | `editor_motions` |
| `[count])` | `motion.sentence_forward` | Count sentences forward | `editor_motions` |
| `[count](` | `motion.sentence_backward` | Count sentences backward | `editor_motions` |
| `[count]}` | `motion.paragraph_forward` | Count paragraphs forward | `editor_motions` |
| `[count]{` | `motion.paragraph_backward` | Count paragraphs backward | `editor_motions` |
| `[count]H` | `motion.screen_top` | Line count from the top of the window, honoring scrolloff | `editor_motions` |
| `M` | `motion.screen_middle` | Middle line of the window | `editor_motions` |
| `[count]L` | `motion.screen_bottom` | Line count from the bottom of the window, honoring scrolloff | `editor_motions` |
| `i` | `mode.insert` | Insert before the cursor | `editor_normal` |
| `a` | `mode.insert_after` | Insert after the cursor | `editor_normal` |
| `I` | `mode.insert_line_start` | Insert at the first non-blank character | `editor_normal` |
| `A` | `mode.insert_line_end` | Insert after the last character | `editor_normal` |
| `o` | `mode.insert_open_below` | Open a line below, with autoindent | `editor_normal`, `editor_insert` |
| `O` | `mode.insert_open_above` | Open a line above, with autoindent | `editor_normal` |
| `:` | `mode.cmdline` | Enter command-line mode | `editor_cmdline` |
| `<C-c>` | `message.quit_hint` | Show how to quit with unsaved changes | `editor_normal` |
| `<leader>w` | `:w<CR>` | Write the file | `editor_normal` |
| `<leader>q` | `:q<CR>` | Quit | `editor_cmdline` |

Differences from Neovim: `startofline` is off, so `gg G H M L` keep the wanted column; keyword characters are ASCII letters, digits, underscore, and every code point from U+00C0 upward until `iskeyword` exists; sentence ends are `. ! ?` with optional `) ] " '` before a blank or the line end, and paragraph boundaries are empty lines only (no nroff macros, no form feeds); `H` and `L` take `scrolloff` into account when moving the cursor and ignore it under an operator, as Neovim does; the quit hint names `:q!` as Neovim does for the last window.

## Operators

The operand is a motion from the table above, a text object from the table below, or the operator key again for count lines.

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| `d{motion}`, `[count]dd` | `operator.delete` | Delete into the register; charwise leaves the cursor at the start, linewise on the first non-blank | `editor_operators` |
| `c{motion}`, `[count]cc` | `operator.change` | Delete into the register and enter insert mode; `cw` on a non-blank acts as `ce`; `cc` keeps the indent with autoindent | `editor_operators` |
| `y{motion}`, `[count]yy` | `operator.yank` | Copy into the register; the cursor goes to the start of the range | `editor_operators` |
| `>{motion}`, `[count]>>` | `operator.indent` | Indent the lines by shiftwidth, leaving empty lines empty | `editor_operators` |
| `<{motion}`, `[count]<<` | `operator.dedent` | Dedent the lines by shiftwidth, never below column 0 | `editor_operators` |
| `[count]x` | `operator.delete_char` | Delete count characters under and after the cursor, within the line | `editor_operators` |
| `[count]s` | `operator.substitute_char` | Delete count characters and enter insert mode | `editor_operators` |
| `[count]S` | `operator.substitute_line` | As `cc` | `editor_operators` |
| `[count]C` | `operator.change_to_end` | As `c$` | `editor_operators` |
| `[count]D` | `operator.delete_to_end` | As `d$` | `editor_operators` |
| `[count]Y` | `operator.yank_to_end` | As `y$`, Neovim's default mapping | `editor_operators` |
| `[count]J` | `operator.join` | Join count lines, at least two, with one space unless the line ends in a blank or the next starts with `)` or is empty | `editor_operators` |
| `[count]p` | `operator.put_after` | Put the register after the cursor count times | `editor_operators`, `editor_registers` |
| `[count]P` | `operator.put_before` | Put the register before the cursor count times | `editor_operators`, `editor_registers` |
| `[count]r{char}` | `operator.replace_char` | Replace count characters with char, the cursor on the last; nothing when fewer remain | `editor_operators`, `editor_repeat` |
| `[count]~` | `operator.toggle_case` | Switch the case of count characters, as many as remain, and move past them | `editor_operators`, `editor_repeat` |

Exclusive motions follow Vim's two adjustments: an operator range ending in column 0 of a later line ends at the end of the previous line inclusively, and becomes linewise when it started at or before the first non-blank; `w` under an operator stops at the end of the line when the last word moved over ends there (`editor_operators`).

Differences from Neovim: the `=`, `g~`, `gu`, `gU`, and `gq` operators and `X` are not implemented in normal mode (visual mode has `u U X`); `r<CR>` does not split the line and `r` with fewer characters left than its count does nothing silently where Neovim beeps; `tildeop` does not exist; `joinspaces` is off; `p` of an empty register shows `E353` as Vim does.

## Text objects

Usable after an operator, in operator-pending mode, and in the visual modes (see Visual mode).

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| `[count]iw`, `[count]aw` | `textobject.inner_word`, `textobject.a_word` | The word, or the word with the blanks after it (before it at the line end); the count takes more runs or words | `editor_text_objects` |
| `[count]iW`, `[count]aW` | `textobject.inner_big_word`, `textobject.a_big_word` | The same over WORDs | `editor_text_objects` |
| `is`, `as` | `textobject.inner_sentence`, `textobject.a_sentence` | The sentence, without or with the blanks after it | `editor_text_objects` |
| `[count]ip`, `[count]ap` | `textobject.inner_paragraph`, `textobject.a_paragraph` | The paragraph's lines, without or with the empty lines after it | `editor_text_objects` |
| `[count]i( a( i) a) ib ab` | `textobject.inner_paren`, `textobject.a_paren` | Inside or including the count-th enclosing `()` | `editor_text_objects` |
| `[count]i[ a[ i] a]` | `textobject.inner_bracket`, `textobject.a_bracket` | Inside or including the count-th enclosing `[]` | `editor_text_objects` |
| `[count]i{ a{ i} a} iB aB` | `textobject.inner_brace`, `textobject.a_brace` | Inside or including the count-th enclosing `{}`; the inner form is linewise when the braces end their lines | `editor_text_objects` |
| `[count]i< a< i> a>` | `textobject.inner_angle`, `textobject.a_angle` | Inside or including the count-th enclosing `<>` | `editor_text_objects` |
| `i" a"`, `i' a'`, `` i` a` `` | `textobject.inner_double_quote`, `textobject.a_double_quote`, `textobject.inner_single_quote`, `textobject.a_single_quote`, `textobject.inner_backtick`, `textobject.a_backtick` | Inside or including the quoted string on the line, skipping backslash-escaped quotes | `editor_text_objects` |

Differences from Neovim: `is` and `as` take no count; quote objects pair quotes from the start of the line and `2i"` has no special meaning; tag objects `it at` wait for a tokenizer.

## Registers

| Keys | Behavior | Test |
| --- | --- | --- |
| `""` and no prefix | The unnamed register, written by every delete, change, and yank, read by `p` and `P` | `editor_registers`, `domain_registers` |
| `"a` to `"z` | A named register, written together with the unnamed one and read by `p` and `P` | `editor_registers`, `domain_registers` |
| `"A` to `"Z` | Append to the lowercase register: charwise text joins, a linewise part makes the result linewise | `editor_registers`, `domain_registers` |
| empty register | `E353: Nothing in register x` | `editor_operators`, `editor_registers` |
| `"0` | The last yank that named no register | `editor_registers`, `domain_registers` |
| `"1` to `"9` | Deletes and changes of whole lines, of more than one line, or with `( ) { }`, also when a register is named; each shifts `"1` to `"8` down and drops `"9` | `editor_registers`, `domain_registers` |
| `"-` | Deletes and changes within one line that named no register | `editor_registers`, `domain_registers` |
| `"_` | The black hole: a delete, change, or yank into it stores nothing, the unnamed register included; a put reports `E353` | `editor_registers`, `domain_registers` |
| `".` | The text typed in the last insert session; read-only | `editor_registers`, `domain_registers` |
| `":` | The last command line run; read-only | `editor_registers`, `domain_registers` |
| `"%` | The current file's name; read-only | `editor_registers`, `domain_registers` |
| `"/` | Accepted and empty until search exists; read-only | `editor_registers` |
| write to `. : % /` | Refused with `E354: Invalid register name: '.'`; the text is left alone | `editor_registers` |

Differences from Neovim: the registers are written as Neovim's `op_yank` and `op_delete` code does, which differs from its help text in that a big delete naming a register also writes `"1`; after an uppercase append the unnamed register holds only the new text, where Neovim's points to the whole register; a delete, change, or yank into a read-only register shows `E354`, which Neovim shows only for `:let @.`, where it beeps; a visual `p` stores the replaced text by the delete rules, as Neovim's `v_p` does; the `"#`, `"=`, `"*`, and `"+` registers and `:let @x` are not implemented, and `"/` holds nothing until search exists; any other register name drops the prefix instead of beeping.

## Undo and repeat

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| `[count]u` | `history.undo` | Undo count states along the current branch; the cursor goes to the first changed line, at its place before the change when the change started there | `editor_undo`, `domain_undo_tree` |
| `[count]<C-r>` | `history.redo` | Redo count states along the current branch | `editor_undo`, `domain_undo_tree` |
| `U` | `history.undo_line` | Put back the last changed line as it was before the latest run of changes on it, as a change `u` undoes and `U` reverses | `editor_undo`, `domain_undo_tree` |
| `[count]g-` | `history.older` | Go count states back in the order they were made, across branches | `editor_undo`, `domain_undo_tree` |
| `[count]g+` | `history.newer` | Go count states forward in the order they were made, across branches | `editor_undo`, `domain_undo_tree` |
| `[count].` | `history.repeat` | Repeat the last change: an operator with its motion or text object, `x s S C D J p P r ~`, an insert command with its text, or a visual operator over a region of the same size; a count replaces the change's count, and `"1` to `"8` step to the next register | `editor_repeat` |

Every change to a file buffer is one undo state: a normal-mode, visual-mode, or command-line command, an insert session from the command that entered insert mode to leaving it (a visual block insert included), and a plugin's edit request. The messages are Neovim's: `1 line less; before #3  0 seconds ago`, `1 more line`, `N fewer lines`, `N more lines`, `1 change`, `N changes`, `after #N`, `Already at oldest change`, and `Already at newest change`; undo and redo back to the state of the last write leave the buffer unmodified. `undolevels` (default 1000) limits the states a buffer keeps.

Differences from Neovim: times are always shown as seconds ago, also after 100 seconds, where Neovim shows the time of day, because the editor's clock is monotonic; `g-` at the oldest state and `g+` at the newest say `Already at oldest change` and `Already at newest change`; an `undolevels` of 0 keeps no state, where Neovim's Vi-compatible mode lets `u` undo itself, and a negative value is not accepted; buffers a plugin owns keep no undo history; `U` forgets its line when a change inserts or removes lines, and does nothing silently where Neovim beeps; a count before `i a I A o O` is ignored, so `.` after an insert puts its text in once; `.` repeats a plugin's action only when that action is a change the editor knows, which none is; persistent undo, `:undojoin`, `<C-g>u`, and `undoreload` are not implemented (`:e!` is always undoable).

## Visual mode

The selection runs from the anchor, where visual mode started, to the cursor, both included; it belongs to the window, and only the current window draws it, with the `Visual` highlight in reverse video and the cell under the cursor left plain. In visual mode the cursor may rest on the end of a line, where `l`, `$`, and a vertical motion to a shorter line put it, and a charwise selection ending there or on an empty line includes the line break. Counts and the `"x` register prefix work as in normal mode, every motion of the normal-mode table moves the cursor end in all three kinds, and the mode line shows `-- VISUAL --`, `-- VISUAL LINE --`, or `-- VISUAL BLOCK --` with the pending keys at the right. Every row of the two tables below is covered by `editor_visual`, the selection ranges and the block's display columns by `domain_selection`, and the drawing by `adapters_frame_presenter`.

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| `v`, `V`, `<C-v>` | `mode.visual`, `mode.visual_line`, `mode.visual_block` | Start charwise, linewise, or blockwise visual mode at the cursor; the same key again leaves, another switches the kind keeping the selection | `editor_visual` |
| `<Esc>`, `<C-c>` | `mode.normal` | Leave visual mode, moving the cursor off the end of the line | `editor_visual` |
| `o` | `visual.swap_ends` | Exchange the anchor and the cursor | `editor_visual` |
| `O` | `visual.swap_corner` | In a block, go to the other corner on the same row; otherwise as `o` | `editor_visual` |
| `gv` | `visual.reselect` | Select the window's last selection again, clamped to the buffer; in visual mode exchange it with the current one | `editor_visual` |
| `[count]iw aw iW aW is as ip ap` and the bracket and quote objects | `textobject.*` | On one character (one row for `ip ap`) select the object; on more, words, sentences, and paragraphs extend the cursor end and brackets and quotes select the smallest larger object | `editor_visual` |
| `["x]d`, `x`, `<Del>` | `operator.delete` | Delete the selection; the cursor goes to its start, the first non-blank for lines, the top-left for a block | `editor_visual` |
| `["x]y` | `operator.yank` | Yank the selection; the cursor goes to its start | `editor_visual` |
| `["x]c`, `s` | `operator.change` | Change the selection; lines keep the indent with autoindent; a block's text is repeated on every row that reaches it when insert mode is left | `editor_visual` |
| `[count]>`, `[count]<` | `operator.indent`, `operator.dedent` | Shift the lines count times by shiftwidth; in a block, insert or remove spaces at its left edge | `editor_visual` |
| `J`, `gJ` | `visual.join`, `visual.join_raw` | Join the selected lines, at least two, with or without the blank handling of `J` | `editor_visual` |
| `["x][count]p` | `visual.put` | Replace the selection with the register; the removed text goes to the unnamed register and to `"1` or `"-` as a delete | `editor_visual` |
| `["x][count]P` | `visual.put_keep` | Replace the selection with the register, leaving every register unchanged | `editor_visual` |
| `r{char}` | `visual.replace` | Replace every selected character, not the line breaks | `editor_visual` |
| `~`, `u`, `U` | `visual.toggle_case`, `visual.lowercase`, `visual.uppercase` | Toggle, lower, or upper the case of the selection | `editor_visual` |
| `["x]X`, `["x]D` | `visual.delete_lines`, `visual.delete_to_end` | Delete the selected lines; in a block `X` deletes the block and `D` to the end of every row | `editor_visual` |
| `["x]Y` | `visual.yank_lines` | Yank the selected lines; in a block, the block | `editor_visual` |
| `["x]C`, `["x]S`, `["x]R` | `visual.change_to_end`, `visual.change_lines` | Change the selected lines; in a block `C` changes to the end of every row | `editor_visual` |
| `I`, `A` | `visual.insert`, `visual.append` | Insert before or append after the selection; in a block, on every row when insert mode is left, `I` skipping short rows and `A` padding them, after `$` at every row's end | `editor_visual` |
| `$` in a block | `cursor.line_end` | The block reaches the end of every row | `editor_visual`, `domain_selection` |

Blockwise registers: a block yank or delete stores a blockwise entry, and `p` and `P` in normal mode put it as a block from the display column after or at the cursor, padding short rows with spaces and adding rows past the end of the buffer (`editor_visual`, `editor_registers`, `domain_registers`).

Differences from Neovim: there are no `'<` and `'>` marks yet and no `:'<,'>` ranges, so `:` does nothing in visual mode; a count before `v V <C-v>` and on `J gJ r ~ u U I A` is ignored; `selection` is always `inclusive` and `virtualedit` does not exist; in a block a tab or a wide character the block's columns only partly cover is taken whole by the operators instead of being split into spaces, and `>` and `<` on a block insert and remove spaces, never tabs; the showcmd area shows the pending keys, not the size of the selection; a register prefix typed before `v` is not kept for the operator; on a larger selection a quote object selects the string around the selection's start when that is larger and otherwise leaves the selection alone; `p` with an empty register leaves visual mode with `E353`; `.` after a visual operator uses its count for the operator over a region of the original size; `gq`, `g?`, `=`, `!`, `<C-a>`, `<C-x>`, `zf`, select mode, and the mouse are not implemented.

## Insert mode

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| printable | none | Insert the character at the cursor | `editor_insert` |
| `<Esc>` | `mode.normal` | Back to normal mode, one column left | `editor_insert` |
| `<CR>` | `insert.newline` | Split the line, copying the indent with autoindent | `editor_insert` |
| `<BS>` | `insert.backspace` | Delete before the cursor, joining lines at column 0 | `editor_insert` |
| `<Del>` | `insert.delete` | Delete under the cursor, joining lines at the end | `editor_insert` |
| `<Tab>` | `insert.tab` | Spaces to the next tabstop with expandtab, else a tab | `editor_insert` |
| `<Left>`, `<Right>`, `<Up>`, `<Down>` | `cursor.*` | Move, allowing the column after the last character | `editor_insert` |

## Command-line mode

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| printable | none | Append to the command line | `editor_cmdline` |
| `<BS>` | `cmdline.backspace` | Remove the last character; leave when empty | `editor_cmdline` |
| `<Esc>` | `mode.normal` | Discard the command line | `editor_cmdline` |
| `<CR>` | `cmdline.execute` | Run the command | `editor_cmdline` |

## Ex commands

| Command | Behavior | Messages | Test |
| --- | --- | --- | --- |
| `:w[rite] [file]` | Write the buffer to its path or to file | `"name" 2L, 8B written`, `E32`, `E212` | `use_cases_ex`, `editor_cmdline` |
| `:q[uit]` | Close the window when another exists anywhere, else quit unless a buffer is modified | `E37` | `use_cases_ex`, `editor_cmdline`, `editor_windows` |
| `:q[uit]!` | Close the window, or quit discarding changes; on the last window a modified hidden buffer is shown instead | | `use_cases_ex`, `editor_cmdline`, `editor_windows` |
| `:wq [file]`, `:wq!` | Write, then close the window or quit | as `:w`, `E37` | `use_cases_ex`, `editor_cmdline` |
| `:x[it] [file]`, `:exi[t] [file]`, `:x!` | Write when modified or given a file, then close the window or quit | as `:w`, `E37` | `use_cases_ex`, `editor_cmdline` |
| `:wa[ll]`, `:wa!` | Write every modified buffer in every tab page, in list order | as `:w`, `E141` | `use_cases_ex`, `editor_cmdline`, `editor_windows` |
| `:qa[ll]`, `:quita[ll]` | Quit unless a buffer in the list is modified, hidden ones included | `E37` | `use_cases_ex`, `editor_cmdline`, `editor_tabs` |
| `:qa[ll]!`, `:quita[ll]!` | Quit all, discarding changes | | `use_cases_ex`, `editor_cmdline` |
| `:wqa[ll]`, `:xa[ll]`, `:wqa!`, `:xa!` | Write every modified buffer, then quit all | as `:w`, `E141` | `use_cases_ex`, `editor_cmdline`, `editor_tabs` |
| `:e[dit] [file]` | Show the file in the window: the listed buffer for it, or the file read from disk; reload the current one in place | `"name" 1L, 3B`, `"name" [New]`, `E37` | `use_cases_ex`, `editor_cmdline`, `editor_windows` |
| `:e[dit]! [file]` | Open or reload, discarding changes | | `use_cases_ex`, `editor_cmdline` |
| `:sp[lit] [file]` | Split the window horizontally, the new window above showing the same buffer or file | `E36`, as `:e` | `use_cases_ex`, `editor_windows` |
| `:vs[plit] [file]` | Split the window vertically, the new window to the left | `E36`, as `:e` | `use_cases_ex`, `editor_windows` |
| `:new` | Split horizontally with a new unnamed buffer | `E36` | `use_cases_ex`, `editor_windows` |
| `:vne[w]` | Split vertically with a new unnamed buffer | `E36` | `use_cases_ex`, `editor_windows` |
| `:clo[se]` | Close the window, or its tab page when it was the last one there | `E444` | `use_cases_ex`, `editor_windows` |
| `:on[ly]` | Close every other window of the tab page | `Already only one window` | `use_cases_ex`, `editor_windows` |
| `:tabnew`, `:tabe[dit] [file]` | Open a tab page after the current one on a new buffer or the file | as `:e` | `use_cases_ex`, `editor_tabs` |
| `:tabc[lose]` | Close the tab page; the next one, or the previous when it was last, becomes current | `E784` | `use_cases_ex`, `editor_tabs` |
| `:tabo[nly]` | Close every other tab page | `Already only one tab page` | `use_cases_ex`, `editor_tabs` |
| `:tabn[ext]` | Next tab page, wrapping | | `use_cases_ex`, `editor_tabs` |
| `:tabp[revious]`, `:tabN[ext]` | Previous tab page, wrapping | | `use_cases_ex`, `editor_tabs` |
| `:tabfir[st]`, `:tabl[ast]` | First and last tab page | | `use_cases_ex`, `editor_tabs` |
| `:u[ndo]` | Undo one state | as `u`, `Already at oldest change` | `editor_undo` |
| `:u[ndo] N` | Go to the text after state N, 0 for the original | `2 changes; after #1  0 seconds ago`, `E830: Undo number N not found`, `E474: Invalid argument` | `editor_undo` |
| `:red[o]` | Redo one state | as `<C-r>`, `Already at newest change` | `editor_undo` |
| `:undol[ist]` | List the states without later states on their branch: number, changes from the original, seconds ago, and the write number | `Nothing to undo` | `editor_undo` |
| `:ea[rlier] [N]` | Go N states back in time order, one without a count | as `g-`, `E475: Invalid argument: x` | `editor_undo` |
| `:lat[er] [N]` | Go N states forward in time order, one without a count | as `g+`, `E475: Invalid argument: x` | `editor_undo` |
| `:reg[isters] [names]`, `:di[splay] [names]` | List the registers that hold text, or only the ones named | `Type Name Content` | `editor_registers` |
| unknown | Report the command | `E492: Not an editor command: name` | `use_cases_ex`, `editor_cmdline` |

Every command is recognized from its abbreviation to its full name, as the `name[suffix]` notation of the table means: `:vs`, `:vsp`, and `:vsplit` all split vertically, and `:tabf` and `:vsplitx` are unknown; the commands are tried in the order of this table, which is Vim's order where two could match, and the commands plugins declare come after them (`use_cases_ex` checks every spelling of every row, `editor_cmdline` runs `:vsp`, `:spl`, `:wr`, `:wal`, `:xi`, and `:tabfirs`).

Differences from Neovim: `E141` names a buffer by its position in the list, which shifts when a buffer leaves the list, where Neovim keeps buffer numbers for the session; `:qa` on a modified buffer shows only `E37`, not Neovim's second `E162` line naming the buffer; `:wa` shows the message of the last write only; `:e` without a bang refuses a modified buffer even when another window shows it, as Neovim does with `'hidden'` off, while closing a window keeps a modified buffer hidden, as Neovim does with `'hidden'` on; `:x` with a file argument writes even an unmodified buffer, where Neovim writes only a changed one; `:earlier` and `:later` with a time (`10s`, `5m`, `1h`, `1d`) or a write count (`1f`) answer `Not implemented: :earlier 10s`; a listing of several lines, as `:undolist` and `:registers` print, shows its last lines when it is taller than the screen, with no `-- More --` paging and no scrolling back at the hit-enter prompt; `:tabn N`, `:Nsplit`, `:tabm[ove]`, `:ls`, `:bn`, `:bp`, `:bd`, `:b N`, ranges, `:update`, and `:saveas` arrive with later changes.

## Windows

Every window shows one buffer from the buffer list with its own cursor and scroll position, and has a status line; windows side by side are separated by one column. A count before `<C-w>` is taken where Neovim takes one.

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| `[count]<C-w>s` | `window.split` | Split horizontally: the new window above shows the same view with half the text rows, or count rows | `editor_windows`, `domain_layout` |
| `[count]<C-w>v` | `window.vsplit` | Split vertically: the new window to the left shows the same view with half the columns, or count columns | `editor_windows`, `domain_layout` |
| `[count]<C-w>h`, `j`, `k`, `l` | `window.left`, `window.down`, `window.up`, `window.right` | To the neighbour overlapping the cursor's screen row or column, count times, stopping at the edge | `editor_windows`, `domain_layout` |
| `[count]<C-w>w` | `window.next` | Next window in layout order, wrapping; with a count, window number count or the last | `editor_windows` |
| `[count]<C-w>W` | `window.previous` | Previous window in layout order, wrapping; with a count, as `<C-w>w` | `editor_windows` |
| `<C-w>p` | `window.last_accessed` | The window that was current before the last change, if it still exists | `editor_windows` |
| `[count]<C-w>c` | `window.close` | Close the window, or window count; its space goes to the window after it, or before it when last | `editor_windows`, `domain_layout` |
| `<C-w>o` | `window.only` | Close every other window of the tab page | `editor_windows` |
| `<C-w>=` | `window.equalize` | Make the windows of every split the same size, fixed-width windows kept | `editor_windows`, `domain_layout` |
| `[count]<C-w>q` | `window.quit` | `:q` on the window, or on window count | `editor_windows` |

Messages: `E36: Not enough room` when the current window has fewer than three text rows or cannot give both windows one text column plus the number column and a separator; `E444: Cannot close last window` from `<C-w>c` and `:close` on the last window of the last tab page; `Already only one window` from `<C-w>o` and `:only`.

Differences from Neovim: `splitbelow` and `splitright` are off and not options; a window's minimum height is one text row and its minimum width one column plus the number column, with no `winminheight` or `winminwidth`; a fixed-width window (`winfixwidth`) is set by the explorer plugin and not by `:set`; `<C-w>` followed by a count (`<C-w>3j`) is not read, only a count before `<C-w>`; `<C-w>t b x r R H J K L T`, `<C-w>+ - < >`, `:resize`, `<C-w><C-w>` and the other `<C-w><C-x>` aliases, `winfixheight`, and scroll binding arrive with later changes; the neighbour for `<C-w>h j k l` is chosen by the cursor's row and code point column, not its display column.

## Tab pages

Each tab page holds its own window layout; the tab line on the top row lists them only when there is more than one, as `showtabline=1`.

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| `[count]gt` | `tab.next` | Next tab page, wrapping; with a count, tab page count, or nothing when there is none | `editor_tabs`, `domain_layout` |
| `[count]gT` | `tab.previous` | Count tab pages back, wrapping | `editor_tabs`, `domain_layout` |

The tab line label of a tab page is a space, its number, a space, the file name of its current window's buffer or `[No Name]`, ` [+]` when that buffer is modified, and a space; the current label is highlighted (`editor_tabs`, `adapters_frame_presenter`).

Differences from Neovim: the label shows the tab number instead of the window count, and never the count of windows; `:tabm[ove]`, `:tabn N`, `:tabs`, and `:tabdo` arrive with later changes.

## File explorer

The built-in `explorer` plugin is Carat's own, not part of Neovim; its keys follow the conventions common to Neovim's tree plugins, such as nvim-tree and neo-tree, so they feel familiar, but they are not copied from any one of them. Every row is covered by `test/editor_explorer.rb`, and the tree model by `test/plugins_explorer.rb`.

| Keys | Where | Action name | Behavior |
| --- | --- | --- | --- |
| `<leader>e`, `:Explorer` | normal mode | `plugin.explorer.toggle` | Open the tree at the configured side and width, focus it when it is open, close it when it is current |
| `:ExplorerFind` | command line | none | Open or focus the tree with the current file revealed and the cursor on it |
| `<CR>`, `l` | tree | `plugin.explorer.open` | Open the file in the previously used file window, or expand the directory |
| `h` | tree | `plugin.explorer.collapse` | Collapse the directory, or go to the parent's line |
| `o` | tree | `plugin.explorer.toggle_dir` | Toggle the directory, or open the file |
| `s`, `v`, `t` | tree | `plugin.explorer.open_split`, `open_vsplit`, `open_tab` | Open the file in a horizontal split, a vertical split, or a new tab page |
| `a` | tree | `plugin.explorer.create` | Prompt for a name and create a file, or a directory when it ends with `/`, in the entry's directory |
| `r` | tree | `plugin.explorer.rename` | Prompt for a new name, starting from the current one, and rename in place |
| `d` | tree | `plugin.explorer.delete` | Ask `Delete name? (y/n)` and delete a file or an empty directory |
| `R`, `H` | tree | `plugin.explorer.refresh`, `toggle_hidden` | List again from disk; show or hide dot files |
| `-`, `C` | tree | `plugin.explorer.root_up`, `set_root` | Root up one directory; root at the directory under the cursor |
| `q`, `?` | tree | `plugin.explorer.close`, `help` | Close the tree; show the keys in the message row |

`j`, `k`, `gg`, `G`, counts, `<C-w>` commands, and `:` work in the tree as in any window. The tree keeps its width on `<C-w>=` and on resizes, and `:q` in it closes only the tree. Not implemented: copy, cut, and paste of files, bookmarks, git status, recursive delete, trash, and live updates when files change outside the editor.

## Options read so far

`number`, `relativenumber`, `tabstop`, `shiftwidth`, `expandtab`, `autoindent`, `scrolloff`, and `timeoutlen`, from `config/default.json`. `scrolloff` is capped at half the window height as in Neovim. `shiftwidth` of 0 uses `tabstop`, as in Neovim.
