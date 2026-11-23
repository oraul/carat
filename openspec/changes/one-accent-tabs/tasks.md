# Tasks

## 1. Groups and the tab row

- [x] 1.1 Add `TabLineName` (id 69) and draw `TabLineSel` as FG on BG bold (`carat/domain/highlight.rb`, `carat/domain/themes.rb`); prove it in `test/domain_theme.rb` and `test/adapters_screen_presenter.rb` (Scenario: The selected tab is bold on the editor's background)
- [x] 1.2 Drop the tab icon, name the current page number `TabLineName`, add `TabBar#bare=` for 16 colors and NO_COLOR (`carat/adapters/tab_bar.rb`, `carat/adapters/frame_presenter.rb`); prove it in `test/adapters_tab_bar.rb`, `test/editor_tabs.rb`, and `test/adapters_frame_presenter.rb` (Scenario: Two tabs, one modified, The selected tab has no icon and no fill, Tabs under every icon set, The tab row at 16 colors and NO_COLOR, Two tab pages)
- [x] 1.3 Draw the winbar name and the shown view in `TabLineName` (`carat/adapters/winbar.rb`, `carat/adapters/frame_presenter.rb`); prove it in `test/editor_breadcrumbs.rb`, `test/editor_plugins.rb`, and `test/editor_slots.rb` (Scenario: Windows on different files named, Only the innermost symbol is in the accent)
- [x] 1.4 Update the expectations and snapshots the change moves (`make snapshots` diff read)

## 2. Docs

- [x] 2.1 Update `docs/compatibility.md`, `docs/codebase-map.md`, and the closed rows of `docs/design.md`
