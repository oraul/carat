### The language gateway's root check does not resolve symlinks
- Location: carat/adapters/json_rpc_language_gateway.rb:1368 (security Low, confidence 3)
- Why: inside_root? checks the buffer path lexically and does not resolve links, so a symlink inside the project that points outside it counts as inside and, when the user opens it, the file's text goes to the server in didOpen; impact is small since the server only starts on its own under a trusted root and runs the project's code anyway.
- Fix: optionally resolve the path with File.realpath once, when the buffer is first opened (the definitions' project check already does this), and cache the result per URI so the idle tick stays off the disk.

### The process runner's stop can signal a reused pid
- Location: carat/drivers/process_runner.rb:97 (security Low, confidence 2)
- Why: stop sends KILL to a bare pid after checking waiter.alive?; if the child is reaped and its pid reused by another process between that check and the signal, the KILL could hit an unrelated process owned by the same user, a window the comment acknowledges and which is practically very narrow.
- Fix: have the detach waiter itself send the KILL, or use a pidfd where Spinel supports it, so the signal can only reach a child that has not been reaped yet.

### A late OSC 11 reply's tail is read as keys
- Location: carat/drivers/ansi_terminal.rb:78 (security Low, confidence 2)
- Why: the rest of an OSC 11 reply that arrives after a read timeout is passed on as keys; those bytes are hex digits, slashes, and ESC backslash, which can run normal-mode commands such as r, f, b, or a search; they come from the terminal emulator, not an attacker, so this is a robustness issue, and the change only documents the existing behavior and adds a test for it.
- Fix: after a timeout drops a held reply start, keep discarding until the next BEL or ESC backslash, but only for one more short read window, so keys typed later are not eaten.

### The TerminalPort row rewords main's Driver and Test double cells
- Location: docs/architecture.md:206 (quality advisory, reported twice, still present at the head)
- Why: the TerminalPort row's Driver and Test double cells, rewritten in the fix, no longer say how background is answered (AnsiTerminal asks OSC 11 at its first read; FakeTerminal answers unknown) and reword main's unchanged text.
- Fix: keep main's Driver and Test double cells and append only the background clauses.
### The benchmark agent starts when it can decide nothing (vim-case-operators retro 20, pr-trust-lows retro 7)
- Location: `.claude/workflows/deliver-change.js`, the bench phase's start condition; `tools/metrics.sh`.
- Why: vim-case-operators started it twice (8f0ce99, cbd9783) for a key absent from main's recorded row though main's measurement gave the same figure (allocs.grep 842.6 on both sides): 101,841 of 568,067 output tokens (17.9 percent), 15 of 276 calls. pr-trust-lows started it 4 times on a diff touching no carat/, bench/, or test/ file: 16,538 output tokens, 24 of 237 calls (10.1 percent), every key equal, 0 findings. History bench first pass 205/206. Near the entry "The benchmark agent reruns after a head move that changes no carat file (grep-long-files retro 6)" and the backlog queue's `bench-skip-no-code`.
- Fix: start no agent when the diff touches no carat/, bench/, or test/ file, or when a key main's row lacks equals main's own measurement; accepted when such runs record review.bench skipped with no bench start, the record still passing, and a tools-test case covers each condition.

### The quality first pass names one occurrence of a pattern it flags (pr-trust-lows retro 8)
- Location: `.claude/agents/quality-reviewer.md`, the first-pass instructions.
- Why: the advisory at d388c4a (pin copies the test does not read) missed the guard's refusal literal at `tools/agent_guard.sh:902`, present since d388c4a and found at ee4ce6c, causing rework round 2 of 3 with every first pass 1 and 0 blocking findings; reviews 63,219 output tokens (21.0 percent) over 56 calls; quality first pass 113/205 in history. Near the backlog queue's `stale-wording-first-pass` and `rework-review-repeat`.
- Fix: the first pass searches the tree for every occurrence of a flagged pattern and names them all; accepted when over the next 5 runs no advisory names a line unchanged since an earlier quality review of the same run.

### Advisory-only fix rounds rerun the check and both reviews at full cost (vim-case-operators retro 21)
- Location: `.claude/workflows/deliver-change.js`, the rework count and the review reruns.
- Why: vim-case-operators rounds 1 and 2 fixed 3 and 1 advisories, round 2's fix caused the one blocking finding (visual r), and security ran 5 times with 0 findings; rework 3 of 3 with every gate first; reviews 121,744 of 568,067 output tokens (21.4 percent), 74 of 276 calls (26.8 percent); rework 204 over 206 changes. Near the entry "A fix-in-place round is offered for an advisory the contributor may not fix (grep-long-files retro 7, use-case-surface-b retro 5)" and `rework-review-repeat`.
- Fix: an advisory-only round does not count toward the 3-round limit and security reruns only on the final head or a diff touching new files; accepted when a run whose first quality pass has 0 blocking findings runs the security review at most twice.

### The planner's Already met check counts untracked lane files (vim-case-operators retro 19)
- Location: `.claude/agents/planner.md`, the Already met and size check.
- Why: the planner reported 99 rows and bindings at d7f5de8 that were untracked in the lane worktree, so a 770-line, 33-file change was sized small: 568,067 output tokens against the 83,333 small output budget (6.8 times), overrun notes 13, 14, 15, 16, 18 at every check pass (108,357 to 492,616), 2,564,423 total in 190 min.
- Fix: Already met cites only paths tracked at origin/main; accepted when a tools-test case with an untracked file in the lane is not counted as met.
