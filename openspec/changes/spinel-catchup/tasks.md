# Tasks

## 1. Baseline and bump

- [x] 1.1 Measure main at c0502112 in this worktree before the checkout moves: `make dev-build test-build bench-budget metrics` (rounds, analysis, allocations and time per key into `build/metrics/current.tsv`, kept as the base), `make build` (release binary size), and `make bench` (time per key).
  - Result: rounds 2 (carat) and 2 (runner); analysis 58,061.8 ms (carat) and 127,808.5 ms (runner); allocations per key lh 26, j 27, insert 26, ddp 58, undo 52, dot-ciw 66, lh-ruby 26, open-ruby 24; release `build/bin/carat` 7,008,944 bytes; `make bench` total per key lh 19.8 us, j 111.4 us, insert 21.4 us, w 40.4 us, ddp 187.8 us, undo 26.9 us, ciw 54.6 us, dot-ciw 24.5 us, lh-ruby 25.3 us, open-ruby 48.6 us, finder 1,777.4 us.
- [x] 1.2 Set `SPINEL_REF` in the `Makefile` to the new commit and regenerate `tools/spinel/spinel_rt_responds_generated.h` with `make spinel-header` using the c0502112 toolchain; verify the diff is the generator's output only and `make -s spinel-rev` prints the new commit.
  - Result: `make -s spinel-rev` prints 0d1a7ca33a6edd44fad3b074e172f8a327697ebb, upstream `master`'s head (the remote's `HEAD`) when the change started, 1,045 commits after c0502112 (296 first-parent; the old pin an ancestor). The regenerated header is byte-identical to the vendored one: the generator's inputs moved (`src/builtin_ops.c`, `lib/spinel_rt.h`) but not the names it reads, so the file is unchanged.
- [x] 1.3 Build the new toolchain with `make toolchain`; verify it installs `spinel`, `spin`, and `spinel-doctor`, the header the build used is the vendored one, and `make doctor` reports `ruby: refused (stub)`.
  - Result: installed under `tmp/.toolchain/bin` in 9 min 35 s; `spinel --version` reports 0d1a7ca33a; the checkout's header compares equal to the vendored one; `make doctor` reports `ruby: refused (stub)`.

## 2. Carat at the new pin

- [x] 2.1 Run every stage of `make check` on the new toolchain, fixing in carat's code only what fails at the new pin and is small and local, each fix named here with the test that proves it; verify `make check` passes and `make diagnose` is clean.
  - Result: the first run failed one case of `test/domain_plugin_manifest.rb` in `test-run` (113 of 114): "an option line with an illegal byte" expected the raw bytes `\xC0\xAF` in `ManifestCheck`'s message and got them escaped, since Spinel f49716bd ("String#inspect and #dump take only a valid UTF-8 character as one") makes `String#inspect` escape a byte outside a valid UTF-8 sequence as CRuby does. The fix is the test's expectation, now the escaped text, with a comment; `ManifestCheck` is unchanged and its message now matches CRuby's. The second run passed every stage, 114 of 114 tests and 1,805 of 1,805 tool tests, `make diagnose` clean for all three roots with no Spinel warning. No earlier commit was needed, so none was skipped.
- [x] 2.2 Compare with the baseline: `make metrics-compare BASE_METRICS=` the 1.1 measurement (allocations per key and rounds), `make bench` (time per key), the analysis lines, and the release binary size.
  - Result: `metrics-compare` reports no regression: rounds 2 and 2; every scenario allocates one object fewer per key (lh 25, j 26, insert 25, ddp 57, undo 51, dot-ciw 65, lh-ruby 25, open-ruby 23). Analysis 55,870.5 ms (carat, 2.2 s less) and 130,794.2 ms (runner, 3.0 s more), both run-to-run noise on this machine. Release binary 6,947,072 bytes, 61,872 fewer. `make bench` total per key lh 19.1 us, j 98.4 us, insert 21.8 us, w 31.7 us, ddp 187.2 us, undo 28.3 us, ciw 62.1 us, dot-ciw 36.2 us, lh-ruby 21.9 us, open-ruby 22.9 us, finder 1,672.3 us; three reruns of dot-ciw, ciw, and undo measured dot-ciw 25.1 to 52.3 us, ciw 56.3 to 60.4 us, undo 26.0 to 31.6 us, so dot-ciw's 1,000 keys are noise and ciw sits about 5 to 10 percent over the baseline, inside `metrics-compare`'s 20 percent tolerance.

## 3. Notes

- [x] 3.1 Recheck the open notes of `docs/spinel-notes.md` (Known miscompilations and the other `Open:` notes) with reduced probes at the new pin and record each result there; each workaround the pin makes unnecessary whose removal is not trivial and tested goes to `docs/findings/spinel-catchup.md`; verify with `make docs-lint`, `make gates`, and `make spec-validate`.
  - Result: `private_constant` and the `when CONST` folding still reproduce at 0d1a7ca3 (the second also at c0502112); the destructuring, string-return, and empty-array probes answer correctly, so only reverting carat's rewrites decides them; the slab release is unchanged in `lib/sp_slab.c`; the versioned-entry defect has no reduced probe and is not rechecked. No workaround became unnecessary, so no finding is filed. New notes: `String#inspect` escapes illegal bytes since f49716bd, and a child waited for inside a `Fiber` no longer crashes since c6de72a2 (the probe segfaulted at c0502112 and printed 0 at 0d1a7ca3). The `byteindex` note no longer says the next bump meets 84aa303b1, which c0502112 already holds.

## 4. Review fixes

- [x] 4.1 Make the proposal's What Changes and Impact say the header was regenerated with no change, as task 1.2 records (quality advisory on `proposal.md`).
- [x] 4.2 Say in `docs/spinel-notes.md` that the destructuring recheck at 0d1a7ca3 used a smaller probe than the f34005bf one (quality advisory on its destructuring note).
- [x] 4.3 Keep the one fact of the `Fiber` note in `docs/spinel-notes.md` and drop the sentence about the Fiber study's plan (quality advisory on its Fiber note).
