# Proposal

## Why

Two highlight groups a theme sets, `ModeMsg` and `MoreMsg`, are drawn by nothing: the message row's `-- VISUAL --` indicators are drawn in `MsgDim` although Neovim's mode message uses `ModeMsg`, and carat has no `-- More --` pager, so `MoreMsg` has no place to be drawn. Separately, the status bar's `StatusLine` and `StatusLineDim` are proven at 16 colors and under `NO_COLOR` on group ids and sequence tables only, never on the bytes a terminal receives.

## What Changes

- Draw the three visual indicators in `ModeMsg` (the normal foreground, bold, also at 16 colors and under `NO_COLOR`) instead of `MsgDim`, as Neovim's showmode does.
- Remove `MoreMsg`: carat has no pager that could draw it. `Highlight::MESSAGE_MORE` and its theme row go, the ids after it move down by one, `COUNT` becomes 118, and the UI group count is one fewer.
- Add pty smoke cases that start the editor at `TERM=xterm-color` (16 colors), at `TERM=xterm`, and under `NO_COLOR`, and compare the bytes the bar's file name (`StatusLine`) and its file type (`StatusLineDim`) are written after: both are real sequences of the depth, and they differ.

Out of scope: a `-- More --` pager, a warning icon painter, and every other group.

Assumptions: `TERM=xterm` alone is detected as 256 colors (`Domain::ColorDepth` lists `xterm-color`, not `xterm`, among the basic terminals), so the 16-color case uses `TERM=xterm-color`, and `TERM=xterm` is checked as the 256-color bytes; `COLORTERM` is set empty in the child's environment so an inherited truecolor value cannot override `TERM`; the roadmap: outside it, a UI refinement of `docs/design.md`.

## Capabilities

### New Capabilities

### Modified Capabilities
- `screen-rendering`: the visual mode indicators are in `ModeMsg`.
- `color-themes`: the UI group list and the message row's groups lose `MoreMsg` and gain `ModeMsg`'s row.
- `status-bar`: the bar's bytes at 16 colors, at 256 colors, and under `NO_COLOR`.

## Impact

- Code: `carat/domain/highlight.rb`, `carat/domain/themes.rb`, `carat/adapters/frame_presenter.rb`.
- Tests: `test/smoke_editor.rb` and its snapshot, `test/adapters_frame_presenter.rb`, `test/domain_theme.rb`.
- Docs: README.md (the palette paragraph's messages), `docs/compatibility.md` (the message row and the UI group paragraph) and `docs/codebase-map.md` (the message row and the smoke test).
- docs/architecture.md: unchanged, its count of 69 UI groups is the count after the removal.
- CLAUDE.md: unchanged, no agent, workflow, Makefile, or gate changes.
