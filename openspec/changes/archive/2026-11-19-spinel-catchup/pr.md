chore(toolchain): pin spinel at 0d1a7ca3

## Summary

Moves the Spinel pin from c0502112 to 0d1a7ca3, upstream's default-branch head when the change started, 1,045 commits later (296 on its first-parent line), and carat passes every check stage at the new pin. The old pin lacked upstream's GC rooting fixes, String box reads, call-plan and keyword-forwarding work, and the fix for a child waited for inside a Fiber, which the Fiber study and the plugin tasks need.

---

## Changes

- Change SPINEL_REF in the Makefile to 0d1a7ca33a6edd44fad3b074e172f8a327697ebb; make spinel-header regenerated the vendored respond-to header byte-identical, so that file is unchanged
- Change the plugin manifest test's expectation for an option line with an illegal byte to the escaped text, since String#inspect now writes a byte outside a valid UTF-8 sequence as a hex escape as CRuby does (Spinel f49716bd); ManifestCheck itself is unchanged
- Document in docs/spinel-notes.md the String#inspect escaping and that a Process.wait inside a Fiber no longer crashes since Spinel c6de72a2
- Document the recheck of each open Spinel note at 0d1a7ca3: private_constant and the when CONST folding still reproduce, the reduced destructuring, string-return, and empty-array probes answer correctly, the slab release is unchanged, and the versioned-entry defect, having no reduced probe, is not rechecked
- Fix the byteindex note, which said the next bump meets Spinel 84aa303b1 although c0502112 already holds it
- Add the archived OpenSpec change spinel-catchup, a toolchain change with skip_specs set
- Remove the delivered spinel-bump item from the backlog queue and append sprint-20-records' row to the backlog lane's metrics history

---

## Testing

- Security review of the committed diff, pass with no High, Medium, or Low finding
- Quality review, pass with no blocking finding, its three wording advisories on the proposal and docs/spinel-notes.md fixed in the change; benchmark review, pass
- Run make spinel-header with the c0502112 toolchain, output byte-identical to the vendored header, then make toolchain at 0d1a7ca3, and make doctor reports the ruby stub refused
- Run every make check stage at the new pin, all pass: 114 of 114 tests, 1,805 of 1,805 tool tests, make diagnose clean for all three roots; the first run failed only the manifest case changed here
- Run make metrics-compare against main's figures measured at c0502112, no regression, and make bench and make build on both pins for time per key and binary size
- Run make gates, make docs-lint, and make spec-validate after archiving, all pass

---

## Notes

- Before and after, c0502112 then 0d1a7ca3: rounds 2 and 2 for carat and the runner on both; allocations per key one fewer in every scenario, lh 26 to 25, j 27 to 26, insert 26 to 25, ddp 58 to 57, undo 52 to 51, dot-ciw 66 to 65, lh-ruby 26 to 25, open-ruby 24 to 23
- Analysis time 58,061.8 ms to 55,870.5 ms for carat and 127,808.5 ms to 130,794.2 ms for the runner, both within this machine's run-to-run noise; release binary 7,008,944 to 6,947,072 bytes
- Time per key from make bench: lh 19.8 to 19.1 us, j 111.4 to 98.4, insert 21.4 to 21.8, w 40.4 to 31.7, ddp 187.8 to 187.2, undo 26.9 to 28.3, ciw 54.6 to 62.1, dot-ciw 24.5 to 36.2, lh-ruby 25.3 to 21.9, open-ruby 48.6 to 22.9, finder 1,777.4 to 1,672.3; three reruns put dot-ciw between 25.1 and 52.3 us (noise) and ciw about 5 to 10 percent over the baseline, inside metrics-compare's 20 percent tolerance
- The commit count since the old pin is 1,045 by git rev-list; the queue's 656 and the earlier count of 889 predate it. No upstream commit was skipped, since the newest one passed
- No Spinel workaround in carat became unnecessary at the new pin, so none is removed and no finding is filed; the queue item spinel-bump is delivered under this name because a change called spinel-bump merged as #95
