# Tasks

## 1. The tab bar

- [x] 1.1 Write the folder before a name another tab has, count it in `tab_width`, and drop the trailing space so tabs stand two blank cells apart (`carat/adapters/tab_bar.rb`, `Buffer#parent_start`); prove it in `test/adapters_tab_bar.rb` and `test/domain_buffer.rb` (Scenarios: Two tabs, one modified; Tabs under every icon set; Two files with one name show their folders; A shared name's folder counts in the overflow)
- [x] 1.2 Update the tab-row strings of `test/adapters_definitions.rb`, `test/adapters_frame_presenter.rb`, and `test/editor_tabs.rb`, and the snapshots

## 2. The unread icon

- [x] 2.1 Remove `Buffer#icon` and `Buffer.icon_of`, and the test assertions on them

## 3. Docs

- [x] 3.1 Update README.md, `docs/codebase-map.md`, the `FileIcons` comment, the `buffer-tabs` Purpose, and the delta spec
