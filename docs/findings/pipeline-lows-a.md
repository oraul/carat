### The periodic quality reviewer records its notes as double-quoted shell arguments
- Location: `.claude/agents/quality-reviewer.md` Periodic mode step 4 (`sh tools/run_state.sh note <change> quality "<file>:<line> ..."`), run by `.claude/workflows/periodic-review.js`
- Why: a finding that quotes reviewed code holding `$(...)` or a backquote expands when the reviewer runs its own note command, the exposure pipeline-lows-a closed for the sprint skeptic (security Low class, found by its quality step).
- Fix: have the periodic quality reviewer return its findings only and let periodic-review.js record each with a `shellWord`-quoted note command, as sprint-planning.js `skepticNotes` does, with a tools-test case recording a finding holding `$(...)` literally.

### The sprint's security notes run in an unguarded general agent (pipeline-lows-a security Low (4))

- Location: `.claude/workflows/sprint-planning.js`, the `sprint: notes` start running `securityNotes`.
- Why: the security findings' texts quote reviewed code, and the low-effort runner holds Bash with no `tools/agent_guard.sh` hook, so planted text could lead it to run more than the one command; the skeptic's notes now run under the quality reviewer's guarded record mode, this start does not, since the read profile refuses a word naming `build/pipeline`, which a security finding may quote, and the planner would then never start.
- Fix: record the notes without an agent prompt (a fixed `tools/run_state.sh` command reading the notes as JSON from a file), or a guard profile allowing only `run_state.sh note` whose word rules let a finding text through.
