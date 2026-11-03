# Tasks

## 1. Reproduce

- [x] 1.1 Record on 80314d8 the `SP_TIMING=1` phases (`analysis`, `analysis_fixpoint` and `analysis_renarrow` with rounds, `an_cls_facts`, `codegen_program`, and `cc_total` at `-O1`) of `bin/carat.rb` and `test/domain_buffer.rb`, and the widened entries of `spinel --emit-rbs` for both; verify by the table and the lists in design.md.
- [x] 1.2 Survey every compile root at 80314d8: the analysis phases of each, and its emitted library signatures compared with `bin/carat.rb`'s, to find every test program whose calls widen the library; verify by the survey table in design.md, re-measuring the slow programs without other work running.

## 2. Typed values in the tests

- [x] 2.1 `test/domain_buffer.rb`: copy the tables' line lists through a `strings` helper and convert rows and columns with `to_i` before `Buffer.new`, `insert`, `delete`, `set_lines`, and `text_of`, including the empty `set_lines` list; verify that its `spinel --emit-rbs` library signatures equal `bin/carat.rb`'s (`ChangeRecord @inserted: Array[String]`, `Buffer#splice` and `LineSplice` taking `Array[String]`, `Position` typed) and that its analysis needs 2 re-narrowing rounds.
- [x] 2.2 `test/domain_selection.rb` (`buffer_of` copies, `pos` converts), `test/domain_grammar.rb` (an `ints` helper for the key codes, in `codes` and in `run`), `test/adapters_frame_presenter.rb` (`[line.to_s]`), and `test/use_cases_actions.rb` (the ex command name through `to_s`); verify that each program's emitted library signatures equal `bin/carat.rb`'s and that each analyses with 4 fixpoint and 2 re-narrowing rounds.

## 3. The analysis budget

- [x] 3.1 Add `tools/analysis_budget.sh` and the `make analysis-budget` target in the `Makefile` (`ANALYSIS_ROOTS`, `ANALYSIS_ROUNDS`, `ANALYSIS_MS`, the help line, `.PHONY`, and `check`); verify that `make analysis-budget` passes on this change in under a minute and that the script fails on the 80314d8 sources, naming `test/domain_buffer.rb` at 5 rounds.
- [x] 3.2 Run `make bench`'s `lh`, `j`, `insert`, `dd`, and `undo` scenarios on benchmarks built from 80314d8 and from this change, interleaved, and the allocation budget; verify that every scenario is within 10 percent and the budget passes, with the numbers in design.md.
- [x] 3.3 Add an Analysis budget step to `.github/workflows/ci.yml` before the Test step; verify that the workflow still parses and the step's command passes locally; the pull request's job log, checked before merge, shows the two roots within the budget.

## 4. Documentation

- [x] 4.1 Update `CLAUDE.md` (status, Commands with `make analysis-budget` and `make check`, Layout with `tools/analysis_budget.sh` and the CI line, and the coding convention that test programs pass typed values into the library), `docs/architecture.md` (section 10 and the layout of section 11), and the README's command table; verify by reading them against the `Makefile`.
- [x] 4.2 Record in `docs/backlog.md` that every test program analyses the whole library, the main cost of `make test`, and that test plugins widen the unpinned manifest hashes; verify by reading the entries against the survey.

## Workflow follow-up

- Archive with `--skip-specs` and commit, then run the stages of `make check` (`make build`, `make gen-config`, `make analysis-budget`, `make test`, `make diagnose`, `make no-cruby`) and `make bench-budget` on that commit, each detached with its own log and recorded in a progress file under `build/`.
- Run the security review on the committed branch diff.
- Push once, open the pull request, wait for CI, and squash-merge.
