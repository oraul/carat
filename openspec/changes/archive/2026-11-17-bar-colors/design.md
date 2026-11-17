# Design

## Context

See proposal.md, Why. A frame cell carries one group id, and a theme maps each id to its colors at three depths; a group with no background of its own (the `Diagnostic*` groups) shows the terminal's. ux-fixes-a gave the `lsp` groups the bar's `PANEL` background with three accent roles, `PANEL_YELLOW`, `PANEL_GREEN`, and `PANEL_RED`, checked at 24-bit and 256 colors only; no test computes a 16-color ratio.

## Goals / Non-Goals

**Goals:**
- Counts drawn on the bar's background, readable there at every depth.
- Every group on the bar readable at 16 colors against one reference table, asserted in `test/domain_theme.rb`.

**Non-Goals:**
- A per-cell background override in the frame, or a fourth layer (bar) beside the cursor-line and float layers.
- 16-color contrast checks for groups off the bar.

## Decisions

- Four new UI groups, `StatusLineDiagnostic{Error,Warn,Info,Hint}`, after `StatusLineLspError`, rather than a bar layer that would draw each `Diagnostic*` foreground over `PANEL`: the buffer's diagnostic colors do not read on every bar (dark_plus's blue `DiagnosticInfo` on its blue bar), so the counts need accents picked per bar, as the `lsp` slot got. The ids after them move up by four; `NAMES`, `token_id`, and the layers follow from `COUNT`, and plugins only ever resolve ids by name.
- Error and warning reuse `PANEL_RED` and `PANEL_YELLOW`; info and hint get `PANEL_BLUE` and `PANEL_CYAN`, picked per palette at 4.5:1 or more on `PANEL` at 24 bits and at the 256 colors written (nearest index, no own index needed): carat-dark `0x7fa6ff` and `0x5fcfd0`, carat-light `0x2c58d0` and `0x0a6c84`, one_dark `0x8cc4f5` and `0x8fd3dc`, one_light `0x2453b8` and `0x0b6276`, dark_plus and light_plus `0xd6ebff` and `0xc4f7f0`.
- The 16-color reference is xterm's default 16 colors, written into the test as a table, at 4.5:1 like text at 24 bits. On the light gray bar (7, `0xe5e5e5`) only black (16.6:1), dark red (4.6:1), and dark blue (7.4:1) pass, so `PANEL_RED` stays 1, `PANEL_BLUE` is 4, and `PANEL_YELLOW`, `PANEL_GREEN`, and `PANEL_CYAN` take 0, the bar's text. On the blue bar (4, `0x0000ee`) bright yellow (8.7:1), green (6.8:1), and cyan (7.4:1) pass while bright red (2.3:1) and bright blue (1.9:1) do not, so `PANEL_RED` and `PANEL_BLUE` take 15, the bar's text. Alternative considered: a darker bar at 16 colors (0 or 8); on a dark terminal it would vanish into the background, and bright red on 8 is 1.0:1.
- The status bar paints the counts and the segment's closing space in the new groups; `paint_count` and `last_count_group` keep their shape.

## Risks / Trade-offs

- [A terminal whose 16 colors differ from xterm's reads otherwise] → the table is named in the test; the accents chosen are the darkest or lightest basic colors, the ones most terminals keep dark or light.
- [Starting and ready look alike at 16 colors on the light gray bar] → the slot's text names the state ("starting", "indexing 42%", nothing when ready), and the error stays red and bold.
- [Snapshots or tests holding numeric group ids] → the full test run after the renumbering; ids are referenced by constant everywhere.
