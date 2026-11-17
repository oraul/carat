fix(pipeline): close the late-finding, open-pr, and checks lows

## Summary

Closes three security Lows and two parsing defects of the delivery pipeline: late-finding notes reach the findings history only when stamped with the run's merged commit, the open-pr checkout stores no token, `open_pr.sh wait` no longer records a fork's pull request on the pushed commit, `staleRed` reads a check name holding commas, and the merger returns checks in one form. Branch code a check runs could write a note that reached the backlog verbatim, a fork's pull request on the same commit could be recorded and merged, and a name such as `spin (ubuntu, 4)` was misread as a stale red.

---

## Changes

- Change `tools/run_state.sh` so a `late-finding` note is accepted only once the run's merged commit is recorded, stamped with it, and `history` keeps a late finding only when its stamp is that commit and its text has the workflow's note shape.
- Change `.claude/workflows/deliver-change.js` to record late findings at the close only: merged runs as late findings, an unmerged run after the push as held findings a resume reads back, and a run stopped before the push as unpushed findings its resume's package step hands over.
- Change `tools/open_pr.sh wait` to record a pull request only when exactly one pull request head is the pushed commit, or the number the run state already records is among them, refusing several others.
- Change the `Check out main` step of `.github/workflows/open-pr.yml` to set `persist-credentials: false`.
- Fix `staleRed` to read a check as its workflow, its name commas included, its status, and its conclusion.
- Change `.claude/agents/merger.md` and the merger schema to one checks form, workflow, name, status, conclusion, the workflow read from the head's workflow run, a green return giving a dash.
- Add `tools/tools_test.sh` cases for an unstamped or forged late finding kept out of the history, the token-free checkout, a fork's pull request on the pushed commit not recorded, a comma name parsed, and the one checks form.
- Document the fixes in README delivery step 9 and the area 1 lines of `docs/codebase-map.md`, and record the archived change, its non-blocking findings, the backlog lane's plan, and its metrics history.

---

## Testing

- Run the security review of the committed diff at fa874016e2a4, pass with no High or Medium finding, one Low, none blocking
- Run the quality review at fa874016e2a4, pass with no blocking finding and five advisories
- Run the checker's stages at fa874016e2a4 (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass
- Run the benchmark review at fa874016e2a4, pass with no allocation or round regression
- Run make spec-validate after archiving, 53 passed and 0 failed

---

## Notes

Backlog lane delivery of docs/queue-backlog.md Sprint 12 item 1, beside the feature lane's delivery; it touches no feature-lane file and does not edit `tools/rules.sh`. The remaining security Lows (a forged note key through `set`, a race where a fork opens the only pull request first, held and unpushed finding notes writable before the merge) and two quality advisories are recorded in docs/findings/checks-and-pr-lows.md for the planner. The README placement, comment placement, and comment wrap advisories were dropped as minor wording and style.
