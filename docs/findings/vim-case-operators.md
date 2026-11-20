
### A visual case key that changes nothing is not the dot command's last change
- Location: carat/use_cases/visual/recase_selection.rb (the set_lines guard) and Dispatcher#record, which needs transaction_edits to grow
- Why: a visual ~, u, or U over text already in the target case makes no edit, so a later . repeats the change before it, where Neovim repeats the case key; normal-mode gUU over capitals already records through Operators.recase_range, so the two differ
- Fix: let the dispatcher record a repeat-kind command that made no edit, or state the choice in the operators spec, with an editor row such as xvlgUl. on aBC

### A visual or doubled case key that changes nothing is not the last change
- Location: carat/use_cases/visual/recase_selection.rb:35, and normal-mode gUU through Operators.recase_range
- Why: a visual ~, u, or U (and a normal gUU) that changes no text is not recorded as the last change, since Dispatcher#record needs transaction_edits to grow, so a later . repeats the change before it, where Neovim repeats the case key and the operators spec line says the dot command SHALL repeat each case operator.
- Fix: let the dispatcher record a repeat-kind command that made no edit, or state the choice in the operators spec, with a test row such as xvlgUl. on aBC.

### Case operator test header comment runs past the wrap width
- Location: test/editor_case_operators.rb:12
- Why: the extended header comment runs to 79 columns, past the wrap width of the comment around it, the same kind of point the operator_handler.rb rewrap closed.
- Fix: rewrap the header comment.
### The benchmark agent reruns after a head move that changes no carat file (grep-long-files retro 6)
- Location: `.claude/workflows/deliver-change.js`, the bench phase's start condition; `tools/metrics.sh`.
- Why: grep-long-files spent 158,719 of 586,295 output tokens (27 percent) and 32 of 285 tool calls on 3 benchmark starts at 5dd6b49f95e5, 56fb6d90553c, d4ee3a660680, each with no regression and only the new key allocs.grep 842.6; the third followed a merge of main touching only README.md, docs/codebase-map.md, tools/tools_test.sh. Near the backlog queue's `bench-skip-no-code`.
- Fix: start the benchmark at most once when every shared allocation and round key equals main's and the check only adds keys, and never after a fix or merge changing no carat/, test/, or bench/ file; accepted when such a run's bench share of output tokens is under 10 percent.

### A fix-in-place round is offered for an advisory the contributor may not fix (grep-long-files retro 7, use-case-surface-b retro 5)
- Location: `.claude/workflows/deliver-change.js`, the advisory fix-in-place round and the rework count; the advisory at `docs/findings/grep-long-files.md:10` and `tools/run_state.sh:1926`.
- Why: grep-long-files recorded rework 2 of 3 with every first pass 1; its second round's one advisory pointed at a file outside the branch diff and a mid-file edit of an append-only findings file, so the round made no commit. use-case-surface-b recorded rework 1 with check, security, quality, bench, and CI all first and 0 blocking quality findings (2 advisory), yet its second pass at 026dd754eb37 reran dev-build 67 s, test-build 180 s, diagnose 211 s, tools-test 208 s and both reviews (22696/28). Status shows 199 rework rounds over 203 changes. Near the backlog queue's `rework-review-repeat` (Pool 17).
- Fix: record an advisory the contributor may not fix in place for the findings file without a contributor start, and count an advisory-only round as no rework, skipping the second check and security review; accepted when a run whose first quality pass has 0 blocking findings records rework 0 and runs the check once.

### The merge phase of a green-first-CI run costs the most of the close phases (use-case-surface-b retro 3)
- Location: `.claude/workflows/deliver-change.js`, the merge phase; `.claude/agents/merger.md`.
- Why: use-case-surface-b's merge took 80,031 output tokens on 12 calls (6,669 a call), 29.8 percent of its 268,714 output tokens, with CI green first in 9 min and 6 wait calls; the highest of the last 20 lane rows, whose merge phases ran 4,219 to 47,542 (backlog median about 15,000, feature 6,047 to 32,655).
- Fix: find what a green-first merge spends beyond the wait and the squash message and cut it; accepted when the merge phase stays at or under 20,000 output tokens in each of the next 5 runs whose CI is green on its first pass.

### use-case-surface-c and -d acceptance asks for an analysis-time comparison that decides nothing (use-case-surface-b retro 4)
- Location: `docs/queue-backlog.md` Pool 7 (`use-case-surface-c`, `-d`), its acceptance line.
- Why: use-case-surface-b's implement phase (111,761/68, 41.6 percent of output tokens, 40.5 percent of calls) built a detached worktree of main to compare analysis time; the runner root read 107.0 s on main, 96.8 s on the branch, 128.7 s in the check's metrics stage, a 33 percent spread, while rounds (2 and 2) and allocations (equal in 8 scenarios) decided the benchmark gate.
- Fix: drop the analysis-time comparison from the c and d acceptance, or take both sides from figures the check already records; accepted when part c's contributor builds no second tree of main and its pull request still states rounds and allocations against main.
