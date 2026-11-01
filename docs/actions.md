# Actions

The action names a keymap value may use, in `namespace.action` form, or `plugin.<name>.<action>` for a plugin's action. A keymap value that is not an action name is a key sequence in Vim notation to replay. Actions that `config/default.json` already binds but that a later roadmap item implements are listed under Reserved; pressing their keys shows "Not implemented: name". Every name under Implemented and Reserved is registered in the editor's action table, and `test/use_cases_actions.rb` fails when the table and this file differ. A binding whose value is an action name that neither this file nor a registered plugin declares is reported when the configuration loads, with the file name and the JSON path, as `config/default.json: keymaps.normal.zq: unknown action foo.bar`, and is not added.

In normal, operator-pending, and the visual modes the command grammar reads an action by the kind of the handler the action table registered for it: `cursor.*` and `motion.*` are motions, which move the cursor on their own and give an operator its range; `operator.delete`, `operator.change`, `operator.yank`, `operator.indent`, and `operator.dedent` are the pending operators, which wait for a motion, a text object, or themselves again for a linewise command; `textobject.*` actions are text objects, usable after an operator or in a visual mode; `register.select`, the four find motions, and `visual.replace` read one more key; every other action, the `window.*`, `tab.*`, `visual.*`, and `plugin.*` actions included, completes at once with the count and register typed before it. In a visual mode the five operators do not wait: they act on the selection at once, and a motion moves the cursor end of the selection.

In the Modes column, `visual` stands for the three visual maps, `visual`, `visual_line`, and `visual_block`, which bind the same keys. A `plugin.<name>.<action>` action is routed to the plugin that declared it in its manifest; a plugin's default bindings live in its manifest, not in `config/default.json`, and a user binding of the same keys replaces them.

## Implemented

| Action | Modes | Effect |
| --- | --- | --- |
| `cursor.left` | normal, operator_pending, visual, insert | Count columns left |
| `cursor.right` | normal, operator_pending, visual, insert | Count columns right; under an operator may reach the end of the line |
| `cursor.up` | normal, operator_pending, visual, insert | Count rows up, keeping the wanted column; linewise |
| `cursor.down` | normal, operator_pending, visual, insert | Count rows down, keeping the wanted column; linewise |
| `cursor.line_start` | normal, operator_pending, visual | Column 0 |
| `cursor.first_nonblank` | normal, operator_pending, visual | First non-blank character |
| `cursor.line_end` | normal, operator_pending, visual | End of the line count minus one rows down; inclusive; wanted column at the line end |
| `cursor.buffer_start` | normal, operator_pending, visual | Line count, or the first line; linewise |
| `cursor.buffer_end` | normal, operator_pending, visual | Line count, or the last line; linewise |
| `motion.find_forward` | normal, operator_pending, visual | Count-th occurrence of the next key to the right; inclusive |
| `motion.find_backward` | normal, operator_pending, visual | Count-th occurrence of the next key to the left |
| `motion.till_forward` | normal, operator_pending, visual | Before the count-th occurrence to the right; inclusive |
| `motion.till_backward` | normal, operator_pending, visual | After the count-th occurrence to the left |
| `motion.repeat_find` | normal, operator_pending, visual | Repeat the last find or till |
| `motion.repeat_find_reverse` | normal, operator_pending, visual | Repeat it the other way |
| `motion.line_down` | normal, operator_pending, visual | Count lines down, first non-blank; linewise |
| `motion.line_up` | normal, operator_pending, visual | Count lines up, first non-blank; linewise |
| `motion.line` | normal, operator_pending, visual | Count minus one lines down, first non-blank; linewise |
| `motion.word_forward` | normal, operator_pending, visual | Start of the next word; under an operator stops at the line end |
| `motion.big_word_forward` | normal, operator_pending, visual | Start of the next WORD |
| `motion.word_backward` | normal, operator_pending, visual | Start of the current or previous word |
| `motion.big_word_backward` | normal, operator_pending, visual | Start of the current or previous WORD |
| `motion.word_end` | normal, operator_pending, visual | End of the current or next word; inclusive |
| `motion.big_word_end` | normal, operator_pending, visual | End of the current or next WORD; inclusive |
| `motion.word_end_backward` | normal, operator_pending, visual | End of the previous word; inclusive |
| `motion.big_word_end_backward` | normal, operator_pending, visual | End of the previous WORD; inclusive |
| `motion.sentence_forward` | normal, operator_pending, visual | Start of the next sentence |
| `motion.sentence_backward` | normal, operator_pending, visual | Start of the current or previous sentence |
| `motion.paragraph_forward` | normal, operator_pending, visual | Next empty line, or the end of the buffer |
| `motion.paragraph_backward` | normal, operator_pending, visual | Previous empty line, or the start of the buffer |
| `motion.screen_top` | normal, operator_pending, visual | Line count from the top of the window; linewise |
| `motion.screen_middle` | normal, operator_pending, visual | Middle of the visible lines; linewise |
| `motion.screen_bottom` | normal, operator_pending, visual | Line count from the bottom of the window; linewise |
| `operator.delete` | normal, operator_pending, visual | Delete the range into the register; doubled, count lines; in visual mode on the selection at once |
| `operator.change` | normal, operator_pending, visual | Delete the range into the register and enter insert mode; doubled, count lines; in visual mode on the selection at once |
| `operator.yank` | normal, operator_pending, visual | Copy the range into the register; doubled, count lines; in visual mode on the selection at once |
| `operator.indent` | normal, operator_pending, visual | Indent the lines of the range by shiftwidth; doubled, count lines; in visual mode on the selection at once |
| `operator.dedent` | normal, operator_pending, visual | Dedent the lines of the range by shiftwidth; doubled, count lines; in visual mode on the selection at once |
| `operator.delete_char` | normal | Delete count characters under and after the cursor |
| `operator.substitute_char` | normal | Delete count characters and enter insert mode |
| `operator.substitute_line` | normal | Change count lines, keeping the indent with autoindent |
| `operator.change_to_end` | normal | Change to the end of the line, count minus one lines down |
| `operator.delete_to_end` | normal | Delete to the end of the line, count minus one lines down |
| `operator.yank_to_end` | normal | Yank to the end of the line, count minus one lines down |
| `operator.join` | normal | Join count lines, at least two |
| `operator.put_after` | normal | Put the register after the cursor count times |
| `operator.put_before` | normal | Put the register before the cursor count times |
| `register.select` | normal, visual | Read the next key as the register name for the command |
| `textobject.inner_word` | operator_pending, visual | The word under the cursor, or the blanks |
| `textobject.a_word` | operator_pending, visual | The word and the blanks after it, or before it |
| `textobject.inner_big_word` | operator_pending, visual | The WORD under the cursor, or the blanks |
| `textobject.a_big_word` | operator_pending, visual | The WORD and the blanks after it, or before it |
| `textobject.inner_sentence` | operator_pending, visual | The sentence without the blanks after it |
| `textobject.a_sentence` | operator_pending, visual | The sentence with the blanks after it, or before it |
| `textobject.inner_paragraph` | operator_pending, visual | The paragraph's lines, or the empty lines; linewise |
| `textobject.a_paragraph` | operator_pending, visual | The paragraph and the empty lines after it, or before it; linewise |
| `textobject.inner_paren`, `textobject.a_paren` | operator_pending, visual | Inside, or including, the enclosing `()` |
| `textobject.inner_bracket`, `textobject.a_bracket` | operator_pending, visual | Inside, or including, the enclosing `[]` |
| `textobject.inner_brace`, `textobject.a_brace` | operator_pending, visual | Inside, or including, the enclosing `{}` |
| `textobject.inner_angle`, `textobject.a_angle` | operator_pending, visual | Inside, or including, the enclosing `<>` |
| `textobject.inner_double_quote`, `textobject.a_double_quote` | operator_pending, visual | Inside, or including, the `"` string on the line |
| `textobject.inner_single_quote`, `textobject.a_single_quote` | operator_pending, visual | Inside, or including, the `'` string on the line |
| `textobject.inner_backtick`, `textobject.a_backtick` | operator_pending, visual | Inside, or including, the backtick string on the line |
| `mode.insert` | normal | Insert before the cursor |
| `mode.insert_after` | normal | Insert after the cursor |
| `mode.insert_line_start` | normal | Insert at the first non-blank character |
| `mode.insert_line_end` | normal | Insert after the last character |
| `mode.insert_open_below` | normal | Open a line below and insert |
| `mode.insert_open_above` | normal | Open a line above and insert |
| `mode.normal` | insert, cmdline, operator_pending, visual | Back to normal mode, cancelling a pending command or leaving the selection for `gv` |
| `mode.cmdline` | normal | Enter command-line mode |
| `mode.visual` | normal, visual | Start charwise visual mode, leave it when it is current, or switch to it from another visual mode |
| `mode.visual_line` | normal, visual | Start linewise visual mode, leave it, or switch to it |
| `mode.visual_block` | normal, visual | Start blockwise visual mode, leave it, or switch to it |
| `visual.reselect` | normal, visual | Select the window's last selection again; in visual mode exchange it with the current one |
| `visual.swap_ends` | visual | Exchange the anchor and the cursor |
| `visual.swap_corner` | visual | In a block, go to the other corner on the same row; otherwise as `visual.swap_ends` |
| `visual.join` | visual | Join the selected lines, at least two |
| `visual.join_raw` | visual | Join the selected lines without inserting or removing blanks |
| `visual.put` | visual | Replace the selection with the register count times; the removed text goes to the unnamed register |
| `visual.put_keep` | visual | Replace the selection with the register count times, leaving every register unchanged |
| `visual.replace` | visual | Replace every selected character with the next key |
| `visual.toggle_case` | visual | Toggle the case of the selected characters |
| `visual.lowercase` | visual | Lower the case of the selected characters |
| `visual.uppercase` | visual | Upper the case of the selected characters |
| `visual.delete_lines` | visual | Delete the selected lines; in a block, the block |
| `visual.delete_to_end` | visual | Delete the selected lines; in a block, from its left edge to the end of every row |
| `visual.change_lines` | visual | Change the selected lines as one, in every kind |
| `visual.change_to_end` | visual | Change the selected lines; in a block, from its left edge to the end of every row |
| `visual.yank_lines` | visual | Yank the selected lines; in a block, the block |
| `visual.insert` | visual | Insert before the selection; in a block, on every row that reaches it when insert mode is left |
| `visual.append` | visual | Append after the selection; in a block, on every row, padding short rows |
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

## Plugins

| Action | Plugin | Default keys | Effect |
| --- | --- | --- | --- |
| `plugin.explorer.toggle` | `explorer` | `<leader>e` | Open the file tree, focus it, or close it when it is focused |
| `plugin.explorer.focus` | `explorer` | none | Open the file tree or focus it |
| `plugin.explorer.open` | `explorer` | `<CR>`, `l` in the tree | Open the file under the cursor in the editing window, or expand the directory |
| `plugin.explorer.collapse` | `explorer` | `h` in the tree | Collapse the directory under the cursor, or go to its parent |
| `plugin.explorer.toggle_dir` | `explorer` | `o` in the tree | Expand or collapse the directory under the cursor, or open the file |
| `plugin.explorer.open_split` | `explorer` | `s` in the tree | Open the file under the cursor in a horizontal split |
| `plugin.explorer.open_vsplit` | `explorer` | `v` in the tree | Open the file under the cursor in a vertical split |
| `plugin.explorer.open_tab` | `explorer` | `t` in the tree | Open the file under the cursor in a new tab page |
| `plugin.explorer.create` | `explorer` | `a` in the tree | Create a file, or a directory with a trailing /, next to the entry |
| `plugin.explorer.rename` | `explorer` | `r` in the tree | Rename the entry under the cursor |
| `plugin.explorer.delete` | `explorer` | `d` in the tree | Delete the file or empty directory under the cursor after confirmation |
| `plugin.explorer.refresh` | `explorer` | `R` in the tree | List the tree again from disk |
| `plugin.explorer.toggle_hidden` | `explorer` | `H` in the tree | Show or hide entries whose name starts with a dot |
| `plugin.explorer.root_up` | `explorer` | `-` in the tree | Make the parent of the root the root |
| `plugin.explorer.set_root` | `explorer` | `C` in the tree | Make the directory under the cursor the root |
| `plugin.explorer.close` | `explorer` | `q` in the tree | Close the file tree |
| `plugin.explorer.help` | `explorer` | `?` in the tree | Show the tree's keys in the message row |

The keys marked "in the tree" are bound in the tree window's own keymap, which the plugin gives its scratch buffer, so they apply only while the tree is the current window; every other key falls through to the normal keymap. The test fixture `hello` (`carat/plugins/hello/`) declares `plugin.hello.greet` on `<leader>hh`, but it is not in the registry, so the editor does not contain it.

## Reserved

`history.undo`, `history.redo`, `history.repeat`, `search.forward`, `search.backward`, `search.next`, `search.previous`.
