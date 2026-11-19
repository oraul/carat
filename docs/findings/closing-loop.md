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
### closeAdvisories trusts the contributor's self-reported head
- Location: .claude/workflows/deliver-change.js, closeAdvisories (around line 1383 and 1404)
- Why: when the closing start reports the earlier head, verify() and the security re-review are skipped, and since c5285fbabaac the same comparison clears awaiting; a start that committed code but reported the old head (for example after injection carried in advisory text) would reach package without a fresh workflow security review. The pre-push and merge gates (tools/gates.sh settled_at) still refuse a stale security pass, so nothing is bypassed in practice.
- Fix: compare the lane's actual HEAD (git rev-parse HEAD, read by a record start or taken from the checker's verdict commit) with before, not the returned head, before skipping verify() and clearing awaiting. Defense in depth only.

### closing figures are a lower bound after a resume during the closing re-review
- Location: .claude/workflows/deliver-change.js:1400 and openspec tasks 5.6 of closing-loop
- Why: the comment says final figures follow the early flush, but a resume during the closing re-review restores closed 0 left N, closeAdvisories returns at once, and awaiting and fixedInPlace are not restored, so advisories_closed stays 0 however many the re-review confirms.
- Fix: word the comment and the task as a lower bound on a resume, or record the confirmed count from the resumed re-review's fixed_in_place.
