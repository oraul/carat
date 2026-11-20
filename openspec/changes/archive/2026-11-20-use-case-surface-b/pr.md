refactor(use-cases): read the windows wiring from the ledger

## Summary

The eleven window and tab use cases no longer expose public readers: the shared-instance guard now reads what EditorAssembly handed each of them from the wiring ledger, as part a did for the discovery area. Their 20 readers existed only for that guard, widening each use case's surface past its one public call, and part a's late review left seven advisories in the ledger, its lint rule, two tests, and section 8 of the architecture. This is part b of 4: one area, carat/use_cases/windows/, plus those seven fixes.

---

## Changes

- Remove the 20 readers of CloseFloat, CloseOtherTabs, CloseOtherWindows, CloseTab, CloseWindow, OpenFloat, OpenSideWindow, OpenTab, SplitWindow, SwitchTab, and ToggleSlot in favor of typed instance variables, taking the use cases' readers from 274 to 254
- Change EditorAssembly to record each of those 20 objects in its WiringLedger right after the holder is built, and test/adapters_assembly.rb to read them through the ledger by equal?, with carat/use_cases/windows/ added to the readerless directories lint checks
- Add edge-case tests ahead of the change, in their own commit, for a split, Ctrl-W c, and Ctrl-W o from the last line and over an empty buffer, and for tabclose, tabonly, tabn, and tabnew from a tab page left on its last line and over an empty buffer
- Refactor the shared-holder rule of test/lint.rb into a readerless and a rbs keyword pass, read each holder's ledger records once as slot and object pairs, check a construction passing a value with one passes? helper so a mismatched record is one check with one message, and rename the assembly's text local to assembly_text
- Change the readerless directory rule of test/lint.rb to refuse a public attr_accessor as it does an attr_reader, with a self-test row
- Remove WiringLedger#record's replace-on-second-record branch, which no caller used, and the guard's probe row that only covered it
- Refactor test/editor_key_hints.rb and test/editor_palette.rb so the usual and the empty-buffer session share one session_on builder taking the file's text
- Document in docs/architecture.md section 8 that the assembly keeps a reader for each shared object and records what each readerless holder was handed, and update the golden use case in docs/examples.md and the guard and lint wording in the code map

---

## Testing

- Run the security review of the committed diff, pass with no finding
- Run the quality review, pass with no blocking finding; its two advisories on an earlier commit were fixed in place and re-reviewed
- Run the benchmark review, pass with no blocking finding
- Run the checker stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, and metrics, all pass
- Run make build, dev-build, test-build, bench-budget, and metrics on main at 8a99bdd and then on the branch on the same machine: re-narrowing rounds stay at 2 and 2 for both compile roots; analysis time is 43.4 s on main and 42.1 s on the branch for bin/carat.rb and 107.0 s and 96.8 s for the test runner, one run each; the release binary is 7,004,576 bytes on main and 7,006,736 on the branch (2,160 more, 0.03 percent); allocations per key are equal in all eight scenarios; time per key in microseconds, main then branch, is lh 102.1 and 106.8, j 537.8 and 543.4, insert 124.9 and 127.7, ddp 940.0 and 911.3, undo 118.0 and 119.0, dot-ciw 114.6 and 115.7, lh-ruby 129.4 and 127.7, open-ruby 166.4 and 218.1
- Run spec-validate after archiving the change, all 54 items pass, then make gates and make docs-lint, both pass

---

## Notes

No key path changes: the ledger is written once while the editor is assembled, so the time-per-key differences, which run both ways, come from the machine; open-ruby, which opens a file and starts a fake language server per key, showed the same spread in part a. All seven of part a's late findings are fixed here, so none is recorded for the backlog. The other areas' readers, the production reads of a use case's reader, and the call signatures that return no Outcome are left to parts c and d.
