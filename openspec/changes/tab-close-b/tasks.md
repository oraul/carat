# Tasks

## 1. Buffer switches from a side window

- [ ] 1.1 Add `TabPage#editing_leaf` (`carat/domain/tab_page.rb`) and use it in `WindowRequests#editing_window`; proved by the `editing_window` rows of `test/use_cases_plugin_files.rb`
- [ ] 1.2 Focus the editing leaf in `SwitchBuffer#call` (`carat/use_cases/buffers/switch_buffer.rb`) when a side window is focused, refusing with no file window; proved by "gt from the explorer moves the file window's buffer tab", "gT from the explorer ...", ":bn and :bp from the explorer switch the file window" in `test/editor_explorer.rb` and "A switch from a lone side window is refused" in `test/editor_buffers.rb`

## 2. :tabe of a listed file

- [ ] 2.1 Leave the empty buffer unlisted while `OpenTab#call` (`carat/use_cases/windows/open_tab.rb`) opens a path; proved by "Tab edit a listed file leaves no empty buffer" in `test/editor_tabs.rb`

## 3. The explorer's t follows the row

- [ ] 3.1 Add the `open_as_tab` host request (`carat/plugin_api.rb`, `carat/use_cases/plugins/plugin_link.rb`, `carat/use_cases/plugins/window_requests.rb`), API 2.8, with the version rows; proved by "Open as a tab under buffer tabs" and "Open as a tab under tab pages" in `test/editor_explorer.rb`
- [ ] 3.2 Call it from the explorer's `t` (`carat/plugins/explorer/plugin.rb`), its HELP line and description, `docs/actions.md`, `docs/plugins.md`; proved by "t opens a buffer tab", "t on a listed file shows its tab", "Tab page", and "A name with a bar in a tab page" in `test/editor_explorer.rb`

## 4. The scenario suite

- [ ] 4.1 Add `test/editor_tab_flows.rb` (`EditorTabFlowsTest`) with the open, move, and close flows under both `option.gt` values and the user's reported sequences, wired in `test/runner/run_all.rb`, with its snapshot

## 5. Docs and checks

- [ ] 5.1 README.md, `docs/architecture.md` section 9, `docs/codebase-map.md`, `docs/compatibility.md`
- [ ] 5.2 `make gates`, `make spec-validate`, `make lint`, `make docs-lint`, and `make test` pass
