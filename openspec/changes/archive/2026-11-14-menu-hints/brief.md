# Brief

menu-hints — The head item of sprint 3 in docs/queue.md, delivered as the planner wrote it there (self-contained: locations, acceptance, and the backlog headings it covers; split at its start if over four fixes, as the item says). The pull request is opened by the branch-push Action from pr.md; never call a pull request create tool. During the delivery never read or grep docs/backlog.md, not even through a repository-wide search (exclude it). Keep to exactly the queue item; name anything extra and ask..

Plan notes:

- Scope for this delivery (part a only): a centered bottom key-hints panel that names groups instead of `+N` (carat/use_cases/discovery/show_key_hints.rb:97, the bottom-right FloatSpec at :143). It covers these 4 backlog headings: "## KEYHINTS_DELAY is never read", "## ShowKeyHints copies HideKeyHints' close", "## Key hints repeat the grammar-mode test", "## HandleKey restates KeyHints#showing?". It is accepted when the hints are a centered bottom panel with named groups and the `palette` scenario plus lh 26.0, j 27.0, insert 34.0 hold. The palette rows, Pmenu match spans, the 4.5:1 selected rows, and the 1-column popup padding moved to `palette-rows` in sprint 3 item 1. Leave them out of this change.
- float-placement (#116) is pending history: this package step adds its metrics row once (1,176,745 total, 118.0 wall min, estimate large) and commits build/plan/queue.md as docs/queue.md.
- A #116 quality advisory sits in a file this change edits: show_key_hints.rb:125 (the screen_cols < 6 guard duplicates `limit < 1`). It is already in docs/backlog.md and is placed in `discoverability-tidy`. Outside this change's scope. If the panel rewrite removes the guard anyway, the PR's Notes should say so, so the sprint groom can drop the entry as fixed.
- No build/plan/backlog.md this time: every finding was placed in the queue or is already in the backlog. I removed stale build/plan/groom.txt, groomed.md, and sprint.applied (sprint-2's groom is already applied; no build/plan/sprint waits).
- build/plan/queue.md is 15,665 bytes, under the 17,369 docs-lint budget; every numbered item carries a tier and a size.
