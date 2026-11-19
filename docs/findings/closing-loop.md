### The lane history files keep a 22-column header above 24-field rows
- Location: `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv` header line, and `HEADER` in `tools/run_state.sh`.
- Why: `history_row` now appends `advisories_closed` and `advisories_left`, but a file that already exists keeps its old header, so the first rows carrying them have two fields the header does not name.
- Fix: a records change that adds the two names to each header line, with the test that every history row has the header's columns (now 24 for a fresh file) read against the header of the file.
### Process text of the closing loop is absent from CLAUDE.md and docs/goals.md
- Location: `CLAUDE.md` Agents section (30,713 of 30,720 bytes) and `docs/goals.md` line about own-file advisories fixed in place within the rounds.
- Why: both describe advisories as fixed in place or recorded; the closing loop adds one last start after the rounds, described only in README.md and `docs/contributor-notes.md`.
- Fix: when budget allows, one sentence in the CLAUDE.md contributor bullet and the planner's goals text naming `close-advisories`, once its recorded figures show whether it stays.

### closeAdvisories trusts the contributor's reported head to skip the re-review
- Location: .claude/workflows/deliver-change.js, closeAdvisories (head === before)
- Why: a closing start that committed code but reported the old head would skip verify() in the workflow; the pre-push and merge gates (settled_at) still refuse a security pass that code changed since, so nothing is bypassed in practice. The workflow holds no shell, so a lane head read needs a new record start (new behavior).
- Fix: have the checker's verdict commit or a rev-parse record start give the lane head, compare it with before, and skip verify() only when they match.
