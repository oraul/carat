chore(docs): record sprint 28 and queue sprint 29

## Summary

Records sprint 28: it files the sprint's findings into the backlog, appends the lanes' pending metrics rows and the sprint's row, and sets the Sprint 29 queues from the planner's plan. The next sprint cannot start until its queues and the sprint's records are applied, and the backlog sprint as planned held 5 items, over the docs lint's cap of 3.

---

## Changes

- Add the findings entries of the sprint's changes to the backlog files of their first named paths and remove the filed findings files
- Change the feature and backlog queues to the planner's Sprint 29 order and Pool
- Change the backlog Sprint 29 to exactly 3 items, scout-drop first and alone, then merge-path-lows and cheap-tier, by the user's answer of 2026-11-22, with plugin-host-lows and config-trust-tidy moved unchanged to Pool item 1 for Sprint 30 and the Pool renumbered
- Change the exception line so it names scout-drop and cheap-tier as the two pipeline changes within the sprint's 3, scout-drop landing first and alone
- Fix both queues' Pool sizes to read estimated and drop the code marks on a path that does not exist
- Add the pending rows of both lanes' metrics files and the sprint 28 row of docs/sprints.tsv
- Add the archived OpenSpec change of these records, with skip_specs set since no behavior changes

---

## Testing

- Run the security review of the committed diff, pass with 0 High, 0 Medium, 0 Low
- Run the check stages at the implement head, all pass
- Run make spec-validate, 56 passed and 0 failed
- Run make gates and make docs-lint, both pass

---

## Notes

The records change touches no code or tool. One quality finding, Pool item 1 naming planner-loop, which no queue holds, is kept in the user's wording and recorded in the change's findings file rather than adding a queue item.
