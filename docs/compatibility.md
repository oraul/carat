# Neovim compatibility

Every Neovim command Carat implements has a row here and a table-driven test. The test column names the `test/*.rb` program whose table or assertions cover the row. Commands from later roadmap items are not listed until they land; pressing a key bound to one of them shows a "Not implemented" message.

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

Differences from Neovim: `startofline` is off, so `gg G H M L` keep the wanted column; keyword characters are ASCII letters, digits, underscore, and every code point from U+00C0 upward until `iskeyword` exists; sentence ends are `. ! ?` with optional `) ] " '` before a blank or the line end, and paragraph boundaries are empty lines only (no nroff macros, no form feeds); `H` and `L` take `scrolloff` into account when moving the cursor and ignore it under an operator, as Neovim does; the quit hint names `:q!` because there is one window.

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
| `:q[uit]` | Quit unless modified | `E37` | `use_cases_ex`, `editor_cmdline` |
| `:q[uit]!` | Quit, discarding changes | | `use_cases_ex`, `editor_cmdline` |
| `:wq [file]`, `:wq!` | Write, then quit | as `:w` | `use_cases_ex`, `editor_cmdline` |
| `:e[dit] [file]` | Open file, or reload the current one | `"name" 1L, 3B`, `"name" [New]`, `E37` | `use_cases_ex`, `editor_cmdline` |
| `:e[dit]! [file]` | Open or reload, discarding changes | | `use_cases_ex`, `editor_cmdline` |
| unknown | Report the command | `E492: Not an editor command: name` | `use_cases_ex`, `editor_cmdline` |

Differences from Neovim: `:w` abbreviations other than `w` and `write` are not recognized yet; ranges, `:x`, `:wa`, `:qa`, and `:saveas` arrive with later changes.

## Options read so far

`number`, `relativenumber`, `tabstop`, `shiftwidth`, `expandtab`, `autoindent`, `scrolloff`, and `timeoutlen`, from `config/default.json`. `scrolloff` is capped at half the window height as in Neovim. `shiftwidth` of 0 uses `tabstop`, as in Neovim.
