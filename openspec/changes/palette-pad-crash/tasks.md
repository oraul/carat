# Tasks

## 1. Cell-aware cut and fit

- [x] 1.1 Add `bytes_within`, `cut`, and `fit` to `carat/domain/display_width.rb`, proved by the wide, combining, control, and invalid-byte rows of a new `test/domain_display_width.rb` (`make test-one T=test/domain_display_width.rb`)

## 2. The menus use them

- [x] 2.1 Change `carat/use_cases/discovery/follow_palette.rb` to fit its columns and cut its rows by cells, proved by the wide-key and combining-key rows of `test/editor_palette.rb`
- [x] 2.2 Change `carat/use_cases/discovery/show_key_hints.rb` to cut its entries by cells, proved by the wide-remap row of `test/editor_key_hints.rb`
- [x] 2.3 Refactor `carat/use_cases/completion/show_completion.rb` onto `DisplayWidth.fit`, proved by `test/editor_completion.rb` unchanged

## 3. Records

- [x] 3.1 Update the map (`display_width.rb` entry, the new test on the render area's Tests line) and the backlog bookkeeping of the plan notes in `docs/backlog.md`, proved by `make docs-lint` and `make lint`
- [x] 3.2 Run `make gates`, `make spec-validate`, and the targeted tests; `make bench` shows `lh` allocations per key unchanged

## Workflow follow-up

- The plan's backlog entries (`build/plan/backlog.md`) and queue (`build/plan/queue.md`) are already in `docs/backlog.md` and `docs/queue.md`, with item 36's cut-by-characters defect dropped; the package step re-copies only a newer plan and runs `tools/run_state.sh history`.
