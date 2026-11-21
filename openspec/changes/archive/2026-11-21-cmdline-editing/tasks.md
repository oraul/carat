# Tasks

## 1. Keys

- [x] 1.1 `Key::SHIFT_LEFT`, `SHIFT_RIGHT`, `CTRL_LEFT`, `CTRL_RIGHT`, `Key.unmodified`, the decoder, `encode`, and key notation (proved by `test/adapters_key_decoder.rb` "Ctrl and Shift arrows decode to their own keys", `test/domain_keys.rb`)
- [x] 1.2 `HandleKey#lookup` falls back to the plain arrow (proved by `test/editor_cmdline_edit.rb` "An unbound Ctrl or Shift arrow acts as the plain arrow")

## 2. The cursor and the editing

- [x] 2.1 `EditorState#cmdline_after`, `cmdline_position`, and `replace_cmdline`, used by every writer of `cmdline`
- [x] 2.2 `Domain::CommandLineText` (proved by `test/domain_command_line_text.rb`)
- [x] 2.3 `EditCommandLine`, `EraseCommandLine`, `MoveCommandLineCursor`, `DeleteCommandLineText`, `CommandLineEditHandler`, the keymap lines, `make gen-config`
- [x] 2.4 `FramePresenter` places the bar at the cursor cell (proved by `test/adapters_frame_presenter.rb` "The bar counts wide characters and the prompt" and `test/editor_cmdline_edit.rb` "The bar is at the cursor cell")

## 3. Tests and docs

- [x] 3.1 `test/editor_cmdline_edit.rb` names every ADDED scenario
- [x] 3.2 README, `docs/compatibility.md`, `docs/actions.md`, `docs/codebase-map.md`

## Quality review

- [x] Q.1 The `EditorState` comment names the command line's cursor (fixed in `carat/domain/editor_state.rb`)
- [x] Q.2 A plugin prompt's cursor was proved only at the end of its text (fixed: `test/use_cases_plugin_files.rb` edits it mid-line)
- [x] Q.3 A text written straight to `cmdline` after a cursor move keeps the old count of characters after the cursor (recorded in `docs/findings/cmdline-editing.md`: every shipped writer uses `replace_cmdline`, and a lint refusing a direct write needs new code)
