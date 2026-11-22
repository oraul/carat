# Design

## Context

`FramePresenter#paint_window` paints a closed fold's row through `paint_row` with the label of `Folds#label` as its line and `Domain::SyntaxLine::NONE` as its syntax, so `paint_text` writes every cell in `Normal`. A row's tokens are painted by `paint_tokens` after the text, in code point columns, and the row cache (`PaintedRows#same?`) keys on the syntax entry by identity. The cursor-line layer is applied afterwards by `Frame#lift`. Highlight ids are plain integers; UI groups come first, and `Themes::GROUPS` maps each to its roles, the cursor-line and float copies derived from it.

## Goals / Non-Goals

**Goals:**
- Paint the closed-fold row in its own group, `Folded`, in both carat themes and every other palette, at every depth, under ascii and `NO_COLOR`.

**Non-Goals:**
- The label's text or glyphs (`docs/design.md`'s `▸` and `⋯ N lines`), `foldtext`, `fillchars`, a fold column.

## Decisions

- One constant token entry. The fold branch sets `syntax` to `FOLD_SYNTAX`, a `SyntaxLine` constant of `FramePresenter` holding one token from column 0 over `FAR` code points in `Folded`. `paint_tokens` cuts it at the label's end, so the label and its fill take `Folded`, and what paints over tokens (search matches) still paints over it. Being one shared value, it keeps the row cache's identity key stable, allocates nothing per frame, and makes a row repaint when it turns from text into a fold or back. Alternative: a `frame.fill` over the text after `paint_row`; it would paint over the matches drawn there and need its own cache input, so it was not taken.
- `Folded` is a UI group after `MsgDim`, Neovim's name, as `MsgDim` was added before it: the later ids move up by one, and no code names them by number. A UI group, so `Highlight.token?` and `float_style?` refuse it.
- The theme row is `DIM, NONE, 0, 0`, the dim role every palette already carries at 16 colors (basic color 8), so the 16-color check of `test/domain_theme.rb` holds with no new role, and the cursor-line copy derives from it.
- `NO_COLOR` keeps the group: the frame presenter's plain mode keeps UI groups (the message row does the same) and leaves the color choice to the terminal side.

## Risks / Trade-offs

- Every syntax, file-icon, and markup id moves by one: a snapshot or plugin test that printed an id number changes; plugins resolve groups by name (`token_id`), so none breaks.
- The label still reads `+--N lines:` with the `·` fill, also under ascii, which the design file does not describe; recorded for a later change rather than widened here.
