# Brief standard

The form of every delivery brief and of every queue entry the planner writes. Briefs in the queue-entry shape (locations as file:line, one sentence of why, the outcome, an acceptance test, one change, no prescribed how) needed 0.36 rework rounds on average over 129 merged runs; hand-written briefs needed 0.78 to 1.44, the worst for a missing location, several asks in one brief, and a prescribed how instead of a what.

No session writes a brief by hand: `sh tools/brief.sh build CHANGE` builds it from the change's queue item and run state, and `sh tools/brief.sh check [FILE]` refuses an incomplete one. A brief that is only the change name, and the resume brief, stay valid: they send the contributor to the queue item.

## Fields

The header is one line, then each field starts a line of its own, in this order.

- `CHANGE: x   LANE: backlog   BRANCH: chore/x   BASE: 12-character commit`: the change, its lane queue, the branch of its run state, and the commit it starts from.
- `WHERE:` one `path:line` per location the change edits, where the contributor starts reading. No WHERE, no start.
- `WHY:` one sentence, with the numbers that justify the change.
- `OUTCOME:` what is true after the change, never how to get there; the backlog headings the entry covers close it.
- `ACCEPTED WHEN:` a test or snapshot that fails before the change and that the gate measures, such as a tools-test case or a test row.
- `CONSTRAINTS:` only the repository rules that apply to this change.
- `OUT OF SCOPE:` what the change leaves alone.
- `USER DECISIONS:` the user's words, quoted, each as an outcome; `none` when there is none.
- `RULES:` the standard tail, the same for every brief, which `brief.sh` writes.

One change per brief: a second `CHANGE:` line, or an ask of two independently testable parts, is split first.

## Queue entries

A numbered queue item writes the labels the builder cuts it at: `Where:`, `Why:`, `Outcome:` (a `Fix outline:` of an older item serves), `Accepted when`, and when they apply `Constraints:`, `Out of scope:`, `User decisions:`, and `Backlog:` (the exact headings it covers). The planner writes a sprint item with them, a pool item may stay one line until a sprint draws it.

## Check

`brief.sh check` refuses a brief with a missing, empty, repeated, or misordered field, a header without its four values, a second `CHANGE:` line, a WHERE with no `path:line`, and an ACCEPTED WHEN that names no test, snapshot, or case that fails before.
