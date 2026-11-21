### The quality reviewer's steps 5 to 7 describe a delivery review no workflow starts
- Location: .claude/agents/quality-reviewer.md:22 (steps 5 to 7)
- Why: after review-in-openspec no delivery starts the quality reviewer on its diff; only the pull request text check, the sprint, skeptic, and periodic modes use the agent, and the contributor applies steps 1 to 4 itself, so steps 5 to 7 (quality-blocking and quality-advisory notes, fix in place, the hand-over) describe a path that no longer runs and could lead the text check to record notes nobody reads.
- Fix: decide whether the pull request text check records anything; then reduce steps 5 to 7 to that and to the sprint and periodic modes, and say the contributor's step records findings as tasks.
### The advisory-only settled round can no longer arise
- Location: .claude/workflows/deliver-change.js (settleFrom, settleRound, settledTesting, the alone branch of rounds and closeAdvisories)
- Why: fix in place and the closing loop now offer only security findings, and settleFrom returns no commit when a security finding is offered, so the review-lite path that stands on the earlier check, security, and bench passes is dead code with its tools-test cases.
- Fix: remove settleFrom, settleRound, settledTesting, settleAfter, settleAt, and the settle line of checkLines with their tools-test cases, or offer a non-security finding again; keep tools/run_state.sh settled while main's merge gates read settled_at.
### A run resumed across review-in-openspec drops its earlier quality advisories
- Location: .claude/workflows/deliver-change.js (seed)
- Why: seed no longer reads quality-advisory notes into the findings the package step hands over, so a delivery that ran a quality reviewer before this change merged and is resumed after it writes those advisories to no findings file; they stay only as run state notes.
- Fix: none needed once the deliveries in flight at the merge have finished; otherwise read quality-advisory notes into the backlog list in seed once more.
