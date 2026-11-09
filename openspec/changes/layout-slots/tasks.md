# Tasks

## 1. Domain

- [x] 1.1 Add `Window#fixed_height` and `Window#unfix_size`, make `Layout#fixed?(id, along_row)` axis-general for `equalize_node`, `fit`, and `close`, and add `Layout#split_bottom` and `Layout#place_slot`, proven by new rows of `test/domain_layout.rb`
- [x] 1.2 Add the `Slot` record and the three slots of `TabPage`, count a hidden slot's window in `TabList#shown?`, and let go of it in `BufferList#close_tab`, proven by `test/domain_slot.rb`
- [x] 1.3 Add `option.layout.left_width`, `option.layout.right_width`, and `option.layout.panel_height` to `Options` (0 to 500), proven by rows of `test/domain_options_config.rb`

## 2. Slots

- [x] 2.1 Make `OpenSideWindow` place a view in its slot (one window per slot, the configured size, a hidden slot shown again), `WindowRequests#open_scratch` accept `bottom`, the file-open paths unfix both sizes, and `PluginApi` go to 2.4, proven by `test/editor_plugins.rb`
- [x] 2.2 Reserve the header row in `ArrangeView` and paint the headers in `FramePresenter`, proven by `test/editor_slots.rb` and `test/editor_explorer.rb`
- [x] 2.3 Add `ToggleSlot` and `LayoutHandler` (`layout.toggle_sidebar`, `layout.toggle_right_sidebar`, `layout.toggle_panel`), wired in `EditorAssembly`, proven by `test/editor_slots.rb` and `test/use_cases_actions.rb`
- [x] 2.4 Bind `<leader>ls`, `<leader>lr`, `<leader>lp` and the `<leader>l` group and add the three options in `config/default.caratrc`, run `make gen-config`, proven by `test/config_sync.rb` and `test/editor_slots.rb`

## 3. Docs and checks

- [x] 3.1 Update `docs/actions.md`, `docs/compatibility.md`, `docs/plugins.md`, `docs/architecture.md`, `docs/codebase-map.md`, and `README.md`, checked by `make docs-lint` and `make gates`
- [x] 3.2 Record the plan notes in `docs/backlog.md` (renamed queue items, widened and raised-again entries), checked by `make docs-lint`
- [x] 3.3 Run `make test`, `make lint`, `make diagnose`, `make gates`, and `make spec-validate`, all passing
