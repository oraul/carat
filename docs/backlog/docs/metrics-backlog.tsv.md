# Backlog: docs/metrics-backlog.tsv

### authoring-kit sits in the backlog lane against the migration rule
- Location: docs/metrics-backlog.tsv:4
- Why: its merged commit e375e4cfa5cf is held by no ref, and the proposal sends a row without a known commit to the feature lane, which lane authoring-kit prints, so the history and the lane disagree
- Fix: move the row to docs/metrics-feature.tsv, or state the exception in the archived design
- Also: docs/metrics-feature.tsv
- Category: pipeline
- Added: 2026-11-16

### And docs/metrics-backlog.tsv (sprint-20 sweep quality, metrics-feature.tsv:1)

- Location: `docs/metrics-feature.tsv:1`
- Why: and docs/metrics-backlog.tsv:1 the committed headers still hold 22 columns while tools/run_state.sh:484 HEADER and the rows written since closing-loop hold 24 (advisories_closed, advisories_left); history only writes HEADER to a new file (line 2164), so the lane histories drift from the header the code documents
- Fix: append the two column names to both headers, or have history rewrite a shorter header line
- Also: docs/metrics-feature.tsv, tools/run_state.sh
- Category: pipeline
- Added: 2026-11-19
