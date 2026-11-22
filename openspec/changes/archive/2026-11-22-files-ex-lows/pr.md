fix(files): charge replacements before building and refuse dangling links

## Summary

A substitute now charges the work budget for each replacement before it builds it, and `:e` asks the file port about a path once, refusing a dangling link instead of opening it as a new buffer. Before this, `:s/.*/&&&&/` on a 64 MiB line of an untrusted file built a 256 MiB string before the budget stopped it, and the two separate port answers of `:e` could disagree, so a new buffer's write could follow a dangling link out of the tree.

---

## Changes

- Add `Replacement.size`, which counts a replacement's length without building it, and charge that size in `Substitution.line` before `Replacement.expand` builds the text, stopping with E363 when the budget cannot pay; a recased replacement of another size is charged or refunded the difference.
- Change `OpenFile#call` to ask the port once through `ProbePath` and take whether the path exists from that answer, so a dangling link is refused with "path" is not a file, as `MakePath` already treats it.
- Add `pad` and `dangling` to the `MemoryFiles` double, a file whose reported size exceeds its text and a link whose target is missing, and put the files over and at the open limit in `test/editor_cmdline.rb` with `pad`, so a test run no longer builds two 64 MiB strings.
- Add tests for the charged replacement past the budget, the dangling link refused at `:e`, the read race left after the one stat, and the double's dangling links and padding, with refreshed snapshots.
- Change the `substitute` and `command-line-mode` specs for the replacement charged before it is built and the refused dangling link.
- Document the refused dangling link and the charged replacement in `docs/compatibility.md`, the README's `:e` sentence, and the code map lines of the touched files.
- Record the descriptor-relative create, rename, and delete gap of the file operations, which needs an openat the toolchain does not offer, in this change's findings file.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run every check stage at the change's head (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all pass
- Run the benchmark review against main's recorded figures, pass with nothing blocking
- Run the quality review of the diff, five findings, three fixed and two recorded
- Run make spec-validate after the archive, 56 passed and 0 failed

---

## Notes

The ex range arithmetic, patterns, and marks, the `ExRange` member no caller reads, and the `SubstituteArgs` and `GlobalArgs` tidies of the same queue entry are split to the follow-up change ex-range-tidy and stay listed by the backlog queue. The openat gap is recorded rather than fixed because neither the pinned Spinel nor Ruby's core offers a descriptor-relative open. Refusing a dangling link at `:e` differs from Vim, which opens a new buffer and writes through the link; the difference is documented in `docs/compatibility.md`.
