# Goals

The planner's charter: what every change and every place in the queue serves, in order of priority, and the rubric that places each item. Every queue decision in `docs/queue.md` cites its tier and the data behind it: a benchmark, a CI time, a gate result, a token count, a finding, or the user's request.

1. Security first. No merge without the security review of the committed diff and its result in the pull request; a High or Medium finding at confidence 8 or above blocks the merge; security fixes go to the front of the queue. A review of the whole codebase runs every five merged changes and after any change to config loading, file access, plugin boundaries, terminal output, process spawning, the entry point, or the tooling and CI.
2. Performance on CI and at run time, kept by the benchmark and a history of benchmark and CI results.
3. Code quality the Ruby way, within Spinel's rules.
4. Clean Architecture that is easy to extend.
5. Code simple and elegant for the people who read it.
6. Neovim command support.
7. UX.
8. UI with readable color contrast.
9. Highlights.
10. Autocomplete.
11. The README kept current, including how carat is built with AI.
12. Documentation size and quality controlled.
13. A pipeline that is token-efficient, never forgets, and improves itself: the retrospective may also simplify the workflow or improve its script.
14. Agents effective at writing code.

## The rubric

Every item of `docs/queue.md` names its tier and its size, as `(T2 user request, estimated small)`, and every queue decision cites its tier and a number; `make docs-lint` refuses an item without both.

- Tiers, in order: T0 a blocking High or Medium security finding, a red `main`, or a crash; T1 pipeline defects that corrupt metrics or stall runs; T2 user-reported bugs and now-requests; T3 Low security findings reachable from an untrusted project without extra user action; T4 efficiency, ordered by cost of delay; T5 roadmap items and user features, in the order of the goals above; T6 other Lows and advisories, folded into a change of the same domain and queued alone only when five accumulate.
- Inside T3 to T6, order by value divided by size. A quick win may jump ahead within T4 to T6, never ahead of T0 to T2. Same-domain quick wins are batched into one change to share its fixed overhead, about 300k output tokens a change before `workflow-trim`.
- Sizes are output-token budgets, estimated from `docs/metrics.tsv`: small under 300k, medium under 700k, large under 1.2M. The history records each change's estimate beside its actual output tokens, and the retrospective flags an overrun (`sh tools/run_state.sh budget CHANGE`).
- Size check before a change starts: a brief with more than about four separate fixes, or estimated large outside the roadmap, is split into balanced changes. `workflow-trim` bundled seven fixes and needed four quality rounds across two runs, 56,348 output tokens of quality review in its last run alone.
- Aging: an item records how often it was pushed back; at three it rises one tier or gets a written reason.
- At least one user-requested feature in every three changes, counted over consecutive merged changes. A user-requested feature is a now-request of the user, a feature the user requested or scheduled, or a user-visible roadmap feature the user approved, such as `search-and-substitute` (goal 6); pipeline, tooling, security, and tidy-up changes do not count. The rule never moves a feature ahead of T0 to T3 items, which keep their place, nor ahead of the track it depends on (`markdown-preview` and `csv-viewer` stay after the UI track); when those fill three changes in a row, a plan decision says so.
- A brief part, plan note, or proposal states the problem, its numbers, and the acceptance check, never the implementation, which the contributor chooses. In `workflow-trim` a blocking quality finding reversed the approach a brief part, a retrospective note, and a plan note had all prescribed.
