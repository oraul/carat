# Tasks

## 1. Planner records

- [ ] 1.1 `docs/queue.md` and `docs/goals.md` from `build/plan/`, the three periodic quality entries of `build/plan/backlog.md` in `docs/backlog.md`, and the `theme-tokens` row of `docs/metrics.tsv` through `sh tools/run_state.sh history`; verified by `make docs-lint`.

## 2. Options and the terminal

- [ ] 2.1 `carat/domain/options.rb`: `startscreen` (true) and `reducedmotion` (false) as bool members and kinds; `config/default.caratrc` and `make gen-config`; rows in `test/domain_options_config.rb` and the shipped defaults in `test/config_sync.rb` pass.
- [ ] 2.2 `carat/ports/terminal_port.rb` `no_color?`, `carat/drivers/ansi_terminal.rb` reading `NO_COLOR`, `carat/doubles/fake_terminal.rb` with a writer; covered by `test/editor_start_screen.rb`.

## 3. The start screen

- [ ] 3.1 `carat/domain/start_art.rb`: `StartArt.build(plain)`, the six precomputed frames and the wordmark, `paint`; frames and glyph widths checked in `test/editor_start_screen.rb`.
- [ ] 3.2 `carat/domain/start_screen.rb`: the record with `start`, `animating?`, `due?`, `advance`, `wait`, `dismiss`; timing rows in `test/editor_start_screen.rb`.
- [ ] 3.3 `carat/adapters/input_controller.rb` (timeout, advance, dismiss on a key), `carat/adapters/frame_presenter.rb` (the overlay), `carat/adapters/editor_assembly.rb` (the record, `open` with an empty path or a directory); `test/adapters_assembly.rb` shared-instance row, the presenter tests' constructors, and `test/editor_start_screen.rb` with every frame printed into its snapshot.
- [ ] 3.4 `bin/carat.rb`: zero or one argument, `usage: carat [FILE]`; `test/smoke_editor.rb` rows for two arguments and a start without one.

## 4. Documentation and checks

- [ ] 4.1 `README.md`, `docs/compatibility.md` (Start screen), `docs/codebase-map.md` (new files and tests), `docs/backlog.md` (`NO_COLOR` for the rest of the editor); `make docs-lint` passes.
- [ ] 4.2 `make gates`, `make lint`, and the bench allocations of `lh` unchanged (`make bench-budget`).
