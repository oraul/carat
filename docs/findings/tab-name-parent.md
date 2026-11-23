### Stale first-tab scenarios of the buffer-tabs spec
- Location: `openspec/specs/buffer-tabs/spec.md`, the scenarios "One file has the row under 2" and "The open file's modified mark follows its name under 2".
- Why: they read row 0 as "  • a.txt" and "  • a.txt ●", a dot before the name the tabs dropped with the file icon, so the spec disagrees with "A tab is a name and a mark, with no icon" and the shipped row.
- Fix: a delta spec modifying the requirement "Buffer tabs take the top row from two buffers or two tab pages" with "  a.txt" and "  a.txt ●", and the test that names them.
