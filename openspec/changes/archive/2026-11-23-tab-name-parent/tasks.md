# Tasks

## 1. The tab bar

- [x] 1.1 Write the folder before a name another tab has, count it in `tab_width`, and drop the trailing space so tabs stand two blank cells apart (`carat/adapters/tab_bar.rb`, `Buffer#parent_start`); prove it in `test/adapters_tab_bar.rb` and `test/domain_buffer.rb` (Scenarios: Two tabs, one modified; Tabs under every icon set; Two files with one name show their folders; A shared name's folder counts in the overflow)
- [x] 1.2 Update the tab-row strings of `test/adapters_definitions.rb`, `test/adapters_frame_presenter.rb`, and `test/editor_tabs.rb`, and the snapshots

## 2. The unread icon

- [x] 2.1 Remove `Buffer#icon` and `Buffer.icon_of`, and the test assertions on them

## 3. Docs

- [x] 3.1 Update README.md, `docs/codebase-map.md`, the `FileIcons` comment, the `buffer-tabs` Purpose, and the delta spec

## Quality review

- [x] 4.1 `shares_name?` is rescanned for every tab width in the overflow loops, growing with the listed files; recorded in `docs/findings/tab-name-parent.md` (a cache needs a flush on open, close, and rename, beyond the brief)
- [x] 4.2 The first-tab scenarios of the `buffer-tabs` spec still read a `•` before the name; recorded in `docs/findings/tab-name-parent.md` (a different requirement, outside the brief)
