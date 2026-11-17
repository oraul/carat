### The groom appends the benchmark-phase and groom-output entries three times

- Location: docs/backlog.md:7218
- Why: the entries 'The benchmark phase measures records and docs-only runs that build nothing it measures' and 'Groom output needs a hand edit and draws the records runs' quality advisories' are appended verbatim twice (:7200/:7205 and :7218/:7223) and a third time as sprint-12-records retro notes 4 and 5 (:7268 on), the groom double-append the backlog already records (duplication).
- Fix: list the copies at :7218-7227 and :7268 on as duplicates at the next grooming and have groom not append both a groomed.md entry and the folded finding of the same note.

### The groomed.md entries repeat the folded retro notes

- Location: docs/backlog.md:7176
- Why: the groomed.md entries at :7176-7198 (contributor self-check checklist, post-review prose edit, in-run budget line, scout packs, advisory classes) repeat the folded retro notes at :7228-7251 in near-identical words (duplication).
- Fix: keep one of each pair at the next grooming (backlog-dups).

### Folded headings follow the previous entry with no blank line

- Location: docs/backlog.md:7176
- Why: the folded headings at :7176, :7209, and :7218 follow the previous entry with no blank line (format).
- Fix: have folded_backlog put one blank line before every folded heading, as the queued groom entry says.

### Three sprint-12-records findings use level-two headings

- Location: docs/backlog.md:7253
- Why: the three sprint-12-records findings at :7253, :7259, and :7265 use level-two headings while every other entry is level three (format).
- Fix: make them level-three headings and have the findings append keep the entry level.

### A folded entry is already resolved and its Location lines are stale

- Location: docs/backlog.md:7253
- Why: the folded entry on the three doubled headings is already resolved by this groom (groom.txt drops the duplicates), and the Location lines of :7253-7265 (docs/backlog.md:6775, :6787, :6790, :6751, :6765, :6861) point at pre-groom lines that now hold other entries (docs currency).
- Fix: list it as fixed at the next grooming and have findings name a heading instead of a backlog line number.
