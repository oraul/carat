### The sprint's records change merges past a blocking sprint security finding
- Location: .claude/workflows/sprint-planning.js:196
- Why: security Low (4): the records change sprint-N-records is delivered even when the sprint plan returns security_first or the sprint's combined-diff review found blocking findings; it skips the planner (plan_needed returns not needed for a records change and checks only periodic security reviews), so the security-first stop never runs for it, weakening the rule that blocking security fixes go first. A process-gate gap, not directly exploitable: the change writes only docs records and gets its own security review.
- Fix: deliver the records change only when `!(plan.security_first || []).length && !blocking.length` holds at line 196, otherwise report that it waits for the security fix; or have plan_needed treat a blocking sprint-N security review record as needing the planner.

### The not-due parseDue case uses review-due's old text
- Location: tools/tools_test.sh:3442
- Why: missing test: the case feeds parseDue 'for the next package step', which review_due no longer prints (now 'for its records change, sprint-N-records'), so the case no longer tracks the real output and a regression in parsing the new line goes unseen.
- Fix: use review_due's current not-due line in the fixture, or capture it from review_due itself.

### lane_of prints the shell's error for a missing queue file
- Location: tools/run_state.sh:1264
- Why: correctness: `item_named < "docs/queue-$l.md" 2>/dev/null` opens the input before stderr is redirected, so a missing queue file still prints the shell's error into the command's output.
- Fix: put 2>/dev/null before the input redirection, or test -f the queue first.
