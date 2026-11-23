# Brief

CHANGE: check-jobs-lows   LANE: backlog   BRANCH: bugfix/check-jobs-lows   BASE: 77c4228620b5
WHERE: `tools/run_state.sh:637` stages_reap and the jobs directory beside the check clone, `:639`, `:778` the failing stage's log excerpt.
WHY: a stage's branch code can write a sibling stage's pass into the runner's job files (Medium, confidence 6, reported twice), and a failing stage's excerpt reaches the terminal with its control bytes (Low (4), reported twice).
OUTCOME: a stage's pass comes only from what the runner itself observed, beyond the stages' reach; the excerpt shows control bytes as visible text. Covers the backlog entries: "### A stage's branch code can forge its pass record through the runner's job files (security Medium, confidence 6)", "### A check stage can fake a sibling stage's pass through the job files (sprint-13 security Medium (6))", "### A failing stage's log excerpt reaches the terminal unfiltered (security Low, confidence 4)", "### The failing stage's log excerpt reaches the terminal unfiltered (sprint-13 security Low (4))".
ACCEPTED WHEN: a tools-test case where a stage writes another stage's job file, and one whose log holds an ESC sequence, fail before.
CONSTRAINTS: only the repository rules that apply; none added
OUT OF SCOPE: anything not named in OUTCOME
USER DECISIONS: none
