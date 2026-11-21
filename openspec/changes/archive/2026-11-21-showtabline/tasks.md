# Tasks

## 1. The option

- [x] 1.1 `Options` gains `showtabline` (1 in code, 2 shipped, `bounded` 0 to 2); `config/default.caratrc` row and `make gen-config` mirror (proved by `test/domain_options_config.rb` "showtabline is 0, 1, or 2" rows and "The shipped default")
- [x] 1.2 `BufferList#tab_row?` takes the value; `ArrangeView` and `FramePresenter` pass it (proved by `test/use_cases_arrange_view.rb` rows and `test/adapters_frame_presenter.rb` rows, "Buffer tabs take the top row" scenarios)
- [x] 1.3 `:set showtabline` and `:set stal` answer Not implemented (proved by `test/editor_syntax.rb`, "`:set` answers not implemented")
- [x] 1.4 `FixedConfig.defaults` keeps `option.showtabline 1`; `FixedConfig.shipped` is the defaults alone

## 2. Docs

- [x] 2.1 buffer-tabs and config-files specs, `docs/compatibility.md`, README option list, `docs/architecture.md`, `docs/codebase-map.md`

## 3. The editor-level proof

- [x] 3.1 `test/editor_tabs.rb` rows: a configuration line gives one file its row, 0 hides two files' row, and the shipped configuration alone shows one file's row (proved by "One file has the row under 2")
- [x] 3.2 `test/smoke_editor.rb`: the shipped default shows one file's row, so the window-move cursor and the PageDown page move one row down

## Quality review

- [x] Q.1 The `Options` header comment ran past the wrapped width; reflowed (fixed)
- [x] Q.2 The `FixedConfig` header said `defaults` reads the shipped defaults, which `shipped` now does; reworded (fixed)

Edge-case checklist: the option changes only a row count, so empty range, CRLF, UTF-16, trailing blanks, and last line do not arise; the empty buffer (no file listed under 2) has a row of the frame presenter and a row of the arrange test.
