# Tasks

## 1. Host requests (API 2.5)

- [x] 1.1 Add `ListTree` (`carat/use_cases/files/list_tree.rb`) and the `list_files` and `read_file` requests in `PluginApi::Host`, `PluginLink`, and `FileRequests`; rows in `test/use_cases_plugin_files.rb`.
- [x] 1.2 Add `live_prompt`, `close_prompt`, and `Plugin#on_prompt_change`: `Domain::PluginUi` members, `UiRequests`, `PluginRouter#follow_prompt`, `PluginHost#follow_prompt`, and the prompt keymap and follow in `HandleKey`; bump `PluginApi::VERSION` to 2.5; rows in `test/use_cases_plugin_files.rb` and `test/editor_floats.rb`.

## 2. The finder

- [x] 2.1 Add `Plugins::Finder::Matcher` (`carat/plugins/finder/matcher.rb`); table in `test/plugins_finder_matcher.rb`.
- [x] 2.2 Add `Plugins::Finder::Plugin` (`carat/plugins/finder/plugin.rb`), list it in `config/plugins.caratrc`, add its lines to `config/default.caratrc`, remove `file.find` from `FileHandler` and its default line, and run `make gen-config`; every `file-finder` scenario a row of `test/editor_finder.rb`; `test/editor_leader.rb` loses the reserved row.
- [x] 2.3 Add the `finder` scenario to `bench/keys.rb` and check its time per key under 20 ms and the `lh` allocations unchanged.

## 3. Docs and checks

- [x] 3.1 Update `docs/plugins.md`, `docs/actions.md`, `docs/compatibility.md`, `docs/codebase-map.md`, `docs/architecture.md`, `README.md`, and `docs/backlog.md` (the plan notes); `make docs-lint` and `make gates` pass.
- [x] 3.2 Run `make test`, `make lint`, `make diagnose`, and `make spec-validate`, all passing.
