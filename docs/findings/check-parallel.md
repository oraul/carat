### A stage's branch code can forge its pass record through the runner's job files (security Medium, confidence 6)
- Location: tools/run_state.sh:637 (stages_reap and the jobs directory beside the check clone)
- Why: a stage runs the branch's own code in the check clone, and the runner's job files sit in ../jobs/ beside it; the code can overwrite ../jobs/NAME.start with a PID the runner did not start plus the current commit and write 0 to ../jobs/NAME.status, so stages_reap records stage.NAME as passed at HEAD for its own stage or any stage running beside it, and gate_stages in tools/gates.sh accepts it, weakening the clone isolation the README promises; before this change the exit status came straight from `wait`. Not blocking since a deliberate stage could already reach the run state through the tmp/.toolchain symlink.
- Fix: keep each job's PID, start second, and commit in runner shell variables, take the exit status from `wait PID` on the runner's own child (poll with `kill -0`, then `wait`), or keep status files in a runner-owned mktemp -d outside the clone's parent, and trust only a PID the runner launched.

### A failing stage's log excerpt reaches the terminal unfiltered (security Low, confidence 4)
- Location: tools/run_state.sh:778
- Why: the last 20 lines of a failing stage's log go to the check's stdout and check.log as they are; branch code controls that log, so terminal escape sequences such as OSC 52 clipboard writes or title changes reach whoever runs the check or cats check.log.
- Fix: strip control characters from the excerpt before printing it, for example through `LC_ALL=C tr -d '\000-\010\013-\037\177'` ahead of the sed prefix, or print it with `cat -v`.

### stages_stop does not record a passed compile stage as compiled
- Location: tools/run_state.sh:666
- Why: a compile stage that passed while the check was stopping is recorded through stage_end but compiled_set is never called, so the next check compiles it again, costing minutes of a stage the cache already holds.
- Fix: share one record-a-passed-stage step (stage_end, then compiled_set for COMPILE_STAGES) between stages_reap and stages_stop.

### A lost runner's stage jobs keep running, and its test waits them out with a fixed sleep
- Location: tools/tools_test.sh:558, check_lost in tools/run_state.sh
- Why: the fixed `sleep 3` is timing-fragile and shows that check_lost leaves a hard-killed runner's stage jobs running, writing into the stage logs the next check reuses.
- Fix: have check_lost stop the lost runner's process group (setsid makes its pid the group id) and drop the sleep from the test.
### The contributor self-check and the quality reviewer share no blocking checklist
- Location: `.claude/agents/contributor.md` (self-check), `.claude/agents/quality-reviewer.md` (blocking rule)
- Why: quality fails its first pass most often, 66 of 130 changes against check 128/130 and security 125/130; 5 of the last 11 feature rows quality:0; lsp-container-b's fix round (SIGPIPE ending carat on stop) cost implement 153,294 of 264,142 output (58.0%) and put the run over its 200,000 output budget at 229,659 (retro note 11).
- Fix: one blocking checklist both read, or drop the self-check items that never caught a blocker; accepted when the feature lane's quality first pass over the next 10 rows reaches 8 of 10 with implement output no higher than its current median. Queued in `review-demotion`.

### A post-review prose edit in the package step refuses the push
- Location: the package step of `.claude/workflows/deliver-change.js` and the check and security records it invalidates
- Why: in lsp-container-b a docs-only wording fix (`docs/architecture.md:275`, Open3) invalidated the recorded check and security review, the push was refused, the edit reverted and the stale sentence left on main; package 21 of 210 tool calls (10.0%) (retro note 12).
- Fix: settle the advisories the package step may fix before the last review, or let pure prose edits of docs keep the records; accepted when no package step over the next 10 runs has a refused push from a post-review prose edit. Queued in `check-skip`.

### The in-run budget line prices total tokens at 6 per output token
- Location: the check-pass budget line of `.claude/workflows/deliver-change.js`
- Why: sprint-12-records spent 36,282 output against 2,147,268 total (59 per output), 4.3x over small's 500,000, while 6 per output predicted 217,692; the last ten backlog rows ran 3.5 to 59 per output; windows-tabs-tidy 1,433,283 and windows-buffers-tidy 1,373,899 were over 1,200,000 at 4.8 and 10.7; sprint-security's line said under at 131,132 output (lsp-container-b note 13, sprint-security note 8).
- Fix: derive the multiplier from the lane history or drop the in-run total estimate; accepted when the line, replayed over the last ten rows of both lanes, says over for every row whose final total exceeded its budget. Queued in `budget-prediction`.

### Scout packs whose facts the contributor redoes
- Location: the scout phase of `.claude/workflows/deliver-change.js`, `.claude/agents/scout.md`
- Why: in sprint-security the scout took 34,911 of 181,413 output (19.2%) and 19 of 126 calls, its pack found the brief's lines stale and the contributor re-checked them at the same commit; backlog rows' scout share 18.4% to 40.1% (sprint-security note 7).
- Fix: start a scout only where its facts change a decision, or let the contributor take the pack as read; accepted when over the next five runs that start a scout its output stays under 10% of the run's with no drop in the quality first-pass rate. Queued in `scout-value`.

### The quality reviewer reports advisory classes the package step drops
- Location: `.claude/agents/quality-reviewer.md` (advisory classes)
- Why: of sprint-security's 6 advisories, 3 naming or duplication ones (RAN, the repeated prompts, the findingLine format) were dropped, changing no decision; the reviews phase took 15,732 output and 28 of 126 calls (22.2%) (sprint-security note 9).
- Fix: stop reporting the classes the package step drops by rule; accepted when over the next five runs the package step drops no advisory class the reviewer reported, with blocking findings unchanged. Queued in `review-demotion`.
