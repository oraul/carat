# Neovim compatibility

Every Neovim command Carat implements has a row here and a table-driven test. The test column names the `test/*.rb` program whose table or assertions cover the row. Commands from later roadmap items are not listed until they land; pressing a key bound to one of them shows a "Not implemented" message. The commands plugins add are Carat's own, not Neovim's, and are listed in `docs/actions.md` and `docs/plugins.md`; the file explorer's are in the File explorer section below. A scratch window a plugin opens behaves as a `nofile` buffer in a `winfixwidth` window with `nonumber`: `:w` reports `E382`, `:wa` skips it, and `:q` closes it; `:q` in the last window that shows a file, when the only other windows of its tab page are plugin windows, closes that tab page, or ends the editor on the last one, as Neovim's tree plugins arrange.

## Command grammar

| Keys | Behavior | Test |
| --- | --- | --- |
| `[count]` | `1` to `9` start a count and `0` to `9` extend it; counts before and after an operator multiply | `editor_grammar`, `domain_grammar` |
| `"x` | Select register `"`, `a` to `z`, or `A` to `Z` for the command; another name drops the prefix | `editor_grammar`, `editor_registers` |
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

Exclusive motions follow Vim's two adjustments: an operator range ending in column 0 of a later line ends at the end of the previous line inclusively, and becomes linewise when it started at or before the first non-blank; `w` under an operator stops at the end of the line when the last word moved over ends there (`editor_operators`).

Differences from Neovim: `d c y` always write the unnamed register, never the numbered or small-delete registers, until the undo change; the `=`, `~`, `g~`, `gu`, `gU`, `gq`, and `r` operators and `X` are not implemented; `joinspaces` is off; `p` of an empty register shows `E353` as Vim does.

## Text objects

Usable after an operator, in operator-pending mode.

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

Differences from Neovim: the numbered registers `0` to `9`, the black hole `_`, the read-only `% : .`, and the selection registers arrive with later changes; any other register name drops the prefix instead of beeping.

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
| unknown | Report the command | `E492: Not an editor command: name` | `use_cases_ex`, `editor_cmdline` |

Differences from Neovim: only the shortest and the full spelling of each command are recognized (`w` and `write`, not `wr`; `x` and `xit`, not `xi`; `tabn` and `tabnext`, not `tabne`); `E141` names a buffer by its position in the list, which shifts when a buffer leaves the list, where Neovim keeps buffer numbers for the session; `:qa` on a modified buffer shows only `E37`, not Neovim's second `E162` line naming the buffer; `:wa` shows the message of the last write only; `:e` without a bang refuses a modified buffer even when another window shows it, as Neovim does with `'hidden'` off, while closing a window keeps a modified buffer hidden, as Neovim does with `'hidden'` on; `:x` with a file argument writes even an unmodified buffer, where Neovim writes only a changed one; `:tabn N`, `:Nsplit`, `:tabm[ove]`, `:ls`, `:bn`, `:bp`, `:bd`, `:b N`, ranges, `:update`, and `:saveas` arrive with later changes.

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
