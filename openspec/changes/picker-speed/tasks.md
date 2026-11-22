# Tasks

## 1. The gate

- [ ] 1.1 Add `lh-float` and `palette` to the default list of `bench/run.sh` and the `--budgets` mode; prove them in `tools/tools_test.sh` (the default list holds the float, finder, and palette scenarios; a figure passes; a doubled figure fails; one failing scenario fails the list and names itself)
- [ ] 1.2 Add `PICKER_BUDGETS` to the Makefile and run it from `bench-budget` at 20 and 120 keys; prove it by `make bench-budget` and `make -n bench-budget` in `tools/tools_test.sh`

## 2. Docs

- [ ] 2.1 Update README.md, `docs/architecture.md`, `docs/codebase-map.md`, the Makefile help line, and the CI step comment
- [ ] 2.2 Append the planner's backlog notes (`build/plan/picker-speed/backlog.md`) and the out-of-scope notes to `docs/findings/picker-speed.md`

## Quality review
