# Tasks

## 1. The groups

- [x] 1.1 Add `Highlight::POPUP_MENU_MARK_SELECTED` (`PmenuMarkSel`) and `POPUP_MENU_LABEL_SELECTED` (`PmenuLabelSel`) before `STATUS_DIM`, moving the later ids up by two, and admit both in `FLOAT_GROUPS` (`carat/domain/highlight.rb`); prove it in `test/use_cases_plugins.rb` or `test/editor_floats.rb` (Scenario: The popup menu groups resolve, Other UI groups are refused)
- [x] 1.2 Add the `MARK` role to every palette and both rows to `Themes::GROUPS` (`carat/domain/themes.rb`); prove it in `test/domain_theme.rb` (Scenario: The mark and label groups in every palette)

## 2. The host

- [x] 2.1 Paint a float's `PmenuMarkSel` and `PmenuLabelSel` spans under `NO_COLOR` and leave its other spans plain (`carat/domain/highlight.rb`, `carat/adapters/float_painter.rb`, `carat/adapters/line_painter.rb`); prove it in `test/editor_floats.rb` (Scenario: Selected row spans under NO_COLOR, The selected row's mark and label groups style a span)
- [x] 2.2 Bump the plugin API to 2.15 and document the groups on `style_float` and `syntax_group` (`carat/plugin_api.rb`); update the version tests (`test/use_cases_plugins.rb`, `test/domain_plugin_manifest.rb`, `test/editor_floats.rb`: Scenario: A plugin written against 2.10, 2.11, 2.12 still loads)

## 3. The finder

- [x] 3.1 Mark the highlighted row `▎ ` and style the list float after every refill with the selected row, `PmenuMarkSel`, and `PmenuLabelSel` (`carat/plugins/finder/plugin.rb`); prove it in `test/editor_finder.rb` (Scenario: The selected row under truecolor, at 16 colors, under NO_COLOR, under option.icons ascii, The style follows the highlight, No match shows no highlighted row) (and Scenario: A grep row is styled as a file row)
- [x] 3.2 Update the rows' expectations of the finder tests and the grep preview's mark (`test/editor_finder.rb`, `test/editor_finder_grep.rb`, `test/editor_finder_grep_preview.rb`, snapshots through `make snapshots`, the diff read)
- [x] 3.3 Hold `PICKER_BUDGETS` (`make bench-budget`)

## 4. Docs

- [x] 4.1 Remove the finder's drift row (`docs/design.md`); update `docs/plugins.md` (2.15, `style_float`, `syntax_group`), `docs/compatibility.md` (the UI group count, the finder row), `docs/architecture.md` (the `Highlight` count), `docs/codebase-map.md` (the API version, `Highlight`), and README.md (the finder's highlighted row)
- [x] 4.2 Append the out-of-scope preview styling to `docs/findings/finder-rows.md`

## Quality review

- [x] 5.1 Painting every UI-group span under `NO_COLOR` would also draw the palette's and the command-line menu's `PmenuMatch` and `PmenuExtra` spans, a behavior change outside the brief (`carat/adapters/line_painter.rb`); narrow it to `PmenuMarkSel` and `PmenuLabelSel` (`Highlight.plain_style?`) and prove a `PmenuMatch` span stays plain (`test/editor_floats.rb`, Scenario: Selected row spans under NO_COLOR), fixed
- [x] 5.2 The finder's header comment kept an overlong line after the rewrap (`carat/plugins/finder/plugin.rb`), fixed
- [x] 5.3 The float painter's header comment said "its fill's kind", which names nothing (`carat/adapters/float_painter.rb`), fixed
- [x] 5.4 A failed `syntax_group` would leave the group ids 0 and make `style_float` fail silently, the row unselected (`carat/plugins/finder/plugin.rb`, `activate`); it cannot arise while the finder is compiled with the host at the same API, recorded in `docs/findings/finder-rows.md`
