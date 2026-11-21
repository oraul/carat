# Tasks

## 1. Keys

- [ ] 1.1 `Key::SHIFT_LEFT`, `SHIFT_RIGHT`, `CTRL_LEFT`, `CTRL_RIGHT`, `Key.unmodified`, the decoder, `encode`, and key notation (proved by `test/adapters_key_decoder.rb`, `test/domain_keys.rb`)
- [ ] 1.2 `HandleKey#lookup` falls back to the plain arrow (proved by `test/editor_cmdline_edit.rb` "An unbound Ctrl or Shift arrow acts as the plain arrow")

## 2. The cursor and the editing

- [ ] 2.1 `EditorState#cmdline_cursor` and `replace_cmdline`, used by every writer of `cmdline`
- [ ] 2.2 `Domain::CommandLineText` (proved by `test/domain_command_line_text.rb`)
- [ ] 2.3 `EditCommandLine`, `EraseCommandLine`, `MoveCommandLineCursor`, `DeleteCommandLineText`, `CommandLineEditHandler`, the keymap lines, `make gen-config`
- [ ] 2.4 `FramePresenter` places the bar at the cursor cell (proved by `test/adapters_frame_presenter.rb`)

## 3. Tests and docs

- [ ] 3.1 `test/editor_cmdline_edit.rb` names every ADDED scenario
- [ ] 3.2 README, `docs/compatibility.md`, `docs/actions.md`, `docs/codebase-map.md`
