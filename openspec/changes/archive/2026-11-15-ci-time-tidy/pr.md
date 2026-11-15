fix(pipeline): run only the stages a change's paths need

## Summary

Scopes the checker's local stages and CI's tools and docs steps to the paths a change touches, so a documentation-only change runs only the docs lint and the gates, and a change touching no file `make tools-test` reads skips it locally and in CI. Docs-only pull requests spent hundreds of seconds compiling, testing, and analysing code they never touched (664 local seconds on #137, 91 seconds of `tools-test` on #138), and the Makefile still cited analysis figures the current Spinel pin no longer holds.

---

## Changes

- Change `tools/run_state.sh check` to run only the stages the changed paths since the merge base with main need, recording a stage left out as passed with the note scoped so the stage gate still sees every stage; `docs-lint` and `gates` always run
- Change `tools/run_state.sh bench` to carry main's recorded figures when the metrics stage was scoped out
- Add the shared path classes to `tools/rules.sh`: `documentation`, moved from `tools/ci_scope.sh` and now counting a `LICENSE` file, and `TOOLS_RE`, the paths `make tools-test` reads
- Change `tools/ci_scope.sh` to write a `tools=` output and CI to run its Tools step on it and its Docs lint step on every pull request
- Add `tools/tools_test.sh` cases for the scoped check, the carried figures, the `tools=` output, the `LICENSE` class, and one holding every path the tool tests read to `TOOLS_RE`
- Remove the stale analysis figures from the Makefile's analysis budget comment
- Document the path scope in the README pipeline section, `docs/architecture.md` section 10, and area 1 of `docs/codebase-map.md`
- Archive the OpenSpec change `ci-time-tidy` with `--skip-specs`, record the planner's queue and the metrics history, and append the four quality advisories to the backlog

---

## Testing

- Run the security review of the committed diff, passed with no High, Medium, or Low finding
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass
- Run the quality review, passed with no blocking finding and four advisories recorded in the backlog
- Run the benchmark comparison against main's recorded figures, passed
- Run make spec-validate after the archive, 51 passed and 0 failed
- Run make gates and make docs-lint before the push, both pass

---

## Notes

This is part a of `ci-time-tidy` as the planner split it; part b, `ci-time-tidy-b`, stays first in the queue with the two CI workflows (pull requests only and push to main only, the required check `spin` kept), an equal-tree push to main compiling nothing, and `ci-stages` keeping a fractional step, so the backlog heading on CI time after the Spinel pin bump stays open until it merges. The changed paths come from the merge base with main; a branch whose merge base cannot be found runs every stage. `docs/codebase-map.md`, `docs/actions.md`, and `docs/compatibility.md` are deliberately not treated as documentation because the lint, action, and ex tests read them.
