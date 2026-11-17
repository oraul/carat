# Tasks

## 1. A side window is a slot's window

- [x] 1.1 Add `TabPage#side_window?` (`carat/domain/tab_page.rb`); proved by the side-window rows of `test/editor_breadcrumbs.rb`
- [x] 1.2 Use it in `SwitchBuffer#call` (`carat/use_cases/buffers/switch_buffer.rb`) instead of the scratch test; proved by "Buffer switches from a lone reading view act on its window" and "Buffer switches from a reading view in a split act on the focused window" in `test/editor_tab_flows.rb`, every existing flow there still passing

## 2. A refused switch changes nothing

- [x] 2.1 Restore the tab page's current and previous windows on a refusal in `SwitchBuffer#call`; proved by "A refused switch from a side window keeps the previous window" in `test/editor_tab_flows.rb`

## 3. Docs and checks

- [ ] 3.1 `docs/codebase-map.md` (`tab_page.rb`, `switch_buffer.rb`), `docs/compatibility.md` (the `:bnext` row), the `switch_buffer.rb` header comment
- [ ] 3.2 `make gates`, `make spec-validate`, `make lint`, `make docs-lint`, and the touched tests pass
