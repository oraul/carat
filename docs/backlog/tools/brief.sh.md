# Backlog: tools/brief.sh

### brief.sh cuts each label at its first occurrence anywhere in the item at tools/brief.sh:109 (sprint-31 review quality)
- Location: tools/brief.sh:109 (`index(text, labels[i])`, the label `Where` without a colon)
- Why: a Backlog heading quoting `Why:` or `Outcome:`, or the word `Where` earlier in the item, moves a field's start, so the brief built carries a wrong WHERE or OUTCOME that the check still passes.
- Fix: take a label only at the item's start or after a sentence end, with a tools-test case whose Backlog heading holds `Why:`.
- Category: pipeline
- Added: 2026-11-23

### build_brief finds each queue label by its first index anywhere at tools/brief.sh:109 (sprint-32 sweep quality, note 21)
- Location: tools/brief.sh:109
- Why: build_brief finds each queue label by its first index anywhere in the joined item text, so a label word inside an earlier field (a Why naming Constraints: or Outcome:) cuts that field there and the brief is built from the wrong text
- Fix: match a label only at a field boundary (the item start or after a sentence end), or require the labels in order and search each after the previous
- Category: quality

### FIELDS is set and never read (check_brief keeps its own at tools/brief.sh:35 (sprint-32 sweep quality, note 49)
- Location: tools/brief.sh:35
- Why: FIELDS is set and never read (check_brief keeps its own label list), so it is dead code
- Fix: remove it
- Category: quality
