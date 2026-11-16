# Design

## Context

`tools/run_state.sh` holds the backlog helpers: `folded_backlog` (the backlog, then each findings file), `backlog_dups` (the `backlog-dups` command), and `backlog_entry`, read by `groom`, which removes the entries of `build/plan/groom.txt` by whole heading line. The planner's sprint mode grooms and writes both lane queues, its two backlog items chosen by judgment; nothing parses an entry's `- Location:` line or maps it to a `docs/codebase-map.md` area, whose numbered `## N. Title` sections name each file at a `` - `path` `` line.

## Decisions

- The pick is `backlog-pick [FILE...]` in `tools/run_state.sh`, dispatched before the change name like `backlog-dups`: the backlog helpers and `queue_files` are there, the code map already names the script, and a file argument lets the cases read fixtures only. With no FILE it reads `folded_backlog`, so the planner's sprint run sees the findings files `groom` folds in later.
- One awk pass: its BEGIN reads the map (paths under numbered areas only, the `Delivered changes` names left out) and the queue files with `getline`; the body collects each `### ` entry, ended by any heading; END ranks and prints. An entry is skipped when its heading text appears in a queue file. A Location keeps its first token without backticks or `:line`, matched exactly, else under a mapped path ending in `/`.
- Ranking: the areas of security entries (`security` in the title or Why, any case) in file order, then every other area by its oldest entry. Each area in turn gives a batch while fewer than `PICK_BATCHES` (2) are printed: 5 or more entries give at most `PICK_MAX` (10), the security ones first, then file order; fewer than `PICK_MIN` (5) with a security entry give the security entries alone; else the area is passed over. Every batch is one area.
- Output: `unmapped: HEADING (PATH)` lines, then per batch a `batch K: area N. Title, M of C entries` line (or `..., its M security entries alone of C`) and its whole heading lines, which the planner copies into its item's Backlog part and `groom`'s `listed` lines need. No batch prints `no batch: ...` and exits 1; a missing FILE dies.
- The triage is planner text: once, when `git log -S 'Backlog triage:' -- docs/queue-backlog.md` finds nothing or the user asks, the sprint planner grooms every stale entry through the existing `fixed` and `duplicate` lines and records a `Backlog triage:` decision in the backlog queue. No new groom line kind, so `groom`'s checks (a security entry only by `listed` or `fixed`) hold.
- Calibration is planner text too: after about 5 backlog-lane runs, a decision comparing the two lane histories' total tokens, wall minutes, first-pass rates, and entries closed per run, proposing a budget, call cap, or tier change only from them.
- Budget: `planner.md` sits 3 bytes under its 8,192; its existing sentences are tightened to make room, never the budget raised.

## Risks

- Heading text matched as a substring of a queue file can skip an entry whose short heading happens to appear in other queue prose; headings carry their location, which makes that unlikely, and a skipped entry stays in the backlog.
- The pick only proposes: the planner still writes the items, so an unmapped entry waits until its Location is fixed or the triage removes it.
