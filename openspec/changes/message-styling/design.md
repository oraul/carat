# Design

## Context

`FramePresenter#paint_message` draws the message row: every part is `Normal` except an error, which is `MessageError` over the whole line. `EditorState` holds one bool for the level (`message_error`). The theme rows of `WarningMsg`, `MoreMsg`, and `Question` exist and no code paints them.

## Goals / Non-Goals

Goals: the Facet message styling for what the editor produces today, in both carat themes, with the attributes kept under `NO_COLOR`. Non-goals: producers for a warning, a pager, or a match count; the multi-line band; diagnostic text.

## Decisions

- One new group, `MsgDim` (`MESSAGE_DIM`, the dim role on the terminal's background), for the prompt, the pending keys, and an information message. The other wanted styles reuse groups: the error glyph `DiagnosticError` (red, as the sign), the code `ErrorMsg` (bold red), the text `Normal`, the hit-enter prompt `Question`. Rejected: reusing `LineNrFifth` or an icon group, whose names say something else.
- The new id follows `LineNrFifth`, so the plugin-token range stays the last ids and no UI group is a token; the ids from `SYNTAX_FIRST` on move up by one, which no snapshot records.
- The error's code is the leading `E`, digits, and colon of the text. The split is made when drawing; `EditorState` keeps its text and bool.
- The glyph is `Icons.glyph("error", options.icons)`, so `option.icons ascii` gives `X`.
- Insert mode draws nothing in the message row; a message or the pending keys still show.
- `WarningMsg` becomes yellow without bold because it colors only a glyph; `MoreMsg` becomes bold blue. Both stay unpainted until a producer exists.

## Risks / Trade-offs

An error row is two cells longer, so a test or a user reading it as text sees the glyph first. A plugin that draws the whole error line itself is unaffected.
