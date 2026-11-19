fix(pipeline): confine check stages to their clone and toolchain copy

## Summary

Gives each check clone its own copy of the shared toolchain and fails a check whose stage wrote outside its clone, naming the paths. A stage runs branch code, and the clone's links to the shared toolchain let it overwrite the Spinel binaries the next check runs, or reach the delivery clone's hooks, configuration, run state, or tracked files by an absolute path, with nothing noticing.

---

## Changes

- Change the check clone to get its own copy of the shared toolchain with its absolute links pointed at the copy, and stop linking Spinel's checkout into it
- Add a check that, once the stages passed, fails when a file changed in the delivery clone, its linked worktree's git directory, its hooks, the shared toolchain, or Spinel's checkout, when its repository configuration changed beyond a pushed upstream, or when its run state holds anything but the stage records the runner wrote
- Route every stage record the runner writes through one helper so the runner knows the run state it expects, comparing only the measurements of the figures and leaving out the notes and the phases a workflow's close records
- Change the rejoining waiter's dirty-tree test to read without optional locks, so it leaves the index the runner scans untouched
- Add tools-test cases for the toolchain copy, its relinked links, and a failed check per write by an absolute path to the shared toolchain, Spinel's checkout, a tracked file, the run state, a stage record, a hook, the repository configuration, or a linked worktree's git directory, plus passing rejoin and upstream cases
- Document the clone's own toolchain and the escape check in the README and the code map
- Record the residual risks a shell runner cannot close in the change's findings file

---

## Testing

- Run the security review of the committed diff, passed with no High, one Medium and three Low findings, none blocking, all recorded as findings
- Run the quality review, passed with no blocking finding
- Run the checker's stages (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass
- Run the benchmark review, passed
- Run make spec-validate, 54 passed and 0 failed
- Run make gates and make docs-lint, both pass

---

## Notes

The benchmark, which runs branch code in the lane with the toolchain and run states linked, is queued separately as check-runner-safety-bench. A stage that rewrites the runner's own files or the shared compile cache, writes the main checkout or other lanes' refs from a lane, leaves a detached child writing after the scan, or forges its own run state's notes, closing phases, or non-measurement figures is not caught; those residuals need an operating-system sandbox or a caller-written log and are recorded in docs/findings/check-runner-safety.md. No tools/rules.sh edit.
