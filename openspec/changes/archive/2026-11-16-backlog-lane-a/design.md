# Design

## Context

`tools/run_state.sh` reads `docs/queue.md` (status, estimate_of, exception_item, groom, plan_needed), `docs/metrics.tsv` through `metrics_file` (status, bench, has_row, history, sprint_state, merged_of, sprint_row, groom, merged_since), and `docs/backlog.md` through `backlog_file` (history's late findings, backlog-dups, backlog_entry, groom). `tools/docs_lint.sh` budgets and checks the queue; `tools/rules.sh` lists the records-only paths; the workflow and agents name the paths in prose.

## Decisions

- Lane files, not lane columns: a column would keep one file and its conflicts. Each lane file keeps the old shape, so the existing awk programs run unchanged over a merged stream.
- `history_rows` prints the header, then both lanes' rows ordered by the place of each row's merged commit in `git rev-list --reverse --topo-order HEAD BASE`, one git call, BASE (origin/main) passed as the commit it resolves to and left out when it resolves to none: main's squash commits form one chain, so the order is the merge order whatever the timestamps (a first try by committer time tied within a second and made the tests flaky), and a change merged on main after the branch point, whose row history appends though HEAD lacks its commit, sorts after every row HEAD holds (ranking by HEAD alone put it first, so status and bench showed an older row as the newest and groom left it out of the sprint); a row whose commit neither holds gets 0 and a stable sort keeps its file order. Readers that need order use it; lookups by name (`has_row`, `merged_of`) read the lanes unsorted.
- `lane_of CHANGE`: the lane file naming the item at `merged^`, else the squash subject's type, else feature. A recorded file is the record of the lane; nothing else is stored.
- `queue_at COMMIT`: both lane files at COMMIT, else `docs/queue.md` at COMMIT when neither exists there (history before the split).
- `exception_item` reads `merged^`, then `merged`, and accepts a numbered item or the `The user-approved exception: \`NAME\` (` line, the mark in its first parenthesis.
- `plan_needed`: the change is the head when it is item 1 of either lane's queue (the waiting plan's lane files while a sprint plan waits).
- `folded_backlog` prints the backlog and then each `docs/findings/*.md` in name order. `groom` validates every groom line against it, then writes it through the removal awk into the backlog and removes the findings files, so a refused groom leaves both untouched.
- Late findings go to `docs/findings/<change>.md` under the same `## Findings of CHANGE after its package step` heading.
- Budgets: `docs/queue-feature.md` and `docs/queue-backlog.md` share the old 17,369 bytes, plus one intro line each.

## Risks

- Merge order differs from append order when a row was appended late; the merge order is the truer one for a sprint (on today's history one row, `authoring-kit`, moves up two places).
- A planner still writing `build/plan/queue.md` would be ignored by `groom`; the planner's file names the lane files, and this change's package step splits the waiting plan by hand.
