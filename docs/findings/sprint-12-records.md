
## Three folded headings appear twice from the markdown-reading-c double append

- Location: docs/backlog.md:6775
- Why: the headings "Quality fails its first pass on about half the runs", "A resumed run records 0 output tokens for the phases done before the resume", and "A check pass after a fix round costs more than a first pass" were folded twice from the markdown-reading-c findings file's double append, which groom.txt did not list as repeats, so the backlog carries duplicate entries.
- Fix: have the next sprint grooming list the three as repeats so groom drops the second copies.

## Quality advisory on the markdown-reading-c double append is folded twice

- Location: docs/backlog.md:6787 and docs/backlog.md:6790
- Why: the same quality advisory on the markdown-reading-c double append is folded twice in near-identical words, so the backlog holds a duplicate entry.
- Fix: keep one entry at the next grooming.

## Folded backlog headings follow the previous entry with no blank line

- Location: docs/backlog.md:6751, docs/backlog.md:6765, docs/backlog.md:6861; tools/run_state.sh:1851 (folded_backlog)
- Why: findings entries are appended without a separator and folded_backlog keeps them as written, so the folded headings at those lines sit directly under the previous entry with no blank line, breaking the backlog's format.
- Fix: have the findings append or folded_backlog put one blank line before every heading.
