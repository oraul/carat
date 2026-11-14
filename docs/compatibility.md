# Neovim compatibility

Every Neovim command Carat implements has a row here and a table-driven test. The test column names the `test/*.rb` program whose table or assertions cover the row. Commands from later roadmap items are not listed until they land; pressing a key bound to one of them shows a "Not implemented" message. The commands plugins add are Carat's own, not Neovim's, and are listed in `docs/actions.md` and `docs/plugins.md`; the file explorer's and the file finder's are in the File explorer and File finder sections below. A scratch window a plugin opens behaves as a `nofile` buffer in a `winfixwidth` window with `nonumber`: `:w` reports `E382`, `:wa` skips it, and `:q` closes it; `:q` in the last window that shows a file, when the only other windows of its tab page are plugin windows, closes that tab page, or ends the editor on the last one, as Neovim's tree plugins arrange.

## Command grammar

| Keys | Behavior | Test |
| --- | --- | --- |
| `[count]` | `1` to `9` start a count and `0` to `9` extend it; counts before and after an operator multiply | `editor_grammar`, `domain_grammar` |
| `"x` | Select register `"`, `a` to `z`, `A` to `Z`, `0` to `9`, `-`, `_`, `.`, `:`, `%`, or `/` for the command; another name drops the prefix | `editor_grammar`, `editor_registers` |
| operator twice | `dd`, `cc`, `yy`, `>>`, `<<` act linewise over count lines | `editor_grammar`, `editor_operators` |
| `<Esc>` in operator-pending mode | Cancel the pending operator, count, and register | `editor_grammar` |
| unbound key | Drop the pending count and register | `editor_grammar` |
| pending keys | The keys typed so far show at the right of the message row, as `showcmd` | `editor_grammar` |
| prefix wait | Keys that only begin a command (`g`, `z`, `<C-w>`, `<leader>`) wait for the next key with no time limit, as Neovim's built-in commands do; a key that is bound and begins a longer binding, and a prefix in insert or command-line mode, are resolved after `timeoutlen` | `editor_normal`, `editor_windows`, `editor_explorer`, `smoke_editor` |

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
| `%`, `[count]%` | `motion.match_pair` | The bracket matching the first `(`, `[`, `{`, `)`, `]`, or `}` at or after the cursor on its line, nested pairs of its kind counted across lines, inclusive; with a count the line at count percent of the buffer, rounded up, keeping the wanted column; a jump | `editor_motions`, `editor_jumps` |
| `i` | `mode.insert` | Insert before the cursor | `editor_normal` |
| `a` | `mode.insert_after` | Insert after the cursor | `editor_normal` |
| `I` | `mode.insert_line_start` | Insert at the first non-blank character | `editor_normal` |
| `A` | `mode.insert_line_end` | Insert after the last character | `editor_normal` |
| `o` | `mode.insert_open_below` | Open a line below, with autoindent | `editor_normal`, `editor_insert` |
| `O` | `mode.insert_open_above` | Open a line above, with autoindent | `editor_normal` |
| `:` | `mode.cmdline` | Enter command-line mode | `editor_cmdline` |
| `<C-c>` | `message.quit_hint` | Show how to quit with unsaved changes | `editor_normal` |
| `[count]<leader>ws`, `[count]<leader>wv`, `[count]<leader>wh`, `wj`, `wk`, `wl`, `[count]<leader>wc`, `<leader>wo` | `window.*` | Carat's window group: as `<C-w>` with the same last key | `editor_leader`, `domain_keymap` |
| `<leader>qq`, `<leader>qw` | `quit.all`, `quit.write_all` | Carat's quit group: `:qa`, and `:wqa` | `editor_leader`, `editor_cmdline`, `smoke_editor` |
| `<leader>fs`, `<C-s>` | `file.save` | Carat's file group and save key: `:w`, Ctrl-S also in insert mode, staying in it | `editor_leader`, `smoke_editor` |
| `K` | `docs.hover` | The language server's hover documentation under the cursor in a bordered float, its markdown as plain rows; `K` again enters it, `Esc` or a cursor move closes it; with no server Neovim runs `keywordprg` instead, Carat says `No hover provider for this buffer` | `adapters_hover` |
| `gd` | `definition.jump` | The language server's definition under the cursor, asked without waiting: one target opens in the window with the cursor on it and the position left in the jump list, several open a pick list (Enter goes, Esc closes), a target outside the project opens as a read-only buffer with its own tab, which no write takes (`E45`, no bang overriding it), or shows the file's listed buffer; under `option.jumptab replace`, as shipped, a target with no tab takes the tab of the buffer left, at its position, and that buffer goes unlisted, where Neovim keeps every opened file listed (Vim's behavior is `option.jumptab keep`), since the user wants a jump not to fill the tab row; with no server Neovim searches for a local declaration instead, Carat says `method textDocument/definition is not supported by any of the servers registered for the current buffer`, and an empty answer `No locations found` | `adapters_definitions` |
| `<leader>dd` | `definition.peek` | The definition's source in a bordered float at the cursor, 12 rows from the target line, the cursor staying put; `Esc` or a cursor move closes it (Carat's own key) | `adapters_definitions` |
| `<C-o>` | `jump.older` | The older position of the window's jump list, by the count, across buffers; each window keeps its own list of at most 100 entries, one per line, a new window (a split, `:new`, a tab page) copying its parent's, and `gd`, every buffer switch (`:e`, `:b`, `:bn`, `:bp`, `:bN`, `:bfirst`, `:blast`, `<C-^>`, the buffer keys, the finder, the explorer), and the jump motions (`G`, `gg`, `%`, `(`, `)`, `{`, `}`, `H`, `M`, `L`, `/`, `?`, `n`, `N`, `*`, `#`, `g*`, `g#`, a range alone such as `:N`) add the position left when they move, also in the visual modes and under an operator, as in Neovim; under `option.jumptab replace` a file buffer with no tab takes the tab of the buffer left, as after `gd` | `adapters_definitions`, `editor_jumps`, `domain_jump_list` |
| `<C-i>`, `<Tab>` | `jump.newer` | The newer position of the window's jump list, by the count, with the tab rule of `<C-o>` | `adapters_definitions`, `editor_jumps` |
| `option.jumptab` | none | What a jump (`gd`, a pick-list choice, `<C-o>`, `<C-i>`) does with the tab of the buffer it leaves when the target has none: `replace` (shipped) gives the target that tab and unlists the buffer left, unless it is modified or another window shows it, and a scratch buffer neither takes nor gives one; `keep` (without a configuration) keeps it, as Neovim does; a target with a tab is only selected; `file:line: unknown jumptab mode WORD` for another word, read from `option.*` lines only | `adapters_definitions`, `domain_options_config` |
| `<leader>dp` | `docs.pin` | Carat's docs group: the documentation float pinned into a split | `adapters_hover` |
| `<leader>bb`, `[count]<leader>bn`, `[count]<leader>bp`, `[count]<leader>bd` | `buffer.*` | Carat's buffer group: `:ls`, `:bn`, `:bp`, `:bd` or `:bd N` | `editor_leader` |
| `[count]]b`, `[count][b`, `[B`, `]B` | `buffer.next`, `buffer.previous`, `buffer.first`, `buffer.last` | vim-unimpaired's buffer keys: `:bn`, `:bp`, `:bfirst`, `:blast`, the same with any number of tab pages and under either `option.gt` | `editor_tabs`, `domain_keymap` |
| `[count]<C-^>`, `<C-6>` | `buffer.alternate` | The window's alternate buffer, the one it showed before the current one, as `:b N` shows it, or with a count buffer count; every buffer switch sets it, a split and a new tab page copy it; `E23: No alternate file` without one, `E37` for a modified buffer | `editor_jumps`, `domain_keys` |

Differences from Neovim: `startofline` is off, so `gg G H M L` keep the wanted column; keyword characters are ASCII letters, digits, underscore, and every code point from U+00C0 upward until `iskeyword` exists; sentence ends are `. ! ?` with optional `) ] " '` before a blank or the line end, and paragraph boundaries are empty lines only (no nroff macros, no form feeds); `H` and `L` take `scrolloff` into account when moving the cursor and ignore it under an operator, as Neovim does; `%` matches brackets only, without `matchpairs`, the C comment and `#if` items, or Vim's skipping of brackets inside quotes; `<C-^>` shows no file message, as `:b N` shows none here; the quit hint names `:q!` as Neovim does for the last window.

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

## Search

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| `[count]/pattern<CR>` | `search.forward` | Open the `/` prompt, then the count-th match after the cursor; an empty pattern reuses the last one; `<Esc>` or `<BS>` on an empty prompt cancels | `editor_search`, `domain_search` |
| `[count]?pattern<CR>` | `search.backward` | The same backward, with the `?` prompt | `editor_search`, `domain_search` |
| `[count]n` | `search.next` | The last search again in its direction, its highlight shown again | `editor_search` |
| `[count]N` | `search.previous` | The last search in the other direction | `editor_search` |
| `[count]*`, `[count]#` | `search.word_forward`, `search.word_backward` | The keyword under or after the cursor as `\<word\>`, or the non-blank text there; becomes the last pattern and a history entry; ignores `smartcase` | `editor_search` |
| `[count]g*`, `[count]g#` | `search.partial_word_forward`, `search.partial_word_backward` | The same without `\<` and `\>` | `editor_search` |
| operator + search | any of the above | Exclusive charwise motion; a delete or change over it writes `"1`; `.` repeats it with the same pattern | `editor_search` |
| visual mode + search | any of the above | Moves the cursor end of the selection; `<Esc>` at the prompt returns to the visual mode | `editor_search` |
| wrap | | `search hit BOTTOM, continuing at TOP`, `search hit TOP, continuing at BOTTOM` | `editor_search`, `domain_search` |
| errors | | `E486: Pattern not found: pat`, `E35: No previous regular expression`, `E348: No string under cursor` | `editor_search` |
| `hlsearch`, `incsearch` | | Every match of the last pattern in the `Search` group until `:noh`; while typing, the cursor on the first match in `IncSearch`, back on `<Esc>` | `editor_search`, `adapters_frame_presenter` |
| `ignorecase`, `smartcase`, `\c`, `\C` | | Case ignored with `ignorecase` unless `smartcase` and an uppercase letter; `\c` ignores and `\C` matches case | `editor_search`, `domain_vim_pattern` |

Patterns (`domain_vim_pattern`) are Vim's magic patterns, translated for the regular expression engine Spinel bundles (`docs/spinel-notes.md`): literal text; `.`; the multis `*`, `\+`, `\=`, `\?`, `\{n,m}`, `\{n}`, `\{n,}`, `\{,m}`, `\{}`, and the lazy `\{-...}`; `^` at the start of a branch and `$` at its end; `[...]` with ranges, `^` negation, `[:alpha:]` and the other POSIX classes, and the escapes `\e \t \r \\ \] \^ \-`; `\(\)`, `\%(\)`, and `\|`; `\<` and `\>`; the classes `\s \S \d \D \w \W \a \A \l \L \u \U \x \X \h \H \o \O \k \K`; `\t \e \r`; `\c` and `\C`; and the modes `\v`, `\m`, `\M`, and `\V`. Malformed patterns give Vim's errors: `E54: Unmatched \(`, `E55: Unmatched \)`, `E61: Nested *`, `E62: Nested \+`, `E64: \+ follows nothing`, `E554: Syntax error in \{...}`, `E944: Reverse range in character class`, and `E33: No previous substitute regular expression` for `~`. In a substitute's pattern `\(\)` captures for `\1` to `\9` (`E51: Too many \(` past nine) and `~` matches the previous replacement string.

Differences from Neovim: back references `\1` to `\9`, look-around `\@`, `\z`, `\%` items other than `\%(`, the `\_` classes, `\n`, `\&`, and `\i \I \f \F \p \P` answer `Not implemented: \1 in a pattern`, and search offsets (`/foo/e`) answer `Not implemented: search offset e`; `\<` and `\>` are both a word boundary, so `\<` also matches at the end of a word before a non-keyword item; `smartcase` looks for an uppercase ASCII letter; a pattern of more than 2,000 states or 4,096 bytes is refused with `E363: pattern uses more memory than 'maxmempattern'`, and a search that would scan more than its budget (the line's length for each match tried plus the characters scanned times the pattern's size) stops with `E363: search stopped, pattern too costly here`, where Neovim has `'maxmempattern'` and `'redrawtime'`; a line that is not valid UTF-8 is matched with each illegal byte as U+FFFD; `'wrapscan'` is always on; there is no search count `[1/5]` and no `CurSearch` group; the wrap message is drawn as a plain message; under an operator the pattern is not echoed; `'history'` is 50.

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
| `"/` | The last search pattern; read-only | `editor_registers`, `editor_search`, `domain_registers` |
| write to `. : % /` | Refused with `E354: Invalid register name: '.'`; the text is left alone | `editor_registers` |

Differences from Neovim: the registers are written as Neovim's `op_yank` and `op_delete` code does, which differs from its help text in that a big delete naming a register also writes `"1`; after an uppercase append the unnamed register holds only the new text, where Neovim's points to the whole register; a delete, change, or yank into a read-only register shows `E354`, which Neovim shows only for `:let @.`, where it beeps; a visual `p` stores the replaced text by the delete rules, as Neovim's `v_p` does; the `"#`, `"=`, `"*`, and `"+` registers and `:let @x` are not implemented; any other register name drops the prefix instead of beeping.

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
| `:` | `mode.cmdline` | Leave the visual mode and enter command-line mode with `'<,'>`, the lines of the selection | `editor_substitute` |
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
| `<C-n>` | `completion.keyword_next` | With no popup showing: keyword completion of the word before the cursor from the listed buffers, scanning forward from the cursor (the rest of the line, the lines below, then from the top), then the other listed file buffers in list order; the matches, each listed once, open the popup on the nearest; no match reads `Pattern not found`; at most 200 matches and 1,000,000 bytes read per press; unlike Neovim the match is inserted only with `<CR>` or `<Tab>`, the original text is no stop in the cycle, and `complete`, `ignorecase`, and `iskeyword` are not read | `editor_word_completion` |
| `<C-p>` | `completion.keyword_previous` | The same, scanning backward from the cursor (the line before it, the lines above, then from the bottom), each other buffer bottom to top; the nearest match is the last row and selected | `editor_word_completion` |

### Completion popup

A typed character opens the popup when the completion source is ready and the cursor follows word characters (ASCII letters, digits, `_`, any non-ASCII character); typing and `<BS>` filter it again, an empty word or no match closes it. Matching cuts the typed part at `_` into parts, each part's first letter starting a part of the candidate (its start, after a non-word character, or an uppercase letter after a lowercase one) after the previous part's, its other letters following in order, ASCII case ignored: `fn_na` finds `file_name`, which Neovim's prefix matching does not. Labels starting with the typed text come first. A popup opened by `<C-n>` or `<C-p>` shows the buffers' words in the order found and takes the same keys. While the popup shows, these `keymap.completion` keys answer first:

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| `<C-n>`, `<Down>` | `completion.next` | Select the next row, wrapping; unlike Neovim the item is not inserted yet (`completeopt=noinsert`) | `editor_completion` |
| `<C-p>`, `<Up>` | `completion.previous` | Select the previous row, wrapping | `editor_completion` |
| `<CR>` | `completion.insert` | Put the selected item in place of the typed part | `editor_completion` |
| `<Tab>` | `completion.replace` | Put the selected item in place of the whole word under the cursor | `editor_completion` |
| `<Esc>` | `completion.close` | Close the popup and stay in insert mode; Neovim's `<Esc>` also leaves insert mode | `editor_completion` |

The selected item's documentation shows in a float beside the popup, as Neovim's `completeopt=popup` does: on its right, or its left without the room, at most 60 columns and 12 rows, markdown read as plain text, closed with the popup. A language server's item documented only through `completionItem/resolve` is resolved once the selection rests on it for 0.1 seconds, at most once per item of an answer (`editor_completion`, `adapters_server_completions`).

### Parameter info

Neovim shows signature help on request (`vim.lsp.buf.signature_help()`, `<C-s>` in insert mode since 0.11); Carat shows it as the common signature plugins do, with no key, and keeps `<C-s>` for saving.

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| `(`, `,` | none | Inserted; inside a call on the row, when the buffer's language server gives signature help, its signature shows in a one-row float above the cursor, the active parameter in `Visual` (Neovim's `LspSignatureActiveParameter` link), asked once typing pauses for 0.1 seconds | `adapters_signature` |
| any key in the call | none | Asks again so the mark follows the cursor; the float closes past the call's `)`, before its `(`, on another row, window, or buffer, and on an empty answer | `adapters_signature` |
| `<Esc>` | `mode.normal` | Leaves insert mode and closes the float | `adapters_signature` |

## Command-line mode

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| printable | none | Append to the command line | `editor_cmdline` |
| `<BS>` | `cmdline.backspace` | Remove the last character; leave when empty | `editor_cmdline` |
| `<Esc>` | `mode.normal` | Discard the command line | `editor_cmdline` |
| `<CR>` | `cmdline.execute` | Run the command, or search at a `/` or `?` prompt | `editor_cmdline`, `editor_search` |
| `<Up>` | `cmdline.history_older` | The next older entry of the prompt's history (`:` or search) that starts with the text typed before the first recall | `editor_cmdline`, `editor_search` |
| `<Down>` | `cmdline.history_newer` | The next newer entry, or the typed text after the newest | `editor_cmdline`, `editor_search` |
| `<C-n>`, `<C-p>` | `palette.next`, `palette.previous` | At the command palette's `>` prompt, select the next or previous entry; nothing elsewhere (Neovim's history keys are `<Up>` and `<Down>` here) | `editor_palette` |

## Ex commands

| Command | Behavior | Messages | Test |
| --- | --- | --- | --- |
| `:w[rite] [file]` | Write the buffer to its path or to file | `"name" 2L, 8B written`, `E32`, `E212` | `use_cases_ex`, `editor_cmdline` |
| `:q[uit]` | Close the window when another exists anywhere, else quit unless a file buffer is modified: the current one refuses with `E37`, another is named and shown in the window | `E37`, `E37` and `E162: No write since last change for buffer "name"` | `use_cases_ex`, `editor_cmdline`, `editor_windows` |
| `:q[uit]!` | Close the window, or quit discarding changes; on the last window a modified hidden buffer is named and shown instead, the current buffer's changes discarded | `E37` and `E162` | `use_cases_ex`, `editor_cmdline`, `editor_windows` |
| `:wq [file]`, `:wq!` | Write, then close the window or quit; a modified hidden buffer is named and shown instead | as `:w`, `E37` and `E162` | `use_cases_ex`, `editor_cmdline` |
| `:x[it] [file]`, `:exi[t] [file]`, `:x!` | Write when modified or given a file, then close the window or quit; a modified hidden buffer is named and shown instead | as `:w`, `E37` and `E162` | `use_cases_ex`, `editor_cmdline` |
| `:wa[ll]`, `:wa!` | Write every modified buffer in every tab page, in list order | as `:w`, `E141: No file name for buffer N` with the buffer number | `use_cases_ex`, `editor_cmdline`, `editor_windows` |
| `:qa[ll]`, `:quita[ll]` | Quit unless a file buffer in the list is modified, hidden ones included; else name the first, the current buffer before the other windows' and the hidden ones, and go to it | `E37: No write since last change` and `E162: No write since last change for buffer "name"` | `use_cases_ex`, `editor_cmdline`, `editor_tabs` |
| `:qa[ll]!`, `:quita[ll]!` | Quit all, discarding changes | | `use_cases_ex`, `editor_cmdline` |
| `:wqa[ll]`, `:xa[ll]`, `:wqa!`, `:xa!` | Write every modified buffer, then quit all | as `:w`, `E141` | `use_cases_ex`, `editor_cmdline`, `editor_tabs` |
| `:e[dit] [file]` | Show the file in the window: the listed buffer for it, or the file read from disk; reload the current one in place; the buffer left stays listed, hidden; bytes that are not UTF-8 are kept and drawn as U+FFFD; a directory, a FIFO, a device, or a file over 64 MiB is refused and the window keeps its buffer | `"name" 1L, 3B`, `"name" [New]`, `"name" [ILLEGAL BYTE in line 2] 2L, 8B`, `"name" is a directory`, `"name" is not a file`, `E37`, `E484` | `use_cases_ex`, `editor_cmdline`, `editor_windows` |
| `:e[dit]! [file]` | Open or reload, discarding changes | | `use_cases_ex`, `editor_cmdline` |
| `:e[dit] #` | Edit the file of the window's alternate buffer as `:e name` does | `E194: No alternate file name to substitute for '#'`, `E499: Empty file name for '%' or '#', only works with ":p:h"` | `editor_jumps` |
| `:sp[lit] [file]` | Split the window horizontally, the new window above showing the same buffer or file | `E36`, as `:e` | `use_cases_ex`, `editor_windows` |
| `:vs[plit] [file]` | Split the window vertically, the new window to the left | `E36`, as `:e` | `use_cases_ex`, `editor_windows` |
| `:new` | Split horizontally with a new unnamed buffer | `E36` | `use_cases_ex`, `editor_windows` |
| `:vne[w]` | Split vertically with a new unnamed buffer | `E36` | `use_cases_ex`, `editor_windows` |
| `:clo[se]` | Close the window, or its tab page when it was the last one there | `E444` | `use_cases_ex`, `editor_windows` |
| `:on[ly]` | Close every other window of the tab page | `Already only one window` | `use_cases_ex`, `editor_windows` |
| `:tabnew`, `:tabe[dit] [file]` | Open a tab page after the current one on a new buffer or the file | as `:e` | `use_cases_ex`, `editor_tabs` |
| `:tabc[lose] [N]` | Close the tab page, or tab page N; the next one, or the previous when it was last, becomes current | `E784` first with one tab page, `E16: Invalid range` for 0, `E475: Invalid argument: x` for a word or a number past the last | `use_cases_ex`, `editor_tabs` |
| `:tabo[nly] [N]` | Close every other tab page, after going to tab page N | `Already only one tab page` first, then as `:tabc N` | `use_cases_ex`, `editor_tabs` |
| `:tabn[ext] [N]` | Next tab page, wrapping, or tab page N | as `:tabc N` | `use_cases_ex`, `editor_tabs` |
| `:tabp[revious] [N]`, `:tabN[ext] [N]` | Previous tab page, or N back, wrapping | `E475: Invalid argument: x` for anything but a positive number | `use_cases_ex`, `editor_tabs` |
| `:tabfir[st]`, `:tabl[ast]` | First and last tab page | `E488: Trailing characters: x` | `use_cases_ex`, `editor_tabs` |
| `:ls`, `:buffers`, `:files` | List the file buffers: number, flags (`%` current, `a` shown or `h` hidden, `=` read-only, `+` modified), the quoted name, and the line of the cursor, the current window's for the current buffer and where a window last left the others; in number order; with `!` also the unlisted buffers, flagged `u`: the plugins' scratch buffers and those a jump left under `option.jumptab replace`, which `:bn`, `:bp`, and `:bd`'s next buffer skip and any open lists again; an argument keeps the buffers matching each of its flags `u + a h % =`, and `# - x R F ?` keep none | | `editor_buffers` |
| `:b[uffer] N`, `:b[uffer]! N` | Show buffer number N in the window with the cursor where a window last left it; the buffer left stays listed, hidden; without N stay | `E86: Buffer N does not exist`, `E37`, `Not implemented: :buffer name` | `editor_buffers`, `use_cases_ex` |
| `:bn[ext] [N]`, `:bn[ext]! [N]` | Show the next listed file buffer, or the Nth, wrapping; 0 stays | `E85: There is no listed buffer`, `E37`, `E488: Trailing characters: x` | `editor_buffers`, `use_cases_ex` |
| `:bp[revious] [N]`, `:bN[ext] [N]`, `:bp[revious]! [N]` | Show the previous listed file buffer, or the Nth before, wrapping | as `:bn` | `editor_buffers`, `use_cases_ex` |
| `:bf[irst]`, `:br[ewind]`, `:bf[irst]!` | Show the first listed file buffer | `E85: There is no listed buffer`, `E37`, `E488: Trailing characters: x` | `editor_buffers` |
| `:bl[ast]`, `:bl[ast]!` | Show the last listed file buffer | as `:bfirst` | `editor_buffers` |
| `:bd[elete] [N]`, `:bd[elete]! [N]` | Remove the current buffer, or buffer N, from the list, closing every window that shows it and its tab page with its last window; the last window shows the next listed file buffer, or the one before, or a new empty buffer when none is left; the bang discards the changes | `E89: No write since last change for buffer N (add ! to override)`, `E516: No buffers were deleted: bd N`, `Not implemented: :bdelete name` | `editor_buffers`, `use_cases_ex` |
| `:u[ndo]` | Undo one state | as `u`, `Already at oldest change` | `editor_undo` |
| `:u[ndo] N` | Go to the text after state N, 0 for the original | `2 changes; after #1  0 seconds ago`, `E830: Undo number N not found`, `E474: Invalid argument` | `editor_undo` |
| `:red[o]` | Redo one state | as `<C-r>`, `Already at newest change` | `editor_undo` |
| `:undol[ist]` | List the states without later states on their branch: number, changes from the original, seconds ago, and the write number | `Nothing to undo` | `editor_undo` |
| `:ea[rlier] [N]` | Go N states back in time order, one without a count | as `g-`, `E475: Invalid argument: x` | `editor_undo` |
| `:lat[er] [N]` | Go N states forward in time order, one without a count | as `g+`, `E475: Invalid argument: x` | `editor_undo` |
| `:reg[isters] [names]`, `:di[splay] [names]` | List the registers that hold text, or only the ones named | `Type Name Content` | `editor_registers` |
| `:sy[ntax] on`, `:sy[ntax] enable`, `:sy[ntax] off` | Turn syntax highlighting on or off for every buffer; it starts on | `E410: Invalid :syntax subcommand: x`, `Not implemented: :syntax list` | `editor_syntax`, `use_cases_ex` |
| `:se[t] filetype=x`, `:se[t] ft=x`, `:se[t] syntax=x`, `:se[t] syn=x` | Set the current buffer's filetype and its syntax, or its syntax alone (`OFF` for none, `ON` for the filetype's); several arguments in one command | `E518: Unknown option: x`, `Not implemented: :set number` | `editor_syntax`, `use_cases_ex` |
| `:se[t] ft?`, `:se[t] filetype` | Show the filetype or the syntax | `  filetype=ruby` | `editor_syntax` |
| `:se[t] ic`, `:se[t] noscs`, `:se[t] invhls`, `:se[t] is!`, `:se[t] hls?` | Set, clear, switch, or show `ignorecase` (`ic`), `smartcase` (`scs`), `hlsearch` (`hls`), `incsearch` (`is`), or `cursorline` (`cul`) | `  hlsearch`, `nohlsearch`, `E474: Invalid argument: hls=1` | `editor_search` |
| `:noh[lsearch]` | Stop highlighting the last search's matches until the next search, `n`, or `:set hlsearch` | | `use_cases_ex`, `editor_search` |
| `:s[ubstitute]` | `:[range]s/{pattern}/{string}/[flags] [count]`: replace the first match on each line of the range (the cursor line without one), every match with `g`; without a pattern, `:s [flags] [count]` repeats the last substitute; see Substitute | `N substitutions on M lines`, `E486`, `E33`, `E35`, `E488`, `E939` | `editor_substitute`, `domain_substitute`, `use_cases_ex` |
| `:&` | `:[range]&[&][flags] [count]`: repeat the last substitute's pattern and string on the range without its flags, with them after `&&` | as `:s` | `editor_substitute`, `use_cases_ex` |
| `:g[lobal]` | `:[range]g/{pattern}/[cmd]`: mark every line of the range (every line without one) that matches, then run the ex command cmd on each marked line in turn, listing them without one; see Global | `Pattern not found: pat`, `E148`, `E146`, `E35`, `E147`, `E363` | `editor_global`, `domain_global`, `use_cases_ex` |
| `:g[lobal]!` | As `:v` | as `:v` | `editor_global` |
| `:v[global]` | `:[range]v/{pattern}/[cmd]`: as `:g` on the lines that do not match | `Pattern found in every line: pat`, as `:g`, `E477` | `editor_global`, `use_cases_ex` |
| `:d[elete]` | `:[range]d [x] [count]`: delete the lines of the range (the cursor line without one), or count lines from its last line, into register x or the unnamed one, shifting the numbered registers; the cursor to the first non-blank of the line after them | `E488: Trailing characters: x`, `E939`, `E477` | `editor_global`, `domain_global`, `use_cases_ex` |
| `:LspStart` | nvim-lspconfig's command: starts the current buffer's language server when none runs for its file type, in any directory, the start a directory outside `language.trusted_roots` waits for; the `lsp` slot reads `starting` | `No language server for this buffer`, `Cannot start ruby-lsp`, `E488: Trailing characters: x` | `editor_lsp`, `use_cases_ex` |
| `:LspRestart` | nvim-lspconfig's command: stops every language server, clears their drawn diagnostics, and starts the current buffer's again; the `lsp` slot reads `starting` | `No language server for this buffer`, `Cannot start ruby-lsp`, `E488: Trailing characters: x` | `editor_lsp`, `use_cases_ex` |
| `:mes[sages]`, `:mes[sages] clear` | Show the message history (Messages and notifications): one entry on the message row, several as a listing with the hit-enter prompt, none as nothing; `clear` empties it | `E474: Invalid argument` | `editor_messages`, `use_cases_ex` |
| unknown | Report the command | `E492: Not an editor command: name` | `use_cases_ex`, `editor_cmdline` |

Every command is recognized from its abbreviation to its full name, as the `name[suffix]` notation of the table means: `:vs`, `:vsp`, and `:vsplit` all split vertically, and `:tabf` and `:vsplitx` are unknown; the commands are tried in the order of this table, which is Vim's order where two could match, and the commands plugins declare come after them (`use_cases_ex` checks every spelling of every row, `editor_cmdline` runs `:vsp`, `:spl`, `:wr`, `:wal`, `:xi`, and `:tabfirs`).

Differences from Neovim: `:wa` shows the message of the last write only; `:e` of a directory, a FIFO, or a device shows Vim's message and keeps the buffer, where Vim opens an empty buffer for a directory and reads a FIFO, and a file over 64 MiB is refused with `E484: Can't open file name: File too large`, where Vim has no limit; `:e`, `:b`, `:bn`, `:bp`, `:bN`, `:bfirst`, and `:blast` without a bang refuse a modified buffer even when another window shows it, as Neovim does with `'hidden'` off, while closing a window keeps a modified buffer hidden and every buffer no window shows stays loaded, as Neovim does with `'hidden'` on, so `:e` and `:b` show its text without reading the file again; `:bd` forgets the buffer, where Neovim keeps it unlisted, so `:b N` of a deleted buffer is `E86` and `:ls!` adds only the plugins' scratch buffers, which `:b` and `:bd` do not take; `:bd` of the current buffer shows the next listed one, where Neovim prefers the one visited last; a buffer remembers one cursor position, where Neovim keeps one per window, and `:ls` shows line 1 for a buffer no window has left, where Neovim shows 0; `:b name`, `:bd name`, several numbers or a range for `:bd`, a count before `:b`, `:bn`, `:bp`, and `:bd`, `:ls t`, `:badd`, `:bwipeout`, `:bunload`, `:sbuffer`, `#` anywhere but `:e #`, and the `#` flag of `:ls` are not implemented; `:x` with a file argument writes even an unmodified buffer, where Neovim writes only a changed one; no write takes a read-only buffer, the target `gd` opens outside the project, where Neovim's `:w!` overrides `'readonly'`; `:earlier` and `:later` with a time (`10s`, `5m`, `1h`, `1d`) or a write count (`1f`) answer `Not implemented: :earlier 10s`; a listing of several lines, as `:undolist` and `:registers` print, shows its last lines when it is taller than the screen, with no `-- More --` paging and no scrolling back at the hit-enter prompt; `:Nsplit`, `:tabm[ove]`, `:update`, and `:saveas` arrive with later changes, a tab ex argument is a number only, Vim's `+N`, `-N`, `$`, and `#` answering `E475`, and a range before any command but `:s`, `:&`, `:g`, `:v`, and `:d` is refused with `E481: No range allowed`, where Vim lets `:w` and others take one; `:set` handles only `filetype`, `syntax`, the four search options, and `cursorline` (the other options the editor has answer `Not implemented: :set name`, the rest arrives with the options change), `:setlocal` and `:filetype` do not exist yet, `:syntax` has no subcommand but `on`, `enable`, and `off`, and the syntax switch is global and not a configuration option.

## Substitute

A range comes before the command name; `:s`, `:&`, `:g`, `:v`, and `:d` take one, and a range alone moves the cursor.

| Range | Lines | Test |
| --- | --- | --- |
| none | The cursor line | `editor_substitute`, `domain_ex_range` |
| `%` | Every line | `editor_substitute`, `domain_ex_range` |
| `.`, `$`, `N` | The cursor line, the last line, line N (0 is 1) | `editor_substitute`, `domain_ex_range` |
| `'<`, `'>` | The first and last line of the window's last visual selection; `E20: Mark not set` without one | `editor_substitute`, `domain_ex_range` |
| `a,b` | From a to b; an empty address is the cursor line, and of more than two the last two count | `editor_substitute`, `domain_ex_range` |
| `:N`, `:$`, `:'>` | A range alone: the cursor to its last line, keeping the wanted column as `G` does | `editor_substitute`, `use_cases_ex` |
| errors | `E16: Invalid range` past the last line, `E493: Backwards range given`, `E481: No range allowed` | `editor_substitute`, `domain_ex_range`, `use_cases_ex` |

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| `[count]&` | `substitute.repeat` | The last substitute again on the cursor line without its flags, as `:s`; with a count on count lines, `E16` past the last | `editor_substitute` |
| `g&` | `substitute.repeat_all` | `:%s//~/&`: the last search pattern replaced by the last string on every line, with the last flags | `editor_substitute` |

| Flag | Effect | Test |
| --- | --- | --- |
| `&` | First: keep the last substitute's flags; without it the flags start from none | `editor_substitute`, `domain_substitute` |
| `g` | Every match in the line (switches a kept `g`) | `editor_substitute`, `domain_substitute` |
| `e` | No `E486` when nothing matches (switches) | `editor_substitute`, `domain_substitute` |
| `i`, `I` | Ignore or match case, over `ignorecase` and `smartcase` | `editor_substitute`, `domain_substitute` |
| `n` | Count the matches, `N matches on M lines`, and change nothing | `editor_substitute`, `domain_substitute` |
| `r` | `:&` and `:s` without a pattern use the last search pattern, not the last substitute's | `editor_substitute` |
| `p`, `#` | Show the last changed line, with `#` after its number | `editor_substitute`, `domain_substitute` |
| `[count]` | After the flags: count lines from the range's last line; `E939: Positive count required` for 0 | `editor_substitute`, `domain_substitute` |

| In the string | Inserts | Test |
| --- | --- | --- |
| `&`, `\0` | The whole match | `editor_substitute`, `domain_substitute` |
| `\1` to `\9` | The text of the pattern's `\(\)` groups, nothing for one that did not match | `editor_substitute`, `domain_substitute` |
| `~` | The previous substitute's string | `editor_substitute`, `domain_substitute` |
| `\u`, `\l`, `\U`, `\L`, `\e`, `\E` | The next character in upper or lower case; the following ones until `\e` or `\E` | `editor_substitute`, `domain_substitute` |
| `\r` | A line break | `editor_substitute`, `domain_substitute` |
| `\t`, `\\`, `\&`, `\~`, `\x` | A tab, a backslash, `&`, `~`, and any other escaped character as itself | `domain_substitute` |

The delimiter is any ASCII character but a letter (`E146: Regular expressions can't be delimited by letters`), a digit, a blank, `\`, `"`, or `|`; a missing closing delimiter ends the string at the end of the line; text after the flags and count is `E488: Trailing characters: x`. An empty pattern uses the last search pattern, and with no previous substitute `:&`, `:s`, and `&` report `E33: No previous substitute regular expression`, an empty pattern or `g&` with no search `E35: No previous regular expression`. A substitute reports `N substitutions on M lines` above two substitutions and `E486: Pattern not found: pat` when nothing matched; it is one undo state, `.` does not repeat it, the cursor goes to the first non-blank of the last line changed, and its pattern becomes the last search pattern, the `/` register, and a search history entry.

Differences from Neovim: the `c` and `l` flags, `\=` expressions, and `\n` in the string answer `Not implemented` and change nothing; `p` and `#` show the line instead of the count message; addresses with `+`, `-`, `;`, a pattern, or a mark other than `'<` and `'>` answer `Not implemented: range x`, a count before `:` is not read, and `:~`, `:sg`-style abbreviations with flags, and `|` between commands are not implemented; a backwards range is refused with `E493` where Neovim asks to swap it; `'<` and `'>` are not moved by later edits and stop at the last line; `'report'` is always 2; `:s` and `:&` take no bang (`E477: No ! allowed`); every line's scan and every character of replacement text are charged to one work budget per command, and a command that runs out changes nothing and reports `E363: search stopped, pattern too costly here`, and a string whose `~` would expand past 1 MiB is refused with `E1240: Resulting text too long`; `~` in a `/` or `?` pattern answers `E33` even after a substitute.

## Global

`:g` works in Vim's two passes: it marks the lines of the range the pattern matches, `:g!` and `:v` those it does not, then runs the command once per marked line from the top, the cursor at the start of the line. A line keeps its mark however the lines above it move, so a marked line that an earlier run deleted is not visited and lines a run inserts are not either: `:g/x/d` deletes exactly the lines holding `x`.

| Case | Behavior | Test |
| --- | --- | --- |
| The argument | The delimiter is any ASCII character but a letter (`E146`); the pattern ends at the next delimiter no backslash escapes, and the rest is the command; no argument is `E148: Regular expression missing from :global` | `editor_global`, `domain_global` |
| The pattern | Compiled as a search pattern under `ignorecase` and `smartcase`; an empty one is the last search pattern (`E35` without one); it becomes the last search and substitute pattern, the `/` register, and a search history entry, so `n` and `:s//x/` use it | `editor_global` |
| No command | The marked lines are listed, the cursor on the first non-blank of the last | `editor_global` |
| No marked line | `Pattern not found: pat` for `:g`, `Pattern found in every line: pat` for `:g!` and `:v`; nothing runs | `editor_global` |
| Messages | The first command that fails stops the global with its message; otherwise the last message a command gave is shown | `editor_global` |
| Undo and repeat | One undo step; `.` does not repeat it | `editor_global` |
| Nested | A global run by a global's command acts on the cursor line only; with a range other than every line it is `E147: Cannot do :global recursive with a range` | `editor_global` |
| The budget | The scan that marks the lines is charged to the search work budget; when it runs out nothing runs and the message is `E363` | `editor_global` |

Differences from Neovim: `\/`, `\?`, and `\&` as the delimiter and a delimiter that is not ASCII answer `Not implemented`; `:m`, `:t`, `:normal`, and `:p` do not exist yet, so a global runs the other ex commands Carat has; after a global the message is the last one its command gave, not Vim's totals (`N substitutions on M lines` over every line, `N fewer lines`); a command that switches to another buffer stops the global, where Vim goes on there; a command that closes the undo step, as `:undo` does, splits the global into more than one; Ctrl-C does not interrupt it; `:d` reports no line count, as `dd` reports none.

## Messages and notifications

Every kind of message, where it shows, when it goes, and whether `:messages` keeps it.

| Kind | Placement | Expiry | History | Test |
| --- | --- | --- | --- | --- |
| Information | The message row in `Normal` (a file written, `Not implemented: name`, a plugin's message) | The next key | Kept, the oldest past 500 dropped | `domain_messages`, `editor_messages` |
| Error | The message row in `ErrorMsg` (`E492`, a plugin disabled) | The next key | Kept | `domain_messages`, `editor_messages` |
| Listing | The rows above the message row with the hit-enter prompt (`:registers`, `:ls`, `:undolist`, `:messages`) | Enter or Space, or any other key run as a command | Not kept | `domain_messages`, `editor_messages` |
| Info notification | A box at the top right, from the row under the buffer tabs, its right edge one column in, `Info` on its top border in `DiagnosticInfo`, the text in `NormalFloat`; at most three stacked oldest first, a fourth replacing the oldest, none reaching the status bar or on a screen under 8 columns | 3 seconds | Kept | `domain_messages`, `editor_messages` |
| Warning notification | As info, `Warning` in `DiagnosticWarn` (a language server's `window/showMessage` of type 2) | 5 seconds | Kept | `domain_messages`, `editor_messages`, `adapters_language_gateway` |
| Error notification | As info, `Error` in `DiagnosticError` (`window/showMessage` of type 1; other types are info) | 8 seconds | Kept | `domain_messages`, `editor_messages`, `adapters_language_gateway` |
| Progress | The status bar's progress segment (Status bar and buffer tabs) | The work's end, or its server stopping | Not kept | `adapters_status_bar`, `adapters_language_gateway` |

Notifications never animate, so `option.reducedmotion` changes only the progress bar; under `NO_COLOR` a box is `+`, `-`, and `|` in `Normal`. A server's message is one line without control characters or escape sequences, cut at 200 bytes. Differences from Neovim: `:{count}messages` is refused with `E481`, the history is not colored, `messagesopt` is not an option, notifications are not dismissed by a key and come only from language servers (no plugin request yet), and `window/showMessageRequest` and `window/logMessage` show nothing.

## Windows

Every window shows one buffer from the buffer list with its own cursor and scroll position; a window above another ends in a separator row and windows side by side are separated by one column, both in `WinSeparator`, and one status bar serves them all (Status bar and buffer tabs below). A count before `<C-w>` is taken where Neovim takes one.

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| `[count]<C-w>s` | `window.split` | Split horizontally: the new window above shows the same view with half the text rows, or count rows | `editor_windows`, `domain_layout` |
| `[count]<C-w>v` | `window.vsplit` | Split vertically: the new window to the left shows the same view with half the columns, or count columns | `editor_windows`, `domain_layout` |
| `[count]<C-w>h`, `j`, `k`, `l` | `window.left`, `window.down`, `window.up`, `window.right` | To the neighbour whose layout rectangle abuts the window's and overlaps the cursor's screen row or column, so in a nested split the cursor's row picks between two stacked windows, count times, stopping at the edge | `editor_windows`, `domain_layout` |
| `[count]<C-w>w` | `window.next` | Next window in layout order, wrapping; with a count, window number count or the last | `editor_windows` |
| `[count]<C-w>W` | `window.previous` | Previous window in layout order, wrapping; with a count, as `<C-w>w` | `editor_windows` |
| `<C-w>p` | `window.last_accessed` | The window that was current before the last change, if it still exists | `editor_windows` |
| `[count]<C-w>c` | `window.close` | Close the window, or window count; its space goes to the window after it, or before it when last | `editor_windows`, `domain_layout` |
| `<C-w>o` | `window.only` | Close every other window of the tab page | `editor_windows` |
| `<C-w>=` | `window.equalize` | Make the windows of every split the same size, the sidebars' widths and the panel's height kept | `editor_windows`, `domain_layout`, `editor_plugins` |
| `[count]<C-w>q` | `window.quit` | `:q` on the window, or on window count | `editor_windows` |
| `[count]<C-w><C-s>`, `[count]<C-w><C-v>`, `[count]<C-w><C-h>`, `<C-j>`, `<C-k>`, `<C-l>`, `[count]<C-w><C-w>`, `<C-w><C-p>`, `<C-w><C-o>`, `[count]<C-w><C-q>` | as the plain second key | The same command with Ctrl held on the second key, in a file window and in the explorer tree | `editor_windows`, `editor_explorer`, `domain_keymap` |

Messages: `E36: Not enough room` when the current window has fewer than three text rows or cannot give both windows one text column plus the number column and a separator; `E444: Cannot close last window` from `<C-w>c` and `:close` on the last window of the last tab page; `Already only one window` from `<C-w>o` and `:only`.

Differences from Neovim: `splitbelow` and `splitright` are off and not options; a window's minimum height is one text row and its minimum width one column plus the number column, with no `winminheight` or `winminwidth`; a fixed-width window (`winfixwidth`) is a sidebar and a fixed-height one (`winfixheight`) the panel (Layout slots below), neither set by `:set`; `<C-w>` followed by a count (`<C-w>3j`) is not read, only a count before `<C-w>`; `<C-w>t b x r R H J K L T`, `<C-w>+ - < >`, `:resize`, the held-Ctrl forms of those commands, and scroll binding arrive with later changes; the neighbour for `<C-w>h j k l` is the window whose layout rectangle overlaps the cursor's row or code point column, not its display column. `<C-w><C-c>` is not bound: as Vim's help says of it (`CTRL-W_CTRL-C`), the `<C-c>` cancels the window command, with the count typed before it, and does not close the window.

## Scrolling

Each command scrolls the current window and then keeps the cursor on a line the window shows, `scrolloff` lines in from an edge that is not the start or the end of the buffer, in its wanted column. They work in normal mode and the three visual modes, where the cursor end of the selection moves; `<PageDown>` and `<PageUp>` work in insert mode too.

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| `[count]<C-f>`, `[count]<PageDown>` | `scroll.page_down` | Forward count pages of the text rows minus two; with the last line shown, the cursor goes to the last line | `editor_scroll`, `smoke_editor` |
| `[count]<C-b>`, `[count]<PageUp>` | `scroll.page_up` | Back count pages | `editor_scroll` |
| `[count]<C-d>` | `scroll.half_page_down` | Down by `scroll` lines, half the window when 0, the cursor moving as far; a count sets `scroll` first | `editor_scroll` |
| `[count]<C-u>` | `scroll.half_page_up` | Up by `scroll` lines, the cursor moving as far; a count sets `scroll` first | `editor_scroll` |
| `[count]<C-e>` | `scroll.line_down` | The view count lines down, the cursor staying on its line while it is shown | `editor_scroll` |
| `[count]<C-y>` | `scroll.line_up` | The view count lines up, the cursor staying on its line while it is shown | `editor_scroll` |
| `[count]zt` | `scroll.cursor_top` | The cursor line, or line count, at the top of the window, with `scrolloff` | `editor_scroll` |
| `[count]zz` | `scroll.cursor_middle` | The cursor line, or line count, in the middle of the window | `editor_scroll` |
| `[count]zb` | `scroll.cursor_bottom` | The cursor line, or line count, at the bottom of the window, with `scrolloff` | `editor_scroll` |

Differences from Neovim: the view never scrolls past the last line, so the window never shows filler rows after the end of a buffer longer than the window, and `<C-e>` and `<C-f>` stop at the last full window (`<C-f>` there moves the cursor to the last line, where Neovim's repeated `<C-f>` ends); `<C-b>` at the first line changes nothing instead of beeping; `scroll` is global, not local to the window, and `:set scroll` is not implemented yet; `z<CR>`, `z.`, `z-`, `zh`, `zl`, `zs`, `ze`, `<S-Down>`, `<S-Up>`, and smooth scrolling are not implemented.

## Tab pages

Each tab page holds its own window layout; from two tab pages their numbers stand at the right end of the buffer tabs row (Status bar and buffer tabs below).

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| `[count]<C-PageDown>` | `tab.next` | Next tab page, wrapping; with a count, tab page count, or nothing when there is none | `editor_tabs`, `domain_keymap` |
| `[count]<C-PageUp>` | `tab.previous` | Count tab pages back, wrapping | `editor_tabs`, `domain_keymap` |
| `g<Tab>` | `tab.last_accessed` | The tab page current before the current one; nothing when it closed or there is none | `editor_tabs`, `domain_keymap` |
| `[count]gt`, `[count]gT` | `tabline.next`, `tabline.previous` | Under `option.gt buffers` (shipped): the next buffer tab, wrapping, with a count the count-th tab of the row or nothing when there is none, and count buffer tabs back, the tab page staying, `E37` for a modified buffer as `:bn`; under `option.gt tabpages` (without a configuration, Vim's) as `<C-PageDown>` and `<C-PageUp>` | `editor_tabs`, `domain_keymap` |
| `option.gt` | none | `buffers` or `tabpages`; `file:line: unknown gt mode WORD` for another word | `domain_options_config` |

Each tab page's number is a space, the number, and a space, the current one in `TabLineSel` (`editor_tabs`, `adapters_tab_bar`).

Differences from Neovim: the top row lists buffers rather than tab pages, as bufferline plugins do, and a tab page shows only its number, so `gt` and `gT` follow the buffer tabs unless `option.gt tabpages` is set; `:tabm[ove]`, `:tabs`, and `:tabdo` arrive with later changes.

## Status bar and buffer tabs

One status bar on the row above the message row serves every window, as `laststatus=3`, and the top row lists the buffers, as the bufferline plugins do; neither is an option yet.

| Part | Behavior | Test |
| --- | --- | --- |
| Mode pill | `NORMAL`, `INSERT`, `VISUAL`, `V-LINE`, `V-BLOCK`, `REPLACE`, `O-PENDING`, or `COMMAND` in `StatusLineModeNormal`, `Insert`, `Visual`, `Replace`, or `Command`; priority 100 | `adapters_status_bar` |
| File | The path, the scratch title, or `[No Name]`, and the `modified` icon when modified; priority 90, cut last | `adapters_status_bar`, `editor_screen` |
| Branch, diagnostics, `lsp` | Empty until git and language services fill them, then the branch after the `git` icon (40), each count above zero after its icon in its `Diagnostic` group (70, the current buffer's at the idle tick), and the server's name with its state (`starting`, `indexing 42%`, `stopped`, `crashed :LspRestart`, `untrusted :LspStart`, nothing when ready) in `StatusLineLspStarting` (starting, indexing), `Ready`, `Error` (crashed), or `StatusLine` (stopped, untrusted) (60) | `adapters_status_bar`, `editor_lsp` |
| Plugin segments | In the order first set, before the `lsp` slot, each at its own priority, 10 for `set_status` | `adapters_status_bar`, `editor_plugins` |
| Progress | While long work runs (a language server's `$/progress`), its title and message (40 bytes) and a ten-cell bar before the `lsp` slot: a `━` per ten percent in `StatusLineLspReady`, the rest `─`; without a percent three cells moving one per report, left out under `option.reducedmotion true`; `#` and `-` in `StatusLine` under `NO_COLOR` (35) | `adapters_status_bar`, `adapters_language_gateway` |
| File type, encoding | The filetype when there is one (30) and `utf-8` (20) | `adapters_status_bar` |
| Position, percent | `row:col` (80) and `All`, `Top`, `Bot`, or `N%` (50) | `adapters_status_bar`, `editor_screen` |
| Narrow bar | Whole segments dropped, lowest priority first and the later of equals first, until the rest fit | `adapters_status_bar` |
| Buffer tabs | From two listed file buffers or two tab pages: a tab per file buffer with its icon, name, and modified icon, the current window's in `TabLineSel`; the tabs that do not fit counted as ` <N ` and ` N> `; the tab-page numbers at the right end | `adapters_tab_bar`, `editor_tabs` |

Differences from Neovim: there is no `laststatus`, `showtabline`, `statusline`, or `tabline` option, no winbar, and no per-window status line; tabs are not clickable and equal file names are not told apart; the encoding is always `utf-8`.

## File explorer

The built-in `explorer` plugin is Carat's own, not part of Neovim; its keys follow the conventions common to Neovim's tree plugins, such as nvim-tree and neo-tree, so they feel familiar, but they are not copied from any one of them. Every row is covered by `test/editor_explorer.rb`, and the tree model by `test/plugins_explorer.rb`.

| Keys | Where | Action name | Behavior |
| --- | --- | --- | --- |
| `<leader>e`, `:Explorer` | normal mode | `plugin.explorer.toggle` | Open the tree in the left sidebar slot (the right one with `plugin.explorer.side right`) at `plugin.explorer.width` unless the slot's width option is set, focus it when it is open or its slot is hidden, close it when it is current |
| `:ExplorerFind` | command line | none | Open or focus the tree with the current file revealed and the cursor on it |
| `l` | tree | `plugin.explorer.open` | Open the file in the previously used file window, or expand the directory and leave an expanded one expanded |
| `h` | tree | `plugin.explorer.collapse` | Collapse the directory, or go to the parent's line |
| `<CR>`, `o` | tree | `plugin.explorer.toggle_dir` | Toggle the directory, or open the file in the previously used file window |
| `s`, `v`, `t` | tree | `plugin.explorer.open_split`, `open_vsplit`, `open_tab` | Open the file in a horizontal split, a vertical split, or a new tab page |
| `a` | tree | `plugin.explorer.create` | Prompt for a name and create a file, or a directory when it ends with `/`, in the entry's directory |
| `r` | tree | `plugin.explorer.rename` | Prompt for a new name, starting from the current one, and rename in place |
| `d` | tree | `plugin.explorer.delete` | Ask `Delete name? (y/n)` and delete a file or an empty directory |
| `R`, `H` | tree | `plugin.explorer.refresh`, `toggle_hidden` | List again from disk; show or hide dot files |
| `-`, `C` | tree | `plugin.explorer.root_up`, `set_root` | Root up one directory; root at the directory under the cursor |
| `q`, `?` | tree | `plugin.explorer.close`, `help` | Close the tree; show the keys in the message row |

`j`, `k`, `gg`, `G`, counts, `<C-w>` commands, and `:` work in the tree as in any window. The tree's first row is its slot's header, and `<leader>ls` hides and shows it with its cursor (Layout slots). The tree keeps its width on `<C-w>=` and on resizes, and `:q` in it closes only the tree. Not implemented: copy, cut, and paste of files, bookmarks, git status, recursive delete, trash, and live updates when files change outside the editor.

## File finder

The built-in `finder` plugin is Carat's own, not part of Neovim; its keys follow the conventions of Neovim's fuzzy finders, such as telescope and fzf-lua. Every row is covered by `test/editor_finder.rb`, and the ranking by `test/plugins_finder_matcher.rb`.

| Keys | Where | Action name | Behavior |
| --- | --- | --- | --- |
| `<leader>ff`, `<C-p>` | normal mode | `plugin.finder.open` | List the files below the working directory, without the names of `plugin.finder.ignore` (`.git build tmp`), links leading out of it, or the inside of linked directories, in a float titled `Files N/M` with the `> ` prompt on the command line |
| typed text | finder | none | Filter by a fuzzy match of the path ignoring case, best first: the file name, word starts, and runs score higher, a shorter path breaks a tie; `No match` when nothing matches |
| `<C-n>`, `<Down>`, `<C-p>`, `<Up>` | finder | `plugin.finder.next`, `previous` | Move the highlight, stopping at the ends |
| `<CR>` | finder | none | Open the highlighted file in the editing window and close the finder; nothing with no match |
| `<C-x>`, `<C-s>`, `<C-v>`, `<C-t>` | finder | `plugin.finder.open_split`, `open_vsplit`, `open_tab` | Open the highlighted file in a horizontal split, a vertical split, or a new tab page |
| `<Esc>`, `<BS>` on the empty prompt | finder | none | Close the finder and open nothing |
| none | finder, 100 columns or more | none | Preview the first rows of the highlighted file in a second float titled with its path |

## Syntax highlighting

The filetype of a buffer comes from its name (`ruby` for `.rb`, `.rake`, `.gemspec`, `.ru`, `Gemfile`, `Rakefile`, `config.ru`) or from a `#!` line naming `ruby`, directly or through `env` (`domain_filetype`). A plugin that declares the filetype tokenizes it, the built-in `ruby` plugin for Ruby (`plugins_ruby`), and the visible rows are drawn in Neovim's standard groups (`Comment`, `String`, `Type`, ...) colored by the theme (`editor_syntax`, `adapters_screen_presenter`). Differences from Neovim: there are no syntax files, `:highlight`, `:colorscheme`, or `syntax sync` options; a tokenizer works line by line with an integer state, so a construct the Ruby plugin cannot encode (a third nested string or heredoc at the end of a line) is highlighted less precisely after it; the colors come from the options of Themes below.

## Themes

The editor knows 56 UI groups: Neovim's 41 by its names (`Normal`, `LineNr`, `StatusLine`, ... `CursorLine`, `Pmenu`, `NormalFloat`, `DiffAdd`, `DiagnosticError`, ...), the thirty syntax groups, thirteen file-icon groups named as nvim-web-devicons names them (`DevIconRb`, ...; the explorer's icons are drawn in them), and six markup groups named as Neovim's tree-sitter captures (`@markup.heading`, ...); the status bar's eight and the indent guides' two, `IblIndent` and `IblScope` as indent-blankline names them, follow Neovim's 41, then `FloatTitle` and Neovim's popup menu groups `PmenuMatch`, `PmenuMatchSel`, `PmenuExtra`, and `PmenuExtraSel`. Every shipped palette meets WCAG AA on its own background and on its cursor line, 4.5:1 for text and 3:1 for decorations, at 24-bit and at 256 colors (`domain_theme`). At 256 colors a palette may give its own index where the nearest one would lose contrast or hue; at 16 colors a group may use an attribute in place of a color the basic set lacks, reverse video for the selection and a menu's selected row and underline for the cursor line (`adapters_screen_presenter`).

| Option | Values | Effect | Problem | Tests |
| --- | --- | --- | --- | --- |
| `option.theme` | Carat's own `carat-dark` (default) and `carat-light`, then `one_dark`, `one_light`, `dark_plus`, `light_plus` | The palette every group takes its colors from, each with its own syntax colors | `file:line: unknown theme x` | `domain_theme`, `adapters_screen_presenter` |
| `option.background` | `terminal` (default), `theme` | `terminal` leaves `Normal` and the background to the terminal; `theme` paints the palette's background and text color under every cell, the cleared screen and scrolled-in rows included, which needs a terminal with background color erase | `file:line: unknown background x` | `domain_theme`, `adapters_screen_presenter` |

Differences from Neovim: `background` in Neovim names `dark` or `light` and lets a color scheme choose; Carat's names who paints the background, since `theme` chooses the palette. Neither is set by `:set` yet (`Not implemented: :set background`). The theme is read once at startup; there is no `:colorscheme` or `:highlight`.

## Cursor line and cursor shape

With `cursorline` on, the cursor's line in the current window is drawn over `CursorLine` from the end of the gutter to the window's edge, each cell keeping its group's color and a group with a background of its own (the selection, search matches) keeping it, the number in `CursorLineNr`; at 16 colors the line is underlined (`adapters_frame_presenter`, `adapters_screen_presenter`). Text on the cursor line keeps 3:1 contrast in every palette, as on the selection (`domain_theme`). The cursor is a steady block in normal, visual, operator-pending, and command-line mode, a bar in insert mode, and an underline in replace mode; leaving the editor by any path, `SIGINT` and `SIGTERM` included, gives the terminal its own cursor shape back (`DECSCUSR` 0) and shows the cursor (`adapters_screen_presenter`, `smoke_editor`).

| Option | Values | Effect | Problem | Tests |
| --- | --- | --- | --- | --- |
| `option.cursorline`, `:set cursorline` (`cul`) | `false` (Neovim's default), `true` (shipped) | Draws the cursor line of the current window | `file:line: option.cursorline takes true or false` | `adapters_frame_presenter`, `domain_options_config`, `editor_search` |

Differences from Neovim: `cursorline` is global and drawn in the current window only, where Neovim's is window-local and drawn in every window that sets it; there is no `cursorlineopt` or `CursorLineSign`; the shapes are fixed, with no `guicursor`, and an operator waits with the block cursor, where Neovim's default shows an underline; replace mode itself (`R`) arrives with a later change.

## Indent guides

Neovim draws no indent guides; Carat draws them as the indent-blankline plugin does, by indentation alone. With `indentguides` on, a file window draws the guide character at each `shiftwidth` level of a line's leading whitespace, in `IblIndent`, and the guide of the cursor's block in `IblScope`; both groups are decorations held to 3:1 in every palette, on the cursor line too (`domain_theme`). Each case is a row of the table in `adapters_indent_guides`.

| Case | Effect | Tests |
| --- | --- | --- |
| Levels | A guide at every multiple of `shiftwidth` before a line's first non-blank, `tabstop` when `shiftwidth` is 0, a tab counted to the next multiple of `tabstop` | `adapters_indent_guides` |
| Scrolled sideways | The guides move with the window's horizontal scroll | `adapters_indent_guides` |
| Blank lines | A blank or whitespace-only line shows the guides of the smaller of the nearest non-blank lines' indents above and below, none past 1000 lines or the buffer's ends | `adapters_indent_guides` |
| The cursor's block | In the current window, the guide at the deepest level below the cursor line's indent, over the rows around it indented past that level, is in `IblScope`; on a line of no indent none is | `adapters_indent_guides` |
| Cursor line | The guides on the cursor line take the cursor-line layer of their groups | `adapters_indent_guides` |
| Windows | File windows only: a plugin's window, a float, and the start screen show none | `adapters_indent_guides` |

| Option | Values | Effect | Problem | Tests |
| --- | --- | --- | --- | --- |
| `option.indentguides` | `false` (fresh options, as Neovim), `true` (shipped) | Draws the guides | `file:line: option.indentguides takes true or false` | `domain_options_config`, `adapters_indent_guides` |
| `option.indentguides.char` | One character one column wide, not a control; `┊` by default | The guide character; with `option.icons ascii` one outside ASCII is drawn as `\|` | `file:line: option.indentguides.char takes one character one column wide` | `domain_options_config`, `adapters_indent_guides` |

Differences from indent-blankline: the cursor's block is found by indentation, not by tree-sitter scope, and only in the current window; there is one color for every level; the options are read at startup, with no `:set` or `:IBLToggle`.

## Start screen

Started with no argument or on a directory, Carat shows a start screen over the empty buffer in place of Neovim's intro message: a point, the gem's table, crown, and pavilion, a sparkle at its top, and then `c a r a t` with three key hints, six frames 0.125 s apart, the last staying until a key, which ends the screen and is handled as usual (`editor_start_screen`, every frame in its snapshot).

| Option | Values | Effect | Problem | Tests |
| --- | --- | --- | --- | --- |
| `option.startscreen` | `true` (default), `false` | Whether the start screen shows; off, the editor starts on the empty buffer and a directory argument is refused as by `:e` | `file:line: option.startscreen takes true or false` | `editor_start_screen`, `domain_options_config` |
| `option.reducedmotion` | `false` (default), `true` | Shows the last frame at once, with no animation | `file:line: option.reducedmotion takes true or false` | `editor_start_screen`, `domain_options_config` |
| `NO_COLOR` (environment) | set and not empty | The start screen in ASCII glyphs and the `Normal` group; the rest of the editor keeps the theme | none | `editor_start_screen` |

The gem takes the theme's `Operator`, `Function`, and `Keyword` colors, the sparkle `Type`, the wordmark `Title`, and the hints `Special` and `Comment`. A window smaller than 20 columns or 15 rows shows only the wordmark. Differences from Neovim: there is no `:intro`, and the intro's `shortmess` flag `I` is `option.startscreen`; neither option is set by `:set` yet (`Not implemented: :set startscreen`).

## Layout slots

Carat's own, in place of the sidebar and panel plugins Neovim users add. Each tab page has a left and a right sidebar slot and a bottom panel slot; a plugin's view (the explorer's tree, a test plugin's lists) opens in the slot its side names, and a slot shows one view at a time in one window, a view opened in a slot with a window taking that window and the view shown before let go. The sidebars span the tab page's height at its edges and keep their width; the panel spans the width between them above the status bar and keeps its height. Each slot window's first row is a header listing the titles of the views opened in it, the shown one in `TabLineSel`, the others in `TabLine`, the rest in `TabLineFill`. A slot window closed by `:q`, `<C-w>c`, or its plugin, or one that took a file, empties the slot (`editor_slots`, `editor_plugins`, `domain_slot`, `domain_layout`).

| Keys or line | Action name | Behavior | Problem | Tests |
| --- | --- | --- | --- | --- |
| left sidebar | none | A view at side `left`, such as the explorer, at the tab page's left edge, full height | `E36: Not enough room` | `editor_slots`, `editor_plugins`, `domain_layout` |
| right sidebar | none | A view at side `right` at the right edge, full height | `E36: Not enough room` | `editor_plugins`, `domain_layout` |
| bottom panel | none | A view at side `bottom` (plugin API 2.4) across the bottom between the sidebars | `E36: Not enough room` | `editor_plugins`, `domain_layout` |
| `option.layout.left_width`, `option.layout.right_width` | none | The sidebar's width in columns, 0 to 500, 0 by default: 0 keeps the width the view asks for (`plugin.explorer.width`) | `file:line: option.layout.left_width takes a number from 0 to 500` | `editor_slots`, `editor_plugins`, `domain_options_config` |
| `option.layout.panel_height` | none | The panel's height in rows, header and status row included, 0 to 500, 0 by default keeping the view's | `file:line: option.layout.panel_height takes a number from 0 to 500` | `editor_plugins`, `domain_options_config` |
| `<leader>ls` | `layout.toggle_sidebar` | Hide the left sidebar, its view and cursor kept, another window current if it was; again, show it with its size, the focus staying; its plugin opening the view shows it too | `No view in the left sidebar`; `E444: Cannot close last window` | `editor_slots` |
| `<leader>lr` | `layout.toggle_right_sidebar` | The same for the right sidebar | `No view in the right sidebar` | `editor_slots` |
| `<leader>lp` | `layout.toggle_panel` | The same for the panel | `No view in the panel` | `editor_slots`, `editor_plugins` |

Not implemented: choosing a view from the header, moving a view between slots, resizing a slot with keys, and a core view for the panel.

## Breadcrumbs

In place of Neovim's `winbar` option and the breadcrumb plugins (such as nvim-navic) Neovim users add. Each file window, a window showing a buffer that is not a plugin's scratch buffer, gives its first row to a winbar: one space, the buffer's path (the scratch title or `[No Name]`), and, when the language server of the current window's buffer offers `documentSymbolProvider` and its answer for that buffer is held, ` > ` and each symbol whose range holds the window's cursor row, outermost first; the current window's winbar in `TabLineSel`, the others' in `TabLine`, the rest of the row in `TabLineFill`. Slot and plugin windows show none and are not counted; a window of one text row keeps its row; a split count still gives the new window that many text rows under its winbar.

| Keys or line | Action name | Behavior | Problem | Tests |
| --- | --- | --- | --- | --- |
| one file window | none | No winbar under `auto` | none | `editor_breadcrumbs` |
| two or more file windows | none | A winbar on each file window under `auto`, gone again when one is left | none | `editor_breadcrumbs`, `editor_cmdline`, `editor_plugins` |
| `option.breadcrumbs` | none | `auto` (default), `always` (every file window), or `never` | `file:line: unknown breadcrumbs mode WORD` | `editor_breadcrumbs`, `domain_options_config` |
| symbol path | none | The symbols spanning the cursor row, from a hierarchical or flat answer, at most 500 symbols, 8 levels, names without control characters and cut to 40 bytes; a window on another buffer shows its path only | none | `editor_breadcrumbs` |
| symbol requests | none | `textDocument/documentSymbol` at an idle tick, only while a winbar shows, once per text of the current window's buffer, one in flight; an edit meanwhile is asked after the answer; unanswered for two seconds it is cancelled and its late answer dropped; a key never waits for one | none | `editor_breadcrumbs` |

Differences from Neovim: Neovim's `winbar` is an empty statusline format by default and shows nothing; Carat's has no format, is read from `option.breadcrumbs` only (`:set breadcrumbs` answers `Not implemented: :set breadcrumbs`), and shows no symbol kinds or icons. Not implemented: picking a symbol from the winbar, and symbols for a buffer other than the current window's until it becomes current.

## Key hints and command palette

Carat's own, in place of the which-key and command palette plugins Neovim users add. Keys that only begin bindings (the leader, `g`, `z`, `<C-w>`), left with no key for `option.keyhints.delay` milliseconds, show a bordered panel centered at the bottom titled with the keys and their group name, one row per next key: its action's description, a group's name, the first segment shared by the actions under an unnamed prefix (`group` when they share none), or the keys a remap replays, in columns when taller than the screen. The next key closes it and is handled as usual. A prefix that is bound itself shows no hints, as `timeoutlen` resolves it; insert and command-line modes show none (`editor_key_hints`, `domain_keymap`).

| Keys or line | Action name | Behavior | Problem | Tests |
| --- | --- | --- | --- | --- |
| `option.keyhints.delay` | none | Milliseconds before the hints, 0 to 10000, 300 by default; 0 turns them off | `file:line: option.keyhints.delay takes a number from 0 to 10000` | `editor_key_hints`, `domain_options_config` |
| `keymap.group <keys> <name>` | none | Names a normal-mode prefix in the hints, a later line winning; read from a project file too, as it binds nothing; the defaults name `<leader>w` windows, `q` quit, `f` files, `b` buffers, `d` docs, `l` layout, `g` goto, `z` view, `<C-w>` window | `file:line: keymap.group takes keys and a name` | `editor_key_hints`, `domain_keymap` |
| `<leader>p`, `<F1>` | `palette.open` | The `>` prompt on the command line and a "Commands" float of every core action, enabled plugin action, and ex command (`:` and its full name), each row its name (29 characters whole), its description dimmed in `PmenuExtra`, and its first normal-mode key on the right, a control key in caret notation (`^Ws`); typing filters by the completion popup's fuzzy match over the name and description (a leading `:` ignored), the matched characters drawn in `PmenuMatch` (`PmenuMatchSel` and `PmenuExtraSel` on the selected row), "No match" when none; `<C-n>` and `<C-p>` move the selection; Enter runs it, an action as its key would (an operator then waits for its motion), an ex command as typed after `:`; Esc closes | none | `editor_palette`, `use_cases_actions` |

Differences from Neovim: Neovim's `F1` opens `:help`, which Carat does not have.

## Float borders

Every float has one blank column of padding inside its left and right sides. Bordered floats (hover, the definition peek, the finder, the palette, the key hints, a plugin's float) and the notification boxes are drawn in the `option.winborder` style, a float's title centered on its top edge in `FloatTitle` and cut between the corners when longer; the completion popup stays borderless, as Neovim's popup menu (`editor_floats`, `editor_messages`).

| Keys or line | Action name | Behavior | Problem | Tests |
| --- | --- | --- | --- | --- |
| `option.winborder` | none | `rounded` (default, `╭╮╰╯─│`), `single` (`┌┐└┘─│`), `double` (`╔╗╚╝═║`), `solid` (blank cells in `FloatBorder`), or `none` (no edge and no title, the padding kept); with `option.icons ascii` or `NO_COLOR` set the styles with lines draw `+`, `-`, and `\|` | `file:line: unknown border style WORD` | `domain_options_config`, `editor_floats` |

Differences from Neovim: Neovim's `winborder` is empty by default, drawing no border, and also takes `bold`, `shadow`, and a list of characters; Carat's is `rounded` by default, takes none of those, and is read from `option.winborder` only (`:set winborder` answers `Not implemented: :set winborder`).

## Options read so far

`number`, `relativenumber`, `tabstop`, `shiftwidth`, `expandtab`, `autoindent`, `scroll`, `scrolloff`, `timeoutlen`, `keyhints.delay` (Key hints), `layout.left_width`, `layout.right_width`, and `layout.panel_height` (Layout slots), `breadcrumbs` (Breadcrumbs), `undolevels`, `icons`, `theme`, and `background` (Themes), `startscreen` and `reducedmotion` (Start screen), `indentguides` and `indentguides.char` (Indent guides), `winborder` (Float borders), from the `option.*` lines of the configuration files; `ignorecase`, `smartcase`, `hlsearch`, `incsearch`, and `cursorline` from those lines and `:set` (Neovim's defaults: off, off, on, on, off; the shipped configuration turns `smartcase` and `cursorline` on); `filetype` and `syntax` per buffer, set by `:set`. `scrolloff` is capped at half the window height as in Neovim. `scroll` of 0 scrolls half the window, as in Neovim, but the option is global. `shiftwidth` of 0 uses `tabstop`, as in Neovim.
