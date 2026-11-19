# Proposal

## Why

The command line and the message row are the last parts of the Facet styling plan (cursor-and-messages parts 4 and 5) still drawn as before: the prompt, the typed text, and the pending keys are all `Normal`, an error paints its whole line bold red, an information message looks like the text around it, the hit-enter prompt is unstyled, and `-- INSERT --` repeats what the status bar's mode pill already says. The change is Facet wave 2 work from the feature queue, outside the numbered roadmap of `docs/architecture.md` section 12.

## What Changes

- Draw the command line's prompt and the pending keys at the right of the message row in a new dim group, `MsgDim`; the typed text stays `Normal`.
- Draw an error message as a glyph in `DiagnosticError`, a space, its code (`E` and digits, with the colon) in `ErrorMsg` (bold red), and the rest in `Normal`; a message of the error level without a code has the glyph and the text. The glyph is the `error` icon of `option.icons`.
- Draw any other message in `MsgDim`.
- Draw the hit-enter prompt in `Question`.
- Leave the message row blank in insert mode (the pill shows the mode); `-- VISUAL --` and the other visual indicators stay.
- Change the theme rows of `WarningMsg` (the warning glyph's yellow, no bold) and `MoreMsg` (bold blue) for every palette, and add the `MsgDim` row; nothing produces a warning, a `-- More --` pager, or a match count yet, so those rows are painted by no code in this change.

Out of scope: the several-line message band (`paint_list`), the diagnostic text on the message row, `ui-groups`, a warning or information level on `EditorState`, a pager, and the search match count (`search-count`).

Assumptions: an information message is any message not of the error level; a plugin prompt's text is drawn as the command line prompt, dim; under `NO_COLOR` the message row keeps its groups, since the frame presenter carries groups and the status of the rest of the editor under `NO_COLOR` is "keeps the theme" (`docs/compatibility.md`); the new group takes the id after `LineNrFifth` and moves the syntax, icon, and markup ids up by one.

## Capabilities

### New Capabilities

### Modified Capabilities
- `screen-rendering`: the message row's content and styling.
- `insert-mode`: the message row no longer shows the insert indicator.
- `color-themes`: the message groups' rows and the new `MsgDim` group.

## Impact

- Code: `carat/adapters/frame_presenter.rb`, `carat/domain/highlight.rb`, `carat/domain/themes.rb`.
- Tests: `test/adapters_frame_presenter.rb` (and its snapshot), `test/domain_theme.rb`, `test/editor_insert.rb`, `test/editor_screen.rb`, and the tests that read an error message from the message row.
- Docs: `docs/compatibility.md`, `docs/architecture.md` (the `Highlight` paragraph), `docs/codebase-map.md` areas 12 and 13.
- README.md: changed, a sentence names the message row's styling.
- docs/architecture.md: changed, the UI group count in the `Highlight` paragraph; the FramePresenter paragraph stays, since the file is at its docs-lint budget and `docs/compatibility.md` states the message row's styling.
