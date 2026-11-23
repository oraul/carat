# Tasks

## 1. Bracketed paste

- [x] 1.1 Turn bracketed paste on at enter and off at leave (`carat/adapters/screen_presenter.rb`); proved by the Bracketed paste sequences row of `test/adapters_screen_presenter.rb`
- [x] 1.2 Decode a paste to `Key::PASTED` codes (`carat/adapters/key_decoder.rb`, `carat/domain/key.rb`); proved by the paste rows of `test/adapters_key_decoder.rb`
- [x] 1.3 Insert a paste as text and never run it (`carat/use_cases/handle_key.rb`); proved by the paste rows of `test/editor_insert.rb`

## 2. Presenter tidies

- [x] 2.1 Repaint a row painted after the budget stopped (`carat/adapters/frame_presenter.rb`); proved by the budget row of `test/adapters_frame_presenter.rb`
- [x] 2.2 Pass the row, currency, and number group as arguments, clear the layout once, ask `TabBar#showing?`; proved by the existing presenter rows and the `showing?` rows of `test/adapters_tab_bar.rb`
- [x] 2.3 Tidy `StatusBar`: dead require, `lsp_state`, `@plugin_index`; proved by the existing status bar rows

## 3. Docs

- [x] 3.1 Document the paste in `docs/compatibility.md` and `docs/codebase-map.md`

## Quality review

- [x] 4.1 The walk of matches left of the horizontal scroll is not changed, since starting mid-line alters overlapping matches: recorded in `docs/findings/render-tidy.md`, recorded
- [x] 4.2 A paste outside insert mode and the command line does nothing, where Neovim puts the text in: recorded in `docs/findings/render-tidy.md`, recorded
- [x] 4.3 A paste whose end mark never arrives keeps the decoder in the paste: recorded in `docs/findings/render-tidy.md`, recorded
- [x] 4.4 A large paste was copied once per byte by `consume`: `decode_paste` reads with a local index and consumes once
- [x] 4.5 A lead byte before the end mark swallowed it: an illegal sequence reads one byte, proved by the lead byte row of `test/adapters_key_decoder.rb`
