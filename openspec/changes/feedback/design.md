# Design

## Context

`EditorState#show(text, error)` is the one setter of the message row (`Reporting#report`, plugin `message`, the plugin registry, hover), and `HandleKey#step` clears a one-line message on the next key. `FramePresenter` paints floats after the windows through a float key (`FLOAT_STRIDE` integers per box) that forgets and compares the rows a box covers, so a box over cached window rows repaints correctly. `StatusBar` fills five integer arrays per frame and allocates nothing. The gateway already counts `$/progress` begin and end on the server for the `lsp` slot. `NO_COLOR` is read once by `AnsiTerminal` and reaches only the start screen, at `EditorAssembly#open`.

## Goals / Non-Goals

**Goals:**

- Keep what the message row showed, readable with `:messages`.
- Show asynchronous news in a small top-right stack that leaves by itself.
- Show long work with its title and a bar.
- Allocate nothing more per key while no notification shows (`lh` 27.0 held).

**Non-Goals:**

- A plugin request for notifications or progress (needs an API version bump), animation of notifications, `:{count}messages`, colored history lines.

## Decisions

- History in the state: `MessageHistory` is a `Struct` record kept by `EditorState` (built in its `initialize`, as `BlockInsert` is), so every `show` records without a new collaborator: a non-empty one-line text is appended with its level (0 info, 2 error), the oldest dropped past `LIMIT = 500`. A text with a newline is command output (`:registers`, `:ls`) and is not kept, as Neovim keeps no listing. `EditorState#show_output(text)` shows a text without recording it, for `:messages` itself. The strings are kept by reference: `show` callers already own them, and a kept line is never mutated.
- `:messages` is an `ExHandler` (`mes[sages]`), registered after `:LspRestart`, last before the plugin commands, where the generator puts it, since no command shares its abbreviation; its description is in `ExTable::DESCRIPTIONS` for the palette. With no argument it joins the history with newlines into one listing (one entry stays on the message row), `clear` empties it, anything else is `E474: Invalid argument`.
- `Notices` is a `Struct` record built once in `EditorAssembly` with the state's history, handed to the gateway (the producer), the `InputController` (expiry), and the `FramePresenter` (drawing). It keeps parallel arrays of text, level (0 info, 1 warning, 2 error), deadline, and a serial; `add(text, level, now)` records the text in the history too, drops the oldest past three, and sets the deadline from `LIFETIMES = [3.0, 5.0, 8.0]`; `expire(now)` drops those past their deadline and answers whether any went; `wait(now)` gives the seconds to the next deadline.
- Expiry on idle: `InputController#next_timeout` waits no longer than the next deadline while a notice shows, and the idle branch of `pump` calls `expire`, answering true (redraw) when one went. With none shown it reads no clock and allocates nothing.
- Drawing through the float key: `build_float_key` appends one `FLOAT_STRIDE` entry per notice box (box rows and columns, then the notice's serial and level), and `@floating` is also true while a notice shows, so the existing `forget_rows`, `compare_boxes`, `@repainted`, and `under_float?` paths cover the boxes with no second mechanism. Boxes are three rows (a border, the text, a border), from the row under the buffer tabs down, right edge one column from the screen's, width the text plus four cut to half the screen (at least 20 columns), skipped when they would reach the status bar. Painted after the floats, so they stay on top.
- Plain drawing: `EditorAssembly#open` sets `FramePresenter#plain=` from `TerminalPort#no_color?`, which passes it to the `StatusBar`; plain boxes use `+ - |` and `Normal`, a plain bar `#` and `-` in `StatusLine`. Otherwise boxes use the rounded border in `FloatBorder`, the text in `NormalFloat`, the title in `DiagnosticError`, `DiagnosticWarn`, or `DiagnosticInfo`; the bar `━` in `StatusLineLspReady` for done cells and `─` in `StatusLine` for the rest. No new highlight group, so the theme tables are unchanged.
- Progress in `StatusSlots`: `set_progress(title, message, percent)` keeps the title across reports (an empty title keeps the last), builds the label once (title, a space, the message, through `ControlText.plain`, 40 bytes), keeps the last percent when a report gives none, and counts the reports as the step of an indeterminate bar; `clear_progress` empties it. The gateway calls it from `progress` and clears it in `show` whenever the current server is not indexing. `StatusBar` adds kind `PROGRESS` (10, priority 35) before the `lsp` slot; its width is the label, the bar, and the spaces, computed without allocating.
- Untrusted text: a server's `message` and `title` go through `Domain::ControlText.plain` (escape sequences and control characters dropped) with a cap (200 bytes for notices, 40 for the label), so no control character reaches the frame; a `type` outside 1 to 4 reads as info.

## Risks / Trade-offs

- A notice repaints the rows its box covers on every frame it shows (the float path); acceptable for at most three boxes of three rows. With none shown the float key is not built, so `lh` keeps its figure.
- The progress segment shows the current buffer's server only; another server's report is overwritten at the next idle tick. Recorded as a difference from Neovim's `vim.lsp.status`.
- The history keeps strings by reference; `Buffer` lines are never passed to `show`, so no text change can alter a kept entry.
