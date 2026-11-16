## 1. Shared trust rule

- [ ] 1.1 Add `Domain::TrustedRoots.cover?` (`carat/domain/trusted_roots.rb`) with the gateway's rule, proved by the new `test/domain_trusted_roots.rb`
- [ ] 1.2 Make `Adapters::JsonRpcLanguageGateway#trusted?` use it, its existing trust tests in `test/adapters_language_*.rb` unchanged and passing

## 2. Program environment

- [ ] 2.1 Give `Ports::ProcessPort#capture` the variables to add, implemented by `Drivers::ProcessRunner` (spawn's environment) and `Doubles::FakeProcesses` (recorded per call), proved by `test/drivers_process_runner.rb` "The driver adds the variables to the child's environment"

## 3. The host's refusal

- [ ] 3.1 `UseCases::FileRequests#run_program` refuses while not trusted and passes `GIT_NO_LAZY_FETCH=1`; `UseCases::PluginHost#activate_all` decides trust through `Domain::TrustedRoots`; proved by `test/use_cases_plugins.rb` "run_program outside a trusted root starts nothing", "run_program before activation starts nothing", and "run_program turns git's lazy fetch off"

## 4. git_signs

- [ ] 4.1 `Plugins::GitSigns::Plugin` passes `-c protocol.ext.allow=never -c core.fsmonitor=false` on both commands; `test/editor_git_signs.rb` runs under a trusted root and proves "Outside a trusted root no git runs", "Under a trusted root the branch and counts show", and "A promisor remote with a command runs nothing"

## 5. Docs

- [ ] 5.1 Update README.md, `docs/plugins.md` (run_program), `docs/architecture.md` (the trust rule), and `docs/codebase-map.md` (the new domain file and its test), checked by `make docs-lint` and `make lint`
