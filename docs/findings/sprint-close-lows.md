### A records check is voided by build/dev/carat.timing escaping the check clone (sprint-27-records note 1)
- Location: `tools/run_state.sh:885` (`escaped_note`), the stage that writes `build/dev/carat.timing`; seen at 1df857f64fc4 in `tmp/.lane-sprint-27-records`.
- Why: the check at 1df857f64fc4 recorded a security-escape note for `build/dev/carat.timing`, a path changed outside the check clone, so its passes were rewritten as not passing for a timing file no stage should write in the lane.
- Fix: find the stage writing the timing file through the lane instead of the clone and keep it inside the clone; accepted when a records run's check records no security-escape note and a tools-test case shows the timing file stays in the clone.
