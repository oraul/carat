### backlog-pick dies on an unmatched findings glob
- Location: .claude/agents/planner.md:35 and .claude/workflows/sprint-planning.js:150, with tools/run_state.sh:1760
- Why: the planner and sprint-planning call backlog-pick docs/backlog.md docs/findings/*.md, but groom removes every findings file (tools/run_state.sh:1973), so a sprint whose changes left no findings passes the literal glob and the pick fails with no docs/findings/*.md.
- Fix: have backlog_pick skip an unmatched literal glob argument, or have the callers name only existing files.

### backlog-pick tries each backticked path twice
- Location: tools/run_state.sh:1831
- Why: candidates re-adds every backticked pathlike token in the bare-word pass after stripping the backticks, so each one is looked up twice, wasted work on every entry.
- Fix: run the bare-word pass over the Location with the backticked spans removed instead of only the backticks.

### Top-level docs findings never reach a batch
- Location: tools/run_state.sh:1757
- Why: entries at README.md, CLAUDE.md, and docs/ paths are always unmapped since docs/codebase-map.md names no numbered area for them, so docs findings never reach a backlog-lane batch and only a planner decision mentions them.
- Fix: map the top-level docs in an area of docs/codebase-map.md, or batch unmapped entries as their own docs item.

### No case pins a bare directory word known only by its files
- Location: tools/run_state.sh:1821
- Why: a bare backticked directory word the map does not name itself but that holds mapped paths (`tools` with only `tools/a.sh` mapped) prints unmapped, while the same directory with a slash is placed by dir_area; the header documents the asymmetry but no tools_test case pins it.
- Fix: in named_file accept a word for which dir_area of the word with a slash is non-empty and the tree holds it, with a tools_test case, or add a case pinning the unmapped result.
