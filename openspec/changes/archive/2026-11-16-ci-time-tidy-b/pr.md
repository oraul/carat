fix(ci): split CI into pull request and main workflows

## Summary

Splits continuous integration into a pull request workflow and a workflow for pushes to main with no overlap, so a pull request no longer runs the release build and its smoke test and an equal-tree push to main whose sources are already cached compiles nothing. Every pull request spent 63 s on the release build and 23 s on its smoke test beside the 84 s compile, an equal-tree push to main still ran five compiling steps, and ci-stages dropped every CI step under one second.

---

## Changes

- Change the ci workflow to run on pull requests only, keeping the full checks and the comparison with main's measurement under the job spin, the required check name, and moving the release build, its smoke test, and the save of main's measurement out of it
- Add the main workflow, run on a push to main or by hand, which measures main and saves it, warms the compile cache, and builds and smoke tests the release binary, running the full checks only when the squash tree differs from the passed head and compiling nothing when the tree is equal and the compile cache holds the exact entry of these sources
- Add a compile output to tools/ci_scope.sh, true when the checks run or, on a push, when a lookup-only probe finds the compile cache entry missing
- Fix tools/run_state.sh ci-stages to keep each step's fraction, rounded to a tenth, so a step under one second is recorded
- Add tools_test cases for the equal-tree cached and uncached pushes, the differing-tree push, a pull request running no main-only step, spin staying the pull request job, and a fractional step
- Document where each step now runs in the Makefile stage comment, area 1 of the codebase map, the README pipeline section, and section 10 of the architecture

---

## Testing

- Run the security review of the committed diff, passed with no High, Medium, or Low finding
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run the quality review, passed with no blocking finding and eight advisories recorded in the backlog
- Run the benchmark comparison with main's recorded figures, passed with no regression
- Run make spec-validate after the archive, 51 items pass

---

## Notes

Branch protection keeps requiring spin, which only the pull request workflow reports, so no setting outside the repository changes. Running CI by hand moves to the main workflow, where it still runs every step. ci-stages keeps reading the spin job of the ci workflow at the pull request head, so the main workflow's steps are not recorded. Covers the backlog heading CI time doubled after the Spinel pin bump. The eight quality advisories, among them the duplicated compile cache key and check steps across the two workflows, are appended to the backlog for a later change.
