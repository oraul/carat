### RISKY_CONFIG omits pager keys (sprint-14 sweep security Low (3))
- Location: tools/agent_guard.sh RISKY_CONFIG, tools/rules.sh:60
- Why: the line must change in tools/rules.sh with the guard's copy (tools/tools_test.sh requires them equal), and the brief stops a change that edits tools/rules.sh; moved to risky-config-pager (Pool 1), not fixed here.
- Fix: add the pager keys to both lines in the one change that may edit tools/rules.sh.

### The Notes phase hands reviewer text to a general agent with Bash (sprint-13 security Low (3))
- Location: .claude/workflows/sprint-planning.js recordNotes
- Why: not fixed here. The workflow script has no file access, so reading the notes from a file needs an agent to write the file, and a file run with sh would bypass the guard's per-command parse of the single quoted note command, the control that holds today; the finding text stays in the prompt of the read-profile record start.
- Fix: decide whether the guard may accept a notes file under build/pipeline (checked line by line), or the run state may store a note read from a file the record start never writes; then test it.

### A post-review prose edit in the package step refuses the push (lsp-container-b retro note 12)
- Location: .claude/workflows/deliver-change.js package step, tools/run_state.sh reviewed_edits
- Why: not fixed here; the delivery cannot read the backlog entry, and the heading alone does not say whether prose files may settle across the security pass or the review reruns.
- Fix: state the rule in the entry (which prose paths settle), then add the path to the settle rule with a tools-test case.

### The in-run budget line prices total tokens at 6 per output token (lsp-container-b retro note 13, sprint-security retro note 8)
- Location: tools/run_state.sh OUTPUT_SHARE and spent_line, .claude/workflows/deliver-change.js SPENT_LINE
- Why: not fixed here; history rows run from 3.5 to 59 total tokens per output token, and the entry's fix (a measured share, a range, or the total as the figure) is not stated in the heading.
- Fix: derive the share from the history rows' median or print the total-token figure, keep SPENT_LINE and the tools-test regex in step.

### tools/spec_validate.sh runs the command of OPENSPEC_CMD, and path_of (security Lows of the periodic review at 186ddfb)
- Location: tools/spec_validate.sh:20, carat/adapters/json_rpc_language_gateway.rb path_of
- Why: not fixed here; the queue entry names the two locations only, and the delivery cannot open the backlog heading that states each Low. path_of already refuses NUL, dot segments, overlong and surrogate escapes, and a path over its limit; control characters below 0x20 in a decoded path are the one open case seen.
- Fix: read the heading's text, then refuse the case with a test per heading (a carat/ edit also runs the benchmark phase).

### The report's not-recorded suffix and new Sweep line have no test (sprint-security quality advisory)
- Location: .claude/workflows/sprint-planning.js securityReport, sweepLine
- Why: fixed already by 8b8e44e (#307): tools/tools_test.sh runs securityReport with the unrecorded suffix and the missed count, and sweepLine for a complete sweep, a partial one, one not run, and an odd sprint; no change needed here.
- Fix: none.

### groom_row's untracked sprint marker (sprint-14 review security Low (3) and quality)
- Location: tools/run_state.sh sprint_row_at, build/plan/sprint
- Why: the marker lives in the ignored build/plan, so it cannot be committed; sprint-row checks the sprint it names against the committed sprint log and uses it for no other value, so a forged marker can only name the sprint in progress. Rows are now read from committed content and compared byte for byte; a branch's own appended history rows stay trusted since the package step appends the change's row after the review.
- Fix: none needed unless the marker gains another value; then derive it from docs/sprints.tsv alone.
