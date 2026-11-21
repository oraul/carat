# Backlog: docs/metrics-feature.tsv

## ux-fixes-a history row records no CI minutes

- Location: docs/metrics-feature.tsv:42
- Why: the ux-fixes-a row records ci_min as - though its CI ran green and its ci_stages are recorded, because build/pipeline/ux-fixes-a.json has no metric.ci_min, leaving a hole in the CI-minutes history.
- Fix: have the merge phase always record ci_min (or history derive it from ci_stages) and backfill this row.
- Category: pipeline
- Added: 2026-11-17

### The lane history files keep a 22-column header above 24-field rows
- Location: `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv` header line, and `HEADER` in `tools/run_state.sh`.
- Why: `history_row` now appends `advisories_closed` and `advisories_left`, but a file that already exists keeps its old header, so the first rows carrying them have two fields the header does not name.
- Fix: a records change that adds the two names to each header line, with the test that every history row has the header's columns (now 24 for a fresh file) read against the header of the file.
- Also: docs/metrics-backlog.tsv, tools/run_state.sh
- Category: pipeline
- Added: 2026-11-19
