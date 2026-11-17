# Tasks

## 1. Activation state and triggers

- [ ] 1.1 Add the `active` member to `PluginEntry`, `PluginRegistry#activate` and `#prepare_all` (replacing `activate_all`), and deactivate only active entries; proven by `test/use_cases_plugins.rb` ("Events wait for activation").
- [ ] 1.2 Activate the owner in `PluginRouter#action` and `#command` and the provider in `PluginSyntax#provider`; skip inactive entries in `PluginEvents#deliver` and `#wanted?`; proven by `test/editor_lazy_plugins.rb` ("The explorer activates on its key", "The explorer activates on its ex command", "The finder activates on its key", "The ruby plugin activates on its first ruby buffer").
- [ ] 1.3 Add `PluginHost#prepare_all`, `#idle`, `#active?`, `#activate`, and call `idle` from the idle branch of `InputController#pump` (wired in `EditorAssembly`); proven by `test/editor_git_signs.rb` ("Git runs only after the first frame") and `test/editor_lazy_plugins.rb` ("No plugin is active at startup").
- [ ] 1.4 A raise in a late activate disables the plugin and the trigger stops; proven by `test/use_cases_plugin_hardening.rb` ("A raise in a late activate", "Tab page in activate").

## 2. API version and template

- [ ] 2.1 Move `PluginApi::VERSION` to 2.9 and document the `activate` contract in `carat/plugin_api.rb`; update `test/domain_plugin_manifest.rb`, `test/editor_floats.rb`, `test/use_cases_plugins.rb`.
- [ ] 2.2 Write the rule into the `make new-plugin` template in `tools/new.sh`; proven by `make tools-test`.

## 3. Existing tests

- [ ] 3.1 Move the plugin tests whose plugins assumed activation at startup to a trigger or `PluginHost#activate`, with `test/editor_explorer.rb` and `test/editor_tab_flows.rb` passing unchanged; proven by `make test`.

## 4. Docs

- [ ] 4.1 Write the rule into `docs/architecture.md` section 9, `docs/plugins.md` (with the 2.9 history), and `docs/codebase-map.md` (area 15, the new test); proven by `make docs-lint` and `make lint`.

## 5. Gates

- [ ] 5.1 Run `make gates`, `make spec-validate`, and `make diagnose-one` on the touched files, all clean.

## 6. Results

- [ ] 6.1 Record the base defect of `make test-one T=test/use_cases_plugins.rb` in `docs/findings/plugin-lazy-activate.md` if it still fails.
- [ ] 6.2 Measure startup to the first frame in a pty over 15 runs and record it in the proposal's Results.
