# Design

## Context

At 1266c8c a sprint close runs: due (runner), the security and quality reviewers over the combined diff with one continuation each and the sweep in an even sprint, the security notes (quality reviewer, record mode), the skeptic (quality reviewer), its notes (record mode), the planner, the record (runner), and the Records phase: a nested `deliver-change.js` run of `sprint-N-records`, whose contributor runs `history` and `groom`, then a records-merged read (runner). `groom` refuses every change but `sprint-N-records`; `recordsHeld` keeps the records run back on a blocking sprint security finding or the plan's security first.

## Decisions

### D1. The planner reviews quality

The planner's sprint start gets the combined diff and the security reviewer's findings. It reviews quality as `.claude/agents/quality-reviewer.md` steps 2 and 3 say, plus architecture, duplication across the sprint's changes, and docs currency, in `tmp/.review-quality-sprint`, and reads each security finding against the code. It returns, beside its plan: `head`, `quality_blocking` and `quality_advisory` counts, `not_reviewed`, `disputed`, `security_missed`, and `notes` (kind quality or security). It records nothing (planner step 6). A quality finding it drops is in no note, so it is not recorded. A disputed security finding is returned as `disputed: REASON; FINDING`; the finding itself was recorded before the planner started.

The planner's `maxTurns` rises from 35 to 85 and the sprint plan cap from 30 to 80: it takes over two quality starts of 53 and a skeptic of 35.

### D2. Records under the read profile

Notes quote reviewed code, so the runner, whose profile also writes reviews and phases, never runs them (cheap-tier, Medium at confidence 5). With no quality reviewer start left, the two record starts (security notes before the planner, the planner's notes after it) run as the security reviewer in a new one-line `Mode: record`, whose hook runs the read profile: notes, no review, no phase. The acceptance check is the guard's read-profile refusals of a review and a phase record, kept as cases.

### D3. The first delivery carries the records

`packagePlan` tells every package step: `history`, then `groom`, then `plan-apply` (or the removal of its item when its planner did not run). `groom CHANGE`:

- retires the marker when main (BASE) holds the sprint's row; a row only in the working tree leaves it;
- does nothing when no plan waits, or when `build/plan/sprint.carrier` names another change of this sprint;
- holds (`queue_hold`) while `sprint-N` or `sprint-N-sweep` records a blocking periodic security review that `merged_since` and `passed_since` do not clear, or while `sprint-N` records `hold security-first` and no change planned after its review merged;
- otherwise applies the plan as before, writes `sprint.carrier` as `sprint-N CHANGE`, and leaves the marker.

`history CHANGE` appends every lane's pending rows when `carries` holds (the same conditions), so the sprint row finds all six; otherwise its own lane's. The carrier's pull request and archived change hold the rows, the groomed backlog, both queues, and the row. A carrier that never merges keeps the plan with it until `build/plan/sprint.carrier` is removed; groom's message says so.

### D4. The other lane

Option (b) of part 4. The marker stays until main holds the row, so the other lane's plan-needed and planner still read the sprint plan's queues while the carrier is open, and its groom stands down. Each lane's package step edits only its own lane queue, and groom both, so a conflict in the queues is the carrier against the other lane: `merge-main` resolves a conflict only in `docs/queue-feature.md` and `docs/queue-backlog.md` by the branch's version of its own lane (`lane_of`) and main's of the other, and commits the merge. Any other conflicted file aborts as before.

### D5. Hold and counts

`queueHeld(blocking, securityFirst)` names the reason for the report. When the plan names `security_first`, the record line sets `hold security-first` before the review lines, so no package step sees the plan reviewed and not held. `review-due` stays not due while a reviewed plan waits, held or not. `placed_by_sprint` now reads each sprint review's commit: a merge at or before it, in a sprint whose plan exists (marker or row), was placed by that planner. The `sprint-N-records` branches of `plan-needed`, `budget`, `history`, `gates.sh` findings, and `docs_lint.sh` go: the findings gate lets a branch whose `docs/sprints.tsv` gains appended rows remove only the entries groom filed (a heading standing under `docs/backlog/` at HEAD, or named by a `- Merged:` line there) or its plan removes (`build/plan/groom.txt`, a security entry only listed or fixed), and docs-lint checks both lanes when `docs/sprints.tsv` differs from BASE.

## Risks

- A delivery whose planner ran before the sprint closed and packages after it carries the plan and then applies a plan directory written from the older queue. The main session starts the next sprint after `/sprint`; recorded as a finding.
- `docs/goals.md` lines 7 and 54 still name the sprint quality review and the notes starts; the planner writes that file only when asked, so it is named for the user.
