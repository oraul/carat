fix(config): keep a project file's keys from running typed text

## Summary

Keeps an untrusted project .caratrc from leaving a text-entry mode or opening the command line or the palette from keys typed while editing text, so text the user types can no longer run as a command. A project file could bind insert-mode Enter to normal mode and then a letter to mode.cmdline or palette.open, chaining allowed bindings into running typed text (sprint-26 review security Lows 5 and 4, sprint-27 note 1).

---

## Changes

- Change Config so a project file binds in insert, replace, cmdline, and the completion layer only the seventeen actions named in TEXT_BINDABLE that edit, move, scroll, or complete and keep the mode, reporting and ignoring any other, mode.normal and palette.next included
- Hold the trusted Esc of insert and cmdline modes, cmdline Ctrl-n and Ctrl-p, and the completion popup's Esc, so a project file cannot trap the user in insert mode or the popup
- Refuse a project binding of mode.cmdline or palette.open to keys made only of keys pressed while editing text (printable and multi-byte characters, Tab, Enter, Backspace, Escape, the arrows, Home, End, the Page keys, Delete), while function, Alt, and other control keys stay allowed
- Remove Keymap.leader_from, its callers reading Config#leader
- Read Config's settings only through count and line_at, the language gateway included, and say in the pin's comment why it stays Array[untyped]
- Add config gateway and action table tests for each rule, each failing with its fix reverted, and move the tests that bound such keys from a project file to function keys or the user file
- Add the two config-files requirements and document the rules in the README, docs/architecture.md section 7, and the code map

---

## Testing

- Run the security review of the committed diff, pass with no finding
- Run every check stage at the implementation head (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all pass
- Run the benchmark review against main's recorded figures, pass with no blocking finding
- Run make spec-validate after the archive, 56 of 56 pass
- Run make gates and make docs-lint on the packaged branch, both pass

---

## Notes

A default or user binding of a prompt to a printable key stays allowed and is not held: the rules apply to the project file only. The other seven headings of this backlog entry are split to config-guards-e and config-guards-f and stay in the backlog.
