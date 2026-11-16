# Tasks

## 1. The one-shot capture

- [ ] 1.1 Add `capture(argv)` to `Carat::Ports::ProcessPort`, `Carat::Drivers::ProcessRunner` (spawn without a shell, 64 KiB, 2-second deadline), and `Carat::Doubles::FakeProcesses` (scripted output); prove with `test/drivers_process_runner.rb` ("The driver runs a program without a shell")

## 2. The host request

- [ ] 2.1 Add `PluginApi::Host#run_program` and version 2.7 (`carat/plugin_api.rb`), the `PluginLink` override, and `FileRequests#run_program` with its checks; pass the process port through `PluginHost` and `EditorAssembly`; prove with `test/use_cases_plugins.rb` (the three request scenarios), `test/adapters_assembly.rb` (the one process port), `test/editor_floats.rb` (the version), and `make lint` (the override)

## 3. Icons and the plugin

- [ ] 3.1 Add the `ahead` and `behind` names to `Carat::Domain::Icons`; prove with `test/domain_icons.rb`
- [ ] 3.2 Add the `git_signs` plugin (`carat/plugins/git_signs/plugin.rb`) with `make new-plugin`, its configuration lines, and the regenerated registry; prove with `test/editor_git_signs.rb` (every scenario of `git-status`)

## 4. Docs and checks

- [ ] 4.1 Document the request, the plugin, and the icons in `docs/plugins.md`, `docs/compatibility.md`, `docs/architecture.md`, the README, and `docs/codebase-map.md`; prove with `make docs-lint` and `make lint`
- [ ] 4.2 Run `make gates` and `make spec-validate`
