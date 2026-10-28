# Actions

The action names a keymap value may use, in `namespace.action` form. A keymap value that is not an action name is a key sequence in Vim notation to replay. Actions that `config/default.json` already binds but that a later roadmap item implements are listed under Reserved; pressing their keys shows "Not implemented: name".

## Implemented

| Action | Modes | Effect |
| --- | --- | --- |
| `cursor.left` | normal, insert | One column left |
| `cursor.right` | normal, insert | One column right |
| `cursor.up` | normal, insert | One row up, keeping the wanted column |
| `cursor.down` | normal, insert | One row down, keeping the wanted column |
| `cursor.line_start` | normal | Column 0 |
| `cursor.first_nonblank` | normal | First non-blank character |
| `cursor.line_end` | normal | Last character, wanted column at the line end |
| `cursor.buffer_start` | normal | First line |
| `cursor.buffer_end` | normal | Last line |
| `mode.insert` | normal | Insert before the cursor |
| `mode.insert_after` | normal | Insert after the cursor |
| `mode.insert_line_start` | normal | Insert at the first non-blank character |
| `mode.insert_line_end` | normal | Insert after the last character |
| `mode.insert_open_below` | normal | Open a line below and insert |
| `mode.insert_open_above` | normal | Open a line above and insert |
| `mode.normal` | insert, cmdline | Back to normal mode |
| `mode.cmdline` | normal | Enter command-line mode |
| `insert.newline` | insert | Split the line at the cursor |
| `insert.backspace` | insert | Delete before the cursor |
| `insert.delete` | insert | Delete under the cursor |
| `insert.tab` | insert | Insert a tab or spaces |
| `cmdline.execute` | cmdline | Run the command line |
| `cmdline.backspace` | cmdline | Remove the last character, or leave when empty |
| `message.quit_hint` | normal | Show the quit hint |

## Reserved

`motion.word_forward`, `motion.word_backward`, `motion.word_end`, `operator.delete_char`, `operator.delete_line`, `operator.yank_line`, `operator.put_after`, `operator.put_before`, `operator.delete`, `operator.yank`, `operator.change`, `operator.indent`, `operator.dedent`, `history.undo`, `history.redo`, `history.repeat`, `mode.visual`, `mode.visual_line`, `mode.visual_block`, `search.forward`, `search.backward`, `search.next`, `search.previous`.
