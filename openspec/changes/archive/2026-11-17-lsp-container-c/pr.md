fix(config): report a root line whose root is not a root

## Summary

Reports a `language.NAME.lsp.root` line whose root is relative or holds a `.` or `..` segment as `file:line: language.NAME.lsp.root ROOT is not a root` and skips it, instead of keeping it silently so that it covers nothing. The README promises that every configuration problem is reported with its file and line, and such a line made a container command never run with no hint why. One domain check of a root word, now shared by the configuration reader and the trusted roots the language gateway covers a directory with, keeps the two from disagreeing.

---

## Changes

- Add `Carat::Domain::RootWord.root?`, the one rule of a root word: `~`, a path under `~`, or an absolute path, with no `.` or `..` segment
- Change the configuration reader to report a `language.NAME.lsp.root` line whose root fails that rule with its file and line, and to drop the line, while a line with fewer than two words keeps its existing report
- Change `TrustedRoots.root_of` to apply `RootWord.root?` after expanding the home, so the gateway and the reader use the same rule and the gateway's covering is unchanged
- Add configuration test rows showing `src`, `/a/./b`, and `/a/../b` reported with their line and `/a/b` kept, and root word rows in the trusted roots test, with their snapshots
- Change the `config-files` spec so a root line whose root is not a root is reported and ignored, and archive the OpenSpec change
- Document the report in the README's language paragraph and add `root_word.rb` to the codebase map
- Apply the feature lane's planned queue to `docs/queue-feature.md`

---

## Testing

- Run the security review of the committed diff, passed with no high, medium, or low finding
- Run the quality review, passed with no blocking finding and three advisories
- Run the fast check stages (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass
- Run the benchmark comparison against main's recorded figures, passed with no blocking finding
- Run `make spec-validate` after archiving the change, all 53 items pass
- Run `make gates` and `make docs-lint` before the push, both pass

---

## Notes

The project file still refuses every language line before any root check, a `language.trusted_roots` word that is no root still trusts nothing without a report, and a root naming a missing directory is not checked against the disk; all three are outside this change. The three quality advisories, folding the two root line checks in `Config#language?`, sharing the home word test between `RootWord` and `TrustedRoots`, and rewording the `under?` comment and its map entry, are style and wording points and were left out of this change.
