# Tasks

## 1. Groups and theme

- [ ] 1.1 Add the `MsgDim` group after `LineNrFifth`, its theme row, and the `WarningMsg` and `MoreMsg` rows (`carat/domain/highlight.rb`, `carat/domain/themes.rb`; `test/domain_theme.rb`)

## 2. Rendering

- [ ] 2.1 Draw the command line's prompt and the pending keys in `MsgDim`, an information message in `MsgDim`, the hit-enter line in `Question`, and an error as glyph, code, and text; drop the insert indicator (`carat/adapters/frame_presenter.rb`; `test/adapters_frame_presenter.rb`, both carat themes and plain)
- [ ] 2.2 Update the tests that read an error or the insert indicator from the message row (`test/editor_*.rb`)

## 3. Docs

- [ ] 3.1 Document the styling and the differences in `docs/compatibility.md`, `docs/architecture.md`, `docs/codebase-map.md`, and `README.md` (`make docs-lint`)
