## 1. Keys and option

- [x] 1.1 `Key::CTRL_PAGE_UP`, `CTRL_PAGE_DOWN`, their `KeyNotation` names, and `KeyDecoder`'s Ctrl modifier on the tilde page keys (`carat/domain/key.rb`, `carat/domain/key_notation.rb`, `carat/adapters/key_decoder.rb`); proved by `test/adapters_key_decoder.rb` ("Ctrl-PageDown and Ctrl-PageUp decode to their own keys", "Arrow keys", "Tilde-terminated keys", "SS3 form", "Modified arrow") and `test/domain_keys.rb`
- [x] 1.2 `Options#gt` with `gt_follows_buffers?` and `option.gt buffers` in the defaults (`carat/domain/options.rb`, `config/default.caratrc`, `make gen-config`); proved by `test/domain_options_config.rb` ("An unknown gt mode is refused and keeps the earlier value")

## 2. Tab pages

- [x] 2.1 `TabList#last_index`, `visit`, `last_accessed_tab`, and `remove_tab` keeping it (`carat/domain/tab_list.rb`); `SwitchTab` target `:last_accessed` and `TabRequest`'s comment (`carat/use_cases/windows/switch_tab.rb`, `tab_request.rb`)
- [x] 2.2 `TabHandler` registers `tab.last_accessed`, `tabline.next`, and `tabline.previous` and takes `switch_buffer`; `SwitchBuffer` target `:tab` over `BufferList#file_at`; bindings `gt`, `gT`, `<C-PageDown>`, `<C-PageUp>`, `g<Tab>` (`carat/use_cases/actions/tab_handler.rb`, `carat/use_cases/buffers/switch_buffer.rb`, `buffer_request.rb`, `carat/domain/buffer_list.rb`, `carat/adapters/editor_assembly.rb`, `config/default.caratrc`); proved by `test/editor_tabs.rb` ("Ctrl-PageDown and Ctrl-PageUp wrap", "Counted Ctrl-PageDown", "Counted Ctrl-PageUp", "g Tab goes to the last accessed tab page", "g Tab with no tab page to go back to does nothing", "option.gt tabpages gives gt and gT the tab pages back", "Ex next and previous", "First and last", "Layouts are independent", "gt shows the next buffer tab, wrapping", "gT shows the previous buffer tab, wrapping", "Counted gt goes to that buffer tab", "gt keeps the tab page", "gt refuses a modified buffer") and `test/domain_keymap.rb`
- [x] 2.3 The tests that typed `gt` for a tab page type `<C-PageDown>` (`test/editor_tabs.rb`, `test/editor_cmdline.rb`, `test/editor_floats.rb`, `test/editor_plugins.rb`)

## 3. Buffer keys

- [x] 3.1 `buffer.first` and `buffer.last` in `BufferHandler`; bindings `[b`, `]b`, `[B`, `]B` (`carat/use_cases/actions/buffer_handler.rb`, `config/default.caratrc`); proved by `test/editor_tabs.rb` ("Bracket b steps through the buffers", "Bracket B goes to the first and the last buffer")

## 4. Tab ex arguments

- [x] 4.1 `TabCommandHandler` reads the argument; `CloseTab#call(state, number)` and `CloseOtherTabs#call(state, number)` (`carat/use_cases/ex/tab_command_handler.rb`, `carat/use_cases/windows/close_tab.rb`, `close_other_tabs.rb`); proved by `test/editor_tabs.rb` ("tabn N goes to tab page N", "tabp N goes N tab pages back", "tabc N closes tab page N", "tabo N keeps only tab page N", "A tab argument that names no tab page is refused") and `test/use_cases_ex.rb` ("One tab page answers before reading the argument")

## 5. Docs

- [x] 5.1 `docs/compatibility.md` (tab-page keys, buffer keys, tab ex rows, Differences), `docs/actions.md`, `README.md`'s feature sentence, `docs/architecture.md`'s `TabList` entry, `docs/codebase-map.md` area 11
- [x] 5.2 `make gates`, `make spec-validate`, `make docs-lint`, and the targeted tests pass
