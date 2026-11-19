### Pair search budget is checked after the row scan
- Location: carat/adapters/frame_presenter.rb:1228
- Why: the budget is charged before a row is scanned but checked only after the scan (line 1207), so the row that exhausts PAIR_BUDGET is still read and a partner in it is drawn, while docs/compatibility.md says at most 200,000 code points are read a frame.
- Fix: return when budget.stopped right after each charge, or say in docs/compatibility.md that the row crossing the budget is still read.
### Codebase map omits the bracket pair for a folded window
- Location: docs/codebase-map.md:474
- Why: the frame_presenter entry says a folded window records no scroll and draws no guides but not that it draws no MatchParen pair, which this change adds.
- Fix: end the sentence with 'and no bracket pair'.
### Advisory-only fix-in-place rounds count as rework (contributor-tier-trial retro 8)
- Location: `.claude/workflows/deliver-change.js` (rework counting of fix-in-place rounds); joins the queued `advisory-findings-auto` (backlog Pool 27).
- Why: contributor-tier-trial spent rework 2 of 3 with 0 blocking findings (7 advisories over 3 quality passes at 0979253d226d, a47624b033bf, 96085591e512); 8 of the last 20 rows with every first pass 1 spent 12 rework rounds, and rework-2 rows took 61.0 to 118.0 min against 44.8 for vim-folds-b at 0; reviews=36277/65, 31% of 207 calls.
- Fix: accepted when, over the next 10 metrics rows, rows whose first passes are all 1 average at most 0.5 rework rounds without a lower quality first-pass rate.

### A resumed implement start that commits nothing costs a full implementation (contributor-tier-trial retro 9)
- Location: `.claude/workflows/deliver-change.js` (the resume's implement start).
- Why: at head 96085591e512 every stage was 0 and every task done, yet implement took 78,908 of 165,645 output tokens (48%) and 73 of 207 calls (35%) to change nothing; check-stage-order's whole implement was 12941/27.
- Fix: accepted when a resume whose head already passes every stage and has every task checked records implement at most 15,000 output tokens and 25 calls.
