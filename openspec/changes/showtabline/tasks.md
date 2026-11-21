# Tasks

## 1. The option

- [x] 1.1 `Options` gains `showtabline` (1 in code, 2 shipped, `bounded` 0 to 2); `config/default.caratrc` row and `make gen-config` mirror (proved by `test/domain_options_config.rb` "showtabline is 0, 1, or 2" rows and "The shipped default")
- [x] 1.2 `BufferList#tab_row?` takes the value; `ArrangeView` and `FramePresenter` pass it (proved by `test/use_cases_arrange_view.rb` rows and `test/adapters_frame_presenter.rb` rows, "Buffer tabs take the top row" scenarios)
- [x] 1.3 `:set showtabline` and `:set stal` answer Not implemented (proved by `test/editor_syntax.rb`, "`:set` answers not implemented")
- [x] 1.4 `FixedConfig.defaults` keeps `option.showtabline 1`; `FixedConfig.shipped` is the defaults alone

## 2. Docs

- [x] 2.1 buffer-tabs and config-files specs, `docs/compatibility.md`, README option list, `docs/architecture.md`, `docs/codebase-map.md`
