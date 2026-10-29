# Tasks

## 1. The API, the manifest rules, and the icons

- [x] 1.1 Add `carat/plugin_api.rb` with `MAJOR`, `MINOR`, `VERSION`, `EVENTS`, the values `Manifest`, `Event`, `Context`, `Command`, `Edit`, `Response`, `BufferView`, and `FileInfo`, the `Host` base class with one method per request, and the `Plugin` base class; add it to `carat.rb` before the use cases; verify with `make build` and the lint RBS check
- [x] 1.2 Add `carat/domain/manifest_check.rb` with the rules of the plugin-host spec and the API version refusal message; verify with `test/domain_plugin_manifest.rb` covering a valid manifest, a bad name, a foreign action, a lowercase command, a bad abbreviation, an unknown event, a bad binding, a binding to a foreign action, a bad option type, and a newer major and minor version
- [x] 1.3 Add `carat/domain/icons.rb` with the three tables, add `icons` to `carat/domain/options.rb` and `config/default.json`, make the private use areas explicit in `carat/domain/display_width.rb`, and run `make gen-config`; verify with `test/domain_icons.rb` covering every name in every set, the set properties, the ascii folder, the unknown name, the option parsing, and the widths of U+F07B and U+F0001

## 2. Buffers, keymaps, and the layout

- [x] 2.1 Extend `carat/domain/buffer.rb` with `owner`, `title`, `keymap`, `signs`, `sign_owners`, `changes`, and `scratch?`, reorder `carat.rb` so the keymap precedes the buffer, make `modified_buffer`, `hidden_modified`, and `release` in `carat/domain/editor_state.rb` skip or drop scratch buffers, and add `segments` to the state; verify with `test/domain_buffer.rb` rows for the change counter, the scratch members, and the modified checks
- [x] 2.2 Add `Keymap#add_all` to `carat/domain/keymap.rb` with `build` delegating to it, and `Layout#split_edge` to `carat/domain/layout.rb`; verify with `test/domain_keymap.rb` rows for plugin bindings added below the configuration, the configuration replacing and unbinding them, and `test/domain_layout.rb` rows for an edge split on the left, on the right, into an existing row, its sizes after arrange and equalize with the fixed width, and the E36 case

## 3. The host

- [x] 3.1 Add `carat/use_cases/plugins/plugin_entry.rb`, `plugin_link.rb`, and `plugin_host.rb` with registration, `activate_all`, the bindings merge, action and command routing, `observe`, `saved`, `resized`, and every request; add them to `carat.rb`; verify with `test/use_cases_plugins.rb` covering registration, the refusal of a newer major version, the disabled configuration entry, option resolution with a wrong type kept at the default, action routing with the context, command routing by name and abbreviation, the event order of the plugin-host spec, every request including the refused edit transaction, the signs of two plugins, and a plugin that raises in an action and in an event being disabled with the editor still usable
- [x] 3.2 Route `plugin.*` actions in `carat/use_cases/dispatcher.rb`, plugin ex commands in `carat/use_cases/files/execute_ex.rb` with `write_all` skipping scratch buffers, `E382` and `saved` in `carat/use_cases/files/save_file.rb`, the scratch keymap, the wider `action_name?`, and `observe` in `carat/use_cases/handle_key.rb`; wire the host in `carat/adapters/editor_assembly.rb`, which takes the plugin list, registers, activates, adds the configuration keymaps, observes after `open`, and reports `resize` from `render`; give `carat/doubles/editor_harness.rb` `with_plugins`; verify with `test/use_cases_ex.rb` rows for `:w` on a scratch buffer and `:wa` skipping one and with every existing test program still passing under `make test`

## 4. The registry and the hello plugin

- [x] 4.1 Add `config/plugins.json`, `carat/domain/registry_source.rb`, the registry generation in `bin/carat-gen-config.rb`, the registry comparison and the `plugins` entries check in `test/config_sync.rb`, and the plugin directory rule in `test/lint.rb`; run `make gen-config`; verify with `make lint` and `test/config_sync.rb` passing and with the registry file matching the rendered text
- [x] 4.2 Add `carat/plugins/hello/plugin.rb` with the manifest, the greet action, `:Hello` with `:Hel`, the `buffer_open` count, the info icon message, the status segment, and the `greeting` option; list it in `config/plugins.json` and `config/default.json`; pass `Registry.all` from `bin/carat.rb`; verify with `test/editor_plugins.rb` rows for `<leader>hh`, a count, `:Hello`, `:Hel`, `:Hello Ada`, the greeting option, the icon set switch, the status segment on the current window only, the disabled configuration, and the all-disabled session

## 5. Plugin windows and rendering

- [x] 5.1 Implement `open_scratch`, `set_scratch_lines`, `close_scratch`, `focus_window`, and `open_file` in the host over `Layout#split_edge`, `CloseWindow#remove`, and `OpenFile`, the scratch keymap precedence in `HandleKey`, the sign column in `carat/domain/window.rb` and `carat/adapters/frame_presenter.rb`, and the scratch title and the segments in `paint_status`; verify with `test/editor_plugins.rb` rows for every scenario of the plugin-windows spec over a test plugin and with `test/adapters_frame_presenter.rb` scenarios for the sign column, the scratch title, and the segment on the current window only

## 6. Documentation and the full check

- [x] 6.1 Add `docs/plugins.md` (the manifest, the base class, the requests, the events, the numbers, the registry entry, the lint rule), the README section "Icons and Nerd Fonts", `plugin.hello.greet` and the action name form in `docs/actions.md`, a plugins note in `docs/compatibility.md`, and the updates to `CLAUDE.md` (Status, Layout, Coding conventions, Commands) and `docs/architecture.md` (section 9 as built, section 11); verify every new action has a line and every doc mention of the plugin host arriving later is updated
- [x] 6.2 Run `make snapshots`, review the diff, then `make check` and diff `make types` against `main` for new `untyped` members; verify everything passes and `spinel-doctor` reports clean

## Workflow follow-up

- Run the security review on the committed branch, then archive the change, open the pull request, and squash-merge it after CI is green.
