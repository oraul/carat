## Why

Started with no file, `carat` prints a usage line and exits, and started on a directory it opens an empty buffer under a refusal message, so a first run shows nothing of the editor and no hint of how to start. The user asked for a start screen and chose its look: a gem that forms from a point, fills its facets, gets a sparkle, and then shows `c a r a t` with key hints, in about 0.6 s, skipped by any key (`docs/queue.md` item 3, T2 user request). It is outside the roadmap of `docs/architecture.md` section 12; its prerequisite, the theme tokens, merged as #57.

## What Changes

- `carat` takes zero or one argument; with none, or with a directory, it starts on an empty buffer and shows the start screen. More than one argument prints `usage: carat [FILE]`.
- The start screen draws, in the current window, a point, the gem filling its facets in three steps, a sparkle at its top, and then the wordmark `c a r a t` with three key hints under it, six frames 0.125 s apart (the last at 0.625 s), and keeps the last frame until a key arrives. Any key ends it and is handled as usual.
- The frames are precomputed when the start screen starts; the event loop advances them with the injected clock, waking only for the next frame while the animation runs.
- `option.startscreen` (on by default) turns it off; `option.reducedmotion` (off by default) shows the last frame at once.
- With `NO_COLOR` set to a non-empty value the start screen uses ASCII glyphs and no colors of its own; otherwise the gem takes the theme's syntax and title colors.
- A window too small for the picture shows only the wordmark.
- The planner's records: `docs/queue.md` and `docs/goals.md` from the plan (the goals record the rule of at most two pipeline changes between features, T0 items excepted), three periodic quality entries in `docs/backlog.md`, and the `theme-tokens` row of `docs/metrics.tsv`.

## Capabilities

### New Capabilities

- `start-screen`: the start screen shown when the editor starts without a file: its frames and timing, how a key ends it, its options, `NO_COLOR`, the small-window form, and its colors.

### Modified Capabilities

- `editor-startup`: the executable takes zero or one argument, and starts on the start screen with none or a directory.

## Impact

- Code: `bin/carat.rb`; `carat/domain/options.rb`, new `carat/domain/start_art.rb` and `carat/domain/start_screen.rb`; `carat/adapters/input_controller.rb`, `frame_presenter.rb`, `editor_assembly.rb`; `carat/ports/terminal_port.rb`, `carat/drivers/ansi_terminal.rb`, `carat/doubles/fake_terminal.rb`; `config/default.caratrc` and its mirror.
- Tests: new `test/editor_start_screen.rb` with every frame in its snapshot; rows in `test/domain_options_config.rb`, `test/adapters_assembly.rb`, `test/smoke_editor.rb`, and the presenter tests that build a `FramePresenter`.
- Docs: `README.md`, `docs/compatibility.md`, `docs/codebase-map.md`, and the planner's records.
- Per key: one boolean read on the read path and none on the paint path beyond one boolean per frame; allocations per key are unchanged.

## Out of scope

- `NO_COLOR` for the rest of the editor: the theme still colors the windows; the start screen alone honors it here (left in `docs/backlog.md`).
- `:intro`, a start screen after the first file is closed, a start screen per tab page, and setting the two options with `:set`.
- Opening the explorer on a directory argument.

## Assumptions

- The last frame stays until a key, as Vim's intro does, so the hints can be read; "any key skips it" means the key ends the screen and is not swallowed.
- A directory argument with `startscreen` off keeps today's behavior: the refusal message over an empty buffer.
- The gem's colors reuse existing groups (`Operator`, `Function`, `Keyword`, `Type`, `Title`, `Special`, `Comment`) rather than adding groups, so every palette colors it without palette changes.
