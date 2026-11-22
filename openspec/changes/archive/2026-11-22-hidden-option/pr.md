feat(set): add the hidden option for modified buffers on a switch

## Summary

Adds the global boolean option `hidden` (short form `hid`), on by default, so that `:e`, `:b`, `:bn`, `:bp`, `:bN`, `:bfirst`, and `:blast` leave a modified buffer hidden with its changes instead of refusing with E37. Switching files with unsaved work meant writing first, while closing a window already kept a modified buffer hidden, as the set-options decision of the design council asked.

---

## Changes

- Add `option.hidden` to the options record, the `.caratrc` kinds, and the default configuration (true), mirrored in the generated default configuration, and set it from `:set` as a boolean in Vim's forms, `hid` included.
- Change `:e` of another file to leave a modified current buffer hidden when `hidden` is on and keep E37 when it is off or the bang is absent with it off; `:e` of the current file still refuses a modified buffer, since it reloads it.
- Change the buffer switch of `:b`, `:bn`, `:bp`, `:bN`, `:bfirst`, and `:blast` the same way, including the buffer tab and jump list switches that share it.
- Keep `:q` and `:qa` naming a modified hidden buffer as before, now covered by a test.
- Update the delta specs of buffer-list, buffer-tabs, command-line-mode, jump-list, and set-command, and archive the change.
- Document the option in the compatibility doc, replacing the 'hidden off' Difference, and update the architecture doc, the code map, and the README.
- Add table-driven tests of `:e` and `:b` over a modified buffer with `hidden` on and off, `:qa` naming the hidden buffer, the option's configuration and `:set` forms, and update the snapshots the new default changed.
- Record the plan and the metrics history of the feature lane.

---

## Testing

- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics) at the reviewed head, all pass.
- Run the security review of the committed diff, pass with no findings.
- Run the benchmark review, pass with no blocking finding.
- Run the contributor's quality review of the diff, one finding added and fixed.
- Run make spec-validate after the archive, 56 specs pass.
- Run make gates and make docs-lint after packaging, both pass.

---

## Notes

This is part 2 of the set-options decision, split from it; no file of the backlog lane is touched. The default turns on, so the E37 refusal of a switch now needs `:set nohidden`.
