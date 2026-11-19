### Findings append is not idempotent across starts

- Location: `.claude/workflows/deliver-change.js` (the findings append a resume repeats), seen in `docs/findings/finder-grep-preview.md:35`
- Why: finder-grep-preview retro note 13: the file carries the retro notes twice (lines 35 to 48 repeat lines 1 to 11) and the security Low twice (lines 26 and 31), 14 of its 48 lines repeats, which cost the last quality round 2 advisories, both left (advisories_closed 0 of 2).
- Fix: accepted when a tools-test case hands the same findings to the append twice, as a resume does, and each entry lands once.

### An overrun note is written at every check pass

- Location: `.claude/workflows/deliver-change.js` (the overrun note per check pass); near-same as the backlog queue's `check-pass-budget-flag`, merge into it
- Why: finder-grep-preview retro note 14: 4 overrun notes in one run (notes 7, 8, 9, 12: 213,428, 336,889, 361,702, 409,157 output against medium's 200,000), each superseding the last, none changing a decision; finder-match-strict 3 of 4.
- Fix: accepted when a run records at most one output overrun note and the planner's overrun input is unchanged.

### Reviews spend a third of a run's tool calls for an eighth of its output

- Location: `.claude/workflows/deliver-change.js` (the review rounds)
- Why: finder-grep-preview retro note 15: 73 of 237 calls (30.8%) for 54,543 of 446,611 output (12.2%), the last round finding 0 blocking, 1 Low, 2 advisories; finder-grep 80 of 268 (29.9%), contributor-tier-routing 73 of 231 (31.6%), sprint-count-t0 59 of 225 (26.2%).
- Fix: accepted when the reviews' share of tool calls over the next five lane rows falls below 20%, the security review still run on every pushed head.
