# Tasks

## 1. Theme groups and frame helpers

- [x] 1.1 Add the eight status bar groups to `carat/domain/highlight.rb` and the `ON_STRONG` role with each palette's value and the groups' rows to `carat/domain/themes.rb`; prove it in `test/domain_theme.rb` (the group count, the contrast tables, a row per mode and state pinning its roles).
- [x] 1.2 Add `DisplayWidth.text_width(text, from)` and `Frame#put_from(row, col, text, from, hl, limit)`; prove them in `test/domain_frame.rb`.

## 2. Shared state

- [ ] 2.1 Add `Domain::StatusSlots` (`carat/domain/status_slots.rb`) and require it in `carat.rb`; prove it in `test/adapters_status_bar.rb`.
- [ ] 2.2 Keep the plugins' segment order and priorities in `carat/domain/plugin_ui.rb` (`owners`, `priorities`, `segment(owner, text, priority)`); prove it in `test/use_cases_plugins.rb`.
- [ ] 2.3 Move the file-icon table into `PluginApi::FileIcons` (`carat/plugin_api.rb`), delegate from `carat/plugins/explorer/file_icons.rb`, and give `Buffer` an `icon` set with its filetype; prove it in `test/plugins_explorer.rb` and `test/domain_buffer.rb`.
- [ ] 2.4 Add `BufferList#tab_row?(tab_count)` and make `ArrangeView` take `buffers:` and reserve row 0 by it; prove it in `test/use_cases_arrange_view.rb`.

## 3. Painters

- [ ] 3.1 Add `Adapters::StatusBar` (`carat/adapters/status_bar.rb`): segments, order, priorities, colors per mode and state, without allocating; prove it with table rows per segment and per width in `test/adapters_status_bar.rb`.
- [ ] 3.2 Add `Adapters::TabBar` (`carat/adapters/tab_bar.rb`): buffer tabs, icons, modified dot, overflow counts, tab-page numbers; prove it with table rows per width in `test/adapters_tab_bar.rb`.
- [ ] 3.3 Make `FramePresenter` paint separator rows and `WinSeparator` columns, call the two painters, and drop `paint_status`, `paint_ruler`, `paint_tabline`, and `file_name`; wire both painters and the slots in `EditorAssembly`; update `test/adapters_frame_presenter.rb`, `test/adapters_screen_presenter.rb`, `test/adapters_assembly.rb`, and the editor tests whose rows move.

## 4. Plugin request

- [ ] 4.1 Add `set_segment(text, priority)` to `PluginApi::Host`, `PluginLink`, and `UiRequests`, keep `set_status` at priority 10, and bump the API to 2.2; prove it in `test/use_cases_plugins.rb`, `test/domain_plugin_manifest.rb`, and `test/editor_plugins.rb`.

## 5. Docs and records

- [ ] 5.1 Update `docs/compatibility.md` (status bar, buffer tabs, tab pages, windows), `docs/architecture.md` sections 8.2 and 9.1, `docs/plugins.md`, `docs/codebase-map.md`, and `README.md`.
- [ ] 5.2 Record the plan notes' entries in `docs/backlog.md`.
- [ ] 5.3 Run `make bench` for `lh`, `j`, and `insert` against main's figures, `make gates`, and `make spec-validate`.
