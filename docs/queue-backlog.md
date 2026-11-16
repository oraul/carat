# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 10

The user-approved exception: `backlog-lane-split` (T1 pipeline, user request, estimated medium, beyond the sprint, the user-approved exception), delivered first, Sprint 10's one exemption.

1. `lsp-incremental-sync` (T2 fix, estimated medium): didChange always sends whole text (`carat/adapters/json_rpc_language_gateway.rb:1311`) though ruby-lsp 0.26 announces change 2 and drops it: a stale server copy, completion InvalidLocationError. Outline: honor the announced sync kind. Accepted when a canned server announcing 2 receives ranges reproducing the buffer, one announcing 1 the whole text, allocations held. Backlog: none.

2. `ruby-structure-remove` (T2 user request, fix, estimated medium, after lsp-incremental-sync): #147's check took a 100,000-line Ruby open from 22 to 116 ms, rescans the buffer per normal-mode change (`carat/plugins/ruby/plugin.rb:74`), and `endless?` is quadratic on a long line of `def a(` (`carat/plugins/ruby/tokenizer.rb:859`, sprint-9 Low (6)). Delete `carat/plugins/ruby/structure.rb`, the plugin's event handling, #147's opener tracking (`tokenizer.rb:749` to `:859`, JUMPS), `test/editor_ruby_structure.rb`, the structure cases of `test/plugins_ruby.rb`, their map rows and docs wording, the ruby-syntax requirements by a REMOVED delta; read_buffer, place_sign, clear_signs stay. Accepted when highlighting snapshots are unchanged, lh-ruby 26.0, open-ruby 24.0 hold, the open is near 22 ms, no reference is left outside openspec/changes/archive, and a canned server's unclosed-def diagnostic signs the def line. Backlog: "### Ruby structure sign goes stale after a buffer rename", "### Ruby plugin restates the filetype tables", "### Ruby structure editor test covers only insert mode", "### Ruby structure modifier table misses most jump words", "### Ruby tokenizer keeps the loop flag across a semicolon", "### Ruby structure check rescans the whole buffer per normal-mode change", "### README wording makes the structure sign sound conditional".

## Pool

1. `spinel-notice` (T2 user request, docs, estimated medium, beyond the sprint, S11's exemption by the user): `tools/spinel/` lacks Spinel's MIT notice (#137). Accepted when a LICENSE there holds it without the email and the README credit names it. Backlog: "### Spinel's MIT notice does not travel with the vendored generated header (README.md:212)".

2. `backlog-lane-b` (T1 pipeline, estimated medium, S11's pipeline by the user, after backlog-lane-split): oldest entries first, security first, 5 to 10 of one area, a one-time triage. Accepted when 3 runs each close 5 or more of one area.

3. `ci-workflow-tidy` (T1 pipeline defect, estimated medium, split at its start, S11+ candidate): a merge changing only the `Makefile`, `bench/`, or `config/` misses the probe (`.github/workflows/main.yml:47`), skipping build, smoke, measurement; #143 `:52`, `:95`, `:151`. Accepted when a case fails before and passes after each.

4. `merged-name-guard` (T1 pipeline defect, estimated medium, pushed back 3, S11+ candidate): a merged name replayed #95 twice (123,736 tokens); the main session checks for a run state first.

5. `resume-fix-round` (T1 pipeline defect, estimated medium, S11+ candidate): twice (review-coverage, backlog-lane-a: quality blocked=3 at fa3947b) a resumed review past the push raised new blocking findings and the run stopped, a redelivery each (`.claude/workflows/deliver-change.js` blocked-on-resume stop, `tools/run_state.sh` push). Accepted when a case resumes past the push into one fix round whose push counts as a review fix, or demotes what the last pass settled. Backlog: "### A resume past the push cannot answer a new blocking review".

6. `gateway-split-a` (T5 architecture-review M1, estimated medium, pushed back 1, S11+): 1,374 lines; `json_rpc_language_gateway.rb:469` and 6 more.

7. `backlog-read-guard` (T1 pipeline, estimated small, pushed back 1): `tools/agent_guard.sh` lets a delivery read `docs/backlog.md` (#129, #140).

8. `gate-object-pin` (T1 pipeline security, estimated medium, pushed back 3, reason: Medium (5), (6), below 8, needing a planted object): `.claude/agents/merger.md:12`; `tools/gates.sh:415`.

9. `frame-painters` (T5 architecture-review M2, estimated medium, S11+): the presenter's 1,274 lines.

10. `own-line-advisories` (T1 pipeline, estimated medium, S11): #143 8 of 8 own-line advisories missed the backlog.

11. `gateway-split-b` (T5 architecture-review M1, estimated medium, S11): `json_rpc_language_gateway.rb:691`, `:838`, `:222`, `:268`.

12. `process-capture-hardening` (T3 security Lows, estimated medium, S12): sprint-9 Low (5): a relative PATH entry lets git_signs run a project's `./git` (`carat/drivers/process_runner.rb:98`). Backlog: "### Relative PATH entries let git_signs run a project's ./git" and sprint-9's 4 capture and run_program entries.

13. `hook-one-place` (T1 pipeline, estimated medium, pushed back 1, S12): `planner.md` 8,190 of 8,192 bytes; `CLAUDE.md:213`.

14. `plugin-api-split` (T5 architecture-review M3, estimated medium, S12).

15. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14, S13): merge 12+ calls in 10 of 12 runs. User fold: the merger gates at open, enables pinned auto-merge and stops; README: only a created pull request gets a footer (#150 note 17). Accepted when 5 merges take 9 calls or fewer, 3 store main's squash commit, a placeholder close restarts once or is named. Backlog: "### The close start returned a placeholder with no tool calls".

16. `language-followers` (T5 architecture-review H2, estimated medium, S13).

17. `review-demotion` (T1 pipeline defect, estimated medium, pushed back 4, S15): reviews 21.9% to 32.9% of output. Accepted when 3 runs stay under 18%.

18. `record-tier` (T1 pipeline, estimated small): record about 103,000 weighted a start. Accepted when 3 runs stay under 5,000.

19. `prose-grep-cases` (T1 pipeline, estimated medium): 17 of 957 expect lines grep prose (`tools/tools_test.sh:2790`).

20. `plan-apply-guard` (T1 pipeline, estimated small): #145's package applied the plan over the branch's queue edit.

21. `sprint-marker-tidy` (T1 pipeline advisories, estimated small): `tools/run_state.sh:1494` and 8 more; #150 notes; sprint-9 note 15 (`run_state.sh:1763`); history_rows walks HEAD and BASE twice per groom, once per status. Backlog: "### Review runs and full commits are looked up in several places of run_state.sh", "### history_rows walks the whole rev-list on every call".

22. `plan-skip` (T1 pipeline, estimated small): plan in 10 of 10 rows, 13.7% of output. Accepted when absent in 2 of the next 5 runs or at most 15%.

23. `scout-value` (T1 pipeline, estimated small): #148 scout 31,419/27, implement 95 calls. Accepted when 5 runs keep scout plus implement at 60 calls or under.

24. `language-ask-port` (T5 architecture-review H1, estimated medium, S15).

25. `sprint-security` (T1 pipeline security, estimated medium, pushed back 3): Medium (7) `sprint-planning.js:121`; `run_state.sh:1735` (sprint-9 Low (4)).

26. `content-gate-gaps` (T1 security, estimated medium, pushed back 15): Medium (7) `gates.sh:224`.

27. `ci-scope-quoting` (T1 pipeline, Low (6), estimated medium, pushed back 3): `tools/ci_scope.sh:95` and 9 more.

28. `spec-tests-first` (T1 pipeline, estimated medium, pushed back 3): quality 53/109 first pass. Accepted above 60% over 10 changes.

29. `open-pr-refusals` (T1 security Lows, estimated medium, pushed back 3).

30. `run-resume` (T1 pipeline, estimated medium, pushed back 17): `deliver-change.js:967`, `:945`: a resume re-ran quality on unchanged code.

31. `check-runner-safety` (T1 security, estimated medium, pushed back 15): Medium (6) `run_state.sh:571`; `Makefile:203`.

32. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): `open-pr.yml:45`; `scan.yml:13`.

33. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26): `open_file.rb:62`.

34. `architecture-docs` (T6, estimated small, pushed back 1): `docs/codebase-map.md:99`, `:530` and 2 more.

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

45. `plugin-host-tidy` (T6, estimated medium, pushed back 1): `plugin_router.rb:40` and 10 more.

46. `input-core-tidy` (T6, estimated medium, pushed back 1): `handle_key.rb:253`.

47. `core-correctness-b` (T6, estimated small): `buffer.rb:656` and 4 more.

48. `editing-dedup-a` (T6, estimated medium): tab width fallback in 10 places (`dispatcher.rb:112`) and 3 more.

49. `editing-dedup-b` (T6, estimated small): `walker.rb:63` and 6 more.

50. `ui-code-tidy` (T6, estimated medium, pushed back 1): `themes.rb:470`; `status_slots.rb:18`.

51. `tools-docs-tidy` (T6, estimated medium, pushed back 1): `Makefile:254`, `docs/architecture.md:351`.

52. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Decisions

- `backlog-lane-split` (T1, user request): replaces backlog-lane-a (blocked=3 at fa3947b) as Sprint 10's exception; 3 features, 2 backlog.

- Estimate medium: backlog-lane-a 296,477 output; sprint-tidy 957,700 total/46 min, review-coverage-b 909,988/86, under 1.2M.

- Not split despite 10 fixes: they fix the cherry-picked code, a split merging their defects; 5 are wording; user request.

- User decisions 1 to 3: `spinel-notice` (T2) S11's exemption; `backlog-lane-b` (T1) S11's pipeline; `resume-fix-round` (T1 defect) an S11+ candidate; claude items (T2) after S15.

- history_rows (T1 performance, 3 walks) folded into `sprint-marker-tidy`, same file.

- spinel-update note 1 (archived wording) dropped.

- Sprint-9 groom (applied only in closed 87311b9) waits again: 4 listed, 2 fixed by 67562e6, 3 duplicates.

- Security: none at 8 or above (backlog-lane-a, spinel-update 0).
