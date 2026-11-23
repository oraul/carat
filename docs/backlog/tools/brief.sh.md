# Backlog: tools/brief.sh

### brief.sh cuts each label at its first occurrence anywhere in the item at tools/brief.sh:109 (sprint-31 review quality)
- Location: tools/brief.sh:109 (`index(text, labels[i])`, the label `Where` without a colon)
- Why: a Backlog heading quoting `Why:` or `Outcome:`, or the word `Where` earlier in the item, moves a field's start, so the brief built carries a wrong WHERE or OUTCOME that the check still passes.
- Fix: take a label only at the item's start or after a sentence end, with a tools-test case whose Backlog heading holds `Why:`.
- Category: pipeline
- Added: 2026-11-23
