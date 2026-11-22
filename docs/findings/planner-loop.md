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

### The carrier allowance of the findings gate takes proof that groom itself would refuse
- Location: tools/gates.sh carrier_unproven (the `- Merged:` and groom.txt branches)
- Why: security Low (4). A carrier contributor can delete a security finding by adding a bare `- Merged: ### HEADING` line under any backlog entry, or by writing a `listed x ### HEADING` or `fixed x ### HEADING` line into build/plan/groom.txt, which the guard leaves writable; groom itself would refuse both. This change's task 4.6 already requires a security entry's `- Merged:` line to sit under a security entry with its body after it and hands `listed` and `fixed` lines to `groom-proof`; what remains is that the plan file is still a local file the contributor can write.
- Fix: accept a groom.txt line only after the checks groom applies (for listed, a sprint change whose item lists the heading; for fixed, a commit in the sprint's range that touches the entry), or rely on the docs/backlog evidence at HEAD alone and stop reading the local plan file.

### groom-proof checks a carrier's plan line against evidence the carrier controls
- Location: tools/run_state.sh groom_proof (near line 3743)
- Why: security Low (5). For a `fixed` line the range check runs against the carrier branch's own HEAD, so a carrier commit never merged in the sprint counts as the fix if it touches a file the entry names, and findings_entry_text reads the branch's newest version of the entry, which the carrier can first edit. For a `listed` line, sprint_names and merged_of read the lane history files in the worktree, which the carrier can append rows to. A carrier can still delete a security finding with a groom.txt line that groom, running on main, could not accept.
- Fix: judge against the fork point only: for fixed, require `git merge-base --is-ancestor WORD FORK` in place of HEAD; read the lane histories (metrics_files) at FORK the way sprints_file already is; give the gate the entry text at the fork point, or the newest version naming the same location, not the branch's edited one.

### carrier_unproven accepts a removed entry whose bare heading stands anywhere under docs/backlog
- Location: tools/gates.sh carrier_unproven (near line 647)
- Why: security Low (4). A carrier contributor can add only the `### HEADING` line to a backlog file and delete the entry's body and severity from docs/findings, and the gate passes; the merged_security_kept check requires the body for the merged form only.
- Fix: for a security entry filed under its heading, require the same body check as merged_security_kept: the entry's non-heading lines (its Why, Location, and severity) must stand under that heading in docs/backlog at HEAD, else the entry is unproven.
none
