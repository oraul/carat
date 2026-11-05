# Goals

The planner's charter: what every change and every place in the queue serves, in order of priority, and the rubric that places each item. Every queue decision in `docs/queue.md` cites its tier and the data behind it: a benchmark, a CI time, a gate result, a token count, a wall time, a finding, or the user's request.

1. Token and pipeline efficiency: a change delivered in few tokens and little wall time, CI kept fast, by a pipeline that never forgets and improves itself (the retrospective may also simplify the workflow or improve its script), with agents effective at writing code. The user made this goal 1 in `pipeline-speed`, when a change took about an hour and 1.1M to 1.7M total tokens.
2. Security. No merge without the security review of the committed diff and its result in the pull request, never skipped; a High or Medium finding at confidence 8 or above blocks the merge, and blocking security fixes go to the front of the queue. A review of the whole codebase runs every five merged changes and after any change to config loading, file access, plugin boundaries, terminal output, process spawning, the entry point, or the agent guard and the gates; not after a docs-only, keymap-only, or other tooling change.
3. Performance at run time, kept by the benchmark and a history of benchmark results.
4. Code quality the Ruby way, within Spinel's rules.
5. Clean Architecture that is easy to extend.
6. Code simple and elegant for the people who read it.
7. Neovim command support.
8. UX.
9. UI with readable color contrast.
10. Highlights.
11. Autocomplete.
12. The README kept current, including how carat is built with AI.
13. Documentation size and quality controlled.

## The rubric

Every item of `docs/queue.md` names its tier and its size, as `(T2 user request, estimated small)`, and every queue decision cites its tier and a number; `make docs-lint` refuses an item without both.

- Tiers, in order: T0 a blocking High or Medium security finding at confidence 8 or above, a red `main`, or a crash; T1 pipeline defects and pipeline efficiency (tokens, wall time, rework, CI time); T2 user-reported bugs and now-requests; T3 Low security findings reachable from an untrusted project without extra user action; T4 other efficiency (run time, tests), ordered by cost of delay; T5 roadmap items and user features, in the order of the goals above; T6 other Lows and advisories, folded into a change of the same domain and queued alone only when five accumulate.
- Inside T3 to T6, order by value divided by size. A quick win may jump ahead within T4 to T6, never ahead of T0 to T3. Same-domain quick wins are batched into one change to share its fixed overhead, 1.1M to 1.7M total tokens a change before `pipeline-speed`.
- Sizes are total-token budgets, input plus output as the workflow's usage reports them, estimated from `docs/metrics.tsv`: small under 500k and 25 minutes, medium under 1.2M, large under 2.5M. The history records each change's estimate beside its total and output tokens and its wall minutes, and the retrospective flags an overrun (`sh tools/run_state.sh budget CHANGE`).
- Size check before a change starts: a brief with more than about four separate fixes, or estimated large outside the roadmap, is split into balanced changes. `workflow-trim` bundled seven fixes and needed four quality rounds across two runs; `guard-allowlist`, three fixes with four folds, took 5 rework rounds and 860,176 output tokens.
- The planner runs when the queue needs a decision: a new finding, a user request, or a split; otherwise the next item is taken as written.
- Aging: an item records how often it was pushed back; at three it rises one tier or gets a written reason.
- At least one user-requested feature in every three changes, counted over consecutive merged changes: at most two pipeline, tooling, security, or tidy-up changes run between two features, T0 items excepted, which go first and do not count (the user's rule, recorded at `start-screen` after `theme-tokens` asked). A user-requested feature is a now-request of the user, a feature the user requested or scheduled, or a user-visible roadmap feature the user approved, such as `search-and-substitute` (goal 7); pipeline, tooling, security, and tidy-up changes do not count. To keep the rule a feature may pass T1 to T6 items, which otherwise keep their order; it never passes a T0 item nor the track it depends on (`markdown-preview` and `csv-viewer` stay after the UI track); when no feature is ready or T0 items fill three changes in a row, a plan decision says so.
- A brief part, plan note, or proposal states the problem, its numbers, and the acceptance check, never the implementation, which the contributor chooses. In `workflow-trim` a blocking quality finding reversed the approach a brief part, a retrospective note, and a plan note had all prescribed.
