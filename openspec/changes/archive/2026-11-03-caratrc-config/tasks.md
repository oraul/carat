# Tasks

## 1. The line format in the domain

- [x] 1.1 Add `RcParse`, `RcLine`, and `RcParser` (`carat/domain/rc_parse.rb`, `rc_line.rb`, `rc_parser.rb`): byte-walking parse of one line into a key and words with quoting, escapes, comments, and the malformed-line errors; verify with the table-driven `test/domain_rc_parser.rb` over every value kind, comments, quoting, escapes, carriage returns, and malformed lines
- [x] 1.2 Add `RcValue` (`carat/domain/rc_value.rb`), the bool, integer, string, and list rules with their messages and plugin text, and `Config` (`carat/domain/config.rb`): reading a file's text into lines with the scope and `language` checks, the untrusted flag, notes, problems in file order, and the leader; verify in `test/domain_rc_parser.rb`
- [x] 1.3 Read options from `option.*` lines in `Options.from_config` with the option table, reporting unknown names, wrong kinds, unknown icon sets, and unknown themes; verify in `test/domain_options_config.rb` and the updated `test/domain_theme.rb` and `test/domain_icons.rb`
- [x] 1.4 Build the keymap from lines: `Keymap#add_checked(config, known)`, `#add_lines`, `.from_lines`, with `none` unbinding and problems by file and line; verify in the updated `test/domain_keymap.rb`

## 2. Configuration files and their port

- [x] 2.1 Convert `config/default.json` to `config/default.caratrc` and `config/plugins.json` to `config/plugins.caratrc`, remove the JSON files, render the registry from lines in `RegistrySource`, and generate `DEFAULT_CARATRC` with `bin/carat-gen-config.rb`; verify with `make gen-config` and the rewritten `test/config_sync.rb`
- [x] 2.2 Add `FilePort#home` with `DiskFiles` reading `HOME` and `MemoryFiles` keeping a movable one; make `ConfigPort#load` return a `Config`, replace `JsonConfigGateway` with `RcConfigGateway` reading the defaults, the user file, and the project file, and make `FixedConfig` serve defaults plus given lines; verify with the new `test/adapters_config_gateway.rb` (load order, missing files, unreadable file, project refusal of `language.*`)

## 3. Plugins on lines (API 2.0)

- [x] 3.1 Change `PluginApi` to 2.0 with line-list `bindings` and `options` and line-list scratch bindings; update `ManifestCheck`, `PluginRegistry` (enabled and options from lines, unknown plugins and options noted on the config), and `WindowRequests`; verify with the updated `test/domain_plugin_manifest.rb`, `test/use_cases_plugins.rb`, `test/use_cases_plugin_hardening.rb`, and `test/editor_plugins.rb`
- [x] 3.2 Move the explorer, ruby, and hello plugins and every test plugin to 2.0 manifests with lines; verify with `test/editor_explorer.rb`, `test/plugins_explorer.rb`, `test/editor_syntax.rb`, and the plugin tests passing

## 4. Assembly, tests, and benchmark

- [x] 4.1 Wire `EditorAssembly` and `bin/carat.rb` to the `Config` (leader, options, plugins, keymap, problems in file order) and `EditorHarness` and `bench/keys.rb` to `FixedConfig`; verify with `test/adapters_assembly.rb` (the gateway holds the shared file port) and the editor tests moved to lines (`editor_insert`, `editor_motions`, `editor_normal`, `editor_operators`, `editor_undo`, `editor_syntax`, `editor_visual`, `editor_explorer`, `editor_plugins`)
- [x] 4.2 Keep the analysis budget at 2 rounds, the allocation budget passing, and `make bench` (lh, j, insert, dd, undo) and startup within 10 percent of c4ea5d0; verify with `make check`, `make bench`, `make bench-budget`, and a startup timing of both binaries

## 5. Documentation

- [x] 5.1 Rewrite architecture section 7 for the `.caratrc` format and update sections 1, 2.1, 6, 8.3, 9, 10, 11, 12 (item 9 keeps `:set` beyond filetype and syntax and local options), and 13; verify by reading that no section names `config/default.json`, `config/plugins.json`, or the JSON user files
- [x] 5.2 Update `CLAUDE.md` (Stack, Commands, Layout, key binding and plugin conventions), `docs/plugins.md` (2.0 manifests with lines), `docs/actions.md`, `docs/backlog.md`, the README (a Configuration section with the examples and the load order), and `openspec/config.yaml`; verify with a search for the JSON file names outside archived changes

## Workflow follow-up

- Security review of the committed diff, archive with spec sync, pull request, CI, squash-merge.
