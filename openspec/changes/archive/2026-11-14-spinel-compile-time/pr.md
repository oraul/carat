build(toolchain): pin spinel to 6af548c9, before its compile-time regression

## Summary

Moves the pinned Spinel compiler back to 6af548c9, the last commit before its compile-time regression, so carat compiles in about a quarter of the time it took at 6b43fe94. Since the previous pin bump every compile of the tests and every diagnose run took about four times as long, which this run traced to Spinel 2440954d1 rebuilding its position map on each `[]` call on an untyped receiver.

---

## Changes

- Change `SPINEL_REF` in the Makefile from 6b43fe94 to 6af548c9, the parent of 2440954d1; the vendored generated header is the same at both pins.
- Document Spinel 2440954d1 in `docs/spinel-notes.md` as the compile-time regression with its measurements, so a later bump past it is checked for compile time and not only for rounds.
- Change the `byteindex` note and the comments in `Domain::Utf8` and `PluginApi::Paths` to name 84aa303b1, after the new pin, as the commit that raises `IndexError` on a continuation-byte offset; `Utf8.boundary` stays for that bump.
- Add the archived OpenSpec change with its proposal, design, and tasks; no spec changes, since no editor behavior changes.
- Record the planner's queue, the metrics row of the last merged change, and the five non-blocking review findings in the backlog.

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low findings.
- Run the quality review, pass with no blocking findings and the advisories recorded in the backlog.
- Run the checker's stages at the new pin (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass; the test runner reports 104 of 104 passed.
- Measure the compile time at the new pin, test-build 148 s and diagnose 180 s against 583 to 736 s and 602 to 659 s at 6b43fe94.
- Run the benchmark comparison against main's recorded figures, pass with no more allocations or rounds.
- Run make spec-validate, all 51 items pass.

---

## Notes

The first CI run builds a fresh toolchain because its caches are keyed on the Spinel revision. Removing carat's untyped `[]` calls, which would let the pin move past 2440954d1 again, is the queued untyped-elephant change. The recheck of the older spinel notes at the new pin and the bump procedure's compile-time step are left as backlog follow-ups.
