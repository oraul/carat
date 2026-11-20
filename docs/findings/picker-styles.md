### set_float_lines retitles a listed scratch buffer a float was switched to
- Location: carat/use_cases/plugins/window_requests.rb `set_float_lines`
- Why: a float whose window was switched to one of the same plugin's listed scratch buffers (`:b` inside the float) still passes `own_float_tab`, so a refill reloads that scratch buffer and changes its title, after which `set_scratch_lines` and `scratch_window` no longer find it by its old title.
- Fix: refill only the buffer the float was opened with (a float-owned flag on the buffer, or refuse a listed buffer with "No float N"), with a test that switches a float to a scratch buffer and refills it.
### A records-only change still runs the benchmark and rebuilds the lane (sprint-22-records retro note 3)
- Location: the bench phase of `.claude/workflows/deliver-change.js` and the check's scoped metrics stage, `tools/run_state.sh`; seen in the sprint-22-records run state.
- Why: a diff touching no file under carat/, bin/, test/, or bench/ ran the benchmark, which rebuilt the lane because the check scoped its metrics stage to 0s, hit its 10-call cap, and found all 22 keys equal: bench=5455/10 was 11.6 percent of 47025 output tokens and 11 percent of 90 calls; records rows bench 3547/6, 4147/6, 4721/14, 3513/5, 4548/5 over sprints 16 to 20, none with a regression; sprint-21-records ran none. T1 pipeline efficiency, for the backlog lane.
- Fix: accepted when the next records run shows no bench phase and no lane build, while a code change still fails metrics-compare on a regression.

### groom folds findings entries that still name the findings files it deletes (sprint-22-records retro note 4)
- Location: `tools/run_state.sh` groom; seen at docs/backlog.md lines 9444, 9529, 9600 after sprint-22-records.
- Why: one folded reference failed docs-lint and was edited by hand, two more drew the run's one quality advisory and rework round 1 (quality=1164/4); records rows rework 0, 2, 2, 1, 1, 2, 1 over sprints 16 to 22. T1 pipeline defect, for the backlog lane.
- Fix: accepted when groom's output passes docs-lint and no folded entry names a removed findings file, so the next records run needs no hand edit and no rework round from this cause.
