# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 10

The user-approved exception: rework-guards, backlog-lane-c (accepted when 3 runs each close 5 or more of one area), then parallel-lanes are Sprint 10's second to fourth pipeline changes, approved by the user, each one of its five.

The user-approved exception: parallel-lanes-b is Sprint 10's fifth pipeline change, approved by the user and delivered before markdown-reading-b; it counts as one of the five, since backlog-lane-split holds the sprint's one place beyond the five.

## Pool

1. `planner-split-rule` (T1 pipeline defect, estimated small, S11's pipeline change): the size check splits over about four fixes, so rework-guards and backlog-lane-b (four parts each) ran whole, used 3 rounds, went over budget or stopped. Split at three testable parts or three areas, one size up after two comparable overruns, a split proposed on a round-limit stop; `planner.md` 8,186 of 8,192 bytes: tighten to fit. Accepted when a tools-test or docs-lint case shows the three-part rule.
2. `ruby-structure-remove` (T2 user request, fix, estimated medium, after lsp-incremental-sync, S11): #147's check took a 100,000-line Ruby open from 22 to 116 ms, rescans the buffer per normal-mode change (`carat/plugins/ruby/plugin.rb:74`), and `endless?` is quadratic on a long line of `def a(` (`carat/plugins/ruby/tokenizer.rb:859`, sprint-9 Low (6)). Delete `carat/plugins/ruby/structure.rb`, the plugin's event handling, #147's opener tracking (`tokenizer.rb:749` to `:859`, JUMPS), `test/editor_ruby_structure.rb`, the structure cases of `test/plugins_ruby.rb`, their map rows and docs wording, the ruby-syntax requirements by a REMOVED delta; read_buffer, place_sign, clear_signs stay. Accepted when highlighting snapshots are unchanged, lh-ruby 26.0, open-ruby 24.0 hold, the open is near 22 ms, no reference is left outside openspec/changes/archive, and a canned server's unclosed-def diagnostic signs the def line. Backlog: "### Ruby structure sign goes stale after a buffer rename", "### Ruby plugin restates the filetype tables", "### Ruby structure editor test covers only insert mode", "### Ruby structure modifier table misses most jump words", "### Ruby tokenizer keeps the loop flag across a semicolon", "### Ruby structure check rescans the whole buffer per normal-mode change", "### README wording makes the structure sign sound conditional".
3. `spinel-notice` (T2 user request, docs, estimated medium, beyond the sprint, S11's exemption by the user): `tools/spinel/` lacks Spinel's MIT notice (#137). Accepted when a LICENSE there holds it without the email and the README credit names it. Backlog: "### Spinel's MIT notice does not travel with the vendored generated header (README.md:212)".
4. `ci-workflow-tidy` (T1 pipeline defect, estimated medium, split at its start, S11+ candidate): a merge changing only the `Makefile`, `bench/`, or `config/` misses the probe (`.github/workflows/main.yml:47`), skipping build, smoke, measurement; #143 `:52`, `:95`, `:151`. Accepted when a case fails before and passes after each.
5. `gateway-split-a` (T5 architecture-review M1, estimated medium, pushed back 1, S11+): 1,374 lines; `json_rpc_language_gateway.rb:469` and 6 more.
6. `backlog-read-guard` (T1 pipeline, estimated small, pushed back 1): `tools/agent_guard.sh` lets a delivery read `docs/backlog.md` (#129, #140).
7. `gate-object-pin` (T1 pipeline security, estimated medium, pushed back 3, reason: Medium (5), (6), below 8, needing a planted object): `.claude/agents/merger.md:12`; `tools/gates.sh:415`.
8. `frame-painters` (T5 architecture-review M2, estimated medium, S11+): the presenter's 1,274 lines.
9. `own-line-advisories` (T1 pipeline, estimated medium, S11): #143 8 of 8 own-line advisories missed the backlog.
10. `gateway-split-b` (T5 architecture-review M1, estimated medium, S11): `json_rpc_language_gateway.rb:691`, `:838`, `:222`, `:268`.
11. `process-capture-hardening` (T3 security Lows, estimated medium, S12): sprint-9 Low (5): a relative PATH entry lets git_signs run a project's `./git` (`carat/drivers/process_runner.rb:98`). Backlog: "### Relative PATH entries let git_signs run a project's ./git" and sprint-9's 4 capture and run_program entries.
12. `hook-one-place` (T1 pipeline, estimated medium, pushed back 1, S12): `planner.md` 8,186 of 8,192 bytes; `CLAUDE.md:213`; backlog-lane-split notes 5, 6 (`contributor.md:14`, `planner.md:23`).
13. `plugin-api-split` (T5 architecture-review M3, estimated medium, S12).
14. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14, S13): merge 12+ calls in 10 of 12 runs. User fold: the merger gates at open, enables pinned auto-merge and stops; README: only a created pull request gets a footer (#150 note 17). Accepted when 5 merges take 9 calls or fewer, 3 store main's squash commit, a placeholder close restarts once or is named. Backlog: "### The close start returned a placeholder with no tool calls".
15. `language-followers` (T5 architecture-review H2, estimated medium, S13).
16. `review-demotion` (T1 pipeline defect, estimated medium, pushed back 4, S15): reviews 21.9% to 32.9% of output; rework-guards: 7 of 20 quality notes repeats, one turned blocking unchanged. Accepted when 3 runs stay under 18%, 3 rework runs repeat none.
17. `record-tier` (T1 pipeline, estimated small): record about 103,000 weighted a start. Accepted when 3 runs stay under 5,000.
18. `prose-grep-cases` (T1 pipeline, estimated medium): 17 of 957 expect lines grep prose (`tools/tools_test.sh:2790`).
19. `plan-apply-guard` (T1 pipeline, estimated small): #145's package applied the plan over the branch's queue edit; backlog-lane-split note 9: no plan-needed case heads the feature lane (`tools/tools_test.sh:1360`); rework-guards: a refused records commit cost a fix start. Accepted when 5 package steps pass docs-lint first.
20. `sprint-marker-tidy` (T1 pipeline advisories, estimated small): `tools/run_state.sh:1494` and 8 more; #150 notes; sprint-9 note 15 (`run_state.sh:1763`); backlog-lane-split notes 2, 3, 7, 8 (`run_state.sh:1187`, `:236`, `:239`, the authoring-kit row): lane_of misses "`git-panel` plugin (" items. Backlog: "### Review runs and full commits are looked up in several places of run_state.sh", "### history_rows walks the whole rev-list on every call".
21. `plan-skip` (T1 pipeline, estimated small): plan in 10 of 10 rows, 13.7% of output. Accepted when absent in 2 of the next 5 runs or at most 15%.
22. `scout-value` (T1 pipeline, estimated small): #148 scout 31,419/27, implement 95 calls. Accepted when 5 runs keep scout plus implement at 60 calls or under.
23. `language-ask-port` (T5 architecture-review H1, estimated medium, S15).
24. `sprint-security` (T1 pipeline security, estimated medium, pushed back 3): Medium (7) `sprint-planning.js:121`; `run_state.sh:1735` (sprint-9 Low (4)).
25. `content-gate-gaps` (T1 security, estimated medium, pushed back 15): Medium (7) `gates.sh:224`.
26. `ci-scope-quoting` (T1 pipeline, Low (6), estimated medium, pushed back 3): `tools/ci_scope.sh:95` and 9 more.
27. `spec-tests-first` (T1 pipeline, estimated medium, pushed back 3): quality 54/111 first pass. Accepted above 60% over 10 changes.
28. `open-pr-refusals` (T1 security Lows, estimated medium, pushed back 3).
29. `run-resume` (T1 pipeline, estimated medium, pushed back 17): `deliver-change.js:967`, `:945`: a resume re-ran quality on unchanged code; backlog-lane-c note 8: a re-delivery re-planned for 34,085 of 123,956 output tokens.
30. `check-runner-safety` (T1 security, estimated medium, pushed back 15): Medium (6) `run_state.sh:571`; `Makefile:203`.
31. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): `open-pr.yml:45`; `scan.yml:13`.
32. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26): `open_file.rb:62`.
33. `architecture-docs` (T6, estimated small, pushed back 1): `docs/codebase-map.md:99`, `:530` and 2 more.
34. `periodic-blockers-b` (T6 periodic quality, estimated medium, pushed back 8).
35. `ex-handlers-tidy` (T6, estimated medium): `history_command_handler.rb:44`.
36. `editing-counts` (T6, estimated medium, pushed back 11).
37. `hover-tidy` (T6, estimated medium, pushed back 13): `show_hover.rb:74`.
38. `signature-tidy` (T6, estimated medium, pushed back 12).
39. `slots-tidy` (T6, estimated medium, pushed back 12).
40. `completion-tidy` (T6, estimated medium, pushed back 14).
41. `completion-docs-tidy` (T6, estimated medium, pushed back 14).
42. `buffer-list-tidy` (T6, estimated medium, pushed back 16).
43. `definitions-tidy` (T6, estimated medium, pushed back 11).
44. `plugin-host-tidy` (T6, estimated medium, pushed back 1): `plugin_router.rb:40` and 10 more.
45. `input-core-tidy` (T6, estimated medium, pushed back 1): `handle_key.rb:253`.
46. `core-correctness-b` (T6, estimated small): `buffer.rb:656` and 4 more.
47. `editing-dedup-a` (T6, estimated medium): tab width fallback in 10 places (`dispatcher.rb:112`) and 3 more.
48. `editing-dedup-b` (T6, estimated small): `walker.rb:63` and 6 more.
49. `ui-code-tidy` (T6, estimated medium, pushed back 1): `themes.rb:470`; `status_slots.rb:18`.
50. `tools-docs-tidy` (T6, estimated medium, pushed back 1): `Makefile:254`, `docs/architecture.md:351`.
51. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Decisions

- Delivered `lsp-incremental-sync` (T2 fix, user brief), pool item 1 removed; nothing reordered.
- Medium, kept whole (one behavior, one area): last 10 backlog rows 784,166 to 1,072,940 tokens on 9 of 10, 40 to 100 min.
- Security first: none; parallel-lanes-b has no periodic review, high=0 medium=0 at confidence 8.
- parallel-lanes-b notes: 20 (reviews 36.6% of output) to `review-demotion`, 18 (package 22 calls, an edit reverted) to `plan-apply-guard`, 19 (CLAUDE.md brief part undone 2 of 2 runs) to `hook-one-place`.
