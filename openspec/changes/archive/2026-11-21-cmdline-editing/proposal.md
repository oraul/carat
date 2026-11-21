# Proposal

## Why

The command line only appends and backspaces at its end (the user's decision of 2026-11-21, the design council): a typo in `:e app/models/order.rb` means retyping the line. This is the first part of the change; Tab completion, its popup, and the bounded directory read follow as `cmdline-completion`.

## What Changes

- `EditorState` gains `cmdline_after`, the characters after the cursor of `cmdline`, shared by the `:` line, the search prompts, the palette's prompt, and a plugin's prompt, read as the character index `cmdline_position`; `replace_cmdline(text)` sets a text with the cursor at its end, and every place that set `cmdline` (entering, cancelling, executing, the palette and search openers, the plugin prompt, the history recall) uses it.
- `EditCommandLine` inserts at the cursor, `EraseCommandLine` deletes before it (still leaving an empty line), and the new `MoveCommandLineCursor` and `DeleteCommandLineText` use cases move by character, to either end, and by blank-separated word, and delete under the cursor, the word before it, and everything before it; `Domain::CommandLineText` holds the pure word arithmetic.
- `CommandLineEditHandler` registers `cmdline.left`, `cmdline.right`, `cmdline.home`, `cmdline.end`, `cmdline.word_left`, `cmdline.word_right`, `cmdline.delete`, `cmdline.delete_word`, and `cmdline.delete_line`, bound under `keymap.cmdline` in `config/default.caratrc` to `<Left>`, `<Right>`, `<Home>` and `<C-b>`, `<End>` and `<C-e>`, `<S-Left>` and `<C-Left>`, `<S-Right>` and `<C-Right>`, `<Del>`, `<C-w>`, and `<C-u>`.
- Four new keys, `<S-Left>`, `<S-Right>`, `<C-Left>`, and `<C-Right>`, which the decoder produces from a Shift or Ctrl modifier on Left and Right (it ignored the modifier before), parsed and formatted by key notation; `HandleKey` resolves one a mode does not bind as the plain arrow, so no mode changes behavior.
- `FramePresenter` places the bar at the display column of the prompt plus the text before the cursor, wide characters counted by their cells.
- Docs: README, `docs/compatibility.md` and `docs/actions.md` rows with the differences from Neovim, the code map, the command-line-mode and key-input specs.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `command-line-mode`: MODIFIED "The command line is edited with typed keys"; ADDED "The command line has a cursor" and "The command line deletes at the cursor".
- `key-input`: MODIFIED "Escape sequences decode to special keys" and "Vim key notation names every key".

## Out of scope

- Tab completion, the popup menu above the command line, and the bounded directory read (`cmdline-completion`); `<C-r>` register insert; the `wildmode` and `wildoptions` options.
- No `tools/rules.sh` edit; no file of the backlog lane.
- Assumptions: `<S-Left>` and `<S-Right>` move by blank-separated word and `<C-w>` by word-character run, as Neovim does; `<Del>` at the end of the line acts as `<BS>`, as Neovim does; a wide character is one cursor move.

## Impact

- README.md: changed, the command-line paragraph.
- docs/architecture.md: unchanged, no layer, port, or Spinel rule moves.
- docs/codebase-map.md: area 12 (the use cases, the handler, the tests) and area 4 (`Domain::CommandLineText`).
- docs/compatibility.md and docs/actions.md: the command-line rows.
- Performance: one integer compare per key; the frame's cursor column is a width of the text before the cursor, as it was of the whole text.
