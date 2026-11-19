# Design

## Context

`FramePresenter#paint_window` paints rows through a record (`PaintedRows`) of everything a row shows; a row is repainted only when the record differs. `Highlight::MATCH_PAREN` and the theme rows exist; nothing paints them.

## Goals / Non-Goals

Goals: the pair as Neovim shows it for the three bracket kinds, bounded work per frame, no allocation on a key whose cursor is not on a bracket (the `lh` bench). Non-goals: see the proposal.

## Decisions

- The pair is found once per window paint (`find_pair`), before the row loop, from the decoded lines of the line cache (`DecodedLine#code`, no allocation), only for the current window outside a closed fold and only in a mode of the grammar (`Mode.grammar?`).
- The scan covers the window's rows only, so an off-screen partner draws nothing and the work is bounded by the window; a `SearchBudget` of 200,000 code points (`PAIR_BUDGET`) per frame bounds very long lines. Rejected: scanning the whole buffer as `%` does, which a frame must not.
- Brackets are matched by code point, with `Motions::PAIR_BYTES` and `Motions.pair_kind`, the same pairs and nesting as `%`.
- Row key: `PaintedRows` gains a `pair` integer per segment, the columns of the row's brackets plus one (0 for none), compared in `same?`, so a row repaints when the cursor moves onto or off a bracket and the other bracket's row repaints with it.
- Paint: `paint_pair` fills the bracket's cell through `fill_columns` after the search highlights and before the Visual selection, so horizontal scroll clips it.

## Risks / Trade-offs

A bracket in a string or comment pairs as `%` does; Neovim's plugin skips those through syntax. The pair key assumes columns under 1,000,003.
