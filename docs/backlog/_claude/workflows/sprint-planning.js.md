# Backlog: .claude/workflows/sprint-planning.js

### Sprint security continuation drops differently spelled unreviewed files (`sprint-planning` security Low (5))

- Location: `.claude/workflows/sprint-planning.js:97` `mergeSecurity`.
- Why it matters: it keeps only the continuation's `not_reviewed` entries that exactly match the first start's free-form file names, so a differently spelled path (for example `./tools/run_state.sh`) is dropped and the sprint security review records pass with that file never reviewed.
- Fix outline: fail closed: use `again.not_reviewed` unchanged, or normalize both lists against `git diff --name-only BASE TIP` before intersecting, or constrain the SECURITY schema's `not_reviewed` items to an enum of the combined diff's files as `periodic-review.js` does with its areas.
- Also: tools/run_state.sh
- Category: security
- Added: 2026-11-11

### Rerun of /sprint duplicates the skeptic's notes (`sprint-planning` quality advisory)

- Location: `.claude/workflows/sprint-planning.js:116`.
- Why it matters: a rerun after a partial failure re-inits sprint-N (resume) and the skeptic records every kept finding again, duplicating the notes the planner reads.
- Fix outline: skip the review phases when `review.periodic-security` of sprint-N is already recorded at the same head, or clear its notes first.
- Category: pipeline
- Added: 2026-11-11

### Two result helpers with different argument types (`sprint-planning` quality advisory)

- Location: `.claude/workflows/sprint-planning.js:129` `result(blocked, missed)`, beside the result helper of `.claude/workflows/periodic-review.js`.
- Why it matters: it duplicates the periodic review's helper with a different argument type (a count against an array), so the two drift apart and a caller passing the other shape gets a wrong status.
- Fix outline: share one shape, both taking the `not_reviewed` list.
- Also: .claude/workflows/periodic-review.js
- Category: pipeline
- Added: 2026-11-11

### The sprint quality review gets no continuation at its cap (`sprint-1` review quality)

- Location: `.claude/workflows/sprint-planning.js:123`.
- Why it matters: the security review gets a continued start over the files it left at its cap, the quality review none, so a capped quality review is recorded partial and never covered in that run.
- Fix outline: give quality the same one continuation, or say in the header why it gets none. Queue item `sprint-tidy`.
- Category: pipeline
- Added: 2026-11-12

### The sprint workflow copies the periodic review's caps (`sprint-1` review quality)

- Location: `.claude/workflows/sprint-planning.js:22` (CALLS, FINDING, capLine, the cap 53) against `.claude/workflows/periodic-review.js:17` to `:28` and `:54` (PERIODIC_CAP); the comment at line 71 says they must stay equal.
- Why it matters: workflow scripts cannot import one another, so the copies drift silently.
- Fix outline: a tools-test check that the copies match. Queue item `sprint-tidy`.
- Also: .claude/workflows/periodic-review.js
- Category: pipeline
- Added: 2026-11-12

### The sprint's records change merges past a blocking sprint security finding
- Location: .claude/workflows/sprint-planning.js:196
- Why: security Low (4): the records change sprint-N-records is delivered even when the sprint plan returns security_first or the sprint's combined-diff review found blocking findings; it skips the planner (plan_needed returns not needed for a records change and checks only periodic security reviews), so the security-first stop never runs for it, weakening the rule that blocking security fixes go first. A process-gate gap, not directly exploitable: the change writes only docs records and gets its own security review.
- Fix: deliver the records change only when `!(plan.security_first || []).length && !blocking.length` holds at line 196, otherwise report that it waits for the security fix; or have plan_needed treat a blocking sprint-N security review record as needing the planner.
- Category: security
- Added: 2026-11-17

### A /sprint rerun records every security finding again (`sprint-security` quality advisory)
- Location: .claude/workflows/sprint-planning.js:196
- Why: the Notes step runs on every /sprint run and init resumes sprint-N, so a rerun after an incomplete review (partial, a sweep hold, a capped skeptic, now more frequent) appends every security finding again and the planner reads duplicates.
- Fix: skip a note whose text the run state already holds.
- Category: pipeline
- Added: 2026-11-17

### The report's not-recorded suffix and new Sweep line have no test (`sprint-security` quality advisory)
- Location: .claude/workflows/sprint-planning.js:267
- Why: the Security line's "its findings were not recorded" suffix and the Sweep line's new text have no tools_test case, so a regression in what the report says goes unnoticed.
- Fix: pass noted to securityLine so the existing tools_test case covers the suffix, and add a case for the Sweep line.
- Category: pipeline
- Added: 2026-11-17

### The Notes phase hands reviewer text to a general agent with Bash (sprint-13 security Low (3))
- Location: .claude/workflows/sprint-planning.js:198 (sprint-security).
- Why: shellWord protects the shell, but finding text echoed from the diff can still act as a prompt injection on the notes agent.
- Fix: write the findings to a file under build/ and run one fixed command that reads them (a run_state.sh note-file subcommand), or start the notes agent limited to Bash and the guard hook; accepted when the notes prompt holds no finding text. Queue item `sprint-security-b`.
- Category: security
- Added: 2026-11-17

### A rerun /sprint after a partial review records its notes twice (sprint-13 quality)
- Location: .claude/workflows/sprint-planning.js:197; tools/run_state.sh:1375 (add_note).
- Why: add_note drops repeats only for quality-advisory and init resumes the run state, so a partial review (missed above 0), which forces /sprint again, records the same security and quality notes a second time and the backlog fold gets duplicates.
- Fix: skip Notes and the skeptic on a partial review, or have add_note drop a security or quality note already recorded; accepted when a tools-test rerun leaves one copy. Queue item `sprint-security-b`.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-17

### .claude/workflows/sprint-planning.js:218: reviewed ignores the sprint quality review: a quality start (sprint-22 sweep quality)

- Location: `.claude/workflows/sprint-planning.js:218`
- Why: reviewed ignores the sprint quality review: a quality start that returned nothing or left files is recorded partial (line 235), yet the planner and the records change still run, while a partial security review stops them
- Fix: hold the plan on a missing quality result too, or document why a partial quality review does not hold the sprint
- Category: pipeline
- Added: 2026-11-20

### The review continuations run one after the other
- Location: .claude/workflows/sprint-planning.js:185-195 (the security continuation inside its own branch)
- Why: a security or review Low handed to review-trust-lows, whose first part fixed only the instruction-record settle; left open here.
- Fix: queued by this heading in review-trust-lows-b (docs/queue-backlog.md Sprint 24) or review-trust-lows-c (Pool), the later parts of review-trust-lows; each part adds a tools-test case that fails before its fix.
- Also: docs/queue-backlog.md
- Category: security
- Added: 2026-11-21

### Sprint security continuation drops differently spelled unreviewed files (`sprint-planning` security Low (5))
- Location: .claude/workflows/sprint-planning.js:105 (mergeSecurity, an exact string match)
- Why: a security or review Low handed to review-trust-lows, whose first part fixed only the instruction-record settle; left open here.
- Fix: queued by this heading in review-trust-lows-b (docs/queue-backlog.md Sprint 24) or review-trust-lows-c (Pool), the later parts of review-trust-lows; each part adds a tools-test case that fails before its fix.
- Also: docs/queue-backlog.md
- Category: security
- Added: 2026-11-21

### The sprint quality review gets no continuation at its cap (`sprint-1` review quality)
- Location: .claude/workflows/sprint-planning.js:195 (one quality start)
- Why: a security or review Low handed to review-trust-lows, whose first part fixed only the instruction-record settle; left open here.
- Fix: queued by this heading in review-trust-lows-b (docs/queue-backlog.md Sprint 24) or review-trust-lows-c (Pool), the later parts of review-trust-lows; each part adds a tools-test case that fails before its fix.
- Also: docs/queue-backlog.md
- Category: security
- Added: 2026-11-21
