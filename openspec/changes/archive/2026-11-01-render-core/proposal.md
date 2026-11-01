# Proposal

## Why

Rendering is 73 to 96 percent of the time Carat spends on a key: on 0978d16, at 200 by 60 with 10,000 lines, a key costs 0.89 to 1.08 ms, of which key handling is about 20 us; every key allocates about 8,100 objects (one-character strings from `line[i,1]` and integer arrays from `each_codepoint` in `Frame#put`), the collector takes 6 to 8 percent of the time with single keys up to 10 ms, every `j` that scrolls writes about 13 KB because every row is rewritten, and a cursor at the end of a 10,000-character line with one accented letter costs 21 ms per key. The frame presenter also arranges the layout and scrolls the windows, so use cases read the geometry of the previous render, contrary to section 8.2 of `docs/architecture.md`. This is the `render-core` change of the core-quality queue the user approved before more plugins are added.

## What Changes

- `Frame` keeps its cells in three flat `Array[Integer]` arrays (code point, display width, highlight id) indexed by `row * cols + col`; the frame presenter owns two preallocated frames, reallocated only on resize, and paints into the one not on the screen, so no grid, cell, or copy is made per render. `Frame#cell` builds a `Cell` value on demand for tests.
- Lines are painted from decoded code points: a `DecodedLine` holds a line's code points and the display column of each, and a `LineCache` keyed by line identity holds the decoded lines of the visible rows of every window, dropping the ones that left the view. `DisplayWidth.column` and `col_at` walk the bytes of a line instead of slicing it, and the word motions' `Walker` and `Buffer#first_nonblank` stop slicing one-character strings.
- Each frame records, for every row, whether it differs from the frame before it; the frame presenter repaints only the rows whose content changed (the line shown, its number, sign, selection, or cursor, or the window's geometry and scroll), and the screen presenter compares only those rows and writes only the runs of cells that changed.
- When a window that spans the full width scrolls vertically by fewer rows than its height, the screen presenter emits a terminal scroll region (`DECSTBM` with scroll up or down), resets it, and writes only the rows that came into view and the cells that changed.
- A new `ArrangeView` use case arranges the current tab page's layout and scrolls every window to its cursor, run after every key, after opening a file, and before every render; the screen size lives in `EditorState`. `FramePresenter#call(state)` only reads the state.
- A few allocations of every key outside rendering go, so the collector's share of a key that now takes microseconds stays small: the gutter width counts digits, the keymap looks ASCII keys up under strings made once, the plugin host builds no event no plugin subscribes to, the key decoder keeps one empty string, and typing or deleting within a line builds one new line string instead of three.
- `make bench` builds and runs a key latency and allocation benchmark from `bench/`, `make profile` builds the editor with `spinel --profile` and prints the top functions with `perf` when it exists, and `make bench-budget` fails when the cursor scenario allocates 100 objects or more per key; continuous integration runs the budget check.
- Documentation: section 8.2 of `docs/architecture.md`, `CLAUDE.md` (Commands, Layout), and `docs/backlog.md` (the entry about scrolling rewriting every row is removed).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `screen-rendering`: the terminal receives only the changed runs of cells instead of whole changed rows, and a vertical scroll of a full-width window is sent as a scroll region.
- `windows`: the geometry of every window is current after every key, so window commands typed without a frame drawn between them see the sizes the previous command left.

## Impact

- Code: `carat/domain/frame.rb`, `cell.rb`, `display_width.rb`, `walker.rb`, `motions.rb`, `text_objects.rb`, `buffer.rb` (`first_nonblank`, `indent_of`, one-line edits), `window.rb`, `layout.rb`, `keymap_node.rb`, `editor_state.rb` (screen size), new `utf8.rb`, `decoded_line.rb`, `identity_table.rb`, `line_cache.rb`; `carat/use_cases/arrange_view.rb` (new), `handle_key.rb`, and `plugins/plugin_events.rb`; `carat/adapters/frame_presenter.rb`, `painted_rows.rb` (new), `screen_presenter.rb`, `key_decoder.rb`, `editor_assembly.rb`; new `bench/keys.rb`, `bench/run.sh`; `Makefile`; `.github/workflows/ci.yml`.
- Tests: frame, cache, dirty-row, screen presenter (changed runs, scroll regions both ways, fallback), `ArrangeView` and the two-splits test; snapshots of the screen presenter test change because it now writes runs, not rows. Editor test frames do not change.
- No configuration, plugin API, or dependency change. Roadmap: outside the numbered items; it is the rendering item of the core-quality queue that precedes item 4, `undo-and-registers`.

Assumptions recorded here:

- "Marked dirty by change records" is implemented through the invariant change records rely on, that a changed row holds a new line string: each painted row keeps the identity of the line it drew, so an edit, a plugin's scratch refresh, and an insert session that keeps its transaction open all dirty exactly the rows whose line objects changed, without a second record log.
- A cursor move marks the rows the cursor left and entered as changed, though in normal mode their cells are the same, so relative numbers and the cell under the cursor in visual mode can never go stale; the screen presenter then finds nothing to write in them.
- The insert benchmark types a character and deletes it with backspace (`x<BS>`) in the middle of a line, so the line keeps its length over thousands of keys.
- A scroll region is used only when the screen presenter knows the terminal holds the previous frame; after a resize, the first frame, or a frame drawn without being presented, it falls back to comparing every row.

Out of scope: syntax highlighting, a cursorline, horizontal scroll regions, wrapping, a piece table or chunked line store, and the sentence motions' full-buffer scan (already in the backlog).
