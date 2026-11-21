# Tasks

## 1. The tab bar

- [x] 1.1 `carat/adapters/tab_bar.rb` writes no gem; `GEM` and `ASCII_GEM` removed (proved by `test/adapters_tab_bar.rb` "The ascii icons give the ascii separator and no gem" and "Two tabs, one modified")
- [x] 1.2 Selected group and bold (proved by `test/adapters_tab_bar.rb` "The selected tab's icon is in the selected group" and `test/domain_theme.rb` "the selected tab reads at a glance")

## 2. The tests

- [x] 2.1 `test/editor_tab_flows.rb` drops its gem heuristics (proved by the flow table itself)
- [x] 2.2 Rows of `test/editor_tabs.rb` and `test/adapters_frame_presenter.rb` lose the gem

## 3. Docs

- [x] 3.1 buffer-tabs spec, `docs/compatibility.md`, `docs/codebase-map.md`, findings file
