# Backlog: .claude/workflows/sprint-planning.js

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

### The sprint workflow copies the periodic review's caps (`sprint-1` review quality)

- Location: `.claude/workflows/sprint-planning.js:22` (CALLS, FINDING, capLine, the cap 53) against `.claude/workflows/periodic-review.js:17` to `:28` and `:54` (PERIODIC_CAP); the comment at line 71 says they must stay equal.
- Why it matters: workflow scripts cannot import one another, so the copies drift silently.
- Fix outline: a tools-test check that the copies match. Queue item `sprint-tidy`.
- Also: .claude/workflows/periodic-review.js
- Category: pipeline
- Added: 2026-11-12

### The Notes phase hands reviewer text to a general agent with Bash (sprint-13 security Low (3))
- Location: .claude/workflows/sprint-planning.js:198 (sprint-security).
- Why: shellWord protects the shell, but finding text echoed from the diff can still act as a prompt injection on the notes agent.
- Fix: write the findings to a file under build/ and run one fixed command that reads them (a run_state.sh note-file subcommand), or start the notes agent limited to Bash and the guard hook; accepted when the notes prompt holds no finding text. Queue item `sprint-security-b`.
- Category: security
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

### The Notes phase hands reviewer text to a general agent with Bash (sprint-13 security Low (3))
- Location: .claude/workflows/sprint-planning.js recordNotes
- Why: not fixed here. The workflow script has no file access, so reading the notes from a file needs an agent to write the file, and a file run with sh would bypass the guard's per-command parse of the single quoted note command, the control that holds today; the finding text stays in the prompt of the read-profile record start.
- Fix: decide whether the guard may accept a notes file under build/pipeline (checked line by line), or the run state may store a note read from a file the record start never writes; then test it.
- Category: security
- Added: 2026-11-23

### The report's not-recorded suffix and new Sweep line have no test (sprint-security quality advisory)
- Location: .claude/workflows/sprint-planning.js securityReport, sweepLine
- Why: fixed already by 8b8e44e (#307): tools/tools_test.sh runs securityReport with the unrecorded suffix and the missed count, and sweepLine for a complete sweep, a partial one, one not run, and an odd sprint; no change needed here.
- Fix: none.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-23

### The continued quality review's findings do not shape the sprint's queue
- Location: .claude/workflows/sprint-planning.js (the continued quality-reviewer start after the planner's start)
- Why: the quality reviewer's continued start runs after the planner has written the next queue and the groomed findings, so a finding it keeps over the files the planner left is recorded as a quality note of the sprint's run state but cannot be queued or groomed by that planner; it is read by the next sprint's planning only.
- Fix: run the continued review before the planner's queue step, for example by splitting the planner's sprint start into a review start and a planning start, or hand the continued findings to a second short planner start that appends them to the groomed findings.
- Category: pipeline
- Added: 2026-11-23

### The continued start's file list is agent text in a prompt
- Location: .claude/workflows/sprint-planning.js (the reviewTaskOf call for the quality continuation)
- Why: the files the planner returned in not_reviewed are joined into the continued start's prompt unfiltered, as the security continuation's are; a file name carrying instructions would reach a reviewer that holds the read guard but can still read the repository.
- Fix: pass each file through pathKey and keep only names matching a path pattern (no spaces or control characters) in both continuations.
- Category: pipeline
- Added: 2026-11-23
