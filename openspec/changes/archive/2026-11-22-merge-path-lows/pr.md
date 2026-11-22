fix(pipeline): close the guard and merge path security findings

## Summary

Closes one Medium and four Low security findings on the delivery guard and the merge path: the guard now refuses writes of the local Claude Code settings files for every profile, setting the clock with date, and the merger's read-tree outside the merge gates' copy, and the merge gates' green line and the spec preview refuse planted files and links. A write to the local settings could turn the hooks off so the next agent ran unguarded, and the other gaps let the run state's times, the merge gates' copy, or a file outside the spec preview be altered.

---

## Changes

- Change the guard's write check to refuse, for every profile, a write naming .claude/settings.local.json, .mcp.json, CLAUDE.local.md, or the .claude directory, and refuse every call while one of those three files stands untracked at the top of the project
- Change the guard to allow date only with its read options and a +FORMAT operand, refusing -s, --set, and a date operand
- Change the guard to accept the merger's git read-tree only in tmp/.merge-gates
- Add an untracked-file check of the merge gates' copy to the green line in deliver-change.js, so a file planted beside main's tree stops the merge gates
- Change tools/spec_validate.sh to refuse, before any preview, when openspec/ holds a symbolic link, naming it
- Change the sprint Notes phase to run its command through the quality reviewer in record mode under the guard's read profile, the guard storing a note's text word without its word rules
- Move the sprint report's Security line into the securityReport helper so its not-recorded suffix is tested
- Add a tools-test case per fix, each failing before it
- Document the checks in README.md and the guard and spec_validate.sh rows of docs/codebase-map.md, and record the one quality finding not fixed in docs/findings/merge-path-lows.md

---

## Testing

- Run the security review of the committed diff at d9b23ebc28e3, pass with no High, Medium, or Low finding
- Run the delivery check at d9b23ebc28e3, every stage passes: docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, and metrics
- Run the benchmark review at d9b23ebc28e3, pass with no blocking figure
- Run make spec-validate after the archive, 56 passed and 0 failed

---

## Notes

The change edits no spec, so it is archived with skip-specs, and tools/rules.sh is not edited. A user who keeps a .claude/settings.local.json in the main checkout moves its rules to the user settings, since its presence now refuses every agent call. The Sweep line named by the backlog heading already had tools-test cases on main, so this change adds none for it.
