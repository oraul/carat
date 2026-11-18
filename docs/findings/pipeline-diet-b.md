### Fix-in-place round test checks only a hand-built state
- Location: tools/tools_test.sh:3691
- Why: the case named for the fix-in-place round only checks passedAt on a hand-built state and inPlaceCheck, so the alone branch of rounds() (contributor fix start, continue, check and both reviews again) and the reviews() wiring of reviewFindings (security only in_change non-blocking, quality advisories) are unexercised; raised twice by the quality review, merged here.
- Fix: extract the end-of-round decision into a helper returning the next step and test it, or drop the claim from the case name.

### Security reviewer prompt lacks the fixed_in_place instruction
- Location: .claude/agents/security-reviewer.md:1
- Why: the SECURITY schema gains fixed_in_place and quality-reviewer.md describes it, but security-reviewer.md says nothing, so the security side relies on the prompt alone.
- Fix: add the same one-sentence fixed_in_place instruction to security-reviewer.md.

### Periodic sweep tokens still count in the records budget
- Location: .claude/workflows/periodic-review.js:142
- Why: the sweep runs inside sprint-planning but its record start is labelled record, which add_tokens keys record, not sprint, so its tokens still count in the records change's budget; raised twice by the quality review, merged here.
- Fix: label it periodic: record or match the sweep's record in add_tokens.

### Budget line names the sprint key too narrowly
- Location: tools/run_state.sh:1795
- Why: the budget line says sprint-planning's reviews set apart though the sprint key also holds the due, notes, record, records-merged, and planner starts.
- Fix: say sprint-planning's own starts.

### Proposal names README pipeline step 8 as changed
- Location: openspec/changes/archive/2026-11-18-pipeline-diet-b/proposal.md:13 and :195
- Why: the proposal names README pipeline step 8 as changed but the diff leaves step 8 as it was; raised twice by the quality review, merged here.
- Fix: drop step 8 from the list or say why it stays.

### Two blank lines left where figuresFirst was removed
- Location: .claude/workflows/deliver-change.js:1007
- Why: removing figuresFirst left two blank lines between mayFix and qualityTask (also reported at :1009, merged here).
- Fix: keep one blank line.

### Fixed-in-place state lives only in memory across a resume
- Location: .claude/workflows/deliver-change.js:1169
- Why: fixedInPlace, awaiting, and offered live only in memory while seed rebuilds every quality-advisory note on a resume before the push, so a finding confirmed fixed in place in an earlier start (or offered just before a stop) is handed to docs/findings again.
- Fix: note each confirmed fix as fixed-in-place in the run state and have seed fill fixedInPlace from those notes.

### Run-check prompt may run moved after a failed check
- Location: .claude/workflows/deliver-change.js:924
- Why: checkRunTask lists the moved line as step 3, "Then", after the pass-only step 2, while the old prompt said once the check passed, so a run start may run moved (which writes the moved key) after a failed check.
- Fix: begin step 3 with "Only after that pass" as step 2 does.

### In-place-only rounds inflate the rework metric
- Location: .claude/workflows/deliver-change.js:1268
- Why: an in-place-only round goes through contributor('fix'), which increments rework, so metric.rework, the first-pass picture the planner reads, and the 'still blocked after N fix rounds' stop mix advisory clean-ups with blocking fixes.
- Fix: count in-place rounds in their own metric while still bounding them by ROUNDS.
### The Sprint 17 feature decision still places tab-close-d at place 1
- Location: `docs/queue-feature.md:30`.
- Why: the merge resolution of tab-close-d removed it from the Sprint 17 list, but the decision still places tab-close-d and vim-folds-b at places 1 and 2 and vim-line-commands-c third, while the list holds vim-folds-b at 1 and vim-line-commands-c at 2 (tab-close-d late finding at 5982df4f5353, quality advisory).
- Fix: say tab-close-d merged from place 1, vim-folds-b and vim-line-commands-c now at places 1 and 2.

### The tab-close-d findings entries drop the file's backticks and periods
- Location: `docs/findings/tab-close-d.md:11`.
- Why: the three late entries drop the backticks around paths and the trailing periods the file's earlier entries (lines 1 to 10) use, two formats in one file (tab-close-d late finding at 5982df4f5353, quality advisory).
- Fix: backtick the locations and end each Location, Why, and Fix line with a period as the earlier entries do.
