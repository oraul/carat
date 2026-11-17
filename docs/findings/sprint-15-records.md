# Findings of sprint-15-records

## The fold keeps a findings file's title as a second level-one heading

- Location: docs/backlog.md:7555, tools/run_state.sh (folded_backlog)
- Why: groom folds the sprint-14-records findings file with its title, so the backlog gains a second level-one heading ('# Findings of sprint-14-records') that is no entry and nests every later folded entry under '## Two defects are recorded twice in the backlog'.
- Fix: drop the title line, and let folded_backlog in tools/run_state.sh skip a findings file's leading '# ' line.

## The fold adds headings with no blank line before them

- Location: docs/backlog.md:7488 (also 7492, 7496, 7500, 7540, 7613, 7622), tools/run_state.sh (folded_backlog)
- Why: the fold adds seven headings with no blank line before them (main had 10, the branch 17), the groom defect the folded sprint-14-records finding names, which make docs-lint does not catch.
- Fix: insert the blank lines, and let folded_backlog separate every folded heading by one blank line.
