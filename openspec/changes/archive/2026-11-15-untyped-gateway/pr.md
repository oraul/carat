chore(json): read parsed bodies through typed readers

## Summary

Adds typed readers of a parsed JSON value to Carat::Json and moves the language-server tests' reads of the bodies the editor sent onto them, cutting the test runner's load-record rebuilds at Spinel 6b43fe94 from 1,181 to 779. Each [] on a receiver Spinel types untyped makes code generation from Spinel 2440954d1 on walk the whole program again, which keeps SPINEL_REF at 6af548c9; the seven language-server tests were the largest cause left, at 402 rebuilds.

---

## Changes

- Add Json.field, Json.element, and Json.reach, which read a member, an element, or a dotted path of members and indexes from a parsed value, answering nil for a value of another kind or a missing step, with every [] on a receiver typed Hash or Array
- Change the seven language-server and editor LSP tests to read the parsed bodies through field and reach instead of chained [], with the same values, checks, labels, and snapshots
- Add three checks of the readers to test/json.rb and their lines to its snapshot
- Document the readers and the rebuild figures after this change in docs/spinel-notes.md, and name the readers in docs/codebase-map.md
- Archive the OpenSpec change untyped-gateway with skip_specs, since no editor behavior changes

---

## Testing

- Run the security review of the committed diff, passed with no High, Medium, or Low finding
- Run the quality review, passed with no blocking finding and four advisories recorded in the backlog
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass with re-narrowing at 2 rounds for carat and the runner
- Run the benchmark review against main's recorded figures, passed with no blocking finding
- Measure make test-build with the traced 6b43fe94 toolchain under tmp before and after, 1,181 rebuilds down to 779 and code generation from 151.9 s to 99.8 s, and at the pinned 6af548c9, 39 rebuilds unchanged
- Run make spec-validate after the archive, all 51 items pass

---

## Notes

SPINEL_REF stays at 6af548c9; the 6b43fe94 figures come from the separate toolchain under tmp that untyped-elephant built. The gateway's own JSON reads, 210 rebuilds, are the next cause and are left for a follow-up because they change production code of the language gateway; the readers added here are what it would use.
