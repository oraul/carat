# Brief

CHANGE: bench-skip-nonruby   LANE: backlog   BRANCH: chore/bench-skip-nonruby   BASE: 9df178c
WHERE: .claude/workflows/deliver-change.js:1580 (the Benchmark phase: runs whenever the bench review is not recorded at the head) and :1582 (the no-agent path when the check measured main's figures); tools/rules.sh (the scoped stages a change's paths select; read only, never edit).
WHY: a change that edits no Ruby code cannot change allocations or rounds, yet the gate compares them; sprint-review-coverage (#316) edited no carat/ file and lost a fix round to grep allocation noise (685.3 against 685.0, three reruns at 685.0).
OUTCOME: when the change's committed diff against its base touches no file under carat/, bin/, bench/, or config/ and no carat.rb, the Benchmark phase records the bench review as passed with a note naming the reason (no Ruby code changed) and starts no agent; any change touching those paths keeps today's gate unchanged.
ACCEPTED WHEN: a tools-test case shows a docs-and-tools-only diff recording the bench review with no benchmark start, and another shows a diff touching carat/ still running the gate; both fail before the change; make gates passes.
CONSTRAINTS: no model name or alias anywhere in names or prose; an edit of tools/rules.sh stops the run and is named; the merge gates' records stay as they are (review.bench passed at the head).
OUT OF SCOPE: a tolerance or rerun for allocation noise in Ruby changes; the feature lane's files (docs/queue-feature.md, docs/metrics-feature.tsv).
USER DECISIONS: "about the benchmark for pipeline or coverage it doesn't make sense. Agreed to skip the benchmark when it doesn't change any ruby code" (2026-11-23); placed first in Sprint 31's backlog by the user, beside the sprint's 3 queued items.
