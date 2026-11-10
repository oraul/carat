# Tasks

## 1. Groups and options

- [ ] 1.1 `carat/domain/highlight.rb` and `carat/domain/themes.rb`: `IblIndent` and `IblScope` as UI groups 49 and 50, the later ids moved by two, their palette roles; `test/domain_theme.rb` counts, names, and decorations pass (`make test-one T=test/domain_theme.rb`).
- [ ] 1.2 `carat/domain/options.rb`, `config/default.caratrc`, `carat/domain/default_config.rb` (`make gen-config`): `indentguides` and `indentguides.char` with their checks and `guide_code`; rows in `test/domain_options_config.rb` pass.

## 2. Drawing

- [ ] 2.1 `carat/adapters/indent_guides.rb` and `carat/adapters/painted_rows.rb`: the measure, the guide key, and the paint; `carat/adapters/frame_presenter.rb` calls them for file windows only; `test/adapters_indent_guides.rb` (new) covers every scenario of the `indent-guides` spec through the frame presenter.

## 3. Bench and docs

- [ ] 3.1 `bench/keys.rb` and `bench/run.sh`: `lh-noguides`, `j-noguides`, `insert-noguides`; `make bench-budget` passes.
- [ ] 3.2 `docs/compatibility.md` Indent guides section and Themes count, `README.md`, `docs/architecture.md`, `docs/codebase-map.md` areas 13 and 14; `make docs-lint` and `make gates` pass.
