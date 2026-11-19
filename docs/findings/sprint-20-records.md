### Closing-loop retro entries folded twice verbatim
- Location: docs/backlog.md:8754 repeats :8709, and :8759 repeats :8714 (the closing-loop retro 10 and 11 entries).
- Why: finder-grep's findings file held them twice, and groom merged near-same notes but not exact repeats, so the backlog carries duplicates.
- Fix: list :8754 and :8759 as repeats in the next groom, and have groom drop an exact heading repeat within one fold.

### Quality first-pass entries removed as fixed before their acceptance was met
- Location: docs/backlog.md:6524 (origin/main :6524 "Quality fails its first pass on about half the runs", :8091 "The contributor returns work the quality review blocks on its first pass").
- Why: the two entries are removed as fixed while their acceptance (7 or 8 first passes of the next 10) is unmet; the sprint-20 quality first pass is 1 of 7.
- Fix: keep one merged entry open until the measure is met, or fold its acceptance into the calibration decision.

### Folded headings follow the previous entry's Fix line with no blank line
- Location: docs/backlog.md:8704, :8709, :8720.
- Why: the defect groom-fold-format already tracks; the folded headings run into the previous entry.
- Fix: groom-fold-format puts a blank line before each folded heading.
