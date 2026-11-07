# Tasks

## 1. Domain

- [x] 1.1 `carat/domain/buffer.rb`: `diagnostics`, `diagnostic_marks`, `set_diagnostics`, `clear_diagnostics`, `diagnostic_at`, the marks moved by `shift_signs`, the `lsp.diagnostics` sign layer at priority -1. Tested by `test/domain_buffer.rb` (most severe per row, sign over a plugin's, past the end, moved by an insert, cleared).
- [x] 1.2 `carat/domain/control_text.rb` `line` (breaks and tabs as spaces) and `carat/domain/status_slots.rb` `count_diagnostics`. Tested by `test/domain_rpc_framer.rb` and `test/adapters_status_bar.rb`.

## 2. Gateway and presenter

- [x] 2.1 `carat/adapters/json_rpc_language_gateway.rb`: messages through `ControlText.line`, a publish applied to its buffers at the idle tick, the counts written, a restart and a start after a crash clearing the file type's buffers. Tested by `test/adapters_language_gateway.rb`.
- [x] 2.2 `carat/adapters/frame_presenter.rb` `paint_message`: the cursor line's diagnostic in normal mode in its severity's group. Tested by `test/adapters_frame_presenter.rb` and the drawn editor in `test/editor_lsp.rb` (signs, message row, counts, restart).

## 3. Docs and records

- [x] 3.1 `docs/codebase-map.md`, `docs/architecture.md` language services, `README.md`. Checked by `make gates` and `make docs-lint`.
- [x] 3.2 Plan notes: `build/plan/queue.md` as `docs/queue.md`, the six `build/plan/backlog.md` entries in `docs/backlog.md`, the listed entry updates, the UTF-16 columns entry reworded and the `error?` part of the loose ends entry removed, a follow-up entry for the left-out display parts. Checked by `make docs-lint`.
- [x] 3.3 `make gates`, `make spec-validate`, `make test`, and `make metrics-compare` with allocations per key unchanged.
