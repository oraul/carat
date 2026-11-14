# Brief

top-rows — The head item of sprint 3 in docs/queue.md, delivered as the planner wrote it there (self-contained: locations, acceptance, and the backlog headings it covers; split at its start if over four fixes, as the item says). The pull request is opened by the branch-push Action from pr.md; never call a pull request create tool. During the delivery never read or grep docs/backlog.md, not even through a repository-wide search (exclude it). Keep to exactly the queue item; name anything extra and ask.

Plan notes:

- Scope of this delivery, part a of the split: tab contrast at 3:1 and never by color alone (carat/adapters/tab_bar.rb), a fixed-width modified mark (tab_bar.rb:129, :146), the winbar accent and `›` with an ASCII form under `option.icons ascii` (carat/adapters/winbar.rb:18), and the backlog heading "## The tab bar copies the status bar's digit fit" (tab_bar.rb:53). The rest of the queue item (the :LspRestart stale outline, the single owner of winbar rows, the scratch-split winbar row, the SymbolOutline comment, and the test/editor_breadcrumbs.rb row) is queued as `winbar-outline` at pool 1. Do not deliver those parts here.
- Bookkeeping: this package step adds palette-rows' (#118) history row with `sh tools/run_state.sh history`. Its quality advisories were already appended to docs/backlog.md at its package step, so nothing more is appended.
- No build/plan/backlog.md this time: every finding is placed in the queue (`palette-tidy`, `spec-tests-first`, `review-demotion`).
- build/plan/queue.md is 16,685 of 17,369 bytes (the docs/queue.md budget).
