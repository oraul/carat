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

### The sprint's security notes run in an unguarded general agent (pipeline-lows-a security Low (4))

- Location: `.claude/workflows/sprint-planning.js`, the `sprint: notes` start running `securityNotes`.
- Why: the security findings' texts quote reviewed code, and the low-effort runner holds Bash with no `tools/agent_guard.sh` hook, so planted text could lead it to run more than the one command; the skeptic's notes now run under the quality reviewer's guarded record mode, this start does not, since the read profile refuses a word naming `build/pipeline`, which a security finding may quote, and the planner would then never start.
- Fix: record the notes without an agent prompt (a fixed `tools/run_state.sh` command reading the notes as JSON from a file), or a guard profile allowing only `run_state.sh note` whose word rules let a finding text through.
- Also: tools/agent_guard.sh, tools/run_state.sh
- Category: security
- Added: 2026-11-22

### The sprint's security notes run in an unguarded general agent (security Low (4))
- Location: `.claude/workflows/sprint-planning.js:231` (securityNotes, the 'sprint: notes' start).
- Why: the sprint's security notes still run in a general agent with Bash and no `tools/agent_guard.sh` hook; a merged change can plant code whose quoted text, carried into a security finding, carries instructions, and the low-effort runner may follow them instead of running only the one note command. This predates pipeline-lows-a, which moved only the skeptic's notes under the guarded quality reviewer.
- Fix: record the notes without an agent prompt: the workflow writes the notes as JSON to a file, and a fixed `tools/run_state.sh` command reads that file; or start the runner under an agent type whose hook runs `tools/agent_guard.sh` with a profile that allows only `run_state.sh note`, and whose word rules let a finding's text through, including one that names build/pipeline.
none
- Also: tools/agent_guard.sh, tools/run_state.sh
- Category: security
- Added: 2026-11-22

### dead schema field: the SKEPTIC schema still lists security_recorded at .claude/workflows/sprint-planning.js:64 (sprint-26 review quality, note 12)

- Location: .claude/workflows/sprint-planning.js:64
- Why: dead schema field: the SKEPTIC schema still lists security_recorded as a property and requires it (line 72), but the skeptic records nothing now and the workflow never reads the count
- Fix: drop security_recorded from properties and required, and from any skeptic task text that names it
- Category: pipeline
- Added: 2026-11-22

### duplication: the record prompt (Run this one command with at .claude/workflows/sprint-planning.js:230 (sprint-26 sweep quality, note 50)

- Location: .claude/workflows/sprint-planning.js:230
- Why: duplication: the record prompt (Run this one command with the Bash tool ... exactly as written ... Return ok true when it exited 0) is spelled at :230, :248, and :285, and again in periodic-review.js:143
- Fix: one helper per workflow taking the command lines, the agent type, and the label
- Category: pipeline
- Added: 2026-11-22
