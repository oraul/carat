feat(finder): search every line of long files in grep

## Summary

The grep picker now searches every line of a file within its 256 KiB read limit, its preview reaches the file's last line, and `make metrics` records the grep scenario's allocations per key. A user could not find a match past line 1000 of a long file, since the host's `read_file` refused more than 1000 rows, and the grep scenario's rise in allocations per key went unnoticed because no figure of it was recorded or compared.

---

## Changes

- Change the plugin host's `read_file` to accept up to 262,144 rows, as many lines as its 256 KiB read can hold, bound to the read limit in `FileRequests`, and bump the plugin API to 2.10 so an older host refuses a plugin relying on it
- Change the grep picker to read every line of a file within the read limit, so a match on line 1500 of a 2000-line file is listed and its pick opens at that line, the store cap, the line cut, and the per-key budget unchanged
- Fix the grep preview to end at the file's last line, the empty lines at its end included, where it ended at the last stored line
- Fix the comments on the grep per-key budget to state the bound the search keeps, at most twice the line budget of checks a key
- Add the grep scenario to the default scenarios of `make metrics`, run at 20 and 120 keys as `make bench-budget` runs it, so `metrics-compare` compares its allocations per key, with cases in `tools/tools_test.sh`
- Add tests for the long-file match and its pick, the preview's end, the row bound of `read_file` and its refusal above it, and update the API version rows and their snapshots
- Document the new bounds and API version in README.md, `docs/plugins.md`, `docs/codebase-map.md`, and the `plugin-host` and `file-finder` specs

---

## Testing

- Run the security review of the committed diff, passed with no finding of any severity
- Run the quality review of the committed diff, passed with no blocking finding, its three advisories fixed on the branch
- Run the checker's stages docs-lint, dev-build, test-build, diagnose, bench-budget, test-run, gates, tools-test, and metrics, all pass
- Run the benchmark review, passed with no blocking finding, the grep scenario recorded at 842.6 allocations per key
- Run make spec-validate after the archive, 54 passed and 0 failed
- Run make gates and make docs-lint on the packaged branch, both pass

---

## Notes

The path sanitizer for both pickers, the other invisible format code points grep rows pass, and a pick into a modified buffer landing on another line are split out and queued as finder-path-safe. `metrics-compare` reports the grep scenario as new until main records it. The API change is additive, so a 2.9 plugin keeps working.
