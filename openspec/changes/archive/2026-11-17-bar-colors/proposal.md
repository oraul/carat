# Proposal

## Why

Two status bar findings the user asked to fix now (Sprint 13, item 1 of `docs/queue-feature.md`). At 16 colors the `lsp` slot's starting and ready accents are the basic dark yellow (3) and green (2) over the light gray bar (7) of carat-dark, carat-light, one_dark, and one_light (`carat/domain/themes.rb:212`), about 1.4:1 and 1.7:1 under xterm's default colors, so the state cannot be read; dark_plus and light_plus draw the error accent in bright red (9) over their blue bar (4), 2.3:1. The diagnostics counts are drawn in `DiagnosticError`, `DiagnosticWarn`, `DiagnosticInfo`, and `DiagnosticHint` (`carat/adapters/status_bar.rb:243`), whose background is the terminal's own, so the counts punch a hole in the one-colored bar, the hole the `lsp` slot had before ux-fixes-a.

## What Changes

- Four new UI groups, `StatusLineDiagnosticError`, `StatusLineDiagnosticWarn`, `StatusLineDiagnosticInfo`, and `StatusLineDiagnosticHint`, after `StatusLineLspError`, drawn over the status bar's background at every depth, each in an accent picked per palette to read at 4.5:1 on that bar at 24-bit and 256 colors: error and warning take the `lsp` slot's red and yellow bar accents, info and hint two new palette roles, `PANEL_BLUE` and `PANEL_CYAN`. The bar draws its counts and the diagnostics segment's closing space in them. The editor knows 60 UI groups instead of 56; the syntax, file-icon, and markup group ids move up by four (plugins resolve them by name).
- At 16 colors every group on the bar, `StatusLine`, the three `lsp` groups, and the four count groups, reaches 4.5:1 on the bar under xterm's default colors: over the light gray bar the accents are dark red (error) and dark blue (info), and the starting, ready, warning, and hint accents take the bar's black text, since no other basic color reads there; over the blue bar of dark_plus and light_plus the error and info accents take the bar's white text, the others keep bright yellow, green, and cyan. The state still shows by the slot's text and the count's icon.

Out of scope: the 16-color contrast of groups off the bar (the mode pills, the tab row, the buffer's groups); the editor's own `Diagnostic*` groups, still on the terminal's background where the buffer and messages draw them; a palette's 16-color bar background, kept as it is.

Roadmap: outside the roadmap of `docs/architecture.md` section 12: fixes of two backlog findings on the status bar, asked for by the user for Sprint 13.

Assumptions: the 16-color reference is xterm's default colors, the one table the brief's 1.5:1 figure fits, held to the same 4.5:1 as text at 24 bits; losing hue for some accents at 16 colors is accepted, since the icons and the state text tell them apart; error and warning counts share the `lsp` slot's bar accents, since they mean the same red and yellow on the same bar; the recorded allocation figures hold, since only group ids and palette values change.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `color-themes`: four status bar count groups among the UI groups, drawn on the bar's background and readable there; the bar's groups readable at 16 colors.
- `status-bar`: the diagnostics counts are drawn in the bar's count groups.

## Impact

`carat/domain/highlight.rb` (four ids and names, the later ids renumbered), `carat/domain/themes.rb` (two roles, four groups, the six palettes' bar accents at 16 colors), `carat/adapters/status_bar.rb` (the counts' groups); tests in `test/domain_theme.rb` and `test/adapters_status_bar.rb`. No dependency, no API change, no new file.

- README.md: changed, the theme paragraph names the diagnostics counts with the language server's segment on the bar's own background.
- docs/architecture.md: changed, the `Highlight` line's count of UI groups.
