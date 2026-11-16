# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 9

The user-approved exception: backlog-lane-a is Sprint 9's second pipeline change, approved by the user.

1. `backlog-lane-a` (T1 pipeline, user request, estimated medium): changes in flight conflict on docs/queue.md, docs/metrics.tsv, `docs/backlog.md`. Outline: the queue split into docs/queue-feature.md and docs/queue-backlog.md, the metrics into docs/metrics-feature.tsv and docs/metrics-backlog.tsv, a lane per change; each change writes its findings to `docs/findings/CHANGE.md`, folded into the backlog by the sprint grooming; a sprint of 3 features and 2 backlog changes, a pipeline change only for a defect; on a conflict the contributor keeps both sides of appended files, regenerates generated ones with make, stops when both changed the same logic, the fix staying in the change, checks and reviews rerun; every script reading the old paths updated. Accepted when make check passes, a case folds two changes' findings files, no file outside openspec/changes/archive reads the old paths, and the run reports whether the backlog lane needs its own calibration (budgets, call caps, tiers, scout and benchmark rules), decided from the backlog metrics after about 5 backlog runs, a separate workflow only if the phases differ. Backlog: none.

## Pool

1. `lsp-incremental-sync` (T2 fix, estimated small, S10): didChange goes rangeless (`carat/adapters/json_rpc_language_gateway.rb:1311`) though ruby-lsp 0.26 declares change 2 and drops it: a stale copy, completion InvalidLocationError. Accepted when a canned server announcing 2 receives a range reproducing the buffer, one announcing 1 whole text, allocations held. Backlog: none.

2. `ruby-structure-remove` (T2 user request, fix, estimated small, S10, after lsp-incremental-sync): #147's check took a 100,000-line Ruby open from 22 to 116 ms. Delete `carat/plugins/ruby/structure.rb`, the ruby plugin's event handling (on_event, check, ruby_path?, EXTENSIONS, NAMES, TYPING, the typing and waiting state), #147's opener tracking in the tokenizer, `test/editor_ruby_structure.rb` and its snapshot, the structure cases in `test/plugins_ruby.rb`, their run_all lines, map rows, README and `docs/plugins.md` wording, the ruby-syntax spec requirements by a REMOVED delta; read_buffer, place_sign, clear_signs stay. Accepted when highlighting snapshots are unchanged, lh-ruby 26.0, open-ruby 24.0, insert-ruby 38.0 hold, the open is near 22 ms, no reference is left outside openspec/changes/archive, and a canned server's unclosed-def diagnostic signs the def line. Backlog: "Ruby structure sign goes stale after a buffer rename", "Ruby plugin restates the filetype tables", "Ruby structure editor test covers only insert mode", "Ruby structure modifier table misses most jump words", "Ruby tokenizer keeps the loop flag across a semicolon", "Ruby structure check rescans the whole buffer per normal-mode change", "README wording makes the structure sign sound conditional".

3. `spinel-notice` (T2 user request, docs, estimated medium, beyond the sprint, the user-approved exception, S10's): the README credits Spinel's MIT license without its notice for `tools/spinel/` (#137 advisory 2). Accepted when a LICENSE there holds the copyright and permission notice without the email, the credit names it, docs-lint and gates pass. Backlog: "### Spinel's MIT notice does not travel with the vendored generated header (README.md:212)".

4. `ci-workflow-tidy` (T1 pipeline defect, estimated medium, split at its start, S11's pipeline): a merge changing only the `Makefile`, `tools/metrics.sh`, `bench/`, or `config/` misses the .rb-keyed probe (`.github/workflows/main.yml:47`), skipping the release build, smoke (`main.yml:155`), measurement; #143 advisories (`main.yml:52`, `:95`, `:151`). Accepted when a case fails before and passes after each.

5. `backlog-lane-b` (T1 pipeline, estimated medium, S11): the backlog lane takes the oldest entries first, security first, 5 to 10 neighbours of one file or area a change, plus a one-time `backlog-triage` of stale and duplicate entries in the planner's sprint mode (about 1,063 entries; the last 12 merges added 117, removed 19). Accepted when 3 backlog runs each close 5 or more entries of one area and the triage's groom names every removal.

6. `merged-name-guard` (T1 pipeline defect, estimated medium, pushed back 3, S11): a merged name replayed #95 twice (120K; `/deliver spinel-bump` 123,736 tokens, nothing done). Accepted when a case refuses or fresh-starts it.

7. `gateway-split-a` (T5 architecture-review M1, estimated medium, pushed back 1, S11+): 1,374 lines; `lsp-client-tidy`, `json_rpc_language_gateway.rb:469` and 6 more.

8. `backlog-read-guard` (T1 pipeline, estimated small, pushed back 1): `tools/agent_guard.sh` lets a delivery read `docs/backlog.md` (#129, #140). Accepted when a case refuses each read form, an append passing.

9. `gate-object-pin` (T1 pipeline security, estimated medium, pushed back 3, reason: Medium (5), (6), below 8, needing a planted object): `.claude/agents/merger.md:12`; `tools/gates.sh:415`.

10. `frame-painters` (T5 architecture-review M2, estimated medium, S11+): the presenter's 1,274 lines.

11. `own-line-advisories` (T1 pipeline, estimated medium, S11): #143 8 of 8 own-line advisories missed the backlog. Accepted when a case finds every handed finding merged.

12. `gateway-split-b` (T5 architecture-review M1, estimated medium, S11): `json_rpc_language_gateway.rb:691`, `:838`, `:222`, `:268`.

13. `hook-one-place` (T1 pipeline, estimated medium, pushed back 1, S12): `planner.md` 8,190 of 8,192 bytes; `CLAUDE.md:213`.

14. `plugin-api-split` (T5 architecture-review M3, estimated medium, S12).

15. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14, S13): merge 12+ calls in 10 of 12 runs; #146 stored wrong commits, its close "placeholder", 0 calls. User fold: the merger runs the merge gates at open, enables auto-merge (squash, pr.md's exact title and body, pinned to the pushed head) and stops, checks spin, text, pushed waiting; only a pull request created from a session gets a footer, not an edited one (#150 note 17), so the README says creation. Accepted when 5 merges take 9 calls or fewer, 3 store main's squash commit, a placeholder close restarts once or is named. Backlog: "### The close start returned a placeholder with no tool calls".

16. `language-followers` (T5 architecture-review H2, estimated medium, S13).

17. `review-demotion` (T1 pipeline defect, estimated medium, pushed back 4, S15): reviews 21.9% to 32.9% of output (#141 to #147). Accepted when 3 runs stay under 18%, quality first pass no lower.

18. `record-tier` (T1 pipeline, estimated small): record about 103,000 weighted a start, the checker 1,113 to 3,506. Accepted when 3 runs stay under 5,000.

19. `prose-grep-cases` (T1 pipeline, estimated medium): 17 of 957 expect lines grep prose (`tools/tools_test.sh:2790`); tools-test 92 of 217 check seconds. Accepted when none greps provable prose.

20. `plan-apply-guard` (T1 pipeline, estimated small): #145's package applied the plan over the branch's queue edit. Accepted when a case keeps the edit or names the conflict.

21. `sprint-marker-tidy` (T1 pipeline advisories, estimated small): sprint-8, #145, #149 (`tools/run_state.sh:1494` and 8 more); #150 notes 2 to 5, 7 to 10, 13, 14, 16 (`run_state.sh:1752` to `:1828`, `deliver-change.js:977`, `docs/codebase-map.md:51`).

22. `plan-skip` (T1 pipeline, estimated small): plan in 10 of 10 rows, 13.7% of output. Accepted when absent in 2 of the next 5 runs, no reorder missed.

23. `scout-value` (T1 pipeline, estimated small): #148 scout 31,419/27, implement 95 calls; scout at 3 calls or fewer averaged 55.5 implement calls, at 25+ 64.5. Accepted when 5 runs keep scout plus implement at 60 calls or under.

24. `language-ask-port` (T5 architecture-review H1, estimated medium, S15).

25. `sprint-security` (T1 pipeline security, estimated medium, pushed back 3): Medium (7) `sprint-planning.js:121`; #150 notes 6, 11, 12, 15: a sprint-diff pass or an earlier-planned merge clears a failing whole-tree review (`run_state.sh:1735` and 2 more).

26. `content-gate-gaps` (T1 security, estimated medium, pushed back 15): Medium (7) `gates.sh:224`.

27. `ci-scope-quoting` (T1 pipeline, Low (6), estimated medium, pushed back 3): `tools/ci_scope.sh:95` and 9 more.

28. `spec-tests-first` (T1 pipeline, estimated medium, pushed back 3): quality 53/108 first pass. Accepted above 60% over 10 changes.

29. `open-pr-refusals` (T1 security Lows, estimated medium, pushed back 3).

30. `run-resume` (T1 pipeline, estimated medium, pushed back 17): `deliver-change.js:967` (#141); a resume after the push re-ran quality on unchanged code, an advisory turned blocking with no fix path (1af8f2b, `deliver-change.js:945`): carry reviews when only package commits changed or allow one review-fix push; a superseding branch carries one new pr.md (open_pr.sh read refused review-coverage-b's two).

31. `check-runner-safety` (T1 security, estimated medium, pushed back 15): Medium (6) `run_state.sh:571`; `Makefile:203`.

32. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): `open-pr.yml:45`; `scan.yml:13`.

33. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26): `open_file.rb:62`.

34. `architecture-docs` (T6, estimated small, pushed back 1): `docs/codebase-map.md:99`, `:232`, `:530`; `carat/testing.rb:4`.

35. `periodic-blockers-b` (T6 periodic quality, estimated medium, pushed back 8).

36. `ex-handlers-tidy` (T6, estimated medium): `history_command_handler.rb:44`.

37. `editing-counts` (T6, estimated medium, pushed back 11).

38. `hover-tidy` (T6, estimated medium, pushed back 13): `show_hover.rb:74`.

39. `signature-tidy` (T6, estimated medium, pushed back 12).

40. `slots-tidy` (T6, estimated medium, pushed back 12).

41. `completion-tidy` (T6, estimated medium, pushed back 14).

42. `completion-docs-tidy` (T6, estimated medium, pushed back 14).

43. `buffer-list-tidy` (T6, estimated medium, pushed back 16).

44. `definitions-tidy` (T6, estimated medium, pushed back 11).

45. `plugin-host-tidy` (T6, estimated medium, pushed back 1): `plugin_router.rb:40`; `plugin_host.rb:73` and 9 more.

46. `input-core-tidy` (T6, estimated medium, pushed back 1): `handle_key.rb:253`.

47. `core-correctness-b` (T6, estimated small): `buffer.rb:656` and 4 more.

48. `editing-dedup-a` (T6, estimated medium): tab width fallback in 10 places (`dispatcher.rb:112`) and 3 more.

49. `editing-dedup-b` (T6, estimated small): `walker.rb:63` and 6 more.

50. `ui-code-tidy` (T6, estimated medium, pushed back 1): `themes.rb:470` and 1 more.

51. `tools-docs-tidy` (T6, estimated medium, pushed back 1): `Makefile:254`, `docs/architecture.md:351`; #136 to #143 advisories.

52. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Decisions

- `spinel-update` (T2 user request), this change, estimated medium, not split: `spinel-untyped-bump` 935,582 total, `spinel-rebump` 862,013; `spinel-warnings` 1,443,603 the risk.

- Beyond Sprint 9, its exemption (user); pool 63 `spinel-bump` removed (#95's run state replays).

- Sprint 9: 3 features (#146 to #148), 2 fixes (#150, `backlog-lane-a` T1, the approved second pipeline); `lsp-incremental-sync` to S10 (user 1).

- S10 pool 1 to 6: 3 features, 2 fixes, `spinel-notice` the exemption (user 3); `ruby-structure-bound` removed.

- S11 head pool 7 to 10 (user 4, 8): 3 T1 pipeline items for the sprint-10 planner to fit; `markdown-reading-c` pool 11 (user 5).

- Folds (user 6 to 8): #150 note 17 into `merge-gate-integrity`, 1af8f2b into `run-resume`, 123,736 tokens into `merged-name-guard`; Guide: user 9, 10, lanes no longer dropped.

- Former S10 tags (pool 12 to 16, 19) become S11+, order kept; pool lines cut for the byte budget, no finding dropped.

- #150 notes 6, 11, 12, 15 into `sprint-security` (T1), its other advisories into `sprint-marker-tidy` (T1); note 1 blocking not raised in rounds 2, 3.

- Security: none open at 8 or above: #150 medium 1 below 8, sprint-8 blocking 0. Pace: quality 53/108 first pass, ci 104/110, 90 rework over 108.
