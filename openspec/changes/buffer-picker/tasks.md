# Tasks

## 1. Host requests

- [x] 1.1 Record the recent file paths in `Domain::BufferList` (`recent`, `RECENT_LIMIT`, recorded in `add`, kept after `remove`) and prove order, move to top, `:bd`, scratch and unnamed, and the bound in `test/use_cases_plugins.rb`
- [x] 1.2 Add `list_buffers` and `recent_files` to `PluginApi::Host`, `PluginLink`, and `BufferRequests`, bump the API to 2.14, update the version assertions (`test/use_cases_plugins.rb`, `test/domain_plugin_manifest.rb`, `test/editor_floats.rb`), and prove both requests and the disabled refusal in `test/use_cases_plugins.rb`
- [x] 1.3 Document the requests and 2.14 in `docs/plugins.md`, section 9.1 of `docs/architecture.md`, and `docs/codebase-map.md`; verify with `make docs-lint`

## 2. Finder pickers

- [x] 2.1 Replace the finder's `@grep` flag with a source, add the buffer and recent pickers and their bindings `<leader>fb`, `<leader>fr` in `carat/plugins/finder/plugin.rb`, and prove each scenario of the buffer and recent requirements in `test/editor_finder.rb`
- [x] 2.2 Add `<leader>fR` resuming the last picker with its query and clamped highlight, and the `No search to resume` message, proven in `test/editor_finder.rb`
- [x] 2.3 Prove the pickers' frame rows under `carat-dark`, `carat-light`, and `option.icons ascii` in `test/editor_finder.rb`
- [x] 2.4 Add the `docs/actions.md` rows, the `docs/compatibility.md` File finder rows, README's `<leader>f` paragraph, the item 12 line of `docs/architecture.md`, and the finder line of `docs/codebase-map.md`; verify with `make docs-lint` and `make test-one T=test/lint.rb`

## Workflow follow-up

- Run the quality step, `make gates`, `make spec-validate`, and `sh tools/run_state.sh check buffer-picker`.
- Archive the change in the package step.
