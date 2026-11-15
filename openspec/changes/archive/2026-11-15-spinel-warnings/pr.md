build(spinel): fail every compile target on a spinel warning

## Summary

Every make target that compiles with Spinel now fails when Spinel prints a warning, naming each warning, and the four warnings the pinned Spinel prints today are removed. Before, every build target exited 0 on a warning, so the checker and CI passed while Spinel said a signature was not applied, and the standalone make lint hid a NameError behind a warning. The fixes to tab_request, Utf8, and the lint test are the enabling part of this build change, since the targets could not fail on a warning while the tree still printed four.

---

## Changes

- Change dev-build, test-build, build, test-one and so lint, bench, bench-budget, types, gen-config, diagnose, and diagnose-one to fail when Spinel printed a warning, with or without a location, and remove the binary a failed check leaves so the next run compiles and warns again.
- Add tools/spinel_warnings.sh, whose check mode prints every Spinel warning line of its logs and fails on one, and which otherwise wraps spinel for spinel-doctor, collecting its warnings.
- Fix the two warnings on tab_request.rb by moving its ivar pins out of the empty Data class body.
- Fix the two warnings on Utf8.boundary and Utf8.scalar? with a no-op public_class_method line that names both methods in every program, so Spinel's pruning pass no longer drops them while keeping their signatures.
- Fix test/lint.rb to require carat/domain/json, which it uses, so make lint passes on its own.
- Change tools/run_state.sh to key the compile stages on tools/spinel_warnings.sh, so an edit to the check reruns them.
- Add tools_test.sh cases with a stub toolchain proving a warning fails each target and that the targets pass without one.
- Document the pruned-method warning and the warning check in docs/spinel-notes.md and the code map, and record the plan, the metrics history, and the review findings in the docs.

---

## Testing

- Run the security review of the committed diff, passed with no High, Medium, or Low finding.
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates on the final code, all pass.
- Run the quality review, passed with no blocking finding after the three blocking findings of its first round were fixed, its advisories recorded in the backlog.
- Run the benchmark review, passed with allocations and rounds equal to main's recorded figures.
- Run make spec-validate, make gates, and make docs-lint after the archive, all pass.

---

## Notes

No editor behavior changes, so the OpenSpec change sets skip_specs and every snapshot is unchanged. The release build now keeps spin's standard error in BUILD_LOG and prints it when the build ends instead of streaming it; streaming it again with tee is a recorded follow-up, with the other quality advisories (one shared recipe for the targets, a trap for the wrapper's temporary file, a failing-status wrapper case, and BUILD_BINS derived from bin) left in the backlog to keep this change reviewable.
