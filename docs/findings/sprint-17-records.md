### A tab-close-d findings entry is folded twice into the backlog
- Location: docs/backlog.md:8156, docs/backlog.md:8020
- Why: quality advisory, duplication: "The tab-close-d findings entries break the file's format" at :8156 repeats the entry at :8020 (same finding, Location, Why, and Fix under another heading), which the groom triage missed.
- Fix: list the :8156 heading as a duplicate in the next sprint's groom.txt.

### Two fold format entries are covered by a third
- Location: docs/backlog.md:8066, docs/backlog.md:8072, docs/backlog.md:8171
- Why: quality advisory, duplication: "Fold adds a level-one heading per findings file" (:8066) and "Folded headings lack a blank line before them" (:8072) are covered by "Groom's fold keeps producing format defects" (:8171).
- Fix: groom the two into the :8171 entry at the next grooming.
