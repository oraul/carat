# Backlog: openspec/specs/leader-keys/spec.md

## Docs and spec drift found by the periodic review at 186ddfb

- Where: `openspec/specs/leader-keys/spec.md` line 43 and its scenario at line 49 still say `<leader>ff` shows "Not implemented: file.find"; `docs/codebase-map.md` line 527 (PluginHost omits `follow_prompt`), 617 and 582 (the gateway entry and the area 17 Flow omit the definition request), 465 (DisplayWidth lists the dead `of_char`, omits `code_cells`), 466 (DecodedLine omits `size`), 502 (Keywords omits `value?`), 565 (Tree omits `root`, `marked`, `expanded?`, `count`, `node`). Periodic quality at 186ddfb, queued in `docs-index`.
- Why it matters: a source-of-truth spec contradicts the code, and the map is where a change starts.
- Fix outline: a MODIFIED delta of `leader-keys` saying `<leader>ff` opens the finder, and the names added or dropped.
- Also: docs/codebase-map.md
- Category: pipeline
- Added: 2026-11-10
