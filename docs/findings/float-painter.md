### The float key's layout is read in two classes at carat/adapters/frame_presenter.rb
- Location: `carat/adapters/frame_presenter.rb` `forget_rows`, `compare_boxes`, `covers?` (walking by `FloatPainter::STRIDE`), and `carat/adapters/float_painter.rb` `build_float_key`, `add_notice_boxes`.
- Why: the presenter reads the box rows and columns at offsets 0 to 3 of each `STRIDE` group the float painter writes, so a change of the key's layout must be made in both files.
- Fix: give `FloatPainter` the box queries over a key (`covers?`, and a row range per box the presenter iterates for `forget_rows` and `compare_boxes`), so only it knows the offsets.
### The scout re-packs lines the plan already cites (folded-row retro note 2)
- Location: .claude/workflows/deliver-change.js, the areas and scout phases; a near-same note of "### A one-area change still gets a scout pack (buffer-picker retro note 3, merge-gate-lows retro note 4)" and backlog queue Pool 14 `areas-in-plan`, `scout-prune`: merge into them.
- Why: folded-row scout 35,225/40 (23.6 percent of 149,066 output, 25.3 percent of 158 calls, 91 percent of implement's 44 calls) for 2 areas after the plan named `frame_presenter.rb:881` to `:883` and `themes.rb:226`, `:278`, `:330`, `:382`; set-options 28.7 percent, hidden-option 31.3 percent.
- Fix: no scout pack for an area whose edits the plan cites by path and line; accepted when, over the next 5 feature runs whose plan cites every edit, scout is at most 10 percent of output tokens and first-pass check stays 1.

### A first-pass green CI still costs the merger 33,972 output tokens (folded-row retro note 3)
- Location: the merge phase of .claude/workflows/deliver-change.js; a near-same note of "### The merger spends about half its calls polling CI (buffer-picker retro note 4)" and backlog queue Pool 14 `merge-wait-bound`: merge into them.
- Why: folded-row merge 33,972/13 (22.8 percent of output), ci_wait_calls 6, CI green in 10 min; the same 13 calls cost 14,637 (colorscheme-command) and 16,600 (buffer-picker); border-vocabulary 142,172 (27.4 percent).
- Fix: a bounded, cheap wait for a green first CI; accepted when the next 5 runs with first.ci 1 and rework 0 keep merge at or under 17,000 output tokens in 13 calls or fewer.

### Head-form notes record a head git confirms (folded-row retro note 4, notes 1 and 5)
- Location: tools/run_state.sh and .claude/workflows/deliver-change.js, the head check of a contributor start; backlog queue Pool 14 `head-drop`: merge into it.
- Why: 39 taken-from-git notes across the run states, 0 refused; folded-row 2 more (implement be275416f50a, package 6ec0fe0457d8), neither refused; 43 head-form notes in 16 runs; none changed a decision.
- Fix: no record line when git corrects a reported head to the same commit; accepted when the next 5 runs record no head-form note and tools-test still shows a head that differs from git refused.
