# Backlog: carat/domain/start_art.rb

## StartArt#paint clamps a step no caller passes out of range

- Where: the two clamp lines of `paint` in `carat/domain/start_art.rb` (line 167 at `start-screen`); `StartScreen` only ever holds a step in 0..LAST. Quality review of `start-screen`.
- Why it matters: defensive code no caller needs hides the invariant `StartScreen` keeps.
- Fix outline: drop the two clamp lines.
- Category: editor
- Added: 2026-11-05

## StartArt.from_plain bends the from_x naming

- Where: `StartArt.from_plain(bool)` in `carat/domain/start_art.rb` (line 73 at `start-screen`), while the archived change's `design.md` and task 3.1 call it `StartArt.build(plain)`. Quality review of `start-screen`.
- Why it matters: `from_x` names a conversion from an x value, and a flag is not one, so the name misleads and the design record disagrees with the code.
- Fix outline: rename it to `build(plain)` at its call sites and tests.
- Category: editor
- Added: 2026-11-05

## StartArt's LAST restates FRAMES - 1

- Where: `LAST = 5` in `carat/domain/start_art.rb` (line 105 at `start-screen`), which `StartScreen`, `paint`, and `from_plain` rely on beside `FRAMES`. Periodic quality at 5ac9674.
- Why it matters: two constants to keep in step; a frame added to one and not the other paints past the table or never shows the last frame.
- Fix outline: derive `LAST` from `FRAMES`.
- Category: editor
- Added: 2026-11-05

## StartArt's LEGEND and PLAIN_GLYPHS spell characters as decimal codes

- Where: `LEGEND` and `PLAIN_GLYPHS` in `carat/domain/start_art.rb` (line 130 at `start-screen`), arrays of byte codes such as 47 and 92, while `GEM` is strings read with `getbyte`. Periodic quality at 5ac9674.
- Why it matters: the legend the `GEM` comment describes cannot be read against the table, so a glyph change is checked by decoding numbers.
- Fix outline: hold both as strings read with `getbyte`, as `GEM` is.
- Category: editor
- Added: 2026-11-05

### First-use hints wait for the start screen's logo animation

- Location: `carat/domain/start_art.rb:67` (the hints), `carat/adapters/input_controller.rb:150` (the animation).
- Why: for about 0.6 s the first screen shows a single dot and no hint, the one thing a first-time user needs (ux-pass review finding 1). Reproduction: start `carat` with no file and read the screen within 100 ms, `openspec/changes/archive/*-ux-pass/screens/start-early.txt` against `start-late.txt` and `first-start.txt`.
- Fix: draw the name and the three hint lines in the first frame and animate only the logo.
- Also: carat/adapters/input_controller.rb
- Category: editor
- Added: 2026-11-15
