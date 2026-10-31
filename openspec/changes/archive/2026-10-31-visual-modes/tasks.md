# Tasks

## 1. Domain

- [x] 1.1 Move the display column helpers into `carat/domain/display_width.rb` (`cell`, `column`, `col_at`) and have `carat/adapters/frame_presenter.rb` use them; verify `test/adapters_frame_presenter.rb` still passes unchanged
- [x] 1.2 Add `carat/domain/selection.rb` with `Span`, `Block`, and `Selection`, and `carat/domain/block_insert.rb` with `BlockInsert`, wired into `carat.rb`; verify with the new `test/domain_selection.rb` (charwise, linewise, and blockwise spans, tabs, wide characters, `$`, the char and line ranges)
- [x] 1.3 Add `Mode.visual?`, `Mode.visual_kind`, and `Mode.for_kind` in `carat/domain/mode.rb`, `anchor` and `last_selection` on `Window`, and `selection`, `end_visual`, `block_insert`, and the visual `max_col` on `EditorState`; verify with `test/domain_selection.rb`
- [x] 1.4 Change `RegisterEntry` in `carat/domain/registers.rb` to a kind with `blockwise`, `block`, and the join rule; verify with `test/domain_registers.rb`
- [x] 1.5 Add `accept_visual` and the `visual.replace` character action to `carat/domain/command_grammar.rb`; verify with `test/domain_grammar.rb`
- [x] 1.6 Add the block, case, replace, and raw join work to `carat/domain/operators.rb` and `Highlight::VISUAL`; verify through the editor tests of groups 2 and 3

## 2. Visual mode

- [x] 2.1 Add `carat/use_cases/visual/start_visual.rb` and `extend_visual.rb`, route visual keys through the grammar in `carat/use_cases/handle_key.rb`, and route the visual actions in `carat/use_cases/dispatcher.rb` and `carat/adapters/editor_assembly.rb`; verify with the mode, motion, `o`, `O`, `gv`, count, register, and unbound-key rows of `test/editor_visual.rb`
- [x] 2.2 Bind the three visual maps and `gv` in `config/default.json` and regenerate the mirror with `make gen-config`; verify with `test/config_sync.rb` and `test/editor_visual.rb`
- [x] 2.3 Add the text objects in visual mode to `ExtendVisual`; verify with the text object rows of `test/editor_visual.rb`

## 3. Operators on the selection

- [x] 3.1 Add `carat/use_cases/visual/operate_on_selection.rb` with `d x <Del> y c s > < J gJ r ~ u U X D C S R Y`; verify with the operator rows of `test/editor_visual.rb` for each kind
- [x] 3.2 Add `p` and `P` in visual mode and the blockwise put in normal mode (`carat/use_cases/operate.rb`); verify with `test/editor_visual.rb` and `test/editor_registers.rb`
- [x] 3.3 Add `I` and `A` and the block repeat in `carat/use_cases/leave_insert.rb`; verify with the insert and append rows of `test/editor_visual.rb`

## 4. Rendering

- [x] 4.1 Draw the selection with `Visual` in `carat/adapters/frame_presenter.rb`, the mode indicators, and the reverse video in `carat/adapters/screen_presenter.rb`; verify with `test/adapters_frame_presenter.rb` (three kinds, the cursor cell, a tab and a wide character in a block, two windows on one buffer) and the indicator rows of `test/editor_visual.rb`
- [x] 4.2 Extend `test/smoke_editor.rb` with `Vjd` and `:wq` in the pseudo-terminal; verify the written file

## 5. Documentation

- [x] 5.1 Add the visual mode rows to `docs/compatibility.md` and the new actions to `docs/actions.md`; verify every key of `config/default.json`'s visual maps has a row and an action entry
- [x] 5.2 Update `docs/architecture.md` (entities, use cases, roadmap note on item 5 ahead of item 4, the plugin API sentence), `docs/backlog.md` (the plugin selection requests), `CLAUDE.md` (status, layout, the motion binding convention), and `README.md`; verify by reading them against the code
- [x] 5.3 Run `make check` under Spinel and confirm build, gen-config, test, and diagnose are clean, and diff `make types` against `main` for new `untyped` members

## Workflow follow-up

- Run the security review on the committed branch diff.
- Archive the change with `openspec archive visual-modes -y` and validate all specs.
- Commit, push, open the pull request, wait for CI, and squash-merge.
