fix(tools): record the lone pull request in wait without gh

## Summary

Makes `open_pr.sh wait` record the lone pull request on the pushed head again without running `gh`. Since the read-back was added, no delivery could get past `wait`, because `gh` cannot run in the delivery environment; the head repository and branch are confirmed by the merger's step 1 before any merge, which returns stale for a pull request that is not the change's.

---

## Changes

- Remove the `gh` read-back of the taken pull request from `wait` in `tools/open_pr.sh`: `head_owned`, its call, its refusals, and the unread bookkeeping are gone.
- Update the header and the comment of `wait` to say the merger's step 1 confirms the head repository and branch.
- Replace the `head_owned` cases in `tools/tools_test.sh` with a case where a failing `gh` stub is on the path and a lone pull request on the pushed head is recorded, and a case proving `wait` ran no `gh`.
- Archive the change and record its non-blocking findings and the groomed backlog, the sprint row, and the queues it carries.

---

## Testing

- Run the security review of the committed diff, pass with no High or Medium finding and one Low recorded as a finding.
- Run the fast stages at the pushed head (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass.
- Run the benchmark review, pass with no blocking finding.

---

## Notes

The security review's Low is that `wait` now records a lone pull request without a scripted head-repository check, leaving the merger's step 1 as the only guard; the fix outline, a merge-hook check of the pull request number and title, is recorded in the findings file and not done here. Out of scope and left for the next change of this group: the sprint planning notes, the package step's prose edit, the budget line, and the control characters.
