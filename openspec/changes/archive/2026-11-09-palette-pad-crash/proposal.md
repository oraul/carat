# Proposal

## Why

A key bound to six or more wide characters stops the editor when the command palette opens: the palette cuts its key column to 11 characters rather than 11 cells, so the column measures wider than 12 cells and the pad repeats a space a negative number of times, which raises on the key path. The key hints float cuts its rows the same way and overflows its box with wide text. This is a T0 crash found by the periodic quality review at 7711421 (queue item 1).

## What Changes

- Add a cell-aware cut and fit to `Domain::DisplayWidth`: a text cut at a character boundary to at most N cells (zero-width combining marks kept with the character before them), and a text cut and padded with spaces to exactly N cells, never asking for a negative pad.
- Change the command palette to fit its name and key columns and to cut its rows through them, so a wide bound key is cut and padded without raising.
- Change the key hints float to cut its entries by cells through the same helper.
- Refactor the completion menu's private `fit` onto the shared helper, so the three menus cut text one way.
- Remove the backlog entries this fixes and record the plan's bookkeeping.

Out of scope: sizing the palette's name column from the longest name (queue item `discoverability-tidy`), the other discoverability advisories, and a full East Asian width table.

Roadmap: outside the roadmap of `docs/architecture.md` section 12; it fixes a crash in the delivered discoverability features, which a crash puts at the front of the queue.

Assumptions: the palette keeps its column layout (a name column of 28 cells and a key column of 12, each with at least one space after its text); a control character counts one cell, as `DisplayWidth.text_width` and the frame count it.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `command-palette`: a row's columns are cut and padded by display cells, so a wide or combining bound key renders without stopping the editor.
- `key-hints`: a hint row is cut by display cells to the float's width.

## Impact

- `carat/domain/display_width.rb` (new `cut`, `fit`, `bytes_within`), `carat/use_cases/discovery/follow_palette.rb`, `carat/use_cases/discovery/show_key_hints.rb`, `carat/use_cases/completion/show_completion.rb`.
- Tests: a new `test/domain_display_width.rb`, rows in `test/editor_palette.rb` and `test/editor_key_hints.rb`.
- No allocation on a key while no menu shows; `lh` is unchanged.
