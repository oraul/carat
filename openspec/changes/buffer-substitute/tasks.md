# Tasks

## 1. Ranges

- [ ] 1.1 Add `range` to `Domain::ExCommand` and read the range and the `&` name in `Domain::ExGrammar`, proven by new rows of `test/domain_ex_grammar.rb`
- [ ] 1.2 Add `Domain::ExRange` (`resolve`: `%`, `.`, `$`, numbers, `'<`, `'>`, E16, E20, E493, Not implemented), proven by `test/domain_ex_range.rb`
- [ ] 1.3 Add `ExHandler#ranged?`, E481, and the bare-range cursor move to `UseCases::ExecuteEx`, proven by `test/use_cases_ex.rb` (the bare number row changes) and `test/editor_substitute.rb`
- [ ] 1.4 Make `EnterCommandLine` prefill `'<,'>` from a visual mode, bind `:` in the three visual maps, run `make gen-config`, and update the `mode.cmdline` row of `docs/actions.md`, proven by `test/editor_substitute.rb` and `test/use_cases_actions.rb`

## 2. Substitute in the domain

- [ ] 2.1 Add the substitute mode of `Domain::VimPattern` (capturing groups, E51, `~`), proven by `test/domain_substitute.rb`
- [ ] 2.2 Add `Domain::SubstituteArgs`, `Domain::LastSubstitute`, `Domain::Replacement`, and `Domain::Substitution`, proven by `test/domain_substitute.rb`

## 3. Commands and keys

- [ ] 3.1 Add `UseCases::SubstituteLines` (memory, flags, budget, one splice, cursor, messages, last search) and `SubstituteCommandHandler` (`s[ubstitute]`, `&`), wired in `EditorAssembly`, proven by `test/editor_substitute.rb` and `test/use_cases_ex.rb` (every documented spelling)
- [ ] 3.2 Add `SubstituteHandler` (`substitute.repeat`, `substitute.repeat_all`), bind `&` and `g&` in the normal map, run `make gen-config`, and list both in `docs/actions.md`, proven by `test/editor_substitute.rb` and `test/use_cases_actions.rb`

## 4. Documents and checks

- [ ] 4.1 Document the ranges, `:s`, `:&`, `&`, `g&`, flags, replacement characters, and differences in `docs/compatibility.md`, the files in `docs/codebase-map.md`, `README.md`, and the status line of `CLAUDE.md`, checked by `make docs-lint` and `make gates`
- [ ] 4.2 Apply the plan notes: remove the ranges entry and add the `~` entry in `docs/backlog.md`, add the five periodic review entries, update the queue pointers, and commit `build/plan/queue.md` as `docs/queue.md`, checked by `make docs-lint`
- [ ] 4.3 Check that `lh`, `j`, `insert`, and `undo` allocate what they did at e20c83c (27.0, 28.0, 35.0, 53.0) with `make bench-budget` and `make metrics`, and run `make lint`, `make test`, and `make gates`, all passing

## Workflow follow-up

- Archive with `openspec archive buffer-substitute -y`, record the plan and metrics history, push, and open the pull request.
