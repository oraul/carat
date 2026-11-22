### The periodic quality reviewer records its notes as double-quoted shell arguments
- Location: `.claude/agents/quality-reviewer.md` Periodic mode step 4 (`sh tools/run_state.sh note <change> quality "<file>:<line> ..."`), run by `.claude/workflows/periodic-review.js`
- Why: a finding that quotes reviewed code holding `$(...)` or a backquote expands when the reviewer runs its own note command, the exposure pipeline-lows-a closed for the sprint skeptic (security Low class, found by its quality step).
- Fix: have the periodic quality reviewer return its findings only and let periodic-review.js record each with a `shellWord`-quoted note command, as sprint-planning.js `skepticNotes` does, with a tools-test case recording a finding holding `$(...)` literally.
