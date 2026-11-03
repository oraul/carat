# Tasks

## 1. Struct records

- [x] 1.1 Add `keyword_init: true` to every `Struct.new` under `carat/` and in `test/domain_buffer_list.rb` and `test/use_cases_ex.rb`, give every custom `initialize` keyword parameters with a keyword signature and keyword `super` calls (`TabList`'s parameter renamed to `window:`); verify that `make test-build` compiles the runner with 2 re-narrowing rounds.
- [x] 1.2 Pass keywords at every `Struct` construction site in `carat/`, `test/`, `bench/`, and `bin/`; verify with `make test-run`, every snapshot unchanged.
- [x] 1.3 Measure `make analysis-budget` and the `lh`, `j`, `insert`, `dd`, and `undo` scenarios of the benchmark against a benchmark built from 9edf2a3, interleaved; verify the rounds and that every scenario is within 10 percent, recorded in design.md.

## 2. Data values

- [x] 2.1 Pass keywords at every `Data` construction site in `carat/`, `test/`, `bench/`, and `bin/`, the plugin manifests included, without changing a `Data` definition; verify with `make test-build` and `make test-run`, every snapshot unchanged.
- [x] 2.2 Measure the analysis and the benchmark again as in 1.3; verify against both earlier measurements, recorded in design.md with the decision.

## 3. Lint

- [x] 3.1 Add `struct_problem` and `construction_problem` to `test/lint.rb`, run over `carat/`, `bin/`, `test/`, and `bench/`, and extend the constructor rule to record files; verify with `make lint`, the snapshot the empty report, and with the rules' good and bad cases asserted.

## 4. Documentation

- [x] 4.1 Update `CLAUDE.md` (the record convention, the trap note, the lint description), `docs/architecture.md` (section 2.1 and the lint description), and `docs/plugins.md` (keyword construction of the plugin API values and the 1.3 note); verify by reading them against the code.

## Workflow follow-up

- Run `make check`, `make analysis-budget`, and `make bench-budget` on the final commit, each detached with its own log under `build/stages/`.
- Run the security review on the committed branch diff, archive with `--skip-specs`, push once, open the pull request, wait for CI, and squash-merge.
