## Context

See `proposal.md` for the motivation. Today `FramePresenter#place_cursor` sets the frame's shape to `:bar` in insert mode and `:block` otherwise, and `ScreenPresenter#present` writes `ESC [ 6 q` or `ESC [ 2 q` when the shape changes; `LEAVE` ends with `ESC [ 2 q`, a block. A frame cell carries one highlight group id, and `SgrTable` holds one SGR sequence per id, built once from the theme. `PaintedRows` records every input of a window row segment so a segment is painted only when an input changed; the cursor's column on its row is one of them, so the old and new cursor rows are already repainted on every cursor move. `bin/carat.rb` calls `ScreenPresenter#enter` and `EditorAssembly#open` before the `begin` whose `ensure` calls `leave`.

## Goals / Non-Goals

**Goals:**

- The cursor line in the current window, over `CursorLine`'s background, keeping the syntax colors, with no allocation and no extra painted row per key.
- The shape per mode, and the terminal's own cursor back on every exit.

**Non-Goals:**

- Combining any two groups in general (`:highlight` links, blending); only the cursor line layers over other groups.
- Neovim's operator-pending underline: `test/editor_grammar.rb` already pins the block while an operator waits, a decision of the grammar change kept here.

## Decisions

### The cursor line is a layer of group ids

A cell on the cursor line carries its group's id plus `Highlight::CURSOR_LINE_LAYER`, which is `Highlight::COUNT`; ids from there to `Highlight::LIMIT` (twice `COUNT`) are the layered groups. `Themes.from_palette` resolves them with the base group's foreground and attributes and, when the base group has no background of its own in `GROUPS`, the `CURSOR_LINE` role's background, with the `CursorLine` group's 16-color attributes (underline) added; a group with its own background (Visual, Search, the pop-up menu) keeps it. `SgrTable` builds a sequence for every id below `LIMIT`. The screen presenter needs no change: a layered cell is a different id, so `write_row`'s cell comparison and the dirty rows see it, and its sequence is one lookup as before.

The alternative was a per-row span on the frame that the screen presenter would apply while writing: it needs the span compared in `write_row` and `same_row?`, a second sequence per cell, and a background merged at write time. The layer costs 84 more sequences built once and nothing per key.

`Highlight.name_of` and `token?` keep answering for the base ids; `Highlight.base(id)` strips the layer for the few readers that compare a cell's group (the visual cursor cell in `place_cursor`, tests).

### Painting

`paint_window` computes, per row, the layer to apply: `CURSOR_LINE_LAYER` on the cursor's row of the current window when `options.cursorline` is on, 0 otherwise. The layer is an input of the segment in `PaintedRows#same?` and `#store`, so turning the option on or off, moving focus, or moving the cursor repaints exactly the rows whose layer changed; the cursor's own row was already repainted for its column. After `paint_row`, a lit row has its text cells, from the end of the gutter to the window's right edge, lifted onto the layer by `Frame#lift(row, from, to, layer)`, which adds the layer to every cell below it; the number is put in `CursorLineNr` instead of `LineNr`. `place_cursor`'s visual check compares `Highlight.base` of the cell and puts the token group back on the cell's layer.

### Shapes

`place_cursor` maps the mode: `INSERT` to `:bar`, `REPLACE` to `:underline`, every other mode to `:block`. `ScreenPresenter#present` writes `ESC [ 6 q`, `ESC [ 4 q`, or `ESC [ 2 q` (steady bar, underline, block) when the shape changes. `LEAVE` becomes `ESC [ 0 m ESC [ 0 q ESC [ ? 25 h ESC [ ? 1049 l`: `DECSCUSR` 0 asks the terminal for its own configured shape, which xterm, kitty, Alacritty, WezTerm, foot, and the VTE terminals honor; a block (2) would override a user's bar.

### Every exit path

`bin/carat.rb` opens the `begin` before `ScreenPresenter#enter`, so the `ensure` covers entering the screen, opening the file, and the loop; `:q`, `:wq`, closing the last window, and `SIGTERM` or `SIGINT` (trapped flags that end the loop) all return through it, and an exception unwinds through it. Leaving a screen that was never fully entered writes sequences that are harmless on the main screen. `test/smoke_editor.rb` asserts the full restore tail on each quit it already runs and on a new `SIGINT` session.

### The option

`cursorline` is a `bool` member of `Options`, Neovim's default off, read from `option.cursorline` and set by `:set cursorline`, `cul`, with the boolean forms the search options take. The shipped `config/default.caratrc` turns it on, as it turns `smartcase` on: the user asked for the highlight. It is global, where Neovim's is window-local; the current-window-only drawing is Carat's choice, the effect of the common Neovim autocommand that sets it on focus.

## Risks / Trade-offs

- [Tests that read a cell's group on the cursor row see the layered id under the shipped option] → those reads compare `Highlight.base` of the cell, or the test turns the option off when the row is not what it checks; no check is dropped.
- [Text on the cursor line falls below 4.5:1 in some groups of every palette, down to 3.90:1, since `CursorLine` is lighter (or darker) than the background] → the cursor line is held to 3:1, as text on the selection already is, which `test/domain_theme.rb` checks for every group; tuning the palettes to 4.5:1 is in `docs/backlog.md`, since it changes the colors the user chose with `theme-tokens`.
- [A terminal that ignores `DECSCUSR` 0] → it keeps whatever shape it had, as it would have with 2; no terminal known to the project mishandles 0.
- [The output of a lit row is longer by one background per run] → the row was rewritten anyway; allocations per key are unchanged, which `make bench-budget` and the `lh`, `j`, and `insert` figures check.
