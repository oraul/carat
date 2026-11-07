# Proposal

## Why

The language server client keeps each file's published diagnostics as values, but nothing draws them: the bar's diagnostics counts have no writer, no sign is placed, and the message row never reads a diagnostic. This delivers the second part of roadmap item 10, `language-services`, in `docs/architecture.md` section 12 (docs/queue.md item 2), the part `lsp-diagnostics` left out: signs in the number column, the cursor line's message in the message row, and the counts in the bar.

## What Changes

- A published diagnostic is drawn as a sign in the sign column of its row: the `error`, `warning`, `info`, or `hint` icon of the configured icon set, the most severe one when several share a row, over any plugin's sign on that row. The signs move with the lines when the buffer is edited, and the next publish replaces them.
- In normal mode, with no message pending, the message row shows the message of the most severe diagnostic on the cursor's line, in the diagnostic group of its severity; a pending message, the command line, and the mode indicators still win.
- The bar's diagnostics slot shows the current buffer's counts of errors, warnings, infos, and hints, written at the idle tick.
- A diagnostic message's line breaks and tabs become spaces before the control characters are dropped, so a message of several lines reads as one line; it stays capped at 500 bytes and the message row cuts it at the screen's width.
- `:LspRestart` and `:LspStart` after a crash clear the diagnostics drawn for the restarted server's file type.

Out of scope: jumping between diagnostics (`]d`, `[d`), a floating window with the full message, virtual text at the end of the line, sign colors per severity (the sign column keeps its one group), and columns, which stay UTF-16 units as sent and are not drawn (the later definitions change converts them).

Assumptions: the diagnostic sign wins over a plugin's sign on the same row, as Neovim's diagnostic signs (priority 10) win over a git plugin's (6); the signs keep the icon set in force when they were published until the next publish; the counts follow a buffer switch at the next idle tick, at most 0.25 s later, since the gateway works only on idle ticks; the message row shows the diagnostic in normal mode only, since the other modes have their indicator there.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `language-server`: published diagnostics are drawn as signs, the cursor line's message, and the bar counts; a message is flattened to one line; a restart clears what was drawn.
- `screen-rendering`: the message row shows the cursor line's diagnostic in normal mode when nothing else is shown.

## Impact

- Domain: `Buffer` keeps the diagnostics shown and one mark per line that moves with the lines, places them as signs, and answers the cursor line's diagnostic; `StatusSlots#count_diagnostics`; `ControlText.line`.
- Adapters: `JsonRpcLanguageGateway` hands each publish to the buffers of its file at the next idle tick, writes the counts, and clears on a restart; `FramePresenter#paint_message` draws the cursor line's diagnostic.
- Tests: `test/domain_buffer.rb`, `test/domain_rpc_framer.rb`, `test/adapters_status_bar.rb`, `test/adapters_language_gateway.rb`, `test/adapters_frame_presenter.rb`, `test/editor_lsp.rb`.
- Docs: `docs/codebase-map.md`, `docs/architecture.md` (language services), `README.md`, `docs/backlog.md`, `docs/queue.md`.
