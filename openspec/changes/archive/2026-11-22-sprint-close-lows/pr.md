fix(pipeline): close the sprint review's security lows

## Summary

Closes the sprint review's security Lows and gaps: a continuation's file left in another spelling stays left, the sprint quality review gets one more start at its cap, a security finding both reviewers missed is recorded and counted blocking, the records change waits behind a blocking sprint security finding or the plan's security first, and a /sprint rerun records no security note twice. Each gap let a partial or incomplete sprint review pass as complete, or let the sprint's queue apply past an unresolved security finding.

---

## Changes

- Add `pathKey` and `stillLeft` to the sprint-planning workflow so a continuation's file left is matched to the first start's in any spelling (a leading `./`, doubled or trailing slashes, a `:line` suffix, a worktree or absolute prefix), the first start's spelling kept
- Add `qualityDone`, `mergeQuality`, and one `reviewContinued` helper that gives either sprint reviewer one more start over the files it left, or the whole diff when it returned nothing, every start counted in the overrun notes
- Add the skeptic's `security_missed` field and prompt, recording each returned finding as a `missed by both:` security note and counting a High or Medium at confidence 8 or above among the blocking findings
- Add `recordsHeld` so the sprint's records change is not started while a blocking sprint security finding stands or the plan names security first, the report saying it is held and how to resume it
- Change `tools/run_state.sh note` so a security note whose whole text is already recorded for the change is not recorded again, a disputed note beside its finding still recorded
- Change the quality reviewer's instructions to name a possible security matter in one line, unexamined, and to return what both reviewers missed in `security_missed`, and the /sprint command to resume a held records change only after its fix merged
- Add tools-test cases for each heading, each failing before its fix
- Document the continuations, the missed findings, and the held records change in README step 11 and the code map's area 1

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the benchmark review, pass with nothing blocking
- Run every check stage at the implementation head (dev-build, test-build, test-run, diagnose, tools-test, bench-budget, metrics, gates, docs-lint), all pass
- Run make spec-validate after the archive, 56 passed and 0 failed

---

## Notes

The queue item was split: this pull request delivers the sprint-planning half, and the merge path's headings (the periodic review's security Lows in deliver-change.js, tools/agent_guard.sh, and tools/spec_validate.sh, the moved-main merge, the package step's prose edit, and the budget line) are left for a follow-up change; deliver-change.js, tools/agent_guard.sh, and tools/rules.sh are not edited. A blocking finding the skeptic disputes still holds the records change, since a dispute is a note for the planner, not a resolution.
