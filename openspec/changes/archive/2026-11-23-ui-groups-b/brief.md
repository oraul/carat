# Brief

ui-groups-b: the third Sprint 30 feature item in docs/queue-feature.md at 6825f81 (after recent-files-persist, #319), delivered as the two of its four headings the plan notes keep: "Status bar has no folder segment and shows the server state as text" and "The progress bar and the percent keep StatusLine". The other two headings (the visual indicator and ModeMsg and MoreMsg, NO_COLOR and 16 colors on the terminal bytes) are queued as ui-groups-c.

The queue entry: `ui-groups-b` (T2, estimated medium): Where: `carat/adapters/status_bar.rb:158` (`collect`), `:41` (`LSP`), `:147` (`lsp_group`), `paint_bar` (PERCENT, PROGRESS); `test/adapters_status_bar.rb`. Why: design section 8 names a folder segment and a one-dot server state, neither drawn; the progress bar's undone cells and the percent are bold StatusLine beside quiet neighbours. Fix outline: the folder in StatusLineDim, the server a dot; undone cells and percent in StatusLineDim. Accepted when snapshots show each.
