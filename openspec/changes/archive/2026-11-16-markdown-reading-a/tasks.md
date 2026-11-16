# Tasks

## 1. The reader within the icon set

- [x] 1.1 Give `carat/domain/markdown_text.rb` the icon set and caps as arguments (`parse`, `wrap`, `prefix_size`, `bullet`, `bar`, `rule`, the reading caps), remove `rows`, and bring the module comment current; prove with `test/domain_markdown_text.rb` (existing rows unchanged, the ascii table, the reading caps)
- [x] 1.2 Pass the icon set and the docs caps from `FormatDocs` (`carat/use_cases/docs/format_docs.rb`), `ShowHover`, and `ShowCompletionDocs`; prove with `test/adapters_hover.rb` and `test/editor_completion.rb`, their ascii rigs now expecting the plain markers

## 2. The reading toggle

- [x] 2.1 Add `UseCases::ToggleReading` (`carat/use_cases/docs/toggle_reading.rb`), the `docs.toggle_reading` registration in `DocsHandler`, its wiring in `EditorAssembly`, and its require in `carat.rb`; prove with `test/use_cases_toggle_reading.rb` (the view, back to the source, not Markdown, ascii, hostile text, over-cap)
- [x] 2.2 Bind `keymap.normal <leader>dr docs.toggle_reading` in `config/default.caratrc`, regenerate `carat/domain/default_config.rb` with `make gen-config`, and add the row to `docs/actions.md`; prove with `test/use_cases_actions.rb` and the key path in `test/use_cases_toggle_reading.rb`

## 3. Docs and checks

- [x] 3.1 Update `docs/codebase-map.md` (the new use case and test) and the README (the toggle, the ascii markers), `docs/architecture.md` unchanged as the proposal says; prove with `make docs-lint` and `make lint`
- [x] 3.2 Run `make gates` and `make spec-validate`
