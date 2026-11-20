### A security review after a quality-only fix reads the whole branch again
- Location: the locations listed under this heading in the backlog; the queue line of review-trust-lows names tools/run_state.sh:201 and the sprint and delivery workflows
- Why: a security or review Low handed to review-trust-lows, whose first part fixed only the instruction-record settle; left open here.
- Fix: queued by this heading in review-trust-lows-b (docs/queue-backlog.md Sprint 24) or review-trust-lows-c (Pool), the later parts of review-trust-lows; each part adds a tools-test case that fails before its fix.

### The review continuations run one after the other
- Location: .claude/workflows/sprint-planning.js:185-195 (the security continuation inside its own branch)
- Why: a security or review Low handed to review-trust-lows, whose first part fixed only the instruction-record settle; left open here.
- Fix: queued by this heading in review-trust-lows-b (docs/queue-backlog.md Sprint 24) or review-trust-lows-c (Pool), the later parts of review-trust-lows; each part adds a tools-test case that fails before its fix.

### Security Lows of the periodic review at 186ddfb
- Location: the locations listed under this heading in the backlog; the queue line of review-trust-lows names tools/run_state.sh:201 and the sprint and delivery workflows
- Why: a security or review Low handed to review-trust-lows, whose first part fixed only the instruction-record settle; left open here.
- Fix: queued by this heading in review-trust-lows-b (docs/queue-backlog.md Sprint 24) or review-trust-lows-c (Pool), the later parts of review-trust-lows; each part adds a tools-test case that fails before its fix.

### pr-on-push security Low at tools/open_pr.sh:118
- Location: tools/open_pr.sh:118 (the wait arm, refs/pull/N/head read at :141)
- Why: a security or review Low handed to review-trust-lows, whose first part fixed only the instruction-record settle; left open here.
- Fix: queued by this heading in review-trust-lows-b (docs/queue-backlog.md Sprint 24) or review-trust-lows-c (Pool), the later parts of review-trust-lows; each part adds a tools-test case that fails before its fix.

### pr-on-push security Low at .github/workflows/open-pr.yml:39
- Location: .github/workflows/open-pr.yml:39 (the PR_TOKEN job)
- Why: a security or review Low handed to review-trust-lows, whose first part fixed only the instruction-record settle; left open here.
- Fix: queued by this heading in review-trust-lows-b (docs/queue-backlog.md Sprint 24) or review-trust-lows-c (Pool), the later parts of review-trust-lows; each part adds a tools-test case that fails before its fix.

### Sprint security continuation drops differently spelled unreviewed files (`sprint-planning` security Low (5))
- Location: .claude/workflows/sprint-planning.js:105 (mergeSecurity, an exact string match)
- Why: a security or review Low handed to review-trust-lows, whose first part fixed only the instruction-record settle; left open here.
- Fix: queued by this heading in review-trust-lows-b (docs/queue-backlog.md Sprint 24) or review-trust-lows-c (Pool), the later parts of review-trust-lows; each part adds a tools-test case that fails before its fix.

### The sprint quality review gets no continuation at its cap (`sprint-1` review quality)
- Location: .claude/workflows/sprint-planning.js:195 (one quality start)
- Why: a security or review Low handed to review-trust-lows, whose first part fixed only the instruction-record settle; left open here.
- Fix: queued by this heading in review-trust-lows-b (docs/queue-backlog.md Sprint 24) or review-trust-lows-c (Pool), the later parts of review-trust-lows; each part adds a tools-test case that fails before its fix.

### Restrict the open-pr edit path to same-repository pull requests (security Low, confidence 4)
- Location: .github/workflows/open-pr.yml:35 (the job's if names no head repository)
- Why: a security or review Low handed to review-trust-lows, whose first part fixed only the instruction-record settle; left open here.
- Fix: queued by this heading in review-trust-lows-b (docs/queue-backlog.md Sprint 24) or review-trust-lows-c (Pool), the later parts of review-trust-lows; each part adds a tools-test case that fails before its fix.

### Fork pull requests sharing the branch name block open_pr.sh (security Low (5))
- Location: tools/open_pr.sh:142-151 (several numbers on the pushed head refused)
- Why: a security or review Low handed to review-trust-lows, whose first part fixed only the instruction-record settle; left open here.
- Fix: queued by this heading in review-trust-lows-b (docs/queue-backlog.md Sprint 24) or review-trust-lows-c (Pool), the later parts of review-trust-lows; each part adds a tools-test case that fails before its fix.

### open-pr pins its actions by tag beside PR_TOKEN (security Low, confidence 6)
- Location: .github/workflows/open-pr.yml:48 (actions/checkout by tag)
- Why: a security or review Low handed to review-trust-lows, whose first part fixed only the instruction-record settle; left open here.
- Fix: queued by this heading in review-trust-lows-b (docs/queue-backlog.md Sprint 24) or review-trust-lows-c (Pool), the later parts of review-trust-lows; each part adds a tools-test case that fails before its fix.

### plan-apply copies a planned goals.md after the security review
- Location: tools/run_state.sh plan_apply (goals.md over docs/goals.md, in the package step)
- Why: since review-trust-lows the push gate settles no pass across a docs/goals.md commit, so a planner-written goals.md applied in the package step makes the security pass stale and reviewed-edits names it; the planned goals change is then restored away instead of landing.
- Fix: apply a planned goals.md in the implement step, where the reviews read it, or have plan-apply refuse it with a note that the goals change needs its own delivery.

### INSTRUCTION_RECORDS_RE is defined twice beside the rules file both scripts source (`review-trust-lows` quality advisory)
- Location: `tools/gates.sh:117`, `tools/run_state.sh:465`, `tools/tools_test.sh` ("rules: the instruction records are the gates'"), `tools/rules.sh:69`
- Why: the same pattern lives in two scripts that both source `tools/rules.sh`, held equal only by a test, so a later edit of one copy is a test failure rather than one edit; this change may not edit `tools/rules.sh`, the merge gate's own rules.
- Fix: in a separate rules change landing first, alone, move `INSTRUCTION_RECORDS_RE` beside `RECORDS_RE` in `tools/rules.sh`, drop the two copies and the equality test.

### plan-apply copies goals.md after the security review that reviewed-edits says to restore (`review-trust-lows` quality advisory)
- Location: `tools/run_state.sh` `plan_apply` (about line 1960) against `reviewed_edits` (about line 2103)
- Why: the package step runs `plan-apply`, which copies `build/plan/CHANGE/goals.md` over `docs/goals.md` after the security review, while `reviewed-edits` now tells the contributor to restore any `docs/goals.md` change since that review, so the two rules contradict and a planned goals edit cannot land through a package step.
- Fix: have `plan-apply` leave `goals.md` and name it when a security pass is recorded (or apply it in the implement step, before the reviews), with a tools-test case.
