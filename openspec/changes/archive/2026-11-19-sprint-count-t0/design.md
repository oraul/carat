# Design

## Context

`sprint_state` takes the sprint's names from the history rows after the last sprint row and the merged run states without a row. Only `exception_item`, a test for `beyond the sprint` in an item's first parenthesis, left a name out, at most one per sprint. No tier, heading, or exception paragraph was read, so T0 items, pool items, and the changes an exception line puts outside the 3 were counted.

## Decisions

- One reader, `queue_class`, over the queues at the merged commit's parent (the queue delivered from) and at the merged commit (whose package step may have applied the plan naming it), as `exception_item` read both. It replaces `exception_item`; `queue_items` stays for `item_lists`. Both read each queue through one reader, `queue_records`, which prints every item and exception paragraph joined on one line with its heading class (`sprint` under a `## Sprint N` heading, else `pool`, only a `#` or `##` heading changing it, so a `###` sub-heading keeps its sprint), so the queue line form is parsed in one place.
- Precedence when several apply: `t0`, `outside`, `beyond`, `sprint`, `pool`. A sprint item at either commit is a sprint item, since its package step removes it from the queue.
- Any `## Sprint N` heading counts as the sprint's heading, not only the sprint in progress: a change merged after a sprint's last counted change and before its records change still sits under the old heading, and a queue holds one Sprint heading per lane.
- The outside-the-3 paragraph is prose; its names are the backticked ones of the semicolon clause holding `outside the 3`, before that clause's first ` run ` or ` runs `, so `` `a` and `b` run before `c`, outside the 3 `` puts out `a` and `b` and not `c`, matching every exception line the queues held in sprints 20 and 21.
- A split part is found in a second pass against the changes counted in the first, so merge order does not matter: a pool item whose name less one trailing `-x` letter equals a counted change's name or stem (`finder-grep-c` beside a counted `finder-grep-b`).
- A name no queue holds (a history row of a test fixture or an older commit, or a delivery renamed in prose) is counted as before rather than left out, so no sprint loses a change it cannot class.
- The cap of one uncounted change per sprint goes: the brief leaves out every T0, outside, and beyond change, and the live sprint-21 holds three. A sprint still closes only at `sprint_size` counted changes.

## Risks

- A later feature in a lettered series (`vim-folds-d` beside a counted `vim-folds-c`) delivered from the pool in the same sprint counts as a split part; the planner places such series in the Sprint heading anyway.
- A queue line written in another form than the ones above is not parsed; its change then counts as a pool item or by the fallback, and the not-due line names the reason so the main session sees it.
