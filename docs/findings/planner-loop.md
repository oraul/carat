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

### The findings gate still trusts a plain entry's gone, duplicate, and merged plan lines
- Location: tools/gates.sh:carrier_unproven
- Why: a plain (non-security) entry removed from docs/findings/ passes when the local plan's groom.txt holds any gone, duplicate, or merged line for its heading, or a bare "- Merged:" line names it; groom's proofs of those kinds (paths gone at HEAD, a location named by another heading) need the entry in the backlog, which no longer stands after groom, so the gate cannot repeat them. A contributor-written plan line can still delete a plain entry. Security entries are covered: they leave only by a verified listed or fixed line or a merged line under a security entry holding the body.
- Fix: have groom write the proof it checked (the paths held, the location named) beside each removal into a tracked record, such as the sprint's row file, and let the gate compare it, or file removed plain entries' headings in the pull request's archived change so the gate reads tracked text only.
