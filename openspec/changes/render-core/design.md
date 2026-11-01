# Design

## Context

See proposal.md for the motivation and the baseline. On 0978d16 a render goes `EditorAssembly#render(rows, cols)` → `PluginHost#resized` → `FramePresenter#call(state, rows, cols)`, which clears one reused `Frame` of `Cell` structs, arranges the layout, scrolls every window, and repaints everything → `ScreenPresenter#present(frame)`, which compares every row with a shadow frame, rewrites each changed row whole, and copies the frame into the shadow with `sync_from`.

The allocation report of the benchmark on 0978d16 attributes per key: 4,615 integer arrays (`each_codepoint` in `Frame#put`), 3,771 one-character strings (`line[i, 1]` in `paint_line` and `DisplayWidth.column`), 58 `rjust` strings and 58 `Span` values (one per window row), and about 20 objects of key handling (the command, the motion, a position, the transaction, the plugin events). `Frame`'s `@cells` pin `Array[Array[Cell]]` is not applied, so every cell access is boxed.

Spinel facts this design relies on, probed on the pinned compiler for this change in addition to those of the earlier designs: `String#equal?` and `object_id` are identity (a `dup` differs); `Hash#compare_by_identity` is refused for String keys; a `Hash[String, T]` lookup hashes and compares by value and copies a String key on insert (25 us and 61 allocations per frame of 58 lookups with two generations), while an open-addressing table over `object_id` in an `Array[Integer]` costs 2 us and allocates only for misses; `String#<<` with an Integer appends that code point; `getbyte` walks 20,000 bytes in 9 us while `unpack("U*")` takes 35 us for 10,000 code points; storing 36,000 integers in an `Array[Integer]` takes 17 us; `GC.total_time` and `GC.stat("cycle")` exist, `GC.stat` keeps no allocation count, and `SPINEL_ALLOC_REPORT` counts every object at exit.

## Goals / Non-Goals

**Goals:**

- The targets of the brief, measured with `make bench` on 0978d16 and on the branch: per key total under 0.15 ms on 10,000 lines for `l h`, `j`, and insert; under 100 allocations per key for `l h` and `j`; under 500 bytes per `j`; the collector under 3 percent of the time; no key over 2 ms; a 10,000-character UTF-8 line within twice the cost of the ASCII one.
- Every editor test frame unchanged; the frame presenter a pure reader of the state.

**Non-Goals:**

- A cursorline, syntax highlighting, wrapping, horizontal scroll regions, and themes.
- Decoding lines for the operators and the visual use cases, which call `DisplayWidth` per command, not per frame; they get the faster byte walk and nothing else.

## Decisions

### Flat frames, two of them

`Frame < Struct.new(:rows, :cols, :cursor_row, :cursor_col, :cursor_shape, :codes, :widths, :hls, :dirty, :sources, :scrolls, :serial, :base_serial, :layout)`. `codes`, `widths`, and `hls` are `Array[Integer]` of `rows * cols` built with `Array.new(n, value)` and pinned, so cell reads and writes are unboxed. `dirty` (one integer per row, 1 when the row differs from the frame this one was diffed against), `sources` (per row, the row of that base frame whose content the terminal shows there after the frame's scrolls, -1 for a row that came into view), and `scrolls` (three integers per scroll: first row, last row, signed rows) carry what the screen presenter needs. `serial` numbers each paint, `base_serial` is the serial of the frame it was diffed against (-1 for none), and `layout` is the integer key of the geometry it was painted with. A fresh frame is all blank, every row dirty, no base.

`put(row, col, text, hl)` walks the text's bytes with `Utf8.code_at` and `Utf8.size_at` instead of `each_codepoint`, so it allocates nothing; a control code point is still stored as U+FFFD and a zero-width one skipped. `put_code`, `put_number` (the gutter digits, without `to_s.rjust`), `blank`, `fill`, `code_at`, `width_at`, `hl_at`, `row_text`, `text_rows`, `same_row?(row, other, other_row)`, `dirty?`, and `dirty_rows` complete it. `cell(row, col)` builds a `Cell` value for tests; `Cell` stays only as that view.

The frame presenter owns two frames and paints each render into the one that is not the last painted, swapping them afterwards; they are reallocated only when the size changes. Nothing is copied: what makes this sound is that each frame remembers what every row segment of it shows (below), so the presenter repaints in the back frame exactly the segments whose content differs from what that frame already holds, which after a quiet key is nothing but the rows the key changed in either of the last two frames.

The alternative of one frame plus a shadow copy in the screen presenter copies every dirty row a second time and, on a scroll, the whole window; with two frames a scroll costs one repaint of the window's rows and no copy.

### Decoded lines and the cache

`DecodedLine < Struct.new(:text, :codes, :cols, :tabstop, :plain)`: the line's code points and, for each, the display column where it starts (`cols` has one more entry, the line's width), computed once with the rules of `DisplayWidth.cell` (tabs to the next tabstop, `^X` two cells, `<xx>` four, otherwise `DisplayWidth.of`). A plain line, printable ASCII only, keeps no arrays: its code points are its bytes and its columns their indexes, and the presenter paints it byte by byte; most source lines are plain, and an edited line then costs no decoding arrays. Decoding walks the bytes and produces exactly `text.length` code points, a malformed byte becoming U+FFFD, so cursor columns, which are code point indexes, index it directly. `col(i)` is the display column of code point `i` (clamped to the width past the end) and `index_at(vcol)` the code point covering a display column, by binary search.

`LineCache` holds the decoded lines of the visible rows in two `IdentityTable`s (open addressing over `object_id` in an `Array[Integer]`, the entries in an `Array[untyped]` read through a typed `entry_at`, each hit confirmed with `equal?` on the entry's text): `fetch(line, tabstop)` looks in the current table, then in the previous one, moving a hit forward, and decodes a miss; `turn`, called once per frame, makes the current table the previous one and empties the other. A line not fetched during a frame is therefore dropped at the next turn, and the cache holds at most the lines of two consecutive frames. Identity is enough because lines are never mutated in place (edit-pipeline); an edited row is a new string and is decoded again. A tabstop different from the entry's decodes again. The cache is a domain record built once in the assembly and shared by `ArrangeView` and the frame presenter.

`DisplayWidth.column` and `col_at` walk the line's bytes with the same decoder instead of slicing `line[i, 1]`, which Spinel resolves from the start of the line, so the operators, the selection, and the block (per command, not per frame) stop being quadratic on long UTF-8 lines. `Walker` keeps the code points of the row it is on, decoded when it changes row, and classifies characters with `Motions.code_class`; `Buffer#first_nonblank` and `indent_of` compare bytes, which is exact because a space and a tab are one byte each.

### What a row shows, and dirty rows

Every text row of a window is a segment of the frame row, indexed `row * slots + k` where `k` is the window's place in the layout order and `slots` at least the number of windows, and each frame keeps for every segment what it painted: the line string, the window's `left`, `width`, gutter width, the number and sign shown, the selected display columns on that row and whether the line end is selected, the cursor column when the cursor is on that row (-1 otherwise), and, for scroll detection, the window id and its `top`. These live in parallel pinned arrays of `rows * slots` in an adapter record, `PaintedRows`, one per frame; more windows than slots reallocates both records and drops the frames' layout keys. An index by frame column was tried first: its string arrays of `rows * cols` slots, two per frame, were mostly empty but scanned by every collection. A segment is painted into the back frame only when its new record differs from the one that frame holds, or when the frame's `layout` key (rows, cols, tab line, tabstop, number options, and every window's rectangle) differs from the current one.

The frame's `dirty` row flags compare against the other frame, the last presented one: a text row is dirty when any of its segments differs from the segment at its source row there. The status lines, the tab line, and the message row are painted every frame (a few strings) and are dirty when their cells differ from the base frame's row. Separator cells are painted every frame and change only with the layout. When the layout key differs from the base frame's, every row is dirty and there is no scroll.

This marks a row dirty through the line identity that change records carry rather than through a second log of records: an edit, a scratch refresh, and every key of an insert session (whose transaction stays open) replace the line strings of exactly the rows they change, and lines below a changed line count move, which the identity comparison sees too. Scrolling, mode (through the selection columns), the cursor (its row is part of the record), window and tab changes (the layout key and the window id), the message, and the status line are covered as listed. A cursor move therefore dirties the rows it left and entered and the status line; an edit the rows whose lines changed; a message the message row.

### Scroll regions

For each window that spans the full terminal width, when the base frame has the same layout key and its first text segment belonged to the same window with a `top` that differs by fewer rows than the height, the frame records a scroll of the window's text rows by that difference and sets each of those rows' `sources` to the row it moved from (-1 for rows that came into view). Dirty flags are computed against those sources, so after a one-line scroll with absolute numbers only the new row, the cursor rows, and the status line are dirty.

`ScreenPresenter#present` trusts `dirty`, `sources`, and `scrolls` only when the frame's `base_serial` is the serial of the frame it presented last and that frame was not repainted since; then for each scroll it writes `ESC [ top ; bottom r`, `ESC [ n S` (up) or `ESC [ n T` (down), and `ESC [ r`, with the highlight reset first so the rows that come into view are blank. When the frame is the one presented last and unchanged it writes only the cursor. Otherwise, when the last presented frame still holds what it showed, it compares every row against it with no scroll; and after the first frame, a resize, or a lost base it redraws in full. A window beside another never scrolls this way, because the region would move the other window's rows too.

### Changed runs

For each dirty row the screen presenter compares the cells with their source row (a blank row for -1) and collects runs of changed cells, extending a run to the left onto the lead cell when it starts on the continuation of a wide character in either frame, and joining two runs separated by fewer than eight unchanged cells, about the length of the cursor position it saves. Each run is written as a cursor position, the highlight escape whenever the group changes, and its code points appended with `String#<<` (continuation cells skipped). The output is one string per frame and one write, as before.

### ArrangeView and the screen size

`EditorState` gains `screen_rows` and `screen_cols` (0 before the first render) and `resize(rows, cols)`. `UseCases::ArrangeView#call(state)` reserves the tab line when there are several tab pages and the message row, arranges the current tab page's layout in the rest, and scrolls every window of it vertically to its cursor with scrolloff and horizontally to the cursor's display column, which it reads from the line cache. It does nothing while the size is 0. `HandleKey` runs it after every key it takes from its queue (so a remapped sequence that splits twice arranges between the splits) and after the plugins observe the state, in `call` and in `timeout`; `EditorAssembly#open` runs it after opening the file; `EditorAssembly#render(rows, cols)` stores a changed size, tells the plugins, and runs it before painting, so a state changed outside a key (a test, a plugin event) is arranged too. `FramePresenter#call(state)` reads the size from the state and changes nothing in it; it calls `LineCache#turn`, its own cache's bookkeeping.

The alternative of arranging only before a render keeps the defect that use cases read the previous render's geometry (`Layout#split`, `neighbour`, the minimum width of `SplitWindow`, `H M L`).

### Allocations of a key outside the presenters

With rendering at about nine objects per key, key handling allocates most of what is left, and the collector's share of a 15 us key is what the target measures. Four allocations of every key are removed where it is local and changes no behavior: `Window#gutter_width` counts digits instead of building `line_count.to_s` (it now runs in `ArrangeView` too), `KeymapNode` looks an ASCII key up under a decimal string made once instead of `code.to_s` twice, `PluginEvents#queue` builds no event (with its copied path) that no enabled plugin subscribes to, `KeyDecoder` keeps one empty string for nothing pending instead of slicing a new one, and `Buffer#insert` and a one-row `Buffer#delete` build the new line as one copy of the old with the text put in or taken out, instead of a head, a tail, and their join; the stored line is still never changed. `ArrangeView` walks the layout's node table rather than building the list of leaves, and `HandleKey` runs it before each further queued key rather than after every one.

### Benchmark, profile, and budget

`bench/keys.rb` (from the scratchpad harness, loading `carat/test_support.rb`) runs eleven fixed scenarios over the doubles with a terminal that counts bytes, timing handling and rendering per key and reading `GC.total_time`. `bench/run.sh` adds allocations per key from two runs with `SPINEL_ALLOC_REPORT` and different key counts, so the setup cancels out, pins to one core with `taskset` when it exists, and with `--budget SCENARIO MAX` fails when the scenario allocates `MAX` or more per key. `spin` compiles only `bin/*.rb` and `test/*.rb` and reads a `.rb` elsewhere only when something requires it, so `bench/` needs no hiding; `make bench` compiles it with `spinel $(spin flags)` into `build/bench/keys`. `make bench-budget` runs the `lh` budget of 100, and CI runs it after the tests (one more compile, about a minute). `make profile` builds the benchmark with `spinel --profile`, records the `j` and `lh` scenarios with `perf record -g` when `perf` exists, and prints the top functions by self time with their Ruby names from the symbol map, or says that `perf` is missing.

## Risks / Trade-offs

- [A content change that no segment record covers leaves a stale row] → The record holds every input of a text row's cells (line, geometry, scroll, gutter number and sign, selection, cursor), status and message rows are compared cell by cell, and the editor tests read the painted frame after every key; a fallback full compare is used whenever the screen presenter is unsure of its base.
- [A frame painted but not presented makes the next present wrong] → `serial` and `base_serial` detect it and the screen presenter falls back to a full comparison or a full redraw.
- [`object_id` reused after a line is freed] → A hit is confirmed with `equal?` on the entry's text, which the entry keeps alive, so a reused address cannot match a dropped entry.
- [Changed runs split text that tests and the smoke test search for] → Runs separated by fewer than eight unchanged cells are joined; the smoke test's strings are whole new rows or new text at the end of a row.
- [Painting two frames doubles the memory of the cells] → Two frames of 12,000 cells in integer arrays are smaller than one frame of `Cell` structs was.

## Migration Plan

None: no data, configuration, or plugin API change. Rolling back is reverting the squash commit.
