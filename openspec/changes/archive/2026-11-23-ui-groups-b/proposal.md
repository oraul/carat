# Proposal

## Why

`docs/design.md` section 8 (Status bar) says the file name and the position lead, the folder, branch, server, type, and encoding step back in PANEL_DIM, and the server state is one dot. Today the file is one run of bold `StatusLine` text with no folder distinction, the `lsp` slot spells its state in words (`starting`, `indexing 42%`, `stopped`), and the progress bar's undone cells and the percent are bold `StatusLine` beside quiet neighbours. This is the second part of the queue's `ui-groups-b` item; the first part, `ui-groups`, shipped the quiet group.

## What Changes

- Draw the folder of the file's path (everything up to its last `/`) in `StatusLineDim` and the last segment in `StatusLine`; a path with no folder, the root, a scratch title, and `[No Name]` stay one run in `StatusLine`.
- Draw the `lsp` slot as the server's name in `StatusLineDim`, a space, and one dot (the `modified` icon of the icon set: `●`, `*` under `option.icons ascii`) in the state's group (`StatusLineLspStarting`, `Ready`, `Error`, or `StatusLineDim`); the words of `starting`, `indexing N%`, and `stopped` leave the bar.
- Keep the command a crash or an untrusted directory names after the dot, in the dot's group (`crashed :LspRestart`, `untrusted :LspStart`), since the README and the language-server spec document them as the way back.
- Draw the progress bar's undone cells and the percent (`All`, `Top`, `Bot`, `N%`) in `StatusLineDim`; the done cells, the progress title, the file, and the position stay as they were.
- Add `StatusSlots.hint(state)` for the command a state names, which `label` uses too.

Out of scope, recorded in the findings file: the visual indicator, `MESSAGE_MODE`, and `MESSAGE_MORE` (queued as `ui-groups-c`), the terminal-byte proof of NO_COLOR and 16 colors (`ui-groups-c`), and `StatusSlots#lsp_label`, which the bar no longer reads and the gateway tests still do.

Assumptions: the design's "server state is one dot" is read as the dot standing for every state, with the two commands a crash and an untrusted directory name kept after it rather than dropped; indexing's percent is not lost, the progress segment of the same server shows it; the dot reuses the `modified` icon, so no icon name or set row is added; the percent's two spaces are `StatusLineDim` with its text, and the position's closing space stays `StatusLine`; the folder's cells are recolored after the path is written whole, so the bar still allocates nothing; NO_COLOR keeps the groups, as before, so no driver changes. The roadmap: outside it, a UI refinement of `docs/design.md`.

## Capabilities

### New Capabilities

### Modified Capabilities
- `status-bar`: the folder of the file, the server as a dot, the progress bar's undone cells and the percent in the quiet text.
- `language-server`: the slot shows the server's state as a dot with the hint of a crash or an untrusted directory.

## Impact

- Code: `carat/adapters/status_bar.rb`, `carat/domain/status_slots.rb`.
- Tests: `test/adapters_status_bar.rb`, `test/editor_lsp.rb`, `test/adapters_language_gateway.rb` and their snapshots.
- Docs: README.md (the language server paragraph and the palette paragraph), `docs/compatibility.md` (the status bar paragraph and rows), `docs/codebase-map.md` (the status bar and status slots entries).
- docs/architecture.md: unchanged, it names the status bar only as a presenter part and no segment or group.
- docs/design.md: unchanged, section 8 already describes the target look.
