# Tasks

## 1. The tab line

- [x] 1.1 `TabBar` paints the gem, the fixed-width mark, and the separator, with the ascii forms (proved by the "gem marks the selected tab" rows of `test/adapters_tab_bar.rb`, scenarios "Two tabs, one modified", "The selected tab's icon is in the selected group", and "The ascii icons give the ascii gem and separator")

## 2. The winbar

- [x] 2.1 `Winbar` paints the path quiet and the innermost symbol in the accent (proved by `test/editor_breadcrumbs.rb`, scenarios "Windows on different files named" and "Only the innermost symbol is in the accent")

## 3. Docs

- [x] 3.1 README.md, `docs/compatibility.md`, and `docs/codebase-map.md` describe the look

## 4. Review advisories

- [x] 4.1 Gem table rows labelled "gem and separator, ..." in `test/adapters_tab_bar.rb`
- [x] 4.2 Group assertion for the winbar with symbols held and none spanning the cursor row in `test/editor_breadcrumbs.rb`
- [x] 4.3 Winbar requirement of the breadcrumbs delta spec reworded so the current window's last name is the one exception
- [x] 4.4 `top_row` of `test/editor_tab_flows.rb` strips only the gem and separator cells at tab boundaries
- [x] 4.5 `strip_tab_cells` of `test/editor_tab_flows.rb` takes a "|" as a separator only before a tab boundary and starts a tab after an overflow counter
