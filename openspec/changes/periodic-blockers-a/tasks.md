# Tasks

## 1. gd finds its own file under any spelling

- [ ] 1.1 `carat/use_cases/definitions/visit_target.rb`: `absolute` answers `PluginApi::Paths.absolute(@files.cwd, path)`, and the target is compared through it in `jump` and `listed_for`. Tested by "A target in the current file named with dot segments moves the cursor" in `test/adapters_definitions.rb`, both spellings, modified and unmodified.

## 2. One owner per gateway lifecycle step

- [ ] 2.1 `carat/adapters/json_rpc_language_gateway.rb`: `cancel`, `cancel_resolve`, `cancel_hover`, `cancel_definition`, and `cancel_symbols` call `cancel_request`. Tested by the unchanged cancellation rows of `test/adapters_hover.rb`, `test/adapters_server_completions.rb`, `test/adapters_definitions.rb`, and `test/editor_breadcrumbs.rb`.
- [ ] 2.2 `carat/adapters/json_rpc_language_gateway.rb`: `forget_server` replaces the four forget steps, called by `stop` and `crash`. Tested by "stop forgets the symbol request in flight" in `test/editor_breadcrumbs.rb` and the existing crash rows.
- [ ] 2.3 `carat/adapters/json_rpc_language_gateway.rb`: `position_params` and `running_server` shared by the sends. Tested by the request rows of the completion, hover, definition, signature, and symbol tests.

## 3. Records

- [ ] 3.1 `docs/codebase-map.md`: the gateway entry names the shared steps; `docs/backlog.md`: the four entries removed. Checked by `make gates` and `make docs-lint`.
