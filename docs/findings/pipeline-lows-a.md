### The periodic quality reviewer records its notes as double-quoted shell arguments
- Location: `.claude/agents/quality-reviewer.md` Periodic mode step 4 (`sh tools/run_state.sh note <change> quality "<file>:<line> ..."`), run by `.claude/workflows/periodic-review.js`
- Why: a finding that quotes reviewed code holding `$(...)` or a backquote expands when the reviewer runs its own note command, the exposure pipeline-lows-a closed for the sprint skeptic (security Low class, found by its quality step).
- Fix: have the periodic quality reviewer return its findings only and let periodic-review.js record each with a `shellWord`-quoted note command, as sprint-planning.js `skepticNotes` does, with a tools-test case recording a finding holding `$(...)` literally.

### The sprint's security notes run in an unguarded general agent (pipeline-lows-a security Low (4))

- Location: `.claude/workflows/sprint-planning.js`, the `sprint: notes` start running `securityNotes`.
- Why: the security findings' texts quote reviewed code, and the low-effort runner holds Bash with no `tools/agent_guard.sh` hook, so planted text could lead it to run more than the one command; the skeptic's notes now run under the quality reviewer's guarded record mode, this start does not, since the read profile refuses a word naming `build/pipeline`, which a security finding may quote, and the planner would then never start.
- Fix: record the notes without an agent prompt (a fixed `tools/run_state.sh` command reading the notes as JSON from a file), or a guard profile allowing only `run_state.sh note` whose word rules let a finding text through.

### The sprint's security notes run in an unguarded general agent (security Low (4))
- Location: `.claude/workflows/sprint-planning.js:231` (securityNotes, the 'sprint: notes' start).
- Why: the sprint's security notes still run in a general agent with Bash and no `tools/agent_guard.sh` hook; a merged change can plant code whose quoted text, carried into a security finding, carries instructions, and the low-effort runner may follow them instead of running only the one note command. This predates pipeline-lows-a, which moved only the skeptic's notes under the guarded quality reviewer.
- Fix: record the notes without an agent prompt: the workflow writes the notes as JSON to a file, and a fixed `tools/run_state.sh` command reads that file; or start the runner under an agent type whose hook runs `tools/agent_guard.sh` with a profile that allows only `run_state.sh note`, and whose word rules let a finding's text through, including one that names build/pipeline.
none
