build(toolchain): bump Spinel to 2f6c24864127

## Summary

Bumps the pinned Spinel compiler from 0d1a7ca33a6e (2026-11-19) to 2f6c24864127 (2026-11-22), the head of upstream's default branch when the change started, 654 commits later (229 on its first-parent line). Spinel's fixes and new library support since the old pin reach carat only through a bump, which the user asked for this sprint.

---

## Changes

- Change `SPINEL_REF` in the Makefile to 2f6c24864127a5609533a786a6af120b7438de08; the newest commit passed every stage, so no commit was skipped and no carat code needed a fix.
- Regenerate the vendored respond-to header with `make spinel-header`; its output is byte-identical at the new pin, so `tools/spinel/` is unchanged.
- Document in `docs/spinel-notes.md` that Spinel now enforces `private_constant` since ae6a3602, moving that note from Known miscompilations to Language and library, and record the recheck of every other open note at the new pin.
- Change the use case rule of `docs/architecture.md` section 5 and the matching comment in `test/lint.rb` to say Spinel refuses a private constant read when it runs, keeping the `lint` rule as carat's own layering rule.
- Record the planner's queue and findings for this lane and the metrics history row.

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low finding.
- Run `make check` on the new toolchain, every stage passes: 123 of 123 tests, 2,103 of 2,103 tool tests, `make diagnose` clean for all three roots, `no-cruby` refused by the stub.
- Run the checker's fast stages at the change's head, all pass.
- Run `make metrics-compare` against main measured at the old pin on the same machine, no regression: rounds 2 and 2, every allocation per key equal.
- Run the benchmark review, pass with no blocking figure.
- Run the quality review of the diff, one advisory found and fixed (the section of the `private_constant` note).

---

## Notes

The queue's figure of 5,476 commits behind does not hold: counted with git on a history fetched back to 2026-09-01, the old pin is 654 commits behind the new one, and 2b080f6cad is 635 commits after the old pin. Before and after on one machine: allocations per key unchanged (lh 25, j 26, insert 25, ddp 57, undo 51, dot-ciw 65, lh-ruby 25, open-ruby 23, grep 774.4); analysis time 55,782 ms to 59,229 and 63,606 ms for the editor and 142,186 ms to 139,574 and 146,445 ms for the test runner; release binary 7,235,368 to 7,959,488 bytes (10.0 percent more); `make bench` time per key matches the baseline for lh and G-ruby on reruns while insert and dot-ciw sit about 10 to 20 percent over it, inside the 20 percent tolerance. The other open notes (the `when CONST` folding, the quadratic one-character slice, the slab release) still reproduce or are unchanged; the destructuring, string-return, empty-array, and versioned-entry probes now answer correctly, but removing carat's workarounds for them is left for a later change. CI builds the toolchain cold on its first run, since its cache key is the new pin.
