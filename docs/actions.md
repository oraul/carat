# Actions

The action names a keymap value may use, in `namespace.action` form. A keymap value that is not an action name is a key sequence in Vim notation to replay. Actions that `config/default.json` already binds but that a later roadmap item implements are listed under Reserved; pressing their keys shows "Not implemented: name".

In normal and operator-pending modes the command grammar classifies an action by its name: `cursor.*` and `motion.*` are motions, which move the cursor on their own and give an operator its range; `operator.delete`, `operator.change`, `operator.yank`, `operator.indent`, and `operator.dedent` are the pending operators, which wait for a motion, a text object, or themselves again for a linewise command; `textobject.*` actions are text objects, usable only after an operator; `register.select` and the four find motions read one more key; every other action, the `window.*` and `tab.*` actions included, completes at once with the count and register typed before it.

## Implemented

| Action | Modes | Effect |
| --- | --- | --- |
| `cursor.left` | normal, operator_pending, insert | Count columns left |
| `cursor.right` | normal, operator_pending, insert | Count columns right; under an operator may reach the end of the line |
| `cursor.up` | normal, operator_pending, insert | Count rows up, keeping the wanted column; linewise |
| `cursor.down` | normal, operator_pending, insert | Count rows down, keeping the wanted column; linewise |
| `cursor.line_start` | normal, operator_pending | Column 0 |
| `cursor.first_nonblank` | normal, operator_pending | First non-blank character |
| `cursor.line_end` | normal, operator_pending | End of the line count minus one rows down; inclusive; wanted column at the line end |
| `cursor.buffer_start` | normal, operator_pending | Line count, or the first line; linewise |
| `cursor.buffer_end` | normal, operator_pending | Line count, or the last line; linewise |
| `motion.find_forward` | normal, operator_pending | Count-th occurrence of the next key to the right; inclusive |
| `motion.find_backward` | normal, operator_pending | Count-th occurrence of the next key to the left |
| `motion.till_forward` | normal, operator_pending | Before the count-th occurrence to the right; inclusive |
| `motion.till_backward` | normal, operator_pending | After the count-th occurrence to the left |
| `motion.repeat_find` | normal, operator_pending | Repeat the last find or till |
| `motion.repeat_find_reverse` | normal, operator_pending | Repeat it the other way |
| `motion.line_down` | normal, operator_pending | Count lines down, first non-blank; linewise |
| `motion.line_up` | normal, operator_pending | Count lines up, first non-blank; linewise |
| `motion.line` | normal, operator_pending | Count minus one lines down, first non-blank; linewise |
| `motion.word_forward` | normal, operator_pending | Start of the next word; under an operator stops at the line end |
| `motion.big_word_forward` | normal, operator_pending | Start of the next WORD |
| `motion.word_backward` | normal, operator_pending | Start of the current or previous word |
| `motion.big_word_backward` | normal, operator_pending | Start of the current or previous WORD |
| `motion.word_end` | normal, operator_pending | End of the current or next word; inclusive |
| `motion.big_word_end` | normal, operator_pending | End of the current or next WORD; inclusive |
| `motion.word_end_backward` | normal, operator_pending | End of the previous word; inclusive |
| `motion.big_word_end_backward` | normal, operator_pending | End of the previous WORD; inclusive |
| `motion.sentence_forward` | normal, operator_pending | Start of the next sentence |
| `motion.sentence_backward` | normal, operator_pending | Start of the current or previous sentence |
| `motion.paragraph_forward` | normal, operator_pending | Next empty line, or the end of the buffer |
| `motion.paragraph_backward` | normal, operator_pending | Previous empty line, or the start of the buffer |
| `motion.screen_top` | normal, operator_pending | Line count from the top of the window; linewise |
| `motion.screen_middle` | normal, operator_pending | Middle of the visible lines; linewise |
| `motion.screen_bottom` | normal, operator_pending | Line count from the bottom of the window; linewise |
| `operator.delete` | normal, operator_pending | Delete the range into the register; doubled, count lines |
| `operator.change` | normal, operator_pending | Delete the range into the register and enter insert mode; doubled, count lines |
| `operator.yank` | normal, operator_pending | Copy the range into the register; doubled, count lines |
| `operator.indent` | normal, operator_pending | Indent the lines of the range by shiftwidth; doubled, count lines |
| `operator.dedent` | normal, operator_pending | Dedent the lines of the range by shiftwidth; doubled, count lines |
| `operator.delete_char` | normal | Delete count characters under and after the cursor |
| `operator.substitute_char` | normal | Delete count characters and enter insert mode |
| `operator.substitute_line` | normal | Change count lines, keeping the indent with autoindent |
| `operator.change_to_end` | normal | Change to the end of the line, count minus one lines down |
| `operator.delete_to_end` | normal | Delete to the end of the line, count minus one lines down |
| `operator.yank_to_end` | normal | Yank to the end of the line, count minus one lines down |
| `operator.join` | normal | Join count lines, at least two |
| `operator.put_after` | normal | Put the register after the cursor count times |
| `operator.put_before` | normal | Put the register before the cursor count times |
| `register.select` | normal | Read the next key as the register name for the command |
| `textobject.inner_word` | operator_pending | The word under the cursor, or the blanks |
| `textobject.a_word` | operator_pending | The word and the blanks after it, or before it |
| `textobject.inner_big_word` | operator_pending | The WORD under the cursor, or the blanks |
| `textobject.a_big_word` | operator_pending | The WORD and the blanks after it, or before it |
| `textobject.inner_sentence` | operator_pending | The sentence without the blanks after it |
| `textobject.a_sentence` | operator_pending | The sentence with the blanks after it, or before it |
| `textobject.inner_paragraph` | operator_pending | The paragraph's lines, or the empty lines; linewise |
| `textobject.a_paragraph` | operator_pending | The paragraph and the empty lines after it, or before it; linewise |
| `textobject.inner_paren`, `textobject.a_paren` | operator_pending | Inside, or including, the enclosing `()` |
| `textobject.inner_bracket`, `textobject.a_bracket` | operator_pending | Inside, or including, the enclosing `[]` |
| `textobject.inner_brace`, `textobject.a_brace` | operator_pending | Inside, or including, the enclosing `{}` |
| `textobject.inner_angle`, `textobject.a_angle` | operator_pending | Inside, or including, the enclosing `<>` |
| `textobject.inner_double_quote`, `textobject.a_double_quote` | operator_pending | Inside, or including, the `"` string on the line |
| `textobject.inner_single_quote`, `textobject.a_single_quote` | operator_pending | Inside, or including, the `'` string on the line |
| `textobject.inner_backtick`, `textobject.a_backtick` | operator_pending | Inside, or including, the backtick string on the line |
| `mode.insert` | normal | Insert before the cursor |
| `mode.insert_after` | normal | Insert after the cursor |
| `mode.insert_line_start` | normal | Insert at the first non-blank character |
| `mode.insert_line_end` | normal | Insert after the last character |
| `mode.insert_open_below` | normal | Open a line below and insert |
| `mode.insert_open_above` | normal | Open a line above and insert |
| `mode.normal` | insert, cmdline, operator_pending | Back to normal mode, cancelling a pending command |
| `mode.cmdline` | normal | Enter command-line mode |
| `insert.newline` | insert | Split the line at the cursor |
| `insert.backspace` | insert | Delete before the cursor |
| `insert.delete` | insert | Delete under the cursor |
| `insert.tab` | insert | Insert a tab or spaces |
| `cmdline.execute` | cmdline | Run the command line |
| `cmdline.backspace` | cmdline | Remove the last character, or leave when empty |
| `message.quit_hint` | normal | Show the quit hint |
| `window.split` | normal | Split the window horizontally, the new window above; a count is its text rows |
| `window.vsplit` | normal | Split the window vertically, the new window to the left; a count is its columns |
| `window.left`, `window.down`, `window.up`, `window.right` | normal | Go to the neighbour window in that direction, count times |
| `window.next` | normal | Next window in layout order, wrapping; a count is a window number |
| `window.previous` | normal | Previous window in layout order, wrapping; a count is a window number |
| `window.last_accessed` | normal | Back to the previously used window |
| `window.close` | normal | Close the window, or window count; the last window of the last tab page reports E444 |
| `window.only` | normal | Close every other window of the tab page |
| `window.equalize` | normal | Make the windows of every split the same size, fixed-width windows kept |
| `window.quit` | normal | `:q` on the window, or on window count |
| `tab.next` | normal | Next tab page, wrapping; a count is a tab page number |
| `tab.previous` | normal | Count tab pages back, wrapping |

## Reserved

`history.undo`, `history.redo`, `history.repeat`, `mode.visual`, `mode.visual_line`, `mode.visual_block`, `search.forward`, `search.backward`, `search.next`, `search.previous`.
