# Neovim compatibility

Every Neovim command Carat implements has a row here and a table-driven test. The test column names the `test/*.rb` program whose table or assertions cover the row. Commands from later roadmap items are not listed until they land; pressing a key bound to one of them shows a "Not implemented" message.

## Normal mode

| Keys | Action name | Behavior | Test |
| --- | --- | --- | --- |
| `h`, `<Left>` | `cursor.left` | One column left, not past column 0 | `editor_normal` |
| `l`, `<Right>` | `cursor.right` | One column right, not past the last character | `editor_normal` |
| `k`, `<Up>` | `cursor.up` | One row up, keeping the wanted column | `editor_normal` |
| `j`, `<Down>` | `cursor.down` | One row down, keeping the wanted column | `editor_normal` |
| `0` | `cursor.line_start` | Column 0 | `editor_normal` |
| `^` | `cursor.first_nonblank` | First character that is not a space or a tab | `editor_normal` |
| `$` | `cursor.line_end` | Last character; vertical motions then stick to line ends | `editor_normal` |
| `gg` | `cursor.buffer_start` | First line, keeping the wanted column | `editor_normal` |
| `G` | `cursor.buffer_end` | Last line, keeping the wanted column | `editor_normal` |
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

Differences from Neovim: `gg` and `G` keep the wanted column, as Neovim does with `startofline` off; the quit hint names `:q!` because there is one window.

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

## Options read by the foundation

`number`, `relativenumber`, `tabstop`, `shiftwidth`, `expandtab`, `autoindent`, `scrolloff`, and `timeoutlen`, from `config/default.json`. `scrolloff` is capped at half the window height as in Neovim.
