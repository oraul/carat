## Context

`bin/carat.rb` requires one argument and `EditorAssembly#open` hands it to `OpenFile`. `MainLoop#run` renders when the last pump changed something and then pumps one read; `InputController#next_timeout` picks the read's timeout from the escape wait, the `timeoutlen` deadline, or the 0.25 s idle poll, all on the injected `ClockPort`. `FramePresenter#call` paints two frames in turn, reusing window rows through `PaintedRows`; the hit-enter list already paints over window rows and then forgets the layout key so the next frames repaint in full. Colors come from highlight ids through the theme's `SgrTable`.

## Goals / Non-Goals

**Goals:** the chosen animation in the theme's colors; a key never lost; nothing added to the cost of a key once the screen is gone; every frame testable at a fixed clock.

**Non-Goals:** `NO_COLOR` for the whole editor; new highlight groups; `:intro`.

## Decisions

### The pictures are computed once, as integer cells

`Domain::StartArt` is a `Data` value built by `StartArt.build(plain)` when the start screen starts: six frames of a 15 by 20 canvas in two flat `Array[Integer]` (code point and highlight id per cell, 0 for an empty cell) and the wordmark's one row. The canvas comes from legend strings: a gem of eight rows whose letters name the facet (table, crown left and right, pavilion left, centre, and right) or the edge, each with a reveal stage: the point in frame 0 only, the table in 1, the crown in 2, the pavilion in 3, the sparkle in 4, the wordmark and the hints in 5. A legend letter maps to a Unicode glyph (full block, the four triangles, the down triangle, `✦`, `•`) and a group, or with `plain` to an ASCII glyph (`/ \ : = . | v * .`) and `Normal`. Every glyph is one cell wide. Painting copies cells with `Frame#put_code`, allocating nothing. Alternative: drawing each frame from the legend at paint time; rejected because the brief asks for precomputed frames and it would decode strings per frame.

### The state of the screen is one record, read by the controller and the presenter

`Domain::StartScreen`, a `Struct` record built once in `EditorAssembly` and passed by keyword to `InputController` and `FramePresenter`, holds `showing`, `step`, `started`, and `art`. `start(now, animate, art)` shows step 0, or the last step when `animate` is false; `animating?`, `due?(now)`, `advance(now)` (to the latest step whose time has come), `wait(now)` (seconds to the next step), and `dismiss`. Steps are `STEP` = 0.125 s apart, a binary fraction, so the manual clock lands on each exactly; the last is at 0.625 s, under the 0.7 s the queue item allows.

### The event loop drives it through the controller

`InputController#next_timeout` returns `wait(now)` while animating, below the idle poll, after the escape and `timeoutlen` waits, which still go first. A read that times out advances a due step and reports a change, so `MainLoop` renders it; nothing else in the loop changes. A read that brings bytes dismisses the screen when it shows and handles the keys as usual, reporting a change even when the bytes complete no key. The key path gains one boolean read; allocations per key are unchanged.

### The presenter paints it over the current window

When `showing`, `FramePresenter#call` paints the windows as usual, then `StartArt#paint` blanks the current window's text rectangle and draws the step centred in it, or the wordmark alone centred when the rectangle is smaller than the canvas, clipped to the rectangle. As after the hit-enter list, the frame forgets its layout key and its painted rows, so the start frames are compared in full (they are few) and the first frame after the screen repaints every window row. The status line and the message row are untouched, so a configuration problem still shows.

### Opening

`EditorAssembly#open(path)` starts the screen when `startscreen` is on and the path is empty or a directory (`FilePort#stat`), with `animate` the negation of `reducedmotion` and the art built for `TerminalPort#no_color?`. An empty path otherwise opens nothing; a directory with the screen off goes to `OpenFile` as before. `bin/carat.rb` passes `""` with no argument and refuses two or more with `usage: carat [FILE]`.

### NO_COLOR is read by the terminal driver

`AnsiTerminal` already reads `COLORTERM` and `TERM` once; it reads `NO_COLOR` the same way, true when set and not empty, as the convention defines, and answers it through `TerminalPort#no_color?`. `FakeTerminal` has a writer for tests.

### Colors

The facets take `Operator` (table and culet), `Function` (crown left, pavilion right), and `Keyword` (crown right, pavilion left), the point and the sparkle `Type`, the wordmark `Title`, the hint keys `Special`, and their text `Comment`: groups every palette defines and has checked for contrast.

## Risks / Trade-offs

- A terminal that draws the triangles or `✦` two cells wide misaligns the gem → the glyphs are ones East Asian width tables give one cell; `NO_COLOR` gives ASCII.
- Hints name default bindings (`i`, `:e`, `:q`), which a configuration may rebind → they name the commands Vim users expect and core ex commands that cannot be unbound.
- Two arguments used to print `usage: carat FILE`; now `usage: carat [FILE]` → the smoke test and the spec change with it.
