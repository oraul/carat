# Findings of sprint-14-records

## The folded heading after the merger entry lacks a blank line

- Location: docs/backlog.md:7360 (format).
- Why: the folded heading 'The merger returns pending before its 30-minute CI wait ends' follows the previous entry's Fix line with no blank line; the known groom defect recurs and make docs-lint does not catch it.
- Fix: insert one blank line before it, and let folded_backlog put a blank line before every folded heading, as the queued groom entry says.

## Two defects are recorded twice in the backlog

- Location: docs/backlog.md:7470 (duplication), with :7380, :7375, and :7476.
- Why: the folded merge-record-check findings and the groomed sprint-14 entries record the same two defects twice: 'groom_row trusts history rows the branch can append after review' (:7380) against 'groom_row compares newline-stripped rows and trusts untracked inputs' (:7470), both at tools/gates.sh:131, and 'squash_commit falls back to HEAD' (:7375) against 'merged_at without a pr accepts any ancestor of HEAD' (:7476).
- Fix: fold each pair into one entry at the next grooming (backlog-dups), keeping the sprint-14 wording and the security Low (4) rating.
