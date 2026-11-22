# Tasks

## 1. The groups

- [ ] 1.1 Add `Highlight::POPUP_MENU_MARK_SELECTED` (`PmenuMarkSel`) and `POPUP_MENU_LABEL_SELECTED` (`PmenuLabelSel`) before `STATUS_DIM`, moving the later ids up by two, and admit both in `FLOAT_GROUPS` (`carat/domain/highlight.rb`); prove it in `test/use_cases_plugins.rb` or `test/editor_floats.rb` (Scenario: The popup menu groups resolve, Other UI groups are refused)
- [ ] 1.2 Add the `MARK` role to every palette and both rows to `Themes::GROUPS` (`carat/domain/themes.rb`); prove it in `test/domain_theme.rb` (Scenario: The mark and label groups in every palette)

## 2. The host

- [ ] 2.1 Paint a float's UI-group spans under `NO_COLOR` and skip its token-group spans (`carat/adapters/float_painter.rb`, `carat/adapters/line_painter.rb`); prove it in `test/editor_floats.rb` (Scenario: Popup menu spans under NO_COLOR, The selected row's mark and label groups style a span)
- [ ] 2.2 Bump the plugin API to 2.15 and document the groups on `style_float` and `syntax_group` (`carat/plugin_api.rb`); update the version tests (`test/use_cases_plugins.rb`, `test/domain_plugin_manifest.rb`, `test/editor_floats.rb`: Scenario: A plugin written against 2.10, 2.11, 2.12 still loads)

## 3. The finder

- [ ] 3.1 Mark the highlighted row `▎ ` and style the list float after every refill with the selected row, `PmenuMarkSel`, and `PmenuLabelSel` (`carat/plugins/finder/plugin.rb`); prove it in `test/editor_finder.rb` (Scenario: The selected row under truecolor, at 16 colors, under NO_COLOR, under option.icons ascii, The style follows the highlight, No match shows no highlighted row) (and Scenario: A grep row is styled as a file row)
- [ ] 3.2 Update the rows' expectations of the finder tests and the grep preview's mark (`test/editor_finder.rb`, `test/editor_finder_grep.rb`, `test/editor_finder_grep_preview.rb`, snapshots through `make snapshots`, the diff read)
- [ ] 3.3 Hold `PICKER_BUDGETS` (`make bench-budget`)

## 4. Docs

- [ ] 4.1 Remove the finder's drift row (`docs/design.md`); update `docs/plugins.md` (2.15, `style_float`, `syntax_group`), `docs/compatibility.md` (the UI group count, the finder row), `docs/architecture.md` (the `Highlight` count), `docs/codebase-map.md` (the API version, `Highlight`), and README.md (the finder's highlighted row)
- [ ] 4.2 Append the out-of-scope preview styling to `docs/findings/finder-rows.md`
