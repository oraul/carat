build(spinel): pin Spinel 93d7883b, the newest commit

## Summary

Moves the pinned Spinel compiler from 6af548c9 to its newest commit, 93d7883b, with no change to editor behavior. The pin had stayed behind because newer Spinel rebuilt the load record on every index on an untyped receiver, which part a (#134) removed from carat's code, so the bump now compiles in the time the old pin took.

---

## Changes

- Change `SPINEL_REF` in the Makefile from 6af548c9 to the full 93d7883b commit, which also moves CI's toolchain and compile cache keys.
- Add the nine Symbol false positives Spinel's own generator lists from this range on (b, scrub, encode, strip, lstrip, rstrip, chomp, chop, to_str) to `tools/spinel/gen_respond_to_tables.rb`, so the port's Symbol check passes at the new commit.
- Regenerate the vendored header `tools/spinel/spinel_rt_responds_generated.h` at the new commit, which came out byte for byte unchanged.
- Document the new pin and its figures in the untyped-receiver regression entry of `docs/spinel-notes.md`, which no longer says the pin stays at 6af548c9.
- Archive the OpenSpec change with skip_specs, since no behavior changes.
- Record the next queue, the metrics row of spinel-untyped-bump, and four advisory findings in the backlog.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding.
- Run the quality review, pass with no blocking finding and four advisories recorded in the backlog.
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates at the implementation commit, all pass, with test-build at 176 s and diagnose at 213 s.
- Run the benchmark against main's recorded figures, pass with allocations and analysis rounds unchanged.
- Run make spec-validate after the archive, all 51 items pass.

---

## Notes

The brief accepted the bump at runner rebuilds near the old pin's 39, and the runner still asks 125 at 93d7883b, the figure part a left; it was accepted because compile time, the reason for the target, met it (test-build 176 s and diagnose 213 s in the checker's run). What is left is the bundled FileUtils' rebuilds and those Spinel asks without a carat index, out of scope here. Spinel 93d7883b prints two new warnings on carat/domain/utf8.rb lines 53 and 63 while building carat-gen-config; they are recorded in the backlog for spinel-warnings, with the other three advisories.
