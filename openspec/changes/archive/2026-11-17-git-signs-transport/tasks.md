# Tasks

## 1. Transports

- [x] 1.1 Add `GIT_ALLOW_PROTOCOL` set to "" to `FileRequests::PROGRAM_ENVIRONMENT` and say so in the `git_signs` plugin's comment; proved by "A promisor remote with a command runs nothing" in `test/editor_git_signs.rb`, "run_program allows no transport" in `test/use_cases_plugins.rb`, and "The driver adds an empty variable to the child environment" in `test/drivers_process_runner.rb`

## 2. Floats of a disabled plugin

- [x] 2.1 Close the plugin's floats in every tab page from `PluginRegistry#clean_up`; proved by "Disabled with floats in two tab pages" in `test/use_cases_plugins.rb`

## 3. Focus

- [x] 3.1 Refuse a float the plugin does not own in `WindowRequests#focus_window` with "No window N"; proved by "Focus another plugin's float" in `test/use_cases_plugins.rb`

## 4. Documents and checks

- [x] 4.1 Update `docs/plugins.md` and the `FileRequests` entry of `docs/codebase-map.md`; `make gates`, `make spec-validate`, `make lint`, `make docs-lint`, and the touched tests pass
