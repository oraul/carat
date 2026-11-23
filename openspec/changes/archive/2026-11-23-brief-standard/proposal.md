# Proposal

## Why

Over 129 merged runs, briefs in the queue-entry shape (locations as file:line, why, outcome, a test as acceptance, one change, no prescribed how) averaged 0.36 rework rounds; hand-written briefs averaged 0.78 to 1.44, the worst for a missing location, several asks in one brief, and a prescribed how instead of a what. No file holds the format, so the main session writes each brief by hand.

## What Changes

- Add `docs/brief-standard.md`: the header (CHANGE, LANE, BRANCH, BASE) and the fields WHERE, WHY, OUTCOME, ACCEPTED WHEN, CONSTRAINTS, OUT OF SCOPE, USER DECISIONS, and RULES in order, one change per brief, no WHERE no start.
- Add `tools/brief.sh`: `build CHANGE` prints the brief from the change's queue item and run state and refuses an incomplete one; `check [FILE]` refuses a brief with a missing, empty, repeated, or misordered field, a second `CHANGE:`, a WHERE with no `path:line`, or an ACCEPTED WHEN that names no failing-before test.
- Point the planner's queue item shape at the standard's labels (`.claude/agents/planner.md`).
- Add tools-test cases: a complete brief built from a queue entry, and the refusals.

Out of scope: wiring the check into `.claude/workflows/deliver-change.js` (a brief that is only the change name and the resume brief stay accepted unchanged), a queue-entry check in `tools/docs_lint.sh`, and rewriting existing queue entries.

Assumptions: the brief is plain labelled lines, the header on one line as the user was shown; the builder reads the queue item's labels (`Where`, `Why:`, `Outcome:` or `Fix outline:`, `Accepted when`, `Constraints:`, `Out of scope:`, `User decisions:`, `Backlog:`) and fills only CONSTRAINTS, OUT OF SCOPE, and USER DECISIONS with a default; the backlog headings an item covers close OUTCOME; ACCEPTED WHEN must hold a word of test, snapshot, or case and the word fail; WHERE must hold a `path:line`, so an old item without lines is refused until the planner rewrites it. The roadmap: outside it, a pipeline tooling change.

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- Code: `tools/brief.sh` (new), `tools/tools_test.sh`.
- Docs: `docs/brief-standard.md` (new), `.claude/agents/planner.md`, README.md (the rules-and-tools paragraph), `docs/codebase-map.md` (the tools area).
- docs/architecture.md: unchanged, it names no brief format.
- CLAUDE.md: unchanged, it is at its byte budget and the standard lives in its own doc; the Commands line names `run_state.sh`, `open_pr.sh`, and `lane_facts.sh` as the pipeline tools and the README paragraph names the new one.
- README.md: changed.
