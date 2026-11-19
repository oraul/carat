fix(finder): match paths by substring or initials, not scattered letters

## Summary

The file finder now lists a path only when the typed text is a contiguous substring of it or matches as initials, so scattered letters such as ezzzxpzzzlzzzozzzrzzezrrr no longer match the query explorer. The old matcher accepted any in-order subsequence and let a scattered match inside the file name outrank a contiguous match in a directory, which the user reported as wrong.

A path matches in tier 1 (a case-insensitive ASCII substring, ranked by file name, then word start, then elsewhere) or tier 2 (a few contiguous runs, each after the first starting at a segment or word start); every tier 1 match ranks above every tier 2 match. A query with spaces is several terms that must all match, in any order.

---

## Changes

- Change the finder matcher to the two tiers, with fewer runs ranking higher, then a shorter path, then listing order, keeping it allocation-free and its key packing
- Add multi-term queries: every term must match by the same rules, in any order, ranked by the worst term and then by the terms together
- List a blank or spaces-only query in listing order from the plugin's filter
- Change the file-finder spec's two requirements and their scenarios for the new matching
- Add table-driven matcher and editor test rows for the scattered path, the rank of explorer, initials, mid-word runs, case, terms, an empty query, and multi-byte paths, with rewritten snapshots
- Document the finder's matching in README.md, docs/plugins.md, docs/compatibility.md, docs/actions.md, the plugin's manifest and class comment, and the code map
- Record the plan and the metrics history of the feature lane

---

## Testing

- Run the security review of the committed diff at 040963076f86, pass with no High or Medium finding and one Low finding recorded in the findings file
- Run the quality review at 040963076f86, pass with no blocking finding and one advisory recorded in the findings file
- Run the checker stages at 040963076f86 (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all exit 0
- Run the benchmark review at 040963076f86, pass, allocations per key held on the existing finder scenarios
- Run make spec-validate, 54 passed and 0 failed
- Run make gates and make docs-lint on the packaged head, all checks ok

---

## Notes

The finder's matching is stricter by design: a query whose letters appear only scattered through a path, or whose later runs start mid-word, no longer lists that path. The content search keeps its own substring rules and shares only the boundary check. Two Low security findings about the sprint-end review bound in tools/run_state.sh (which came in through the merge of main) and one README wording advisory are recorded in docs/findings/finder-match-strict.md for follow-up.
