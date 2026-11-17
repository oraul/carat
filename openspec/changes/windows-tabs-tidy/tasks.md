# Tasks

## 1. Float offset bound

- [x] 1.1 Compare offsets without `abs` in `Domain::FloatSpec.offset_refusal` (`carat/domain/float_spec.rb`); proved by "an offset at the integer minimum" in `test/domain_float_layer.rb`

## 2. Scroll handler

- [x] 2.1 Make `breaks_insert?` a predicate of `ActionHandler`, overridden by `ScrollHandler`, read by `Dispatcher`; proved by the insert-mode scroll checks of `test/editor_scroll.rb` and `test/editor_undo.rb` staying green
- [x] 2.2 Name the half-page `ScrollRequest` targets `:half_page_down` and `:half_page_up` in `ScrollHandler`, `ScrollWindow`, and `ScrollRequest`; proved by the Ctrl-D and Ctrl-U checks of `test/editor_scroll.rb`

## 3. Previous window

- [x] 3.1 Clear `tab.previous` in `BufferList#close_window` when it names the new current window and drop `CloseOtherWindows`' own clear; proved by "closing into the previous window clears it" and "Ctrl-W o leaves no previous window" in `test/editor_windows.rb`

## 4. Comments

- [x] 4.1 Rewrap every hand-written comment line past its file's wrap width (comments only, no test)

## 5. Checks

- [x] 5.1 `make gates`, `make spec-validate`, `make lint`, `make docs-lint`, and the touched tests pass
