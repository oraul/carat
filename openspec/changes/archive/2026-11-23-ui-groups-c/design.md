# Design

## Context

`FramePresenter#paint_message` draws the visual indicators in `MESSAGE_DIM`, the pending keys' group. `ModeMsg` has a theme row (normal foreground, bold) and an id, `MoreMsg` too, and neither is drawn. `ScreenPresenter` writes a group's sequence from `SgrTable`, which at 16 colors takes the 16-color attributes and basic colors; `AnsiTerminal` reads `NO_COLOR`, `COLORTERM`, and `TERM` once.

## Goals / Non-Goals

**Goals:**
- Each group a theme sets is drawn by something.
- The bytes of the bar's two groups are proven on a terminal at 16 colors, 256 colors, and under `NO_COLOR`.

**Non-Goals:**
- A `-- More --` pager.

## Decisions

- `ModeMsg` draws the indicators: Neovim's `showmode` text is in `ModeMsg`, and `docs/design.md` has no rule that makes the indicator dim. The pending keys beside it stay `MsgDim`, which Neovim's `showcmd` also draws plain.
- `MoreMsg` is removed rather than painted: Neovim draws it for `-- More --`, and carat's multi-line messages go to a list view with the `Question`-colored hit-enter prompt, which Neovim also draws in `Question`. Removing shifts every later id by one; ids are only constants and indexes, and no file stores one.
- The smoke case reads the editor's first frame from a pty. The bar's file name is the first text written after a `StatusLine` sequence and the file type after a `StatusLineDim` one, so each sequence is the last escape before its word. At 16 colors the sequences hold only basic colors (30-37, 40-47, 90-97, 100-107) and no `38;`; under `NO_COLOR` the presenter keeps every group's colors, so the sequences are the 256-color ones, and the case asserts only that they differ and that the name and the indicator are bold and the type is not. That NO_COLOR still writes colors is recorded in the findings file.
