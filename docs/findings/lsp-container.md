### The language server gateway rescans every configuration line for a rooted command on each idle tick
- Location: carat/adapters/json_rpc_language_gateway.rb:318
- Why: command? runs on every idle tick while the current filetype has no server (any filetype with no lsp, or an untrusted directory) and now scans all of the roughly 760 configuration lines twice instead of once; the design's risk note understates this cost.
- Fix: keep the chosen command per language once read, as trusted? keeps @trust, since neither the directory nor the configuration changes during a session.

### A language.NAME.lsp.root line whose root is not a root is kept without a report
- Location: carat/domain/config.rb:218
- Why: a line whose root is relative or has a . or .. segment is kept silently and covers nothing, though the README promises every configuration mistake is reported as file:line: message.
- Fix: move root_of into a domain helper config.rb can require and report such a line as not a root.

### A phase's recorded output differs from its agent starts' output
- Location: `.claude/workflows/deliver-change.js` phase accounting, `metric.phases` (markdown-reading-c retro note 18).
- Why: phase.check recorded 150,693 output and 27 calls (37.9% of 397,894) while its three checker starts summed 5,213; git-signs-status-b check 57,747 and checks-and-pr-lows 38,907 against 2,029 to 6,432 earlier, so `check-skip` and share-based proposals judge a number the checker did not spend.
- Fix: accepted when, for the next three runs, each phase's recorded output is within 10% of the summed output of its agent starts.

### The package step appends the planner's findings twice
- Location: the package step's findings append, `tools/run_state.sh` plan-apply (markdown-reading-c retro note 19).
- Why: 14 lines of `docs/findings/markdown-reading-c.md` repeated (commit 1fc49d8), raised by 2 quality advisories in a run with quality first pass 0 and rework 3.
- Fix: accepted when a tools-test case runs the append twice on one change and the second leaves the file unchanged.

### A merge refused on a moved main costs a full resume and a CI failure
- Location: `.claude/workflows/deliver-change.js` merge and resume path (markdown-reading-c retro note 20).
- Why: CI green at the first push in 7 min, yet first.ci 0; merge 39,463 output in 24 calls (ci_wait_calls 10), and the resume re-ran 3 checker, 3 quality, 3 security starts.
- Fix: accepted when the next merge refused for a moved main records first.ci 1 on a green CI and reaches the merge with no new checker or review start unless merging main changed files under carat/ or tools/.

### plan-apply and history write into whatever checkout runs them
- Location: `tools/run_state.sh:1707` append_history, plan-apply (planner-split-rule retro note 5).
- Why: the package step ran both from the main checkout, edited main's backlog queue and history while another lane ran, keyed a row to main; package 10,276 output in 21 calls against a median of 14 over the last 10 backlog rows.
- Fix: accepted when both refuse, non-zero with the tree unchanged, outside the change's lane worktree (a tools-test case), and the next package phase stays within 15 calls.

### CLAUDE.md and planner.md have no bytes left for review fixes
- Location: `CLAUDE.md`, `.claude/agents/planner.md` against docs-lint's limits (planner-split-rule retro note 6).
- Why: CLAUDE.md 30,714 of 30,720 bytes, planner.md 8,189 of 8,192; the split rule left out of CLAUDE.md and 2 of 4 quality advisories deferred for want of bytes.
- Fix: free space by removing repetition, limits unchanged; accepted when the next change touching them lands planner-split-rule quality advisories 3 and 4 and the split rule with docs-lint passing.

### The merge start passes its cap on a first-pass green CI
- Location: merger start, `CALL_CAPS` in `.claude/workflows/deliver-change.js`; pool item `merge-gate-integrity` (planner-split-rule retro note 7).
- Why: merge 18,979 output in 14 calls (13.2%) with first.ci 1; 5 of the last 8 medium backlog rows at 14 calls against a cap of 12; merge output 17,462 to 30,050 in 4 runs against 4,045 to 6,438 in 9 of the last 10 feature rows.
- Fix: fold into `merge-gate-integrity`; accepted when five medium runs in a row merge within cap, no overrun note, under 6,000 output on a first-pass green CI.
