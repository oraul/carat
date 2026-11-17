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
