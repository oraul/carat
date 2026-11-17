# Queue: backlog

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every fix is accepted with `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 11

Drained: both Sprint 11 backlog items delivered (`review-pipeline-a`, `windows-tabs-tidy` part one); its split remainder `buffer-commands-tidy` waits in the pool; the lane waits for /sprint.

## Pool

1. `secret-patterns` (T1 pipeline security, estimated small, merge-gate rules, alone): `tools/rules.sh` ASSIGN_RE, TOKEN_RE. Backlog: "## The secret patterns miss unquoted assignments and unlisted token shapes".
2. `ruby-structure-remove` (T2 user request, fix, estimated medium, pushed back 1, S12): #147's check took a 100,000-line open from 22 to 116 ms; remove it, highlighting unchanged. Backlog: the 7 Ruby structure, filetype-table, tokenizer, and README-wording entries #147 left (sprint-9).
3. `spinel-notice` (T2 user request, docs, estimated medium, beyond the sprint by the user): Backlog: "### Spinel's MIT notice does not travel with the vendored generated header (README.md:212)".
4. `lane-guards` (T1 pipeline security, defect, estimated medium): sprint-10 Low (5) `run_state.sh:2350`; parallel-lanes-b Medium (5), Low (4), Low (3); sweep note 37.
5. `lane-records` (T1 pipeline defect, estimated small): sprint-10 note 1 (`run_state.sh:1708`); sweep notes 15, 16, 38.
6. `merge-record-check` (T1 pipeline defect, estimated small): the merge phase records the merger's head and squash commits unchecked: #162 swapped phase.ci and phase.merge, #161 recorded the merge as its CI head (2 of the last 3 runs), so the close's gates ran over 1 file instead of 15. Accepted when a tools-test case shows a CI head not the pushed head, or a merged commit not on main ending in its pull request number, refused or corrected before any phase or note is written.
7. `planner-split-rule` (T1 pipeline defect, estimated small, pushed back 1): 4-part briefs used 3 rounds.
8. `review-pipeline-b` (T1 pipeline, estimated medium): Backlog: "## The review continuations run one after the other", "## A security review after a quality-only fix reads the whole branch again".
9. `lsp-sync-fixes` (T6 correctness, estimated small): sweep notes 23, 32; lsp-incremental-sync findings.
10. `buffer-commands-tidy` (T6 correctness, estimated small, split from `windows-tabs-tidy`): `:b 0000000001` answers E86 since `largest_or_number` reads past 9 bytes as LARGEST (`carat/use_cases/ex/buffer_command_handler.rb:97`); `digits?` is written twice (`buffer_command_handler.rb:102`, `history_command_handler.rb:67`); BufferRequest's `:current` target (`carat/use_cases/buffers/buffer_request.rb:7`, built at `buffer_command_handler.rb:68`) only returns `Outcome.none` (`switch_buffer.rb:33`). Fix outline: strip leading zeros before the byte cap, one shared digits check, `:b` with no argument answered without the target. Accepted when tests show `:b 0000000001` on buffer 1, a 10-digit number past the list still E86, one `digits?` left, `:b` alone unchanged, allocations held. Backlog: "## BufferCommandHandler#digits? duplicates HistoryCommandHandler.digits?", "## A buffer number with leading zeros past nine bytes reads as the largest", "## BufferRequest's :current target exists only to return no outcome".
11. `ci-workflow-tidy` (T1 pipeline defect, estimated medium, split at its start): `main.yml:47`.
12. `gateway-split-a` (T5 architecture-review M1, estimated medium, pushed back 1).
13. `backlog-read-guard` (T1 pipeline, estimated small, pushed back 1).
14. `gate-object-pin` (T1 pipeline security, estimated medium, pushed back 3, reason: Medium (5), (6), below 8).
15. `frame-painters` (T5 architecture-review M2, estimated medium).
16. `own-line-advisories` (T1 pipeline, estimated medium).
17. `gateway-split-b` (T5 architecture-review M1, estimated medium).
18. `process-capture-hardening` (T3 security Lows, estimated medium, S12): Backlog: "### Relative PATH entries let git_signs run a project's ./git".
19. `hook-one-place` (T1 pipeline, estimated medium, pushed back 1, S12).
20. `plugin-api-split` (T5 architecture-review M3, estimated medium, S12).
21. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14, S13): merge 12+ calls in 10 of 12 runs. Backlog: "### The close start returned a placeholder with no tool calls".
22. `language-followers` (T5 architecture-review H2, estimated medium, S13).
23. `review-demotion` (T1 pipeline defect, estimated medium, pushed back 4, S15): reviews 21.9% to 36.6% of output.
24. `record-tier` (T1 pipeline, estimated small).
25. `budget-prediction` (T1 pipeline, estimated small): the small budget and the 6-tokens-per-output-token conversion miss a run's fixed overhead: sprint-10-records 639,673 total for 52,240 output (12.2), over 500,000 though the lowest of the last 21 rows; medium rows 3.5 to 7.8. Accepted when the check-pass budget line predicts under or over right for the next five runs, a small one included.
26. `prose-grep-cases` (T1 pipeline, estimated medium).
27. `plan-apply-guard` (T1 pipeline, estimated small): sprint-10-records note 3, groom took the sprint plan's feature queue naming the merged `git-signs-trust` and folded a nonexistent path, fixed by hand; accepted when tools-test cases show groom preferring `build/plan/<change>/queue-*.md` and refusing an absent path.
28. `sprint-marker-tidy` (T1 pipeline advisories, estimated small).
29. `plan-skip` (T1 pipeline, estimated small): plan in 10 of 10 rows.
30. `scout-value` (T1 pipeline, estimated small): scout 15.6% of output; 20.4% at review-pipeline-a (30155 of 147919, 14 of 117 calls), touching no `carat/` file; sprint-10-records 0 rework with none. Accepted when the next three changes touching no `carat/` file run no scout start, first.check 1, rework at most 1.
31. `check-skip` (T1 pipeline, estimated small): check first pass 113 of 115.
32. `language-ask-port` (T5 architecture-review H1, estimated medium, S15).
33. `sprint-security` (T1 pipeline security, estimated medium, pushed back 3): Medium (7).
34. `content-gate-gaps` (T1 security, estimated medium, pushed back 15): Medium (7).
35. `ci-scope-quoting` (T1 pipeline, Low (6), estimated medium, pushed back 3).
36. `spec-tests-first` (T1 pipeline, estimated medium, pushed back 3).
37. `open-pr-refusals` (T1 security Lows, estimated medium, pushed back 3).
38. `run-resume` (T1 pipeline, estimated medium, pushed back 17).
39. `check-runner-safety` (T1 security, estimated medium, pushed back 15): Medium (6); sweep note 6.
40. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): sweep Low (6).
41. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26).
42. `architecture-docs` (T6, estimated small, pushed back 1): sweep notes 17, 24 to 29, 69.
43. `periodic-blockers-b` (T6, estimated medium, pushed back 8).
44. `ex-handlers-tidy` (T6, estimated medium): sweep notes 21, 22.
45. `editing-counts`, `hover-tidy`, `signature-tidy`, `slots-tidy` (T6, estimated medium each, pushed back 11 to 13).
46. `completion-tidy`, `completion-docs-tidy`, `buffer-list-tidy`, `definitions-tidy` (T6, estimated medium each, pushed back 11 to 16).
47. `plugin-host-tidy` (T6, estimated medium, pushed back 1).
48. `input-core-tidy` (T6, estimated medium, pushed back 1): sweep notes 8 to 11.
49. `core-correctness-b` (T6, estimated small): sweep notes 4, 7, 46, 50, 51.
50. `editing-dedup-a` (T6, estimated medium): sweep notes 42 to 44, 53, 55.
51. `editing-dedup-b` (T6, estimated small).
52. `ui-code-tidy` (T6, estimated medium, pushed back 1): sweep notes 59 to 63, 66 to 68.
53. `tools-docs-tidy` (T6, estimated medium, pushed back 1): sweep notes 14, 35.
54. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Decisions

- Security first: none open (T0): review-pipeline-a security pass high=0 medium=0 at 7c4b5907ab82; the sweep High (9) `carat/plugins/git_signs/plugin.rb:23` stays fixed by f29f956 (#160).
- Split (T6): `windows-tabs-tidy` named 9 entries, over the about-four rule of `docs/goals.md` (workflow-trim, 7 fixes, 4 quality rounds; quality first pass 58/119); one entry is stale, 8 left split 5 and 3.
- `windows-tabs-tidy` delivers the windows and scroll part: float offset minimum (security Low (4)), ScrollHandler trait, half-page names, CloseOtherWindows, nine comment wraps; removed from Sprint 11.
- `buffer-commands-tidy` (T6 correctness, small) queued as pool 10 beside `lsp-sync-fixes` (T6, small): `:b 0000000001` answers E86, 3 entries of the ex buffer commands.
- Stale: "## TabRequest#counted? and CommandGrammar#operator_pending? have no caller" fixed by ad28ebd (#132), neither method left in `carat/`; listed by `windows-tabs-tidy` so groom drops it.
- Estimate medium: last 10 backlog-lane rows 639,673 to 1,739,169 total, 24 to 100 min, no code change under the 500,000 small budget.
- review-pipeline-a retro note 5 (2 of the last 3 runs' merge records wrong) to new `merge-record-check` (T1 pipeline defect, small) after `lane-records`.
- Retro note 6 (scout 20.4% of output with no `carat/` file touched, highest of 11 rows) folded into `scout-value` (T1, small).
- Retro note 7 (12.2 total per output token against the assumed 6) to new `budget-prediction` (T1 pipeline, small); note 8's overrun (639,673 against 500,000) needs no item beyond it.
