### The recent files are kept for one run only
- Location: carat/domain/buffer_list.rb (`recent`, `RECENT_LIMIT`), carat/plugins/finder/plugin.rb (`<leader>fr`)
- Why: Neovim's `oldfiles` survives a restart through shada, so `<leader>fr` in a fresh session lists only what was opened since; a relative path recorded before a `:cd` also names another file after it, as `:ls` does.
- Fix: write the recent list, as absolute paths, to a state file under the user's state directory on quit and read it at startup through the file port, bounded as now, a missing or unreadable file read as empty; a proposal decides the file's place and format.
### The planner's sprint queues reach a records change failing the docs-lint queue check (sprint-26-records retro note 4)
- Location: tools/run_state.sh:4237 (plan-apply copies the planner's lane queue unchecked); tools/docs_lint.sh:68 (the queue check)
- Why: 6 Pool items (13 to 18) of docs/queue-backlog.md lacked an estimated size, failing make docs-lint in sprint-26-records and costing a hand edit of a queue in its implement start.
- Fix: refuse or flag a planner queue that fails the docs-lint queue check before groom and plan-apply copy it; accepted when the next sprint-N-records passes make docs-lint with no hand edit of docs/queue-*.md.
