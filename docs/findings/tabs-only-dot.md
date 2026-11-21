### Records runs start advisory fix rounds and a closing start that change nothing (sprint-24-records retro note 11)
- Location: .claude/workflows/deliver-change.js, the advisory fix round and closing start of a sprint-N-records run
- Why: rework 2 on 0 blocking, 1 of 8 advisories fixed, the second fix round and the closing start made 0 commits (0 closed, 7 left); sprint-23-records rework 2, sprint-22-records 1, all with 0 blocking; the advisories target groom-written files or tools/, which a records change's Out of scope forbids. Near `closing-loop-fold` (docs/queue-backlog.md Pool 9).
- Fix: a records run whose advisories all target groom-written files or tools/ starts no fix or closing contributor and sends them to its findings file; accepted when such a run records rework 0.

### The reviews phase dominates a records-only run (sprint-24-records retro note 12)
- Location: .claude/workflows/deliver-change.js, the reviews phase of a sprint-N-records run
- Why: reviews 27,661 of 68,824 output tokens (40.2 percent) and 31 of 101 calls on a diff of only docs/ records and the archived change; security 0 findings, quality 0 blocking at both passes.
- Fix: on a diff touching only docs/ records and the archived change, keep the reviews under 20 percent of output while the security review still runs on the committed diff; accepted when a records run shows it.

### The merger reported a merged commit that is not the squash commit on main (sprint-24-records note 13)
- Location: the merger's merged-commit report and its run state record (tools/run_state.sh, the merge-disagreement note)
- Why: sprint-24-records reported 50d8a3c00ee6 while the squash commit on main is 24df30ea9c94, recorded instead; a wrong merged commit would reach the history row's merged column without the check.
- Fix: the merger reports the commit `git rev-parse` gives for main after the merge; accepted when a tools-test case records a mismatched report as a disagreement and keeps main's commit.

### The tab-flow row blanks every separator character, a name with a pipe would lose it
- Location: test/editor_tab_flows.rb, blank_separators
- Why: row 0 of a tab row has its `|` and `│` blanked to compare names, so a file named with a pipe would read differently; no flow names one.
- Fix: read the tab names from the buffer list and compare them with the row cells by column from the tab widths, or add a flow with such a name once the helper reads columns.

### Backlog entries resolved by tabs-only-dot
- Location: the backlog entries "The ascii gem and the ascii modified mark are both `*`" and "tab_boundary? takes a digit after a gem as a tab boundary"
- Why: this change removes ASCII_GEM and tab_boundary?, so both entries are fixed
- Fix: groom removes both as fixed by tabs-only-dot

### The scenario "The ascii icons give the ascii gem and separator" keeps a name that no longer fits
- Location: openspec/specs/buffer-tabs/spec.md, the scenario of that name
- Why: a MODIFIED block must keep the current scenario's title, so this change could not rename it though it now asserts no gem
- Fix: a later change renames the scenario in the spec, its test comment in test/adapters_tab_bar.rb, and its task text together

### The MODIFIED scenario title still says gem
- Location: openspec/changes/tabs-only-dot/specs/buffer-tabs/spec.md:14, test/adapters_tab_bar.rb:125, tasks.md 1.1
- Why: the scenario "The ascii icons give the ascii gem and separator" asserts no gem; a MODIFIED block must keep its title to match the main spec.
- Fix: a later change renames it to "The ascii icons give the ascii separator and no gem" in the main spec, the test label, and its tasks.

### Buffer-tabs scenario title still says gem after the gem was removed
- Location: the buffer-tabs spec scenario 'The ascii icons give the ascii gem and separator', test/adapters_tab_bar.rb:125 comment, the archived tabs-only-dot tasks.md 1.1
- Why: the scenario now asserts no gem, but a MODIFIED block must keep the title, so the name no longer fits.
- Fix: a later change renames it 'The ascii icons give the ascii separator and no gem' in the spec (as a RENAMED requirement), the test comment, and the task.

### Backlog entries resolved by tabs-only-dot remain listed
- Location: the backlog entries 'The ascii gem and the ascii modified mark are both *' and 'tab_boundary? takes a digit after a gem'
- Why: ASCII_GEM and tab_boundary? were removed by this change, so both entries are stale.
- Fix: groom removes both as fixed by tabs-only-dot.

### Findings file for tabs-only-dot repeats the scenario-title entry
- Location: docs/findings/tabs-only-dot.md, the earlier entry about the scenario keeping a name that no longer fits and the later 'The MODIFIED scenario title still says gem'
- Why: two entries share the location and fix; the proposed new title, spec path, and test line are folded into the entry above.
- Fix: groom keeps one entry and drops the other as a repeat.
### Records runs start advisory fix rounds and a closing start that change nothing (sprint-24-records retro note 11)
- Location: .claude/workflows/deliver-change.js, the advisory fix round and closing start of a sprint-N-records run
- Why: rework 2 on 0 blocking, 1 of 8 advisories fixed, the second fix round and the closing start made 0 commits (0 closed, 7 left); sprint-23-records rework 2, sprint-22-records 1, all with 0 blocking; the advisories target groom-written files or tools/, which a records change's Out of scope forbids. Near `closing-loop-fold` (docs/queue-backlog.md Pool 9).
- Fix: a records run whose advisories all target groom-written files or tools/ starts no fix or closing contributor and sends them to its findings file; accepted when such a run records rework 0.

### The reviews phase dominates a records-only run (sprint-24-records retro note 12)
- Location: .claude/workflows/deliver-change.js, the reviews phase of a sprint-N-records run
- Why: reviews 27,661 of 68,824 output tokens (40.2 percent) and 31 of 101 calls on a diff of only docs/ records and the archived change; security 0 findings, quality 0 blocking at both passes.
- Fix: on a diff touching only docs/ records and the archived change, keep the reviews under 20 percent of output while the security review still runs on the committed diff; accepted when a records run shows it.

### The merger reported a merged commit that is not the squash commit on main (sprint-24-records note 13)
- Location: the merger's merged-commit report and its run state record (tools/run_state.sh, the merge-disagreement note)
- Why: sprint-24-records reported 50d8a3c00ee6 while the squash commit on main is 24df30ea9c94, recorded instead; a wrong merged commit would reach the history row's merged column without the check.
- Fix: the merger reports the commit `git rev-parse` gives for main after the merge; accepted when a tools-test case records a mismatched report as a disagreement and keeps main's commit.
