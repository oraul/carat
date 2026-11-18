## 1. Groups

- [x] 1.1 Add the UI groups `Added`, `Changed`, `Removed` after the popup menu's in `Highlight` (`carat/domain/highlight.rb`), moving the syntax, file-icon, and markup ids up by three, and color them green, cyan, and red in `Themes::GROUPS` (`carat/domain/themes.rb`), proven by the group rows of `test/domain_theme.rb` (scenarios "The UI groups", "A plugin asks for an editor group", "The search groups have colors", "Every UI group has a color in every palette", "The git sign groups are green, cyan, and red")
- [x] 1.2 Add `Highlight.sign_group(icon)` mapping the diagnostic and git icon names to their groups, `SignColumn` otherwise, proven by its rows in `test/domain_theme.rb`

## 2. Sign records

- [x] 2.1 Keep a group beside each glyph in `SignLayer` (`carat/domain/sign_layer.rb`), take it in `Buffer#place_sign`, answer it from `Buffer#sign_group_at`, and pass the severity's group from `Buffer#set_diagnostics` (`carat/domain/buffer.rb`), proven by `test/domain_buffer.rb` (scenario "A diagnostic sign takes its severity's group") and the updated callers in `test/domain_edits.rb`
- [x] 2.2 Pass `Highlight.sign_group(icon)` from `BufferRequests#place_sign` (`carat/use_cases/plugins/buffer_requests.rb`), proven by `test/use_cases_plugins.rb` (scenario "A sign of another icon keeps the sign column's group")

## 3. Drawing

- [x] 3.1 Draw the glyph in the sign's group in `FramePresenter#paint_row` and compare the sign group in `PaintedRows` (`carat/adapters/`), proven by the carat-dark and carat-light frame rows in `test/adapters_frame_presenter.rb` (scenarios "Diagnostic signs are red and yellow", "Git signs are green and cyan")

## 4. Docs

- [x] 4.1 Update `docs/compatibility.md` (63 UI groups and the sign colors), `docs/architecture.md` and `docs/codebase-map.md` (the `Highlight` entry), and `docs/plugins.md` (`place_sign`), checked by `make docs-lint`

## 5. Review fixes

- [x] 5.1 Remove `FramePresenter.diagnostic_group` and call `Domain::Highlight.diagnostic_group` in `paint_diagnostic` (`carat/adapters/frame_presenter.rb`), the duplicate mapping gone, proven by the diagnostic message rows of `test/adapters_frame_presenter.rb` and the severity rows of `test/domain_theme.rb`
- [x] 5.2 Read the shown layer once through a private `Buffer#shown_layer_index` (-1 for none) that `sign_at` and `sign_group_at` both use (`carat/domain/buffer.rb`), proven by the sign rows of `test/domain_buffer.rb`
- [x] 5.3 Restore the ellipsis after `NormalFloat` in the `Highlight` entry of `docs/architecture.md`, checked by `make docs-lint`
- [x] 5.4 Rewrap the edited comments of `carat/adapters/painted_rows.rb` and `FramePresenter#paint_row` at the surrounding width

## 6. Second review fixes

- [x] 6.1 Drop `diagnostic_group` from the `FramePresenter` entry of `docs/codebase-map.md`, which names `Highlight.diagnostic_group` as the group `paint_diagnostic` uses, checked by `make docs-lint`
- [x] 6.2 Make `Buffer#shown_layer_index` public and have `FramePresenter#paint_window` read a row's glyph and group from the one layer it returns, one scan per painted row where `sign_at` and `sign_group_at` scanned twice (`carat/domain/buffer.rb`, `carat/adapters/frame_presenter.rb`, the map's `Buffer` entry), proven by the shown layer rows of `test/domain_buffer.rb` and the sign rows of `test/adapters_frame_presenter.rb`
- [x] 6.3 Bound the severity in `Highlight.diagnostic_group`, a severity outside 1 to 3 drawn as a hint as the removed presenter mapping drew it (`carat/domain/highlight.rb`), proven by the out-of-range row of `test/domain_theme.rb`

## Workflow follow-up

- Archive with `openspec archive sign-colors -y` at packaging.
