# Tasks

## 1. Domain

- [ ] 1.1 Add `FuzzyMatch.score` in `carat/domain/fuzzy_match.rb`, proven by the table of `test/domain_fuzzy_match.rb`
- [ ] 1.2 Add `group` and `child_keys` to `KeymapNode`, `Keymap#node_at`, and the `keymap.group` line in `Keymap#apply` and `Config#binding?`, proven by new rows of `test/domain_keymap.rb`
- [ ] 1.3 Add `option.keyhints.delay` to `Options` (member, kind, range 0 to 10000), proven by rows of `test/domain_options_config.rb`
- [ ] 1.4 Add the `KeyHints` and `Palette` records in `carat/domain/`, exercised by the editor tests of tasks 2 and 3

## 2. Key hints

- [ ] 2.1 Add `ShowKeyHints` and `HideKeyHints` under `carat/use_cases/discovery/`, the timer in `InputController`, and the close in `HandleKey#call` and `#timeout`, proven by `test/editor_key_hints.rb`
- [ ] 2.2 Add the option and the group lines to `config/default.caratrc` and run `make gen-config`, proven by `test/config_sync.rb` and `test/editor_key_hints.rb`

## 3. Command palette

- [ ] 3.1 Add `ExTable#describe` with a description per ex command, proven by a check in `test/use_cases_ex.rb`
- [ ] 3.2 Add `OpenPalette`, `FollowPalette`, and `PaletteHandler` (`palette.open`, `palette.next`, `palette.previous`), the palette branch of `ExecuteCommandLine`, the chosen action in `HandleKey`, and the `>` prompt in `FramePresenter`, proven by `test/editor_palette.rb`
- [ ] 3.3 Bind `<leader>p`, `<F1>`, `<C-n>`, and `<C-p>` in `config/default.caratrc`, add the rows to `docs/actions.md`, proven by `test/use_cases_actions.rb` and `test/editor_palette.rb`

## 4. Docs and checks

- [ ] 4.1 Update `docs/compatibility.md`, `docs/codebase-map.md`, and `README.md`, checked by `make docs-lint` and `make gates`
- [ ] 4.2 Record the plan notes: `docs/queue.md` from `build/plan/queue.md`, `docs/backlog.md` with the planner's entries and the four widened entries, checked by `make docs-lint`
- [ ] 4.3 Run `make test`, `make lint`, `make diagnose`, `make bench` for `lh` and `j`, `make gates`, and `make spec-validate`, all passing
