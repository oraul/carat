build(toolchain): pin spinel at c0502112 and regenerate its header

## Summary

Moves the pinned Spinel compiler from 93d7883b to c0502112, the head of upstream's default branch when the change started and 193 commits newer, with the vendored respond-to header regenerated at the new pin. The user asked for the bump now, in its own pull request as the Makefile requires, so carat builds and checks on the current compiler.

---

## Changes

- Change `SPINEL_REF` in the Makefile from 93d7883bd8d85ebbce768445c41c03d9a4bc9e92 to c0502112d8cf8c6f57bc7e1ef5a2af1732407036, the old pin an ancestor of the new and 193 commits apart.
- Regenerate `tools/spinel/spinel_rt_responds_generated.h` with `make spinel-header`, which drops the same 29 Enumerable names from the Array and Hash arrays because upstream now lists them in its shared Enumerable array, so `respond_to?` still answers them.
- Add the archived OpenSpec change `2026-11-16-spinel-update` recording the bump, the figures at the new pin, and that carat needed no code fix and `docs/spinel-notes.md` gains no pitfall.
- Change `docs/queue.md` to the planner's queue with the user's decisions of today and add the merged review-coverage-b row to `docs/metrics.tsv`.

---

## Testing

- Run the security review of the committed diff, passed with no high, medium, or low finding.
- Run every checker stage on the new toolchain (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass, 107 of 107 tests passing.
- Run `make diagnose`, clean for `bin/carat-gen-config.rb`, `bin/carat.rb`, and `test/runner/run_all.rb` with no Spinel warning.
- Compare allocations per key and analysis rounds with main's recorded figures, none higher: rounds 2 and 2 as on main, insert falling from 32.0 to 26.0 and dot-ciw from 78.0 to 66.0, the rest unchanged.
- Run the quality review and the benchmark review, both pass with no blocking finding.
- Run `make spec-validate`, 53 of 53 pass.

---

## Notes

No carat code changed: every stage passed on the new compiler at the first run, so no fix is named. The allocation drops for insert and dot-ciw come from the new compiler and are not traced to one upstream commit. Analysis took 66.1 s for carat in the first run, 1.3 s over the range earlier runs measured at the old pin, and 62.1 s in the checker's run, within it, so the difference is run-to-run noise. CI builds a fresh toolchain on its first run since its caches are keyed on the pinned commit. Carat workarounds the new pin may make removable were not rechecked and are left out of scope. The quality advisory on the contradictory analysis-time wording in the tasks was fixed in the archived change rather than recorded in the backlog.
