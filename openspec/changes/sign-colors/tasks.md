## 1. Groups

- [ ] 1.1 Add the UI groups `Added`, `Changed`, `Removed` after the popup menu's in `Highlight` (`carat/domain/highlight.rb`), moving the syntax, file-icon, and markup ids up by three, and color them green, cyan, and red in `Themes::GROUPS` (`carat/domain/themes.rb`), proven by the group rows of `test/domain_theme.rb` (scenarios "The UI groups", "A plugin asks for an editor group", "The search groups have colors", "Every UI group has a color in every palette", "The git sign groups are green, cyan, and red")
- [ ] 1.2 Add `Highlight.sign_group(icon)` mapping the diagnostic and git icon names to their groups, `SignColumn` otherwise, proven by its rows in `test/domain_theme.rb`

## 2. Sign records

- [ ] 2.1 Keep a group beside each glyph in `SignLayer` (`carat/domain/sign_layer.rb`), take it in `Buffer#place_sign`, answer it from `Buffer#sign_group_at`, and pass the severity's group from `Buffer#set_diagnostics` (`carat/domain/buffer.rb`), proven by `test/domain_buffer.rb` (scenario "A diagnostic sign takes its severity's group") and the updated callers in `test/domain_edits.rb`
- [ ] 2.2 Pass `Highlight.sign_group(icon)` from `BufferRequests#place_sign` (`carat/use_cases/plugins/buffer_requests.rb`), proven by `test/use_cases_plugins.rb` (scenario "A sign of another icon keeps the sign column's group")

## 3. Drawing

- [ ] 3.1 Draw the glyph in the sign's group in `FramePresenter#paint_row` and compare the sign group in `PaintedRows` (`carat/adapters/`), proven by the carat-dark and carat-light frame rows in `test/adapters_frame_presenter.rb` (scenarios "Diagnostic signs are red and yellow", "Git signs are green and cyan")

## 4. Docs

- [ ] 4.1 Update `docs/compatibility.md` (63 UI groups and the sign colors), `docs/architecture.md` and `docs/codebase-map.md` (the `Highlight` entry), checked by `make docs-lint`

## Workflow follow-up

- Archive with `openspec archive sign-colors -y` at packaging.
