### Stale first-tab scenarios of the buffer-tabs spec
- Location: `openspec/specs/buffer-tabs/spec.md`, the scenarios "One file has the row under 2" and "The open file's modified mark follows its name under 2".
- Why: they read row 0 as "  • a.txt" and "  • a.txt ●", a dot before the name the tabs dropped with the file icon, so the spec disagrees with "A tab is a name and a mark, with no icon" and the shipped row.
- Fix: a delta spec modifying the requirement "Buffer tabs take the top row from two buffers or two tab pages" with "  a.txt" and "  a.txt ●", and the test that names them.
### The tab bar re-scans the list for a shared name on every width
- Location: `carat/adapters/tab_bar.rb`, `shares_name?` called by `tab_width` and `paint_tab`.
- Why: each tab width compares its name with every other file tab, and the overflow loops call `span_width` repeatedly, so a row with many listed files costs about the cube of the tab count in byte compares per frame (most end on the length test); no allocation, but it grows with the buffer list.
- Fix: compute once per paint a count of tabs per last segment, or cache a shared flag on `BufferList` flushed on open, close, and rename, and read it in `tab_width`.
