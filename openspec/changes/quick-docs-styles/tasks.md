# Tasks

## 1. Groups and themes

- [x] 1.1 Add the six markup groups and `FLOAT_LAYER` to `carat/domain/highlight.rb`, `base` stripping either layer; prove with `test/domain_theme.rb` (names, counts, token ids, base, LIMIT)
- [x] 1.2 Color the markup groups and fill the float layer in `carat/domain/themes.rb`; prove with the float-layer contrast table and the 16-color and uncolored checks in `test/domain_theme.rb`

## 2. Reading markdown with spans

- [x] 2.1 Add `Domain::DocsText` (`carat/domain/docs_text.rb`) and `MarkdownText.parse` and `wrap` keeping heading, strong, italic, code span, link, and fenced spans and the fence language; prove with span rows in `test/domain_markdown_text.rb`, the existing rows unchanged

## 3. Fenced code and the floats

- [x] 3.1 Add `UseCases::FormatDocs` (`carat/use_cases/docs/format_docs.rb`) tokenizing fenced rows through `PluginSyntax`, wired in `EditorAssembly` into `ShowHover` and `ShowCompletionDocs`; prove with `test/adapters_hover.rb`
- [x] 3.2 Add `Buffer#styles`, `style_at`, and `styled?`; set them in `ShowHover`, `ShowCompletionDocs`, and `PinHover`; prove with `test/adapters_hover.rb` (pinned split)
- [x] 3.3 Paint the styles in `FramePresenter` on the float layer for floats and on the base ids for a styled window, none when plain; prove with `test/adapters_hover.rb` (groups, fenced Ruby, unknown language, NO_COLOR) and `test/editor_completion.rb` (strong word)

## 4. Docs and checks

- [x] 4.1 Update `docs/codebase-map.md`, `docs/architecture.md` where it lists the group ranges, and `docs/backlog.md` (the twelve planned entries, the NO_COLOR entry, the diagnostics URI entry); prove with `make docs-lint` and `make gates`
- [ ] 4.2 Run `make bench SCENARIOS="lh lh-float"` and compare allocations per key with main's figures, then `make gates` and `make spec-validate`
