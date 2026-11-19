## 1. Implementation

- [x] 1.1 Add the high effort to CALIBRATION, the metric regexes, and the contributor row
- [x] 1.2 Route critical runs and escalate (criticalRule, escalate, plan field, self_check)

## 2. Tests and docs

- [x] 2.1 Tools-test cases for the high effort, the critical run, the escalation, and the metric
- [x] 2.2 Document Critical changes and the new profile in docs/goals.md and planner.md

## 3. Quality round fixes

- [x] 3.1 Read the critical rule from the queue item (criticalOf) in the skipped-plan branch, tested
- [x] 3.2 Restore the blocking quality rounds on resume (restoreRouting, metric.quality_blocked), tested
- [x] 3.3 Plan critical schema pattern and an unparsed-value note, planner.md text restored, test label and declarations fixed, run_state header lists the metrics

## 4. Quality round 2 fixes

- [x] 4.1 Pass the model option inherit for a contributor start on the session profile (critical or escalated), asserted in the routing test
- [x] 4.2 Move the critical-rule comment above criticalRule, anchor the queue-item pattern to the parenthesis, drop the source-grep escalate test, list README.md and tools/run_state.sh in the proposal Impact
