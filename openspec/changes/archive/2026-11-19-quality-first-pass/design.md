# Design

## Context

See proposal.md, Why. A fix round's quality review is given the last review's commit (`priorQuality`) and blocks only on what the diff since introduces. A blocking finding on lines that diff did not touch is, by construction, one the earlier review could have raised.

## Decisions

- The reviewer, which can run `git diff`, judges whether a finding's lines are unchanged since the last review; the workflow cannot run git, so it reads a marker, `first-pass miss`, in the finding text. A regex helper keeps it testable by `tools/tools_test.sh`'s `js` harness.
- The marked finding stays blocking: the defect is real, and the hard rule is that blocking findings are fixed in the run. The record is a run-state note, read by the retrospective and planner.
- `verdict('quality', ...)` is untouched, so `first.quality` keeps its meaning.

## Risks

- A reviewer that omits the marker leaves a miss unrecorded; the rate itself is still measured as before.
