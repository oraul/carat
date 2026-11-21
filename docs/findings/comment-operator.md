### Comments.toggle copies a row's indent up to four times

- Location: `carat/domain/comments.rb`, `toggle`, `blank?`, and `commented?`.
- Why: each helper calls `Buffer#indent_of`, which copies the leading blanks, so a toggle allocates up to four strings per row; one toggle runs per command and is no hot path, so it was left in the comment-operator change (quality self-review).
- Fix: compute the indent width once per row in `toggle` and pass it to `blank?`, `commented?`, and `uncommented`.

### The last-key doubled rule could replace the g~~ guu gUU bindings

- Location: `carat/domain/command_grammar.rb`, `LAST_KEY_DOUBLED`, and `config/default.caratrc`, the `keymap.operator_pending ~`, `u`, and `U` lines.
- Why: two mechanisms give a multi-key operator its doubled form: the grammar's last-key rule for `gc` and operator_pending bindings of `~`, `u`, and `U` for the case operators; one rule would be simpler, but changing the case operators was outside the comment-operator brief (quality self-review).
- Fix: add the case operators to `LAST_KEY_DOUBLED` (or make the rule hold for every operator of more than one key), drop the three operator_pending lines, and keep the `editor_case_operators` rows for `g~~`, `guu`, and `gUU` passing.
### A change named only in a lane exception line resolves to the wrong lane (facet-design-doc retro note 16)
- Location: tools/run_state.sh:1907 lane_of and plan-apply; docs/queue-feature.md Sprint 25 exception line at 4a84ecee96f8
- Why: facet-design-doc, named in backticks only in the feature lane's exception line and merged with a docs subject, got a backlog-lane history row the contributor reverted by hand; the merged commit holds no docs/metrics-feature.tsv row (15 files) and plan-apply skipped its feature queue plan, so `one-accent` and `glyph-audit` (16 of 20 Known drift rows of docs/design.md section 7) were in 0 lines of docs/queue-feature.md.
- Fix: resolve a change named in a lane's exception line to that lane; accepted when a tools-test case does so and its package step writes only that lane's history row and applies only that lane's queue plan.

### Plan notes reach the findings file twice (facet-design-doc retro note 17)
- Location: tools/run_state.sh plan-apply, the implement step's findings append; docs/findings/facet-design-doc.md at 4a84ecee96f8
- Why: the file holds 13 headings, the 6 plan retro notes each written twice (implement appended them, package plan-apply again) plus 1 lane note; the miscount fed a blocked pull request text round (prtext 4,870 output, 10 tool calls, a second push).
- Fix: append each plan note once; accepted when a run whose implement step appends the plan notes and whose package step runs plan-apply ends with each heading once, a tools-test case or docs-lint refusing a repeated heading in a findings file.

### The check reruns stages that cannot change and confirms passing stages at a sixth to a third of a run (review-in-openspec retro note 9, merged with facet-design-doc retro note 18)
- Location: .claude/workflows/deliver-change.js, the check phase; near the queued `check-at-head` (docs/queue-backlog.md Pool 11)
- Why: review-in-openspec's check took 121,585 of 724,443 output (16.8 percent) over 3 passes, all passing; contributor-tier-high 56,453 of 260,867 (21.6 percent); groom-evidence-only 119,742 of 338,328 (35.4 percent); facet-design-doc's docs-only fix rounds reran the whole check (72,939 output, 14 calls, 4 passes plus 1 rerun recorded at the base 6bb8f2af76ff, not the head 9478b94e2686), test-run 66 s and metrics 32 s though no file under carat/, bin/, test/, bench/, or tools/ changed after 9c0fcdac9b73; check first pass 218/230.
- Fix: accepted when, over the next three deliveries with first.check 1, the check stays under 8 percent of output with no stage failure CI finds that the check left out, a round touching only docs/ and openspec/ reruns no stage, and no check record names a commit other than the head it ran for.

### A non-blocking finding fixed in place still starts a full round (review-in-openspec retro note 10)
- Location: .claude/workflows/deliver-change.js, the fix round; near `closing-loop-fold`, folded into review-in-openspec at 3102188f23a3
- Why: review-in-openspec's round 2 fixed 1 advisory (a note's wording) and output went from 375,022 at the 9b4c63623c05 check pass to 653,549 at 8045d5552c96 (278,527, 38 percent of 724,443), over the large output budget 416,666; rework rounds 246 over 230 changes.
- Fix: accepted when, over the next three deliveries, metric.rework equals the rounds started by a blocking finding or a red CI, a non-blocking finding being fixed inside a running round or recorded.

### The contributor rules card is kept twice word for word (review-in-openspec retro note 11)
- Location: .claude/agents/contributor.md and CONTRIBUTOR_CARD at .claude/workflows/deliver-change.js:879
- Why: contributor.md is 6,996 of its 6,999-byte docs-lint budget; review-in-openspec shortened its Context line and left quality_review's counts out of step 5, the gap its quality advisory note 5 flagged.
- Fix: accepted when the card's text is in one tracked place, contributor.md keeps at least 500 bytes under its budget, and a tools-test case shows every implement start still receives each rule.
