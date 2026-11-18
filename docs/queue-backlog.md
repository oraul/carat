# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 17

1. `plugin-host-tidy` (T6 with a correctness bug, estimated medium, backlog-pick batch 2): `close_scratch` (`carat/use_cases/plugins/window_requests.rb:115`) and `close_scratch_windows` (`plugin_registry.rb:422`) look only at layout leaves, so a view a hidden slot keeps stays held and the next toggle brings it back; the side string goes through a nested ternary (`window_requests.rb:357`) and four dispatches; `ui_requests.rb:123` names a local e; 4 version tests hard-code 2.9 (`test/use_cases_plugins.rb:195`); `resized` (`plugin_events.rb:138`) builds an event with no subscriber, and `PluginRegistry#activate` builds it again (`plugin_registry.rb:260`); unwrapped comments (`plugin_api.rb:480`, `:862`, `plugin_entry.rb:9`, `plugin_host.rb:45`, `plugin_router.rb:60`, `window_requests.rb:30`, `:69`); prepare-versus-activate drift in `file_requests.rb:22`, `editor_assembly.rb:191`, `docs/codebase-map.md:121`, `:147` (`PluginHost#idle`), `docs/architecture.md:188` (`plugin_syntax.rb:48` activates), and `docs/plugins.md:40` (the Activation section splits the base class list). Fix outline: slots released, one side map, one resize builder, comments and docs as the code. Accepted when rows in `test/editor_plugins.rb` and `test/use_cases_plugin_hardening.rb` show a slot-kept view closed and released, and the version tests read `PluginApi::VERSION`. Backlog: "## The plugin prompt request names a local e", "## close_scratch misses a view its hidden slot keeps", "## The side string is mapped by a nested ternary and dispatched in four places", "## Two open_scratch comments are not rewrapped", "## A disabled plugin's view kept by a hidden slot stays held", "## The version refusal tests hard-code the host version", "## A plugin's resize event is built with no subscriber".

## Pool

1. `check-clone-toolchain` (T1 pipeline defect, security Medium (6), (4), Low (5), estimated medium, pushed back 1, reason: the sprint's one pipeline slot is pipeline-diet's): the check clone links the toolchain back (`tools/run_state.sh:893`); `tools/spec_validate.sh:17` runs OpenSpec unpinned. Backlog: "### Security: the check clone links the toolchain back into the delivery clone (sprint-6 sweep, Medium (6))", "### The check clone shares a writable toolchain (security Low (5))", "## OpenSpec runs unpinned beside the push credentials (sprint-2 sweep security Medium (4))".
2. `input-bytes-tidy` (T6 with a security Low (5), estimated medium, pushed back 1, reason: the sprint's 3 backlog slots taken): bracketed paste off (`carat/adapters/screen_presenter.rb:30`); illegal bytes as U+FFFD (`carat/domain/decoded_line.rb:25`). Backlog: "### Bracketed paste is never enabled (sprint-14 sweep security Low (5))", "## Illegal bytes are drawn as U+FFFD, not as hexadecimal markers", "## code_of decodes UTF-8 inside DisplayWidth", "## DisplayWidth.of_char has no caller".
3. `periodic-clear-rules` (T1 pipeline defect, security Medium (6), Low (4), estimated medium, batch 1 part c): `merged_since` and `passed_since` (`tools/run_state.sh`) clear a failing periodic security review unseen; 7 headings.
4. `frame-presenter-tidy` (T6, estimated medium, batch 3 part b): 8 FramePresenter and StartArt headings.
5. `check-runner-safety` (T1 pipeline defect, security Medium (6), estimated medium, pushed back 18, reason: the sprint holds one pipeline item): 3 sprint-13 headings.
6. `explorer-tidy` (T6 with a correctness bug, estimated medium, pushed back 3, reason: backlog-pick order): the tree cursor drifts when follow expands above it; 9 explorer tidy entries.
7. `lsp-tidy` (T6 with a correctness bug, estimated medium): `ProcessRunner#write` answers true after its writer fails; the gateway's copies (sprint-16 sweep 41, 44 to 50, 54).
8. `ci-trust-gaps-b` (T1 pipeline defect, security Low (6), estimated small, pushed back 1): 2 ci_scope.sh headings.
9. `ci-trust-gaps-c` (T1 pipeline defect, security Lows (5) to (3), estimated medium, pushed back 1): `tools/open_pr.sh:118`, `:196`; `sprint-planning.js:270`; 5 headings.
10. `review-scope-pins` (T1 pipeline defect, Medium (4), estimated medium, pushed back 1, split at its start): 4 review-scope headings.
11. `toolchain-clean-scope` (T1 pipeline defect, data loss, estimated small, pushed back 1): `Makefile:203`, `README.md:21`.
12. `sprint-security-b` (T1 pipeline defect, security Lows (6) to (3), estimated medium, pushed back 1): `tools/gates.sh:131`, `run_state.sh:1581`; 3 headings.
13. `motions-search-tidy-b` (T4 run time, estimated medium): sentence motions 96 ms per key on 100,000 lines (`motions.rb:418`); incsearch 1.5 s per key (`preview_search.rb:48`).
14. `motions-search-tidy-c` (T6 tidy, estimated medium): area 6 tidy, `groomed.md` copies.
15. `check-pass-budget-flag` (T1 pipeline defect, estimated small): the check-pass output budget flags runs ending under their total (plugin-lazy-activate 252,910 of 200,000 output, under 1,200,000 total); accepted at 0 false flags over 10 medium rows.
16. `records-plan-apply` (T1 pipeline defect, estimated small): a records run resuming into the planner applies 0 of its 2 plan files (sprint-16-records plan 18,412/22); accepted when no plan phase ends with 0 files applied.
17. `bench-skip-no-code` (T1 pipeline efficiency, estimated small): bench starts on diffs with no `carat/` file (11,192 output, 21 calls over 3 records runs, 0 differences); accepted when such a run records bench with no agent start.
18. `groom-fold-format` (T1 pipeline defect, estimated small): groom's fold leaves a third level-one heading and headings with no blank line, hand-fixed in sprints 10, 12, 13, 16; accepted when a records run needs no hand edit after groom.
19. `merge-main-queue-conflict` (T1 pipeline defect, estimated medium): a lane based before a records merge conflicts in `docs/queue-*.md` on merge-main and a contributor redoes the merge by hand (tab-close-d merge 60,874 output / 21 calls against 24,917 / 7, a second 16-minute CI); accepted when such a lane takes in main with no queue conflict and no contributor start.
20. `moved-review-diff` (T1 pipeline efficiency, estimated small): after merge-main both reviews rerun on a cleanly merged file (tab-close-d reviews 37,844 output / 46 calls, the second round 0 security and 0 blocking findings); accepted when they rerun exactly when the change's own diff of a file differs, a hand-resolved file always counting.
21. `advisory-findings-auto` (T1 pipeline efficiency, estimated small, after `pipeline-diet-b`): packaging hand-wrote advisory entries in two commits (tab-close-d package 60,830 output / 51 calls against a median near 8,000 / 15); accepted when advisories reach `docs/findings/<change>.md` in its one format with no contributor writing them; dropped if b's recording already does.
22. `merge-output-cap` (T1 pipeline efficiency, estimated small): merge output does not follow its call cap (pipeline-diet merge 39,483 output on 10 calls, 4 CI waits; last 10 backlog merges 15,043 average); accepted at 15,000 or less in 8 of the next 10 rows with a first-pass green CI.
23. `scout-prune-step` (T1 pipeline efficiency, estimated small): the scout's prune of old packs is refused, 1 call and 0 packs deleted (pipeline-diet scout 25,051 output / 17 calls); accepted when no scout start spends a call on it over the next 5 scouted runs.

## Decisions

- `pipeline-diet-b` delivered as written and removed (T1 pipeline defect, user request): Sprint 17 backlog item 1 at 37e72e3, the sprint's one pipeline item; quality first passes 88/158 against check 155/158.
- No further split (T1, size rule): b is part b of 2 of the 6-cut split; cuts 4 and 4b are one review round in the user's words; part a's 3 cuts ended at 912,815 / 41.2 min, quality first pass 1.
- Estimate medium, no size up (T1): merge-main-path 814,062 / 36.9 min, moved-review-carry 1,028,455 / 53.7, pipeline-diet 912,815 / 41.2; of the last 2 lane rows only sprint-16-records went over (1,615,388).
- `records-budget-scope` removed, delivered by b's cut 6 (T1): sprint-16-records 1,615,388 against 1,200,000 (its overrun note), sprint-15-records 1,215,649 on a small estimate.
- No merge-gate rule edit (T1): b's locations are the workflows, two agent files, and `run_state.sh:1750`; `tools/rules.sh` untouched, so no first change.
- Security first empty (T0): no periodic finding in the 2 pending runs; sprint-16's Medium (9) fixed by moved-review-carry (#199).
- pipeline-diet retro 8 to b (T1): `contributor.md` at 6,988 of 7,000 bytes, 2 of 6 advisories on unrelated trims; b restores the no-backlog clause if it edits that file.
- pipeline-diet retros 7, 9 queued as `merge-output-cap`, `scout-prune-step` (T1): merge 39,483 output on 10 calls; 1 refused prune.
- tab-close-d retros 12, 13, 14 queued as `merge-main-queue-conflict`, `moved-review-diff`, `advisory-findings-auto` (T1): merge 60,874 / 21, reviews 37,844 / 46, package 60,830 / 51.
- tab-close-d overruns are true flags (T1, 1,654,786 total, 392,868 check-pass output): `check-pass-budget-flag` unchanged.
- tab-close-d late findings 15, 16 to b's findings file (T6): `docs/queue-feature.md:30`, `docs/findings/tab-close-d.md:11`, feature-lane files b does not touch.
- `plugin-host-tidy` now Sprint 17 backlog item 1 (T6 with a correctness bug): 3 backlog slots held by pipeline-diet a, b, and it.
