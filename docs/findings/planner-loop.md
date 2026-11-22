### A delivery planned before a sprint close can carry the plan with an older lane queue

- Location: .claude/workflows/deliver-change.js:1666 (packagePlan), tools/run_state.sh plan_apply
- Why: a delivery whose planner wrote build/plan/<change>/ before the sprint plan existed and that packages after it runs groom (copying the sprint's queues) and then plan-apply, which overwrites its lane queue with the plan written from the older queue, so the sprint's queue for that lane is lost from the pull request.
- Fix: have plan-apply refuse, or skip with a note, when PLAN_DIR/sprint.carrier names this change and the change's lane queue in its plan directory is older than PLAN_DIR/sprint, leaving the groomed queue less the change's item.

### A carrying delivery that never merges strands the sprint plan

- Location: tools/run_state.sh groom (sprint.carrier)
- Why: groom writes build/plan/sprint.carrier for the first package step; when that delivery stops and is abandoned, every later groom stands down until someone removes the file by hand, so the next queue and the sprint row never land.
- Fix: let groom treat a carrier whose run state is gone, records a stop, or was replaced as no carrier, or add a run_state command that releases it, with a tools-test case.

### docs/goals.md still describes the sprint quality review and the notes starts

- Location: docs/goals.md:7, docs/goals.md:54
- Why: after planner-loop the planner reviews the sprint's diff and the security reviewer's record mode records the notes, but goals.md, a planning record the planner writes only when asked, still names the quality reviewer's sprint start, the skeptic, and the notes and skeptic notes starts on the quality reviewer.
- Fix: the user or the planner, when asked, rewrites the two lines to name the planner's review and the security reviewer's record mode.
