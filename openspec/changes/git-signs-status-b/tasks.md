# Tasks

## 1. The timeout message

- [ ] 1.1 Add `timed_out?` to `Carat::Ports::ProcessPort`, `Carat::Drivers::ProcessRunner`, and `Carat::Doubles::FakeProcesses` (with `time_out(command)`), and fail `Carat::UseCases::FileRequests#run_program` with "PROGRAM ran past 2 seconds" on a timeout; prove with `test/drivers_process_runner.rb` and `test/use_cases_plugins.rb` ("run_program says a program ran past its deadline")

## 2. Icons and the diff

- [ ] 2.1 Add `git_added`, `git_changed`, and `git_deleted` to `Carat::Domain::Icons`; prove with `test/domain_icons.rb` ("The git sign glyphs per set")
- [ ] 2.2 Add `Carat::Plugins::GitSigns::LineDiff` (`carat/plugins/git_signs/line_diff.rb`); prove with the new `test/plugins_git_signs_diff.rb` (the marks of each sign kind, the top removal, equal and empty texts, the edit cap)

## 3. The plugin

- [ ] 3.1 Place the signs from the text at HEAD in `Carat::Plugins::GitSigns::Plugin`; prove with `test/editor_git_signs.rb` ("Each sign kind shows on its lines", "Lines removed at the top mark the first line", "A file git does not hold shows no sign", "The text capture refuses ext:: and fsmonitor")
- [ ] 3.2 Gate a focus on the HEAD key and back off after a timeout in `Carat::Plugins::GitSigns::Plugin`; prove with `test/editor_git_signs.rb` ("A focus with HEAD and the file unchanged runs no git", "The signs follow an unsaved edit on focus", "A focus after HEAD moved asks git again", "A timed-out capture stalls no later event", "git runs again after HEAD moves", and part a's segment scenarios)

## 4. Docs and checks

- [ ] 4.1 Document the signs, the focus rule, the timeout, the icons, and the message in `docs/plugins.md`, `docs/compatibility.md`, `docs/architecture.md`, the README, and `docs/codebase-map.md`; prove with `make docs-lint` and `make lint`
- [ ] 4.2 Run `make gates` and `make spec-validate`
