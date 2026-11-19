# Proposal

## Why

Neovim draws the bracket matching the one under the cursor in `MatchParen`. Carat has the group and a theme row for every palette, but no frame paints it, so a pair is never shown. The change is outside the numbered roadmap of `docs/architecture.md` section 12: it is Facet wave 2 work from the feature queue.

## What Changes

- Draw the bracket under the cursor and its partner in `MatchParen`, in the current window, in normal, operator-pending, and visual modes, for `(` `)`, `[` `]`, and `{` `}`, with the cursor on either bracket.
- Look for the partner only in the rows the window shows, counting nested brackets of the kind as `%` does, and read at most 200,000 code points per frame (`SearchBudget`); a pair with no partner in view draws nothing.
- Add the columns of a row's brackets to the record of what a row segment shows, so the row repaints when the pair appears, moves, or goes.
- Document the difference from Neovim in `docs/compatibility.md`.

Out of scope: `matchpairs`, skipping brackets inside strings and comments (as `%` here), the `matchparen` plugin's insert-mode and `showmatch` behavior, a pair across a closed fold, and floats' own cursors.

Assumptions: only the current window draws a pair; the group is painted after search highlights and before the Visual selection, so a selection covers it.

## Capabilities

### New Capabilities

### Modified Capabilities
- `screen-rendering`: adds the matching bracket highlight.

## Impact

- Code: `carat/adapters/frame_presenter.rb`, `carat/adapters/painted_rows.rb`.
- Tests: `test/adapters_frame_presenter.rb` (and its snapshot).
- Docs: `docs/compatibility.md`, `docs/architecture.md` section 8 (FramePresenter), `docs/codebase-map.md` area 13.
- README.md: changed, a sentence names the paired bracket highlight.
- docs/architecture.md: changed, the FramePresenter paragraph names the pair and the row record's new key.
