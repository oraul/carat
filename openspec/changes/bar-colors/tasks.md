# Tasks

## 1. The count groups on the bar

- [x] 1.1 Add `STATUS_DIAGNOSTIC_ERROR`, `STATUS_DIAGNOSTIC_WARN`, `STATUS_DIAGNOSTIC_INFO`, and `STATUS_DIAGNOSTIC_HINT` with their names to `Carat::Domain::Highlight` after `STATUS_LSP_ERROR`, the later ids moved up by four, proved by `test/domain_theme.rb` "The UI groups" (60 UI groups and the names)
- [x] 1.2 Add the roles `PANEL_BLUE` and `PANEL_CYAN` to `Carat::Domain::Themes`, the four groups over `PANEL`, and the two roles in the six palettes, proved by `test/domain_theme.rb` "The count groups share the bar's background", "Every palette's count groups pass on the bar", and the 24-bit and 256-color contrast tables
- [x] 1.3 Draw the counts and the closing space in the new groups in `Carat::Adapters::StatusBar#paint_entry` and `#last_count_group`, proved by `test/adapters_status_bar.rb` "A row per state" (each count in its bar group)

## 2. The bar at 16 colors

- [x] 2.1 Set the 16-color indexes of `PANEL_YELLOW`, `PANEL_GREEN`, `PANEL_RED`, `PANEL_BLUE`, and `PANEL_CYAN` in the six palettes to read at 4.5:1 on the bar under xterm's default colors, proved by `test/domain_theme.rb` "The bar reads at 16 colors" and the one_dark `lsp` rows

## 3. Docs and checks

- [ ] 3.1 Update README.md (the theme paragraph), `docs/architecture.md` and `docs/codebase-map.md` (60 UI groups), and `docs/compatibility.md` (the status bar's twelve groups), checked by `make docs-lint`
- [ ] 3.2 Run `make gates`, `make spec-validate`, and the touched tests through `make test-one`, then the whole suite with `make test`

## Workflow follow-up

- Archive the change after the checks and reviews pass.
