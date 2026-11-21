
### backlog.md repeats of earlier review-trust-lows-b headings

- Location: the three review-trust-lows-b headings folded at the end of docs/backlog.md repeat earlier entries.
- Why it matters: repeats inflate the backlog and the next grooming.
- Fix outline: merge each into its earlier heading in the next grooming, or have groom merge an exact-heading repeat.

### backlog.md stale queue reference for review-trust-lows-b

- Location: the folded review-trust-lows-b entries say queued in review-trust-lows-b (docs/queue-backlog.md Sprint 24), but it merged as #268.
- Why it matters: the reference points at a queue Sprint 24 left.
- Fix outline: point them at review-trust-lows-c and pipeline-lows-a (Pool 3, Pool 1) when merged.

### metrics-backlog.tsv review-trust-lows-b row lacks ci

- Location: docs/metrics-backlog.tsv review-trust-lows-b row has no ci key in first_pass and ci_min is '-' though its run state records ci green.
- Why it matters: sprint 25's ci first-pass ratio counts it out.
- Fix outline: have history_row in tools/run_state.sh fall back to the recorded ci result when first_of ci is empty, with a tools-test case, in a pipeline change.
