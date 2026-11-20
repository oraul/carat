### The ascii gem and the ascii modified mark are both `*`
- Location: carat/adapters/tab_bar.rb (ASCII_GEM) and the ascii `modified` icon in carat/domain/icons.rb
- Why: under option.icons ascii a tab reads `* . a.txt * |` when it is both selected and modified, the two marks differing only by position, so the selection reads less clearly than with the unicode set.
- Fix: choose another ascii gem (for example `>`) or an ascii modified mark such as `+`, with the tests of both rows, once the user picks the glyph.
### The winbar has no direct unit test of its own
- Location: test/editor_breadcrumbs.rb
- Why: the winbar's groups and the no-name word are proved only through the whole editor rig; a frame-level test with a held SymbolRequest would pin the unnamed-buffer row and the ascii separator without a language server double.
- Fix: add test/adapters_winbar.rb (make new-test) with a Window, a SymbolRequest holding names, and rows for the unnamed buffer, the ascii separator, and the accent group.
### tab_boundary? takes a digit after a gem as a tab boundary
- Location: test/editor_tab_flows.rb:147
- Why: tab_boundary? accepts a digit after a gem as well as after a space, so a separator before a name such as "*1.txt" is now dropped, while the comment says only a trailing counter " N> " (space then digit) is meant.
- Fix: accept the digit only when chars[i] == " ".
### A split part may deliver no behavior (status-winbar-tabs retro note 6)
- Location: `.claude/agents/planner.md` step 3 (the split rule); status-winbar-tabs (#262) run state notes.
- Why: status-winbar-tabs was split by painter size and the status-bar part it kept already had the Facet look, so the run spent 182,285 output tokens and 136 tool calls on one constant move and tests (plan 21196/13, scout 41011/25), merged as a refactor with skip_specs.
- Fix: every part a split delivers or queues names a frame row or test that fails at the split commit (applied by hand in the status-winbar-tabs-b plan); accepted when the next two split deliveries each change a row their acceptance names.

### Contributor rule 10 is reported skipped and advisories follow (status-winbar-tabs retro note 7)
- Location: `.claude/agents/contributor.md` rule 10 (re-read the diff with the quality-reviewer instructions).
- Why: both editing starts of status-winbar-tabs reported rule 10 skipped; the quality review then raised 5 advisories at 8573c94c2735, all on added lines, costing rework round 1; quality first pass 126/218 (57.8 percent) against check 206/218 and security 210/218.
- Fix: remove rule 10, or make it bind; accepted when the next five deliveries average no more advisories on contributor-added lines than now (removed) or under 1 (bound).

### An advisory-only fix round reruns the full check (status-winbar-tabs retro note 8)
- Location: `.claude/workflows/deliver-change.js` (the rework loop), joining the queued closing-loop-fold.
- Why: 5 test-duplication advisories at 8573c94c2735 led to a second full check at d3d5af52bbae; check 45667/6 was 25.1 percent of 182,285 output tokens against syntax-tidy 4.6 and metrics-header-fix 5.6 percent, stages summing about 846 s.
- Fix: on a run whose only rework is an advisory fix touching tests and snapshots, rerun only the stages those paths need; accepted when the check phase stays under 10 percent of output tokens on such a run.

### The medium budget sits below one delivery's floor
- Location: `docs/goals.md:23` (sizes), `docs/metrics-feature.tsv` total_tokens.
- Why: the refactor-only status-winbar-tabs (#262) took 1,226,138 total tokens against medium's 1.2M, and every medium-estimated feature row of the last ten went over: message-styling 1,470,193, finder-match-strict 1,971,222, finder-grep-preview 2,075,638, background-detect 1,756,083, so the medium estimate does not separate one change from another.
- Fix: the sprint planner's calibration weighs a medium budget from these rows (or a fixed per-delivery floor plus a per-part figure); accepted when the next six medium rows split about evenly over and under the budget.
