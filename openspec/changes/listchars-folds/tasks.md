# Tasks

## 1. Options

- [ ] 1.1 Add `list` and `listchars` to `Options` (`carat/domain/options.rb`): the members, `KINDS`, `apply` with the `listchars?` check, and `listchar_code` with the ascii form; rows in `test/domain_options_config.rb` for the defaults, each refused value, and the codes with `option.icons ascii`
- [ ] 1.2 Add `option.list false` and `option.listchars "tab:→ ,trail:·,nbsp:␣"` to `config/default.caratrc` and run `make gen-config`; `test/config_sync.rb` and the shipped-defaults row in `test/domain_options_config.rb` prove it

## 2. Marks

- [ ] 2.1 Add `carat/adapters/whitespace_marks.rb` (`WhitespaceMarks`: `configure`, `on?`, `paint`) and call it from `carat/adapters/frame_presenter.rb` for file text rows, its stamp in the geometry key; `test/adapters_whitespace_marks.rb` (new, wired into `test/runner/run_all.rb`) proves every scenario of `whitespace-marks`
- [ ] 2.2 Give `Whitespace` the `GUIDE` role in `carat/domain/themes.rb`; `test/domain_theme.rb` proves the guide color and the contrast rules
- [ ] 2.3 Add `list`, `listchars`, and `lcs` to the options `:set` does not handle yet (`carat/use_cases/ex/set_command_handler.rb`); a row in `test/editor_syntax.rb`

## 3. Docs and checks

- [ ] 3.1 Document the marks: `docs/compatibility.md` (a Whitespace marks section, the option rows, the `:set` paragraph), README.md, `docs/architecture.md` (`Options`, the option scope, `FramePresenter`), `docs/codebase-map.md` (area 13); `make docs-lint` passes
- [ ] 3.2 Run `make test-one` for each touched test, `make lint`, `make diagnose-one` on the new adapter, and `make gates`; all pass

## Workflow follow-up

- Archive with `openspec archive listchars-folds -y` in the package step.
