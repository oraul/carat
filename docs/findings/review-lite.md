### settled_round repeats the RECORDS_RE filtering of other records filters (review-lite quality advisory)

- Location: tools/run_state.sh:1248 and tools/run_state.sh:1264 (settled_round), beside settled_at in tools/gates.sh:122 and run_state.sh's own records filters around lines 1786 and 3170
- Why: the same filter of paths outside RECORDS_RE is written four times, so a change to what counts as a record must be repeated in each place or the settled round and the gates disagree; the two quality findings at lines 1248 and 1264 are merged here as one.
- Fix: one shared helper listing the paths outside RECORDS_RE, used by settled_round, settled_at, and the records filters, when review-lite-docs edits tools/rules.sh

### 'workflow: a blocking round never settles' repeats other settle cases (review-lite quality advisory)

- Location: tools/tools_test.sh:4063
- Why: the rewritten case repeats 'workflow: findings in place ride with the blocking ones' (line 4084, inPlaceRound(true, ...) is 'with') and the alone case of line 4086, and its settleFrom element repeats line 4049, so it adds no proof and costs upkeep.
- Fix: drop it from settle_js (and inPlaceRound from settle_js's names) and cite the place_js cases in tasks.md 2.6
