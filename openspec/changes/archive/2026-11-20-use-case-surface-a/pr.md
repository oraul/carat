refactor(use-cases): read the discovery wiring from a ledger

## Summary

The four discovery use cases no longer expose public readers: the shared-instance guard now reads what EditorAssembly handed each of them from a wiring ledger the assembly fills. The use cases expose 293 readers, nearly all of them only for that guard, which widens each use case's surface past its one public call. This is part a of 4: it adds the ledger and the lint rules that keep it complete, clears the first area, and maps the 22 call signatures that return no Outcome for parts b to d.

---

## Changes

- Add Adapters::WiringLedger with record and held, built first by EditorAssembly and kept in its wiring reader, which records every shared object it hands a discovery use case from the same instance variable it passes
- Remove the 19 readers of ShowKeyHints, HideKeyHints, OpenPalette, and FollowPalette in favor of typed instance variables, taking the use cases' readers from 293 to 274
- Change test/adapters_assembly.rb to read the discovery holders through the ledger, still by equal?, and to check that a pair never recorded counts as a stranger
- Change the shared-holder rule of test/lint.rb to accept a ledger record matching the holder's construction, to refuse a record whose slot the construction does not pass or the holder does not store under its own name, to check each keyword of a readerless holder once by its signature, and to refuse a public reader in carat/use_cases/discovery/, each branch with a self-test row
- Add edge-case tests ahead of the change, in their own commit, for the palette over a text of colons alone, a trailing blank, and an empty buffer, and for the key hints with a second Esc, from the last line, and over an empty buffer
- Document the ledger and the readerless directories in docs/architecture.md sections 5, 8, and 10, the code map, docs/examples.md, and docs/spinel-notes.md
- Record the mapping of the 22 call signatures that return no Outcome in the archived design, and two non-blocking lint findings in docs/findings/use-case-surface-a.md

---

## Testing

- Run the security review of the committed diff, pass with no finding
- Run the quality review, pass with no blocking finding and two advisory findings recorded
- Run the benchmark review, pass with no blocking finding
- Run the checker stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, and metrics, all pass
- Run make build, dev-build, test-build, bench-budget, and metrics on main at 893b97e and then on the branch on the same machine: re-narrowing rounds stay at 2 and 2 for both compile roots; analysis time is 50.7 s on main and 49.9 s on the branch for bin/carat.rb and 108.6 s and 112.8 s for the test runner; the release binary is 6,988,920 bytes on main and 7,004,576 on the branch (15,656 more, 0.2 percent); allocations per key are equal in all eight scenarios; time per key in microseconds, main then branch, is lh 89.1 and 98.5, j 581.5 and 496.4, insert 116.2 and 116.1, ddp 890.3 and 988.0, undo 114.3 and 113.4, dot-ciw 102.4 and 116.9, lh-ruby 122.7 and 110.1, open-ruby 135.2 and 134.3
- Run spec-validate after archiving the change, all 54 items pass, then make gates and make docs-lint, both pass

---

## Notes

No key path changes: the ledger is written once while the editor is assembled, so the time-per-key differences, which run both ways, come from the machine, each within the 20 percent time tolerance of metrics-compare. The other areas' 274 readers, the five production reads of a use case's reader, and the 22 call signatures are left to parts b to d, by the mapping in the archived design. Discovery's three void calls keep their signatures here.
