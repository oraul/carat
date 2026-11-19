### The lane history files keep a 22-column header above 24-field rows
- Location: `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv` header line, and `HEADER` in `tools/run_state.sh`.
- Why: `history_row` now appends `advisories_closed` and `advisories_left`, but a file that already exists keeps its old header, so the first rows carrying them have two fields the header does not name.
- Fix: a records change that adds the two names to each header line, with the test that every history row has the header's columns (now 24 for a fresh file) read against the header of the file.
### Process text of the closing loop is absent from CLAUDE.md and docs/goals.md
- Location: `CLAUDE.md` Agents section (30,713 of 30,720 bytes) and `docs/goals.md` line about own-file advisories fixed in place within the rounds.
- Why: both describe advisories as fixed in place or recorded; the closing loop adds one last start after the rounds, described only in README.md and `docs/contributor-notes.md`.
- Fix: when budget allows, one sentence in the CLAUDE.md contributor bullet and the planner's goals text naming `close-advisories`, once its recorded figures show whether it stays.
