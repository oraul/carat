# Backlog: carat/domain/control_text.rb

## ControlText.cleaned is public with a flag argument

- Where: `ControlText.cleaned` in `carat/domain/control_text.rb` (line 28 at 38d8c47), used only by `strip` and `line`; also `RAW_LIMIT` declared between methods (line 27 at 5722559) and the helpers `sequence_end` and `string_end` left public (`without_sequences` is now called by `MarkdownText.rows`, line 34, so it stays public). Quality advisory at `diagnostics-display`, periodic quality at 5722559.
- Why it matters: a public module function taking a bool flag invites callers outside the module to depend on a helper of its two entry points, and the other helpers and the constant's place read as API.
- Fix outline: mark `cleaned`, `sequence_end`, and `string_end` `private_class_method`, and move `RAW_LIMIT` beside `REPLACEMENT` at the top.
- Category: editor
- Added: 2026-11-07
